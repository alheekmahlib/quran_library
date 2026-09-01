/// محرّك تقييم التلاوة بِنموذج Quran-Lab zipformer v3.1 عبر sherpa-onnx.
///
/// نموذج streaming zipformer2-ctc (73MB int8) + kaldi fbank ‏80-dim داخل
/// sherpa. يدعم مسار الدفعة (WAV كامل) والوضع الحي (بثّ PCM).
library;

import 'dart:developer' show log;
import 'dart:io';
import 'dart:math' show sqrt;
import 'dart:typed_data';

import 'asset_loader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'error_detector.dart';
import 'live_recitation_engine.dart';
import 'madd_timing.dart';
import 'models/muaalem_config.dart';
import 'models/recitation_result.dart';
import 'phoneme_aligner.dart';
import 'quran_reference.dart';
import 'quran_units.dart';
import 'range_tracker.dart';
import '../core/services/tasmee_reference_store.dart';
import 'wav_decoder.dart';
import 'zipformer_model.dart';

/// محرّك offline يشغّل zipformer v3.1 محليًا (دفعة + بثّ حي).
class SherpaZipformerEngine implements LiveCapableRecitationEngine {
  SherpaZipformerEngine({
    this.modelPath,
    this.tokensPath,
    this.referencePath,
    this.maddTimingConfig = const MaddTimingConfig(),
  });

  final String? modelPath;
  final String? tokensPath;
  final String? referencePath;
  final MaddTimingConfig maddTimingConfig;

  sherpa.OnlineRecognizer? _recognizer;
  QuranUnitLexicon? _lexicon;
  QuranPhonemeReference? _reference;
  bool _initialized = false;

  // حالة البثّ الحي.
  sherpa.OnlineStream? _liveStream;
  void Function(LiveRecognitionFrame frame)? _onPartial;
  void Function()? _onEndpoint;

  // تتبّع الكلمة الجارية (إن مُرّرت الآية عند startLive).
  QuranReferenceVerse? _liveRef;
  void Function(int wordIdx)? _onWord;
  int _lastLiveUnitCount = 0;
  int _lastLiveWordIdx = -1;

  // تتبّع النطاق متعدد الآيات (وضع الصفحة) — يُفوَّض إلى RangeLiveTracker.
  QuranReferenceRange? _liveRange;
  RangeLiveTracker? _rangeTracker;

  @override
  Future<bool> isHealthy() async => _initialized && _recognizer != null;

  @override
  String? getVerseText({required int suraIdx, required int ayaIdx}) {
    if (!(_reference?.isLoaded ?? false)) return null;
    return _reference!.getReference(suraIdx: suraIdx, ayaIdx: ayaIdx)?.uthmani;
  }

  /// تهيئة: نموذج + معجم + مرجع + مُتعرّف sherpa.
  Future<void> initialize() async {
    if (_initialized) return;
    // ربط FFI — في تطبيقات Flutter تُحمَّل الرموز من مكتبة الإضافة المضمنة.
    sherpa.initBindings();

    final resolvedModel = await _resolveModelPath();
    // المرجع المشترك (يشاركه TasmeeCtrl) — تحميل واحد لِلذاكرة.
    await TasmeeReferenceStore.instance.load(
      tokensPath: tokensPath,
      filePath: referencePath,
    );
    _lexicon = TasmeeReferenceStore.instance.lexicon;
    _reference = TasmeeReferenceStore.instance.reference;

    final config = sherpa.OnlineRecognizerConfig(
      model: sherpa.OnlineModelConfig(
        zipformer2Ctc:
            sherpa.OnlineZipformer2CtcModelConfig(model: resolvedModel),
        tokens: await _materializeTokensForSherpa(),
        numThreads: 2,
        debug: false,
      ),
      decodingMethod: 'greedy_search',
      feat: const sherpa.FeatureConfig(sampleRate: 16000, featureDim: 80),
      enableEndpoint: true,
      rule1MinTrailingSilence: 2.4,
      rule2MinTrailingSilence: 1.2,
      rule3MinUtteranceLength: 20,
    );
    _recognizer = sherpa.OnlineRecognizer(config);
    _initialized = true;
    log('SherpaZipformerEngine: ready ✓', name: 'ZipformerEngine');
  }

  /// يحلّ مسار النموذج: مسار صريح → مجلد التطبيق (>60MB) → خطأ واضح.
  Future<String> _resolveModelPath() async {
    if (modelPath != null && modelPath!.isNotEmpty) {
      final f = File(modelPath!);
      if (await f.exists()) return modelPath!;
    }
    final appDir = await getApplicationSupportDirectory();
    final p = '${appDir.path}/$kZipformerModelFileName';
    final f = File(p);
    if (await f.exists() && await f.length() > 60 * 1024 * 1024) return p;
    throw Exception(
        'النموذج غير موجود. نزّله أولًا (≈73MB).\nالمسار المتوقع: $p');
  }

  Future<String> _loadTokens() async {
    if (tokensPath != null && File(tokensPath!).existsSync()) {
      return File(tokensPath!).readAsStringSync();
    }
    return loadPackageAssetString('assets/quran_lab/tokens.txt');
  }

  /// sherpa يقرأ tokens من ملف على القرص — اكتب نسخة من الأصل إلى مجلد
  /// التطبيق مرّة واحدة (الأصل مُضمَّن كـ asset).
  Future<String> _materializeTokensForSherpa() async {
    final appDir = await getApplicationSupportDirectory();
    final p = '${appDir.path}/zipformer_tokens.txt';
    final f = File(p);
    if (!await f.exists()) {
      await f.writeAsString(await _loadTokens(), flush: true);
    }
    return p;
  }

  // ── مسار الدفعة ────────────────────────────────────────────────

  @override
  Future<RecitationResult> correctRecitation({
    required Uint8List wavBytes,
    MuaalemConfig config = const MuaalemConfig(),
    double errorRatio = 0.1,
    int? suraIdx,
    int? ayaIdx,
    QuranReferenceRange? range,
    String? referenceText,
  }) async {
    if (!_initialized) await initialize();

    final decoded = decodeWavBytes(wavBytes);
    if (decoded == null) {
      return const RecitationResult(noMatchMessage: 'تعذّر قراءة ملفّ الصوت');
    }
    final samples = _normalizeAmplitude(decoded.samples);
    final durationSec = samples.length / decoded.sampleRate;
    final frame = _recognizeBuffer(samples, decoded.sampleRate);
    return _evaluateUnits(
      frame: frame,
      durationSec: durationSec,
      suraIdx: suraIdx,
      ayaIdx: ayaIdx,
      range: range,
      referenceText: referenceText,
    );
  }

  /// يشغّل كامل العازلة عبر مُتعرّف بثّي (دفعات 0.1s + صمت ختامي).
  LiveRecognitionFrame _recognizeBuffer(Float64List samples, int sampleRate) {
    final rec = _recognizer!;
    final stream = rec.createStream();
    final pcm = _asFloat32(samples); // تحويل واحد قبل الحلقة.
    const chunk = 1600; // 0.1s @ 16k.
    for (var i = 0; i < pcm.length; i += chunk) {
      final end = (i + chunk > pcm.length) ? pcm.length : i + chunk;
      stream.acceptWaveform(
        samples: Float32List.sublistView(pcm, i, end),
        sampleRate: sampleRate,
      );
      while (rec.isReady(stream)) {
        rec.decode(stream);
      }
    }
    _feedTailSilence(stream, sampleRate);
    final frame = _frameFromResult(rec.getResult(stream));
    stream.free();
    return frame;
  }

  /// تطبيع السعة (نقلًا من المحرّك السابق): peak→0.7 ثم رفع RMS≥0.03→0.06.
  Float64List _normalizeAmplitude(Float64List input) {
    var peak = 0.0;
    for (final s in input) {
      final a = s.abs();
      if (a > peak) peak = a;
    }
    if (peak < 1e-6) return input;
    final scale = 0.7 / peak;
    final out = Float64List(input.length);
    var sumSq = 0.0;
    for (var i = 0; i < input.length; i++) {
      out[i] = input[i] * scale;
      sumSq += out[i] * out[i];
    }
    final rms = sqrt(sumSq / input.length);
    if (rms < 0.03) {
      final boost = (0.06 / (rms < 1e-6 ? 1e-6 : rms)).clamp(0.0, 20.0);
      for (var i = 0; i < out.length; i++) {
        var v = out[i] * boost;
        if (v > 1.0) v = 1.0;
        if (v < -1.0) v = -1.0;
        out[i] = v;
      }
    }
    return out;
  }

  // ── الوضع الحي ────────────────────────────────────────────────

  @override
  void startLive({
    void Function(LiveRecognitionFrame frame)? onPartial,
    void Function()? onEndpoint,
    void Function(int wordIdx)? onWord,
    void Function(int verseIdx, int wordIdx)? onRangeWord,
    void Function(int verseIdx, int wordIdx, bool correct)? onWordDone,
    void Function()? onRangeComplete,
    int? suraIdx,
    int? ayaIdx,
    QuranReferenceRange? range,
  }) {
    _liveStream?.free();
    _liveStream = _recognizer!.createStream();
    _onPartial = onPartial;
    _onEndpoint = onEndpoint;
    _onWord = onWord;
    _lastLiveUnitCount = 0;
    _lastLiveWordIdx = -1;
    _liveRef =
        (suraIdx != null && ayaIdx != null && (_reference?.isLoaded ?? false))
            ? _reference!.getReference(suraIdx: suraIdx, ayaIdx: ayaIdx)
            : null;
    _liveRange =
        (range != null && (_reference?.isLoaded ?? false)) ? range : null;
    _rangeTracker = _liveRange == null
        ? null
        : RangeLiveTracker(
            range: _liveRange!,
            onRangeWord: onRangeWord,
            onWordDone: onWordDone,
            onRangeComplete: onRangeComplete,
          );
  }

  @override
  void feedPcm(Float32List samples) {
    final stream = _liveStream;
    if (stream == null || !_initialized) return;
    stream.acceptWaveform(samples: samples, sampleRate: 16000);
    while (_recognizer!.isReady(stream)) {
      _recognizer!.decode(stream);
    }
    if (_recognizer!.isEndpoint(stream)) {
      _onEndpoint?.call();
    }
    final frame = _frameFromResult(_recognizer!.getResult(stream));
    _onPartial?.call(frame);
    _maybeReportLiveWord(frame);
  }

  /// يحاذي الوحدات المتنامية مع الآية ويُبلّغ فهرس الكلمة الجارية.
  ///
  /// يعاد الحساب فقط عند نموّ الوحدات (لا مع كل دفعة PCM صامتة)،
  /// وأبعد موضع مُطابَق يحدّد الكلمة الحالية.
  void _maybeReportLiveWord(LiveRecognitionFrame frame) {
    if (_liveRange != null) {
      _trackLiveRange(frame);
      return;
    }
    final ref = _liveRef;
    final onWord = _onWord;
    if (ref == null || onWord == null) return;
    if (frame.units.length == _lastLiveUnitCount) return;
    _lastLiveUnitCount = frame.units.length;

    final lex = _lexicon!;
    // الرموز مُرشَّحة أصلًا في _frameFromResult لِضمان وجودها بالمعجم.
    final predUnits =
        frame.units.map((s) => lex.bySymbol[s]!).toList(growable: false);
    final ops = alignUnits(ref.units, predUnits);
    final lastIdx = lastMatchedRefIdx(ops);
    final wordIdx = lastIdx < 0 ? -1 : ref.unitWordIdx[lastIdx];
    if (wordIdx != _lastLiveWordIdx) {
      _lastLiveWordIdx = wordIdx;
      onWord(wordIdx);
    }
  }

  /// يتبّع التلاوة على نطاق متعدد الآيات (وضع الصفحة) — يُفوَّض بالكامل
  /// إلى [RangeLiveTracker] (منطق نقي قابل لِلاختبار بلا sherpa).
  void _trackLiveRange(LiveRecognitionFrame frame) {
    if (frame.units.length == _lastLiveUnitCount) return;
    _lastLiveUnitCount = frame.units.length;
    final tracker = _rangeTracker;
    if (tracker == null) return;
    final lex = _lexicon!;
    final predUnits =
        frame.units.map((s) => lex.bySymbol[s]!).toList(growable: false);
    tracker.onUnits(predUnits);
  }

  @override
  Future<LiveRecognitionFrame> endLive() async {
    final stream = _liveStream;
    if (stream == null) {
      return const LiveRecognitionFrame(units: [], timestamps: []);
    }
    _feedTailSilence(stream, 16000);
    final frame = _frameFromResult(_recognizer!.getResult(stream));
    stream.free();
    _liveStream = null;
    return frame;
  }

  @override
  Future<RecitationResult> evaluateLive({
    required MuaalemConfig config,
    int? suraIdx,
    int? ayaIdx,
    QuranReferenceRange? range,
    String? referenceText,
    required LiveRecognitionFrame frame,
  }) async {
    if (!_initialized) await initialize();
    final duration = frame.timestamps.isEmpty
        ? 0.0
        : frame.timestamps.last + maddTimingConfig.harakaSec * 2;
    return _evaluateUnits(
      frame: frame,
      durationSec: duration,
      suraIdx: suraIdx,
      ayaIdx: ayaIdx,
      range: range,
      referenceText: referenceText,
    );
  }

  @override
  void dispose() {
    _liveStream?.free();
    _liveStream = null;
    _recognizer?.free();
    _recognizer = null;
    // لا يُحرَّر المرجع المشترك — يبقى لِجلسات لاحقة (تحميله مكلف).
    _initialized = false;
  }

  // ── التقييم المشترك ───────────────────────────────────────────

  LiveRecognitionFrame _frameFromResult(sherpa.OnlineRecognizerResult result) {
    final units = <String>[];
    final stamps = <double>[];
    final tokens = result.tokens;
    final ts = result.timestamps;
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      // رشّح <blank> ورمز السكوت.
      if (t == '<blank>' || t == kSilenceSymbol) continue;
      if (_lexicon?.bySymbol.containsKey(t) != true) continue;
      units.add(t);
      stamps.add(i < ts.length ? ts[i] : 0.0);
    }
    return LiveRecognitionFrame(units: units, timestamps: stamps);
  }

  Future<RecitationResult> _evaluateUnits({
    required LiveRecognitionFrame frame,
    required double durationSec,
    int? suraIdx,
    int? ayaIdx,
    QuranReferenceRange? range,
    String? referenceText,
  }) async {
    final lex = _lexicon!;
    final predictedPhonemes = frame.units.join(' ');
    final predUnits =
        frame.units.map((s) => lex.bySymbol[s]!).toList(growable: false);

    // وضع النطاق (صفحة كاملة) — أولوية على الآية المفردة.
    if (range != null && (_reference?.isLoaded ?? false)) {
      // تسامح البادئ: بسملة/بداية متأخرة قبل أول مطابقة مرجعية.
      final ops = dropLeadingInserts(alignUnits(range.units, predUnits));
      final stats = computeUnitStats(ops);
      log(
          'ZipformerEngine: aligned range(${range.verses.length} verses) — '
          'ref=${range.units.length} pred=${predUnits.length} $stats',
          name: 'ZipformerEngine');

      if (stats.matches == 0 && stats.totalOps > 0) {
        return RecitationResult(
          uthmaniText: range.uthmani,
          predictedPhonemes: predictedPhonemes,
          noMatchMessage:
              'لم يتمكّن النموذج من التعرّف على التلاوة. حاول مرّة أخرى '
              'بِالتحدّث بِـوضوح أقرب من الميكروفون.',
        );
      }

      final errors = <RecitationError>[
        ...buildErrorsFromUnitAlignment(
          ops: ops,
          refUnits: range.units,
          predUnits: predUnits,
          wordAt: range.wordAt,
        ),
        ..._timingErrors(
            ops, range.units, range.wordAt, predUnits, frame, durationSec),
      ];
      final tagged = _tagErrorPositions(errors, range);
      final first = range.keyOfVerse(0);
      final last = range.keyOfVerse(range.verses.length - 1);
      return RecitationResult(
        uthmaniText: range.uthmani,
        predictedPhonemes: predictedPhonemes,
        referencePhonemes: range.phonemeString,
        errors: tagged,
        start: SurahAyahPosition(suraIdx: first.suraIdx, ayaIdx: first.ayaIdx),
        end: SurahAyahPosition(suraIdx: last.suraIdx, ayaIdx: last.ayaIdx),
      );
    }

    if (suraIdx != null && ayaIdx != null && (_reference?.isLoaded ?? false)) {
      final ref = _reference!.getReference(suraIdx: suraIdx, ayaIdx: ayaIdx);
      if (ref != null) {
        final ops = alignUnits(ref.units, predUnits);
        final stats = computeUnitStats(ops);
        log(
            'ZipformerEngine: aligned ${ref.verseKey} — '
            'ref=${ref.units.length} pred=${predUnits.length} $stats',
            name: 'ZipformerEngine');

        // رفض بِـ 0 تطابقات (تلاوة غير مفهومة).
        if (stats.matches == 0 && stats.totalOps > 0) {
          return RecitationResult(
            uthmaniText: ref.uthmani,
            predictedPhonemes: predictedPhonemes,
            noMatchMessage:
                'لم يتمكّن النموذج من التعرّف على التلاوة. حاول مرّة أخرى '
                'بِالتحدّث بِـوضوح أقرب من الميكروفون.',
          );
        }

        final errors = buildErrorsFromUnitAlignment(
          ops: ops,
          refUnits: ref.units,
          predUnits: predUnits,
          wordAt: ref.wordAt,
        );
        errors.addAll(_timingErrors(
            ops, ref.units, ref.wordAt, predUnits, frame, durationSec));

        return RecitationResult(
          uthmaniText: ref.uthmani,
          predictedPhonemes: predictedPhonemes,
          referencePhonemes: ref.phonemeString,
          errors: errors,
          start: SurahAyahPosition(suraIdx: suraIdx, ayaIdx: ayaIdx),
          end: SurahAyahPosition(suraIdx: suraIdx, ayaIdx: ayaIdx),
        );
      }
      log('ZipformerEngine: verse $suraIdx:$ayaIdx not in reference',
          name: 'ZipformerEngine', level: 900);
    }

    // لا مرجع → أعد الوحدات فقط (بلا أخطاء مُلفّقة).
    if (referenceText != null && referenceText.isNotEmpty) {
      return RecitationResult(
        uthmaniText: referenceText,
        predictedPhonemes: predictedPhonemes,
        referencePhonemes: referenceText,
      );
    }
    return RecitationResult(predictedPhonemes: predictedPhonemes);
  }

  /// يوسم كل خطأ بِموضعه في المصحف (سورة/آية/كلمة) من موضع وحدته المرجعية.
  ///
  /// أخطاء insert بلا موضع مرجعي تُترك بلا وسم.
  List<RecitationError> _tagErrorPositions(
    List<RecitationError> errors,
    QuranReferenceRange range,
  ) {
    return errors.map((e) {
      if (e.speechErrorType == 'insert' ||
          e.uthmaniPos.isEmpty ||
          e.uthmaniPos[0] < 0) {
        return e;
      }
      final span = range.spanOfUnit(e.uthmaniPos[0]);
      if (span == null) return e;
      final key = range.keyOfVerse(span.verseIdx);
      return e.withPosition(
        suraIdx: key.suraIdx,
        ayaIdx: key.ayaIdx,
        wordIdx: span.wordIdx,
      );
    }).toList();
  }

  /// يدمج أحكام المدّ الزمنية كأخطاء (المدّ الرمزي المتطابق يبقى بلا خطأ
  /// إلا إذا خان الزمنُ المُسموعَ).
  List<RecitationError> _timingErrors(
    List<UnitAlignOp> ops,
    List<QuranUnit> refUnits,
    String? Function(int unitIdx) wordAt,
    List<QuranUnit> predUnits,
    LiveRecognitionFrame frame,
    double durationSec,
  ) {
    if (frame.timestamps.isEmpty) return const [];
    final verdicts = judgeMaddTimings(
      ops: ops,
      refUnits: refUnits,
      predCount: predUnits.length,
      predTimestamps: frame.timestamps,
      totalDurationSec: durationSec,
      config: maddTimingConfig,
    );
    final out = <RecitationError>[];
    for (final v in verdicts.where((v) => !v.ok)) {
      out.add(RecitationError(
        errorType: 'tajweed',
        speechErrorType: 'replace',
        uthmaniPos: [v.refIdx, v.refIdx + 1],
        phPos: [v.predIdx, v.predIdx + 1],
        expectedPh: refUnits[v.refIdx].symbol,
        predictedPh:
            v.predIdx < predUnits.length ? predUnits[v.predIdx].symbol : null,
        expectedLen: v.goldenHarakat,
        predictedLen: v.actualHarakat.round(),
        wordText: wordAt(v.refIdx),
        refTajweedRules: [
          TajweedRule(
            nameAr: 'المدّ (زمني)',
            nameEn: 'Madd (timed)',
            goldenLen: v.goldenHarakat,
            correctnessType: 'count',
          ),
        ],
      ));
    }
    return out;
  }

  void _feedTailSilence(sherpa.OnlineStream stream, int sampleRate) {
    stream.acceptWaveform(
      samples: Float32List(sampleRate ~/ 2), // 0.5s صمت.
      sampleRate: sampleRate,
    );
    stream.inputFinished();
    while (_recognizer!.isReady(stream)) {
      _recognizer!.decode(stream);
    }
  }

  Float32List _asFloat32(Float64List src) {
    final out = Float32List(src.length);
    for (var i = 0; i < src.length; i++) {
      out[i] = src[i];
    }
    return out;
  }
}
