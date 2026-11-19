import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, kDebugMode;

import '../core/services/tasmee_reference_store.dart';
import 'live_recitation_engine.dart';
import 'models/muaalem_config.dart';
import 'models/recitation_result.dart';
import 'models/tasmee_tolerance.dart';
import 'platform_io.dart';
import 'quran_reference.dart';
import 'tajweedformer_alignment.dart';
import 'tajweedformer_client.dart';
import 'tajweedformer_coverage.dart';
import 'tajweedformer_evaluation.dart';
import 'tajweedformer_gemination.dart';
import 'tajweedformer_ghunna.dart';
import 'tajweedformer_lattice.dart';
import 'tajweedformer_madd.dart';
import 'tajweedformer_qalqalah.dart';
import 'tajweedformer_range_session.dart';
import 'tajweedformer_reference.dart';
import 'tajweedformer_reference_store.dart';
import 'tajweedformer_speech_endpoint.dart';
import 'tajweedformer_take_window.dart';
import 'tajweedformer_word_progress.dart';
import 'tasmee_error_kind.dart';
import 'wav_decoder.dart';

typedef _EvaluationRequest = ({
  List<TajweedFormerLatticeWord> words,
  List<int> reference,
  List<dynamic> decodedTokens,
  List<String> tokenNames,
  int blank,
  int bar,
  Map<String, dynamic> heads,
  Map<String, dynamic> calibration,
  String context,
  String preset,
  TasmeeToleranceProfile? tolerance,
  bool experimentalQalqalah,
  List<({int surah, int ayah})> verses,
  Map<String, dynamic> timingReferences,
});

({
  TajweedFormerLatticeMatch selection,
  List<RecitationError> errors,
  bool incomplete,
  List<int> heard,
  Map<String, TajweedFormerCategoryCoverage> coverage,
})? _evaluateInBackground(_EvaluationRequest request) {
  final window = windowTajweedFormerTake(
    reference: request.reference,
    decodedTokens: request.decodedTokens,
    blankId: request.blank,
    wordBarId: request.bar,
    heads: request.heads,
  );
  // عند حافة مقصوصة (وصل/استمرار كلام) لا تُفرَض صورة الوصل: مفكّك
  // الحروف يُسقط حركة الحافة القصيرة أحيانًا رغم نطقها، فيولّد فرضُ
  // الوصل أعلام حذف حركة كاذبة على الكلمة الأخيرة. تُجرَّب الصورتان
  // وتُختار الأرخص (مع تكافؤ تُقدَّم الوصل).
  TajweedFormerLatticeMatch? match(TajweedFormerBoundary start,
          TajweedFormerBoundary end) =>
      matchTajweedFormerLattice(
          words: request.words, heard: window.heard, start: start, end: end);
  final startBoundaries = window.croppedStart
      ? const [TajweedFormerBoundary.connected, TajweedFormerBoundary.stop]
      : const [TajweedFormerBoundary.stop];
  final endBoundaries = window.croppedEnd
      ? const [TajweedFormerBoundary.connected, TajweedFormerBoundary.stop]
      : const [TajweedFormerBoundary.stop];
  TajweedFormerLatticeMatch? selection;
  for (final start in startBoundaries) {
    for (final end in endBoundaries) {
      final candidate = match(start, end);
      if (candidate == null) continue;
      if (selection == null || candidate.distance < selection.distance) {
        selection = candidate;
      }
    }
  }
  if (selection == null) return null;
  final result = evaluateTajweedFormerTake(
    reference: selection.units,
    heard: window.heard,
    tokenNames: request.tokenNames,
    blankId: request.blank,
    wordBarId: request.bar,
    heads: window.heads,
    calibration: request.calibration,
    context: request.context,
    preset: request.preset,
    tolerance: request.tolerance,
    connectedStart: window.croppedStart,
    surah: request.verses.first.surah,
    ayah: request.verses.first.ayah,
    verses: request.verses,
  );
  final madd = request.tolerance?.madd == TasmeeToleranceLevel.skip
      ? (
          errors: <RecitationError>[],
          coverage: const TajweedFormerCategoryCoverage(
              state: TajweedFormerCoverageState.notEvaluated,
              reason: TajweedFormerCoverageReason.skippedByUser)
        )
      : evaluateTajweedFormerMadd(
          reference: selection.units,
          heard: window.heard,
          tokenNames: request.tokenNames,
          blankId: request.blank,
          heads: window.heads,
          calibration: request.calibration,
          context: request.context,
          preset: request.tolerance?.madd.v4Preset.name ?? request.preset,
          verses: request.verses,
          timingReferences: request.timingReferences,
        );
  final qalqalah = evaluateTajweedFormerQalqalah(
    reference: selection.units,
    heard: window.heard,
    tokenNames: request.tokenNames,
    blankId: request.blank,
    heads: window.heads,
    calibration: request.calibration,
    context: request.context,
    preset: request.preset,
    verses: request.verses,
    timingReferences: request.timingReferences,
    allowExperimental: request.experimentalQalqalah,
  );
  final gemination = evaluateTajweedFormerGemination(
    reference: selection.units,
    heard: window.heard,
    tokenNames: request.tokenNames,
    blankId: request.blank,
    heads: window.heads,
    calibration: request.calibration,
    context: request.context,
    preset: request.preset,
    verses: request.verses,
    timingReferences: request.timingReferences,
  );
  final ghunna = describeTajweedFormerGhunnaCoverage(
    calibration: request.calibration,
    context: request.context,
  );
  return (
    selection: selection,
    errors: [
      ...result.errors,
      ...madd.errors,
      ...qalqalah.errors,
      ...gemination.errors
    ],
    incomplete: result.incomplete,
    heard: window.heard,
    coverage: {
      ...result.coverage,
      'madd': madd.coverage,
      'qalqalah': qalqalah.coverage,
      'gemination': gemination.coverage,
      'ghunna': ghunna,
      'ikhfa': ghunna,
    },
  );
}

/// V4-backed live recitation. The SDK supplies recognition; evaluation is
/// performed by this library using its reference and the model calibration.
class TajweedFormerRecitationEngine implements LiveCapableRecitationEngine {
  TajweedFormerRecitationEngine(
      {required this.client, required this.metadata, required this.store});

  final TajweedFormerInferenceClient client;
  final Map<String, dynamic> metadata;
  final TajweedFormerReferenceStore store;

  /// التقاط مخرجات النموذج النهائية لإعادة تشغيلها في فحص المقاطع
  /// المعلمة (`test/tajweedformer_labelled_clip_probe_test.dart`). يعمل في
  /// بناء التصحيح فقط مع `--dart-define=TAJWEEDFORMER_CAPTURE=true`؛
  /// إصدارات الإنتاج لا تكتب شيئًا أبدًا.
  static const _captureEnabled =
      kDebugMode && bool.fromEnvironment('TAJWEEDFORMER_CAPTURE');

  Future<void> _writeCapture(QuranReferenceRange range,
      Map<String, dynamic> chunk, Map<String, dynamic> heads) async {
    try {
      final verse = range.verses.first;
      final dir = await PlatformIo.documentsDir;
      final path = '$dir/tajweedformer-captures.json';
      Map<String, dynamic> file = {};
      try {
        final decoded = jsonDecode(utf8.decode(await PlatformIo.readFile(path)));
        if (decoded is Map) file = Map<String, dynamic>.from(decoded);
      } catch (_) {/* أول التقاط */}
      final captures = (file['captures'] as List?) ?? [];
      captures.add({
        'ayah': verse.verseKey,
        'rangeVerses': range.verses.length,
        'rangeWords': range.wordCount,
        'sample': {
          'tokens': chunk['tokens'],
          'heads': heads,
        },
        'reference': await client.reference(
            int.parse(verse.verseKey.split(':').first),
            int.parse(verse.verseKey.split(':').last)),
      });
      file['info'] = metadata;
      file['calibration'] = client.calibration();
      file['captures'] = captures;
      await PlatformIo.writeFile(
          path, Uint8List.fromList(utf8.encode(jsonEncode(file))));
      log('TajweedFormer capture saved: ${verse.verseKey} '
          '(total ${captures.length})',
          name: 'TajweedFormer');
    } catch (e) {
      log('TajweedFormer capture failed: $e', name: 'TajweedFormer');
    }
  }

  Future<void> _queue = Future.value();
  Object? _failure;
  TajweedFormerRangeSession? _take;
  StreamSubscription<dynamic>? _progressSub;
  StreamSubscription<dynamic>? _chunkSub;
  Map<String, dynamic>? _lastChunk;
  Map<String, dynamic>? _heads;
  List<TajweedFormerReferenceUnit> _reference = [];
  List<TajweedFormerLatticeWord> _lattice = [];
  Set<int> _matched = {};
  int _queuedSamples = 0;
  bool _active = false;
  bool _disposed = false;
  Future<void>? _closing;
  Future<void>? _cancelling;
  bool _cancellingInProgress = false;
  Completer<void>? _finishDone;
  TajweedFormerSpeechEndpoint? _speechEndpoint;
  bool get hasActiveTake => _active;
  void Function(Set<({int verseIndex, int wordIndex})>, bool revised)?
      onMatchedWords;

  void _enqueue(Future<void> Function() action) {
    _queue = _queue.then((_) async {
      if (_failure != null) return;
      try {
        await action();
      } catch (error) {
        _failure ??= error;
      }
    });
  }

  /// Wait for the reference and native session before opening microphone input.
  Future<void> waitUntilReady() async {
    await _queue;
    if (!_active) throw StateError('V4 session was cancelled');
    if (_failure != null) {
      _active = false;
      try {
        await _take?.cancel();
      } finally {
        await _chunkSub?.cancel();
        await _progressSub?.cancel();
        _take = null;
      }
      throw StateError('V4 session preparation failed: $_failure');
    }
  }

  Future<void> cancelLive() => _cancelling ??= _cancelSafely();

  Future<void> _cancelSafely() async {
    _cancellingInProgress = true;
    _active = false;
    try {
      await _finishDone?.future;
      await _cancelLive();
    } finally {
      _cancellingInProgress = false;
    }
  }

  Future<void> _cancelLive() async {
    _active = false;
    _heads = null;
    _lastChunk = null;
    _matched = {};
    _speechEndpoint?.dispose();
    _speechEndpoint = null;
    await _queue;
    try {
      await _take?.cancel();
    } finally {
      await _chunkSub?.cancel();
      await _progressSub?.cancel();
      _take = null;
    }
  }

  @override
  void startLive({
    void Function(LiveRecognitionFrame)? onPartial,
    void Function()? onEndpoint,
    void Function(int)? onWord,
    void Function(int, int)? onRangeWord,
    void Function(int, int, TasmeeErrorKind, TasmeeWordMistake?)? onWordDone,
    void Function()? onRangeComplete,
    int? suraIdx,
    int? ayaIdx,
    QuranReferenceRange? range,
  }) {
    if (_active ||
        _disposed ||
        _cancellingInProgress ||
        _finishDone != null ||
        range == null ||
        range.verses.isEmpty) {
      throw StateError('V4 requires an available reference range');
    }
    _speechEndpoint?.dispose();
    _speechEndpoint =
        onEndpoint == null ? null : TajweedFormerSpeechEndpoint(onEndpoint);
    _active = true;
    _cancelling = null;
    _failure = null;
    _queuedSamples = 0;
    _heads = null;
    _lastChunk = null;
    _matched = {};
    _reference = [];
    _lattice = [];
    _enqueue(() async {
      for (var i = 0; i < range.verses.length; i++) {
        final key = range.keyOfVerse(i);
        final verse = await store.verse(
            surah: key.suraIdx, ayah: key.ayaIdx, verseIndex: i);
        final selected = range.selectedDisplayedWords;
        if (selected == null) {
          _reference.addAll(verse.reference);
          _lattice.addAll(verse.lattice);
        } else {
          bool includes(int word) =>
              selected.contains((verseIndex: i, wordIndex: word));
          final mapped = verse.reference.where((u) => includes(u.wordIndex));
          final words = verse.lattice.where((w) => includes(w.wordIndex));
          _reference.addAll(mapped);
          _lattice.addAll(words);
        }
      }
      final selected = range.selectedDisplayedWords;
      if (selected != null &&
          (!_reference
                  .map(
                      (u) => (verseIndex: u.verseIndex, wordIndex: u.wordIndex))
                  .toSet()
                  .containsAll(selected) ||
              !_lattice
                  .map(
                      (w) => (verseIndex: w.verseIndex, wordIndex: w.wordIndex))
                  .toSet()
                  .containsAll(selected))) {
        throw StateError('V4 does not cover the requested displayed words');
      }
      final take = TajweedFormerRangeSession(
        client: client,
        reference: _reference,
        blankId: metadata['blank'] as int,
        wordBarId: metadata['wordBar'] as int,
      );
      _take = take;
      final mapper = TajweedFormerWordProgressMapper(_reference);
      _chunkSub = client.chunks.listen((chunk) {
        _lastChunk = chunk;
        final speech = chunk['speech'];
        if (speech is bool && chunk['isFinal'] != true) {
          _speechEndpoint?.update(speech);
        }
        final raw = chunk['tokens'];
        if (raw is! List) return;
        final tokens = raw.whereType<Map>().toList();
        onPartial?.call(LiveRecognitionFrame(
          units: tokens.map((t) => '${t['name'] ?? ''}').toList(),
          timestamps: tokens
              .map((t) => ((t['firstMs'] as num?) ?? 0).toDouble() / 1000)
              .toList(),
        ));
      }, onError: (Object error, StackTrace stack) {
        _failure ??= error;
      });
      _progressSub = take.progress.listen((value) {
        _matched = value.matchedUnitIndices;
        onMatchedWords?.call(mapper.project(value).matchedWords, value.revised);
        final current = value.currentUnitIndex;
        if (current != null) {
          final unit = _reference[current];
          onRangeWord?.call(unit.verseIndex, unit.wordIndex);
          onWord?.call(unit.wordIndex);
        }
      }, onError: (Object error, StackTrace stack) {
        _failure ??= error;
      });
      await take.start();
    });
  }

  @override
  void feedPcm(Float32List samples) {
    if (!_active) throw StateError('V4 session is not active');
    final copy = Float32List.fromList(samples);
    _queuedSamples += copy.length;
    if (_queuedSamples > 16000 * 30) {
      _failure ??= StateError('V4 inference cannot keep up with audio');
      return;
    }
    _enqueue(() async {
      try {
        await _take!.push(copy);
      } finally {
        _queuedSamples -= copy.length;
      }
    });
  }

  @override
  Future<LiveRecognitionFrame> endLive() async {
    if (!_active) throw StateError('V4 session is not active');
    final done = _finishDone = Completer<void>();
    _active = false;
    _speechEndpoint?.dispose();
    _speechEndpoint = null;
    Map<String, dynamic>? readyHeads;
    try {
      await _queue;
      if (_failure != null) throw StateError('V4 inference failed: $_failure');
      final heads = await _take!.finish();
      await Future<void>.delayed(Duration.zero);
      if (_failure != null) throw StateError('V4 inference failed: $_failure');
      final chunk = _lastChunk;
      if (chunk == null ||
          chunk['isFinal'] != true ||
          chunk['tokens'] is! List) {
        throw StateError('V4 did not return a final transcription');
      }
      final tokens = (chunk['tokens'] as List).cast<Map>();
      final frame = LiveRecognitionFrame(
        units: tokens.map((t) => '${t['name'] ?? ''}').toList(),
        timestamps: tokens
            .map((t) => ((t['firstMs'] as num?) ?? 0).toDouble() / 1000)
            .toList(),
      );
      readyHeads = heads;
      return frame;
    } finally {
      try {
        if (_failure != null) await _take?.cancel();
        await _chunkSub?.cancel();
        await _progressSub?.cancel();
        _take = null;
        _heads = readyHeads;
      } finally {
        _finishDone = null;
        done.complete();
      }
    }
  }

  @override
  Future<RecitationResult> evaluateLive(
      {required MuaalemConfig config,
      int? suraIdx,
      int? ayaIdx,
      QuranReferenceRange? range,
      String? referenceText,
      required LiveRecognitionFrame frame}) async {
    if (config.rewaya.trim().toLowerCase() != 'hafs') {
      return RecitationResult(
        noMatchMessage: 'TajweedFormer يدعم مرجع حفص فقط حاليًا.',
        assessmentComplete: false,
        coverage: unassessedTajweedFormerCoverage(
            TajweedFormerCoverageReason.missingReference),
      );
    }
    if (_heads == null) {
      return RecitationResult(
        noMatchMessage: 'تعذّر تحديد موضع التلاوة. حاول مرة أخرى.',
        assessmentComplete: false,
        coverage: unassessedTajweedFormerCoverage(
            TajweedFormerCoverageReason.missingHead),
      );
    }
    if (range == null || _lastChunk == null || _matched.isEmpty) {
      return RecitationResult(
        noMatchMessage: 'تعذّر تحديد موضع التلاوة. حاول مرة أخرى.',
        assessmentComplete: false,
        coverage: unassessedTajweedFormerCoverage(
            TajweedFormerCoverageReason.noMatchedPath),
      );
    }
    if (_captureEnabled) {
      final chunk = Map<String, dynamic>.from(_lastChunk!);
      final heads = _heads;
      if (heads != null) unawaited(_writeCapture(range, chunk, heads));
    }
    final first = _reference[_matched.reduce((a, b) => a < b ? a : b)];
    final last = _reference[_matched.reduce((a, b) => a > b ? a : b)];
    bool included(TajweedFormerLatticeWord w) =>
        (w.verseIndex > first.verseIndex ||
            (w.verseIndex == first.verseIndex &&
                w.wordIndex >= first.wordIndex)) &&
        (w.verseIndex < last.verseIndex ||
            (w.verseIndex == last.verseIndex && w.wordIndex <= last.wordIndex));
    final words = _lattice.where(included).toList();
    if (words.isEmpty) {
      return RecitationResult(
        noMatchMessage: 'تعذّر تحديد موضع التلاوة.',
        assessmentComplete: false,
        coverage: unassessedTajweedFormerCoverage(
            TajweedFormerCoverageReason.noMatchedPath),
      );
    }
    final blank = metadata['blank'] as int;
    final bar = metadata['wordBar'] as int;
    final tokens = _lastChunk!['tokens'] as List;
    if (tokens.isEmpty) {
      return RecitationResult(
        noMatchMessage: 'تعذّر مطابقة التلاوة.',
        assessmentComplete: false,
        coverage: unassessedTajweedFormerCoverage(
            TajweedFormerCoverageReason.noMatchedPath),
      );
    }
    final verseKeys = [
      for (var i = 0; i < range.verses.length; i++)
        (surah: range.keyOfVerse(i).suraIdx, ayah: range.keyOfVerse(i).ayaIdx)
    ];
    final checked = await compute(_evaluateInBackground, (
      words: words,
      reference: _reference
          .where((u) =>
              (u.verseIndex > first.verseIndex ||
                  (u.verseIndex == first.verseIndex &&
                      u.wordIndex >= first.wordIndex)) &&
              (u.verseIndex < last.verseIndex ||
                  (u.verseIndex == last.verseIndex &&
                      u.wordIndex <= last.wordIndex)))
          .map((u) => u.tokenId)
          .toList(),
      decodedTokens: tokens,
      tokenNames: (metadata['tokens'] as List).cast<String>(),
      blank: blank,
      bar: bar,
      heads: _heads!,
      calibration:
          Map<String, dynamic>.from(client.calibration()['data'] as Map),
      context: metadata['defaultContext'] as String,
      preset: config.tajweedFormerPreset.name,
      tolerance: config.tajweedFormerTolerance,
      experimentalQalqalah: kDebugMode &&
          const bool.fromEnvironment('TAJWEEDFORMER_SHOW_DIAGNOSTICS'),
      verses: verseKeys,
      timingReferences: {
        for (final verse in verseKeys)
          if (store.timingReference(verse.surah, verse.ayah) case final data?)
            '${verse.surah}:${verse.ayah}': data,
      },
    ));
    if (checked == null) {
      return RecitationResult(
        noMatchMessage: 'تعذّر مطابقة التلاوة.',
        assessmentComplete: false,
        coverage: unassessedTajweedFormerCoverage(
            TajweedFormerCoverageReason.noMatchedPath),
      );
    }
    final selected = checked.selection;
    final heard = checked.heard;
    final spans = <({int verseIdx, int wordIdx})>{};
    for (final op in alignTajweedFormerTokens(
        selected.units.map((u) => u.tokenId).toList(), heard)) {
      if (op.referenceIndex != null &&
          (op.kind == TajweedFormerAlignmentKind.match ||
              op.kind == TajweedFormerAlignmentKind.replace)) {
        final unit = selected.units[op.referenceIndex!];
        spans.add((verseIdx: unit.verseIndex, wordIdx: unit.wordIndex));
      }
    }
    if (spans.isEmpty) {
      return RecitationResult(
        noMatchMessage: 'تعذّر مطابقة التلاوة.',
        assessmentComplete: false,
        coverage: unassessedTajweedFormerCoverage(
            TajweedFormerCoverageReason.noMatchedPath),
      );
    }
    final start = verseKeys[spans.first.verseIdx];
    final end = verseKeys[spans.last.verseIdx];
    return RecitationResult(
      start: SurahAyahPosition(suraIdx: start.surah, ayaIdx: start.ayah),
      end: SurahAyahPosition(suraIdx: end.surah, ayaIdx: end.ayah),
      errors: checked.errors,
      // اكتمال التقييم من التقييم الفعلي نفسه: خاضت اللقطة تقييم المواقع
      // دون فروق غير مدعومة. تحقق بالقياس الميداني 2026-11-16 (صفر إنذارات
      // كاذبة على التلاوات الكاملة الصحيحة وكشف 7/7 للأخطاء المتعمدة
      // بالإعداد المتقن) — وثّق في docs/plans/2026-11-15-nahtadi-tasmee-comparison.md.
      assessmentComplete: !checked.incomplete,
      matchedWordSpans: spans.toList(),
      predictedPhonemes: frame.units.join(' '),
      uthmaniText: range.uthmani,
      coverage: TajweedFormerTakeCoverage(categories: checked.coverage),
    );
  }

  @override
  Future<RecitationResult> correctRecitation(
      {required Uint8List wavBytes,
      MuaalemConfig config = const MuaalemConfig(),
      double errorRatio = 0.1,
      int? suraIdx,
      int? ayaIdx,
      QuranReferenceRange? range,
      String? referenceText}) async {
    if (config.rewaya.trim().toLowerCase() != 'hafs') {
      return RecitationResult(
        noMatchMessage: 'TajweedFormer يدعم مرجع حفص فقط حاليًا.',
        assessmentComplete: false,
        coverage: unassessedTajweedFormerCoverage(
            TajweedFormerCoverageReason.missingReference),
      );
    }
    final decoded = decodeWavBytes(wavBytes);
    if (decoded == null || decoded.sampleRate != 16000) {
      return RecitationResult(
        noMatchMessage: 'تعذّر قراءة ملف الصوت بتنسيق 16 kHz PCM.',
        assessmentComplete: false,
        coverage: unassessedTajweedFormerCoverage(
            TajweedFormerCoverageReason.noMatchedPath),
      );
    }
    var selectedRange = range;
    if (selectedRange == null && suraIdx != null && ayaIdx != null) {
      await TasmeeReferenceStore.instance.load();
      selectedRange = TasmeeReferenceStore.instance
          .buildRange([(suraIdx: suraIdx, ayaIdx: ayaIdx)]);
    }
    if (selectedRange == null) {
      return RecitationResult(
        noMatchMessage: 'يلزم تحديد نطاق التلاوة للتقييم.',
        assessmentComplete: false,
        coverage: unassessedTajweedFormerCoverage(
            TajweedFormerCoverageReason.missingReference),
      );
    }
    startLive(range: selectedRange);
    for (var offset = 0; offset < decoded.samples.length; offset += 16000) {
      final end = (offset + 16000).clamp(0, decoded.samples.length);
      feedPcm(Float32List.fromList(decoded.samples.sublist(offset, end)));
      await _queue;
      if (_failure != null) break;
    }
    final frame = await endLive();
    return evaluateLive(config: config, range: selectedRange, frame: frame);
  }

  @override
  double? get liveRangeProgress =>
      _reference.isEmpty ? null : _matched.length / _reference.length;
  @override
  void onLiveResumed() {}
  @override
  Future<bool> isHealthy() async => !_disposed;
  @override
  String? getVerseText({required int suraIdx, required int ayaIdx}) => null;
  @override
  void dispose() {
    unawaited(close());
  }

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    _disposed = true;
    try {
      await cancelLive();
    } finally {
      await client.close();
    }
  }
}
