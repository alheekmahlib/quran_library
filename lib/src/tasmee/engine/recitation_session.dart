import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:get/get.dart';
import 'package:record/record.dart';

import 'platform_io.dart';
import 'live_recitation_engine.dart';
import 'models/muaalem_config.dart';
import 'models/recitation_result.dart';
import 'quran_reference.dart';
import 'recitation_engine.dart';
import 'wav_decoder.dart';
import 'recitation_state.dart';
import 'tasmee_error_kind.dart';
import 'tajweedformer_coverage.dart';
import 'tajweedformer_recitation_engine.dart';

/// Combines consecutive V4 takes without converting partial coverage into a
/// complete assessment. A take without a match never contributes a verdict.
/// Per-category coverage is merged so a segment that assessed a category is
/// never masked by one that could not.
RecitationResult mergePartialV4Results(List<RecitationResult> segments) {
  if (segments.isEmpty) {
    return RecitationResult(
      noMatchMessage: 'لم تُسجّل تلاوة.',
      assessmentComplete: false,
      coverage: unassessedTajweedFormerCoverage(
          TajweedFormerCoverageReason.noMatchedPath),
    );
  }
  final matched = segments.where((s) => s.hasMatch).toList();
  if (matched.isEmpty) {
    return RecitationResult(
      noMatchMessage: segments.last.noMatchMessage ?? 'تعذّر تحديد موضع التلاوة.',
      assessmentComplete: false,
      coverage: mergeTajweedFormerCoverage([
        for (final segment in segments)
          segment.coverage ??
              unassessedTajweedFormerCoverage(
                  TajweedFormerCoverageReason.noMatchedPath),
      ]),
    );
  }
  final spans = <({int verseIdx, int wordIdx})>{};
  for (final segment in matched) {
    spans.addAll(segment.matchedWordSpans);
  }
  final ordered = spans.toList()
    ..sort((a, b) => a.verseIdx != b.verseIdx
        ? a.verseIdx.compareTo(b.verseIdx)
        : a.wordIdx.compareTo(b.wordIdx));
  return RecitationResult(
    start: matched.first.start,
    end: matched.last.end,
    uthmaniText: matched.first.uthmaniText,
    errors: [for (final segment in matched) ...segment.errors],
    matchedWordSpans: ordered,
    assessmentComplete: false,
    coverage: mergeTajweedFormerCoverage([
      for (final segment in segments)
        segment.coverage ??
            unassessedTajweedFormerCoverage(
                TajweedFormerCoverageReason.noMatchedPath),
    ]),
  );
}

/// جلسة تسميع واحدة — تسجّل WAV، تُرسله لِلمحرّك (online أو offline)،
/// تستلم التصحيح.
///
/// A single recitation session — records WAV, sends it to the engine (online
/// or offline), receives the correction.
///
/// النمط **batch** (وليس streaming): يُسجّل الصوت كاملاً في ملف مؤقّت أثناء
/// التلاوة، ثم عند الإيقاف يُمرّره لِلمحرّك ويستلم النتيجة. هذا أبسط
/// وأكثر موثوقية من streaming.
///
/// **Batch** pattern (not streaming): records the full audio to a temp file
/// during recitation, then on stop passes it to the engine and receives the
/// result. Simpler and more reliable than streaming.
class RecitationSession {
  RecitationSession({
    required this.config,
    required RecitationEngine engine,
    AudioRecorder? recorder,
    this.suraIdx,
    this.ayaIdx,
    this.range,
    this.referenceText,
  })  : _engine = engine,
        _recorder = recorder;

  /// إعدادات المصحف (Hafs افتراضياً).
  /// Moshaf config (Hafs by default).
  final MuaalemConfig config;

  /// رقم السورة (offline) — لِـ جلب المرجع من DB.
  final int? suraIdx;

  /// رقم الآية (offline) — لِـ جلب المرجع من DB.
  final int? ayaIdx;

  /// النطاق المرجعي متعدد الآيات (offline، وضع الصفحة) — يشمل ما سبق.
  final QuranReferenceRange? range;

  /// النصّ المرجعي (offline، بديل) — يُستخدم إن لم يُعطَ suraIdx/ayaIdx.
  final String? referenceText;

  final RecitationEngine _engine;
  void _verifyEngineConfig() {
    if (_engine is TajweedFormerRecitationEngine) {
      if (config.rewaya.trim().toLowerCase() != 'hafs') {
        throw StateError('TajweedFormer يدعم مرجع حفص فقط حاليًا.');
      }
      // إعداد فوق الافتراضي لا يقيّمه V4 يُرفض صراحةً قبل فتح الميكروفون
      // لا أن يُتجاهل بصمت فيبدو محسوبًا وهو لم يُقرأ.
      final unsupported = config.unsupportedTajweedFormerSettings();
      if (unsupported.isNotEmpty) {
        throw StateError(
            'TajweedFormer لا يدعم هذه الإعدادات بعد: ${unsupported.join('، ')}');
      }
    }
  }

  bool _disposed = false;
  AudioRecorder? _recorder;
  bool _ownsRecorder = false;
  String? _recordingPath;

  /// إيقاف تلقائي (إعادة نطق الكلمة) — مراقبة النسبة وسقف المدة.
  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _maxDurationTimer;

  /// حالة الجلسة (reactive لِـ GetX).
  /// Session state (reactive for GetX).
  final Rx<RecitationState> state = RecitationState.idle.obs;

  /// آخر خطأ (إن وُجد).
  /// Last error (if any).
  final RxString lastError = ''.obs;

  /// نتيجة التصحيح (بعد stop).
  /// Correction result (after stop).
  final Rx<RecitationResult?> result = Rx<RecitationResult?>(null);

  /// ابدأ التسجيل.
  ///
  /// Start recording.
  ///
  /// يُسجّل WAV (16kHz mono) إلى ملف مؤقّت. لا يُرسل شيئاً لِلخادم حتى [stop].
  ///
  /// [stopAfterSilence]: إيقاف تلقائي بعد نطقٍ ثم سكون (كشف بالنسبة عبر
  /// `onAmplitudeChanged`) — لِجلسات قصيرة بلا تدخل يدوي (إعادة نطق كلمة).
  ///
  /// [maxDuration]: سقف صلب لِلمدة مهما حدث.
  ///
  /// [ignoreInitial]: مهلة تصاهل في بداية التسجيل — صدى صوت الكلمة من
  /// السماعة (شيت المصحّح يشغّل النطق الصحيح) لا يُحسب كلام مستخدم ولا
  /// يُعدّل لحظة آخر كلام.
  Future<void> start({
    Duration? stopAfterSilence,
    Duration? maxDuration,
    Duration? ignoreInitial,
  }) {
    // بدء جارٍ (انتظار إذن/بدء مسجّل والحالة ما تزال خمولًا) — أعد طلبه
    // نفسه لا عملية ثانية فوق المسجّل ذاته.
    final pending = _startFuture;
    if (pending != null) return pending;
    if (state.value.isActive) {
      log('RecitationSession already active', name: 'RecitationSession');
      return Future.value();
    }
    // استذكِر مستقبل البدء: التحرير ينتظره حتى تستقر عملية الالتقاط قبل
    // إيقاف المسجّل — إيقاف يسبق اكتمال البدء قد يعيد قبل استقرار القناة
    // فيُستأنف المسجّل الرئيسي مبكرًا.
    final future = _startImpl(stopAfterSilence, maxDuration, ignoreInitial);
    _startFuture = future;
    return future.whenComplete(() {
      if (identical(_startFuture, future)) _startFuture = null;
    });
  }

  Future<void>? _startFuture;

  Future<void> _startImpl(
    Duration? stopAfterSilence,
    Duration? maxDuration,
    Duration? ignoreInitial,
  ) async {
    // بدء تسجيل جديد يصفّر مذكّرة الإيقاف — إيقاف الجلسة السابقة داخل
    // هذه الجلسة (بدء بعد توقف) لا يجب أن يُعاد لطلب لاحق.
    _stopFuture = null;
    try {
      result.value = null;
      lastError.value = '';
      _verifyEngineConfig();
      _recorder ??= AudioRecorder();
      _ownsRecorder = true;

      final hasMic = await _recorder!.hasPermission();
      if (!hasMic) {
        throw StateError('Microphone permission denied');
      }
      if (_disposed) {
        // حُرّرت الجلسة أثناء طلب الإذن — فكّك مسجّلها ولا تبدأ الالتقاط.
        // (التفكيك المباشر لا انتظار للبدء: نحن البدء نفسه.)
        await _teardownBatchRecorder();
        return;
      }

      // WAV 16kHz mono — مدخل quran-muaalem المتوقَّع.
      // WAV 16kHz mono — quran-muaalem's expected input.
      const settings = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      );

      // أنشئ مساراً مؤقّتاً لِملف WAV (record v6 يتطلّب path مُسبقاً).
      // Create a temp path for the WAV file (record v6 requires a path upfront).
      final dir = await PlatformIo.tempDir;
      _recordingPath =
          '$dir/recitation_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder!.start(settings, path: _recordingPath!);
      if (_disposed) {
        // بدأ الالتقاط ثم حُرّرت الجلسة — أوقفه فورًا وفكّك بلا تقييم.
        await _teardownBatchRecorder();
        return;
      }
      _wireAutoStop(stopAfterSilence, maxDuration, ignoreInitial);
      state.value = RecitationState.recording;
      log(
        'RecitationSession started recording: $_recordingPath',
        name: 'RecitationSession',
      );
    } catch (e, s) {
      state.value = RecitationState.error;
      lastError.value = e.toString();
      log(
        'RecitationSession start failed: $e',
        name: 'RecitationSession',
        stackTrace: s,
      );
    }
  }

  /// يربط الإيقاف التلقائي: سقف مدة، وسكون بعد نطق (كشف النسبة)، ومهلة
  /// تصاهر بادئة (صدى السماعة لا يُحسب كلامًا).
  void _wireAutoStop(
    Duration? stopAfterSilence,
    Duration? maxDuration,
    Duration? ignoreInitial,
  ) {
    if (maxDuration != null) {
      _maxDurationTimer = Timer(maxDuration, () {
        if (state.value == RecitationState.recording) stop();
      });
    }
    if (stopAfterSilence == null) return;
    final startedAt = DateTime.now();
    var spoke = false;
    DateTime? lastVoiceAt;
    _amplitudeSub = _recorder!
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      // عهدة البادئة: صدى نطق الكلمة من السماعة (شيت المصحّح) ليس كلام
      // المستخدم — لا يُعلّم spoke ولا يُحدّث آخر كلام.
      if (ignoreInitial != null &&
          DateTime.now().difference(startedAt) < ignoreInitial) {
        return;
      }
      // كلام البشر عادة > ‎-35dB‏ والسكوت حول ‎-45dB‏ فأدنى.
      final heard = amp.current > -35;
      if (heard) {
        spoke = true;
        lastVoiceAt = DateTime.now();
        return;
      }
      if (spoke &&
          lastVoiceAt != null &&
          DateTime.now().difference(lastVoiceAt!) >= stopAfterSilence &&
          state.value == RecitationState.recording) {
        stop();
      }
    });
  }

  /// يقرأ ملف WAV كاملاً، يُمرّره لِلمحرّك لِلتصحيح.
  ///
  /// Stop recording and pass the audio to the engine for correction.
  ///
  /// يقرأ ملف WAV كاملاً، يُمرّره لِلمحرّك (online: HTTP، offline: ONNX)،
  /// ويخزّن النتيجة في [result].
  /// Reads the full WAV file, passes it to the engine (online: HTTP,
  /// offline: ONNX), and stores the result in [result].
  ///
  /// إيقاف مذكَّر: طلبان متداخلان (مؤقّت سكون + سقف مدة + إيقاف يدوي)
  /// يُقيَّمان مرة واحدة — الطلب الثاني يعيد مستقبل الأول نفسه فلا يُقرأ
  /// الملف ولا يُستدعى المحرك مرتين، والإيقاف بعد الاكتمال لا يقلب نتيجة
  /// منتهية إلى خطأ بقراءة ملف محذوف.
  Future<void> stop() {
    final pending = _stopFuture;
    if (pending != null) return pending;
    return _stopFuture = _stopImpl();
  }

  Future<void>? _stopFuture;

  Future<void> _stopImpl() async {
    try {
      state.value = RecitationState.processing;
      _recordingPath = await _recorder?.stop() ?? _recordingPath;
      log(
        'RecitationSession stopped. Sending to server...',
        name: 'RecitationSession',
      );

      if (_recordingPath == null) {
        throw StateError('No recording file');
      }

      // اقرأ ملف WAV كاملاً.
      // Read the full WAV file.
      final wavBytes = await PlatformIo.readFile(_recordingPath!);
      log(
        'RecitationSession: read ${wavBytes.length} bytes',
        name: 'RecitationSession',
      );

      // 🔍 تشخيص في وضع التصحيح فقط: نسخة من التسجيل لِتحليلها offline —
      // في الإصدارات لا يبقى صوت المستخدم على القرص (خصوصية).
      if (kDebugMode) {
        try {
          final docDir = await PlatformIo.documentsDir;
          final diagPath = '$docDir/last_recitation.wav';
          await PlatformIo.writeFile(diagPath, wavBytes);
          log(
            'RecitationSession: DIAG copy saved → $diagPath',
            name: 'RecitationSession',
          );
        } catch (_) {}
      }

      // مرّر لِلمحرّك (online: خادم، offline: ONNX).
      // Pass to the engine (online: server, offline: ONNX).
      result.value = await _engine.correctRecitation(
        wavBytes: wavBytes,
        config: config,
        suraIdx: suraIdx,
        ayaIdx: ayaIdx,
        range: range,
        referenceText: referenceText,
      );

      log('RecitationSession done: ${result.value}', name: 'RecitationSession');
      state.value = RecitationState.finished;
    } catch (e, s) {
      state.value = RecitationState.error;
      lastError.value = e.toString();
      log(
        'RecitationSession stop error: $e',
        name: 'RecitationSession',
        stackTrace: s,
      );
    } finally {
      // تنظيف: أوقف مراقبات الإيقاف التلقائي، واحذف الملف المؤقّت وتصرّف
      // بالمسجّل.
      _amplitudeSub?.cancel();
      _amplitudeSub = null;
      _maxDurationTimer?.cancel();
      _maxDurationTimer = null;
      if (_recordingPath != null) {
        try {
          await PlatformIo.deleteFile(_recordingPath!);
        } catch (_) {}
      }
      if (_ownsRecorder) {
        try {
          await _recorder?.dispose();
        } catch (_) {}
      }
      _recorder = null;
    }
  }

  /// صرّح بالموارد فوراً إن لم تُستدعَ stop.
  /// Dispose resources immediately if stop wasn't called.
  void dispose() {
    _disposed = true;
    final engine = _engine;
    if (engine is TajweedFormerRecitationEngine && _v4TakeOpen) {
      if (isLive.value &&
          (state.value == RecitationState.recording ||
              state.value == RecitationState.paused)) {
        // جلسة حية تملك المحاولة — أوقفها والملكية قائمة: الإيقاف يمرّ
        // بمسار endLive فيحرّر المحاولة. تصفير العلامة قبله يوجّه الإيقاف
        // إلى فرع دمج المقاطع فتظل محاولة المحرك مفتوحة ترفض الجلسة
        // التالية.
        stopLive();
        return;
      }
      // ملكية بلا جلسة حية (تعثّر البدء بعد القبول مثلًا) — إلغاء مباشر.
      _v4TakeOpen = false;
      unawaited(engine.cancelLive());
      return;
    }
    if (isLive.value &&
        (state.value == RecitationState.recording ||
            state.value == RecitationState.paused)) {
      stopLive();
    } else if (state.value == RecitationState.recording) {
      stop();
    }
  }

  /// يحرّر الجلسة تحريرًا منتظَرًا بلا تقييم: مسجّلها (الحيّ أو الدفعي)
  /// يُوقف ويُفكَّك حتى يكتمل ذلك قبل العودة — لِلمسارات التي تستأنف
  /// الميكروفون الرئيسي بعدها مباشرة (إغلاق شيت تصحيح الكلمة أثناء
  /// محاولة جارية) فلا يتنازع مسجّلان على قناة الصوت.
  Future<void> release() async {
    final engine = _engine;
    if (engine is TajweedFormerRecitationEngine) {
      await cancelV4Live();
      return;
    }
    if (isLive.value &&
        (state.value == RecitationState.recording ||
            state.value == RecitationState.paused)) {
      await stopLive();
      return;
    }
    await _releaseBatchRecorder();
  }

  /// تفكيك مسجّل الوضع الدفعي (إيقاف الالتقاط/حذف الملف/التصريف) —
  /// انتظاري وإعدادي التكرار.
  Future<void> _releaseBatchRecorder() async {
    _disposed = true;
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    // انظر عملية بدء الالتقاط الجارية حتى تستقر قبل الإيقاف — التحرير لا
    // يعود قبلها فلا يُستأنف المسجّل الرئيسي فوق بدء لم يكتمل بعد.
    await _startFuture;
    // وانظر إيقافًا جاريًا كذلك — تحرير أثناء تقييم الإيقاف لا يفكك
    // المسجّل تحت قراءته للملف ولا يكرر استدعاء المحرك.
    await _stopFuture;
    await _teardownBatchRecorder();
  }

  Future<void> _teardownBatchRecorder() async {
    final recorder = _recorder;
    _recorder = null;
    final path = _recordingPath;
    _recordingPath = null;
    try {
      await recorder?.stop();
    } catch (_) {}
    if (path != null) {
      try {
        await PlatformIo.deleteFile(path);
      } catch (_) {}
    }
    if (_ownsRecorder) {
      try {
        await recorder?.dispose();
      } catch (_) {}
      _ownsRecorder = false;
    }
    if (state.value == RecitationState.recording) {
      state.value = RecitationState.idle;
    }
  }

  // ═══════════════════════ الوضع الحي (بثّ PCM) ═══════════════════════
  // Live mode (PCM streaming while reciting).

  /// آخر وحدات متعرَّف عليها أثناء البثّ (لِلعرض اللحظي).
  /// Latest recognized units while streaming (for live display).
  final RxList<String> liveUnits = <String>[].obs;

  /// فهرس الكلمة الجارية في آية الجلسة أثناء البثّ (0-based، أو -1).
  ///
  /// يُحدَّث لحظيًا بمحاذاة الوحدات المتنامية مع الآية المرجعية —
  /// اربطه بواجهتك لِإبراز الكلمة تتاليًا أثناء التلاوة.
  /// Index of the word currently being recited (0-based, or -1).
  final RxInt currentWordIdx = (-1).obs;

  /// فهرس الآية الجارية داخل نطاق الجلسة أثناء البثّ (0-based، أو -1).
  ///
  /// يعمل مع وضع النطاق (الصفحة) — يُقرأ مع [currentWordIdx].
  /// Index of the verse currently being recited within the range (or -1).
  final RxInt currentVerseIdx = (-1).obs;

  /// يُستدعى عند اكتمال نطق كلمة (وضع النطاق) — بَعد مرور المحاذاة على
  /// آخر وحدة فيها — ومعها صحة نطقها وتفصيل خطئها. اربطه لِتلوين الكلمة
  /// أخضر/أحمر وعرض الخطأ في المصحح.
  ///
  /// Called when a word is fully pronounced (range mode) with its verdict
  /// and mistake detail.
  void Function(
    int verseIdx,
    int wordIdx,
    TasmeeErrorKind kind,
    TasmeeWordMistake? mistake,
  )? onWordDone;

  /// يُستدعى عند تغيّر الكلمة الجارية في وضع النطاق بالفهرسين **معًا** —
  /// بعد تحديث [currentVerseIdx] و[currentWordIdx] سويةً، فلا يُقرأ أيٌّ
  /// منهما بجوار قيمة قديمة من الآية السابقة (إشعار GetX متزامن، وتحديث
  /// الحقلين فرديًا يكشف لحظيًّا كلمةً من الآية الجديدة برقم قديم).
  ///
  /// Called once with both indices after both Rx fields are updated.
  void Function(int verseIdx, int wordIdx)? onRangeWord;

  /// V4 exact matches awaiting final evaluation, not correctness verdicts.
  void Function(Set<({int verseIndex, int wordIndex})> words, bool revised)?
      onMatchedWords;

  /// يُستدعى عند اكتمال كل كلمات النطاق (إتمام الصفحة).
  ///
  /// Called when every word in the range has been completed.
  void Function()? onRangeComplete;

  /// يُستدعى عند كشف المحرّك صمتَ نهاية مقطع أثناء البثّ (فاصل — ليس
  /// إيقافًا). يوصل صمت الختام لِلطبقة الأعلى (إنهاء آلي بوضع المعلم
  /// عند تقدّم كافٍ عبر [liveRangeProgress]).
  ///
  /// Called when the engine detects end-of-utterance silence while live.
  void Function()? onEndpoint;

  /// تقدّم التلاوة الحيّة على نطاق الجلسة (0..1) أو null — نسبة الوحدات
  /// المرجعية المستهلَكة. أساس الإنهاء الآلي بالصمت.
  double? get liveRangeProgress {
    final engine = _engine;
    return engine is LiveCapableRecitationEngine
        ? engine.liveRangeProgress
        : null;
  }

  /// هل الجلسة في الوضع الحي؟
  /// Is the session in live mode?
  final RxBool isLive = false.obs;

  StreamSubscription<dynamic>? _liveSub;
  AudioRecorder? _liveRecorder;
  Pcm16StreamDecoder _livePcm = Pcm16StreamDecoder();
  Object? _liveCaptureFailure;
  final List<RecitationResult> _v4Segments = [];
  bool _v4TakeOpen = false;
  Future<void>? _stopLiveFuture;
  Future<void>? _pauseLiveFuture;
  Future<void>? _startLiveFuture;

  /// Release a V4 retry without evaluating it, and wait for native teardown.
  Future<void> cancelV4Live() async {
    final engine = _engine;
    if (engine is! TajweedFormerRecitationEngine) return;
    _disposed = true;
    await _startLiveFuture;
    final stopping = _stopLiveFuture;
    if (stopping != null) {
      await stopping;
      return;
    }
    await _liveSub?.cancel();
    _liveSub = null;
    try {
      await _liveRecorder?.stop();
    } catch (_) {}
    // محاولة المحرك لا تُلغى إلا إن كانت ملكًا لهذه الجلسة — جلسة رفضها
    // المحرك (محاولة مشغولة بجلسة أخرى) تنظّف مسجّلها فقط.
    if (_v4TakeOpen) {
      _v4TakeOpen = false;
      await engine.cancelLive();
    }
    try {
      await _liveRecorder?.dispose();
    } catch (_) {}
    _liveRecorder = null;
    isLive.value = false;
    state.value = RecitationState.idle;
  }

  // تشخيص البث (لِملاحقة جودة ما يسلّمه الميكروفون).
  int _liveChunkCount = 0;
  int _liveTotalBytes = 0;
  double _livePeak = 0.0;

  /// مسجّل تسخيني لإذن الميكروفون — الجلسات تنشئ مسجّلها خاصًّا.
  static AudioRecorder? _warmupRecorder;

  /// تجهيز مسبق لإذن الميكروفون (pre-roll فحص التسميع C8): طلبه بعد
  /// انتهاء تلاوة القارئ في وضع المعلم يبتلع أول كلمة — يُطلب أثناء
  /// التلاوة فيعود فورًا عند بدء التسجيل.
  static Future<bool> ensureMicPermission() async {
    try {
      _warmupRecorder ??= AudioRecorder();
      return await _warmupRecorder!.hasPermission();
    } catch (_) {
      return false;
    }
  }

  /// معالجة صوت المنصة (AGC/AEC/NS) للمسار الحي — للتجربة على الجهاز
  /// (فحص التسميع C8): قد تقطع نهايات الكلمات الخافتة فتُسقط وحدات؛
  /// جرّب false وقارن قبل تغييره افتراضيًّا.
  static const bool kLiveVoiceProcessing = true;

  /// يبدأ التسجيل الحي — يغذّي المحرّك بِـ PCM ويحدّث [liveUnits] لحظيًا.
  ///
  /// يرمي [StateError] إن كان المحرّك لا يدعم البثّ (الأونلاين).
  Future<void> startLive() => _startLiveFuture ??= _startLiveImpl();

  Future<void> _startLiveImpl() async {
    if (state.value.isActive) {
      log('RecitationSession already active', name: 'RecitationSession');
      return;
    }
    final engine = _engine;
    if (engine is! LiveCapableRecitationEngine) {
      throw StateError('المحرّك الحالي لا يدعم الوضع الحي');
    }
    try {
      result.value = null;
      lastError.value = '';
      _verifyEngineConfig();
      liveUnits.clear();
      currentWordIdx.value = -1;
      currentVerseIdx.value = -1;
      _livePcm = Pcm16StreamDecoder();
      _liveCaptureFailure = null;
      _v4Segments.clear();
      // المسجّل المحقون (اختبارات) يُستخدم في المسارين — الإنتاج لا يحقن.
      _liveRecorder ??= _recorder ?? AudioRecorder();
      if (!await _liveRecorder!.hasPermission()) {
        throw StateError('Microphone permission denied');
      }
      if (_disposed) {
        await _cleanupLiveRecorder();
        return;
      }
      await _startEngineTake(engine);
      if (_disposed && engine is TajweedFormerRecitationEngine) {
        await _cleanupLiveRecorder();
        await engine.cancelLive();
        return;
      }
      await _startPcmStreaming(engine);
      if (_disposed && engine is TajweedFormerRecitationEngine) {
        await _cleanupLiveRecorder();
        await engine.cancelLive();
        return;
      }
      isLive.value = true;
      state.value = RecitationState.recording;
      _liveChunkCount = 0;
      _liveTotalBytes = 0;
      _livePeak = 0.0;
      log(
        'RecitationSession started LIVE streaming',
        name: 'RecitationSession',
      );
    } catch (e, s) {
      if (engine is TajweedFormerRecitationEngine && _v4TakeOpen) {
        // هذه الجلسة تملك محاولة المحرك المفتوحة — ألغها ونظّف مسجّلها.
        _v4TakeOpen = false;
        try {
          await engine.cancelLive();
        } finally {
          await _cleanupLiveRecorder();
        }
      } else {
        // المحرك رفض التسجيل (محاولة مملوكة لجلسة أخرى) أو ليس حصريًا —
        // نظّف مسجّل هذه الجلسة فقط دون المساس بمحاولة جلسة أخرى.
        await _cleanupLiveRecorder();
      }
      if (_disposed) return;
      state.value = RecitationState.error;
      lastError.value = e.toString();
      log(
        'RecitationSession startLive failed: $e',
        name: 'RecitationSession',
        stackTrace: s,
      );
    }
  }

  Future<void> _startEngineTake(LiveCapableRecitationEngine engine) async {
    var lastLoggedCount = 0;
    engine.startLive(
      suraIdx: suraIdx,
      ayaIdx: ayaIdx,
      range: range,
      onPartial: (frame) {
        liveUnits.assignAll(frame.units);
        // سجّل العدد فقط دون إخراج وحدات التلاوة إلى السجل.
        if (frame.units.length - lastLoggedCount >= 5 ||
            (frame.units.isNotEmpty && lastLoggedCount == 0)) {
          lastLoggedCount = frame.units.length;
          log(
            'RecitationSession LIVE partial — '
            'units=${frame.units.length}',
            name: 'RecitationSession',
          );
        }
      },
      onWord: (wordIdx) => currentWordIdx.value = wordIdx,
      onRangeWord: (verseIdx, wordIdx) {
        currentVerseIdx.value = verseIdx;
        currentWordIdx.value = wordIdx;
        onRangeWord?.call(verseIdx, wordIdx);
      },
      onWordDone: onWordDone,
      onRangeComplete: onRangeComplete,
      onEndpoint: () => onEndpoint?.call(),
    );
    if (engine is TajweedFormerRecitationEngine) {
      // نجاح تسجيل المحاولة يجعلها ملكًا لهذه الجلسة فورًا — إلغاؤها
      // (أدناه وفي مسارات الخطأ) لا يجوز إلا للمالك: جلسة ثانية يرفضها
      // المحرك (محاولة مشغولة) لا تملك حق إلغاء محاولة الجلسة الأولى.
      _v4TakeOpen = true;
      // مستمع المطابقات يُربط بعد القبول لا قبله: ربطه قبل startLive
      // يستبدل مستمع الجلسة الأولى وإن رُفض تسجيل هذه الجلسة، فتُوجَّه
      // تحديثات كلمات الأولى إلى جلسة ميّتة. الأحداث لا تنطلق قبل
      // اكتمال التهيئة داخل المحرك فلا تفوتنا أي تحديث.
      engine.onMatchedWords =
          (words, revised) => onMatchedWords?.call(words, revised);
      await engine.waitUntilReady();
      if (_disposed) {
        await engine.cancelLive();
        _v4TakeOpen = false;
        return;
      }
    }
  }

  Future<RecitationResult> _finishV4Take(
      TajweedFormerRecitationEngine engine) async {
    final frame = await engine.endLive();
    _v4TakeOpen = false;
    return engine.evaluateLive(
      config: config,
      suraIdx: suraIdx,
      ayaIdx: ayaIdx,
      range: range,
      referenceText: referenceText,
      frame: frame,
    );
  }

  Future<void> _cleanupLiveRecorder() async {
    await _liveSub?.cancel();
    _liveSub = null;
    try {
      await _liveRecorder?.stop();
    } catch (_) {
      // Permission or stream startup may have failed before recording began.
    } finally {
      try {
        await _liveRecorder?.dispose();
      } catch (_) {}
      _liveRecorder = null;
    }
  }

  /// يشترك في بثّ الميكروفون ويغذّي المحرّك بوحدات PCM — مشترك بين
  /// [startLive] و[resumeLive].
  Future<void> _startPcmStreaming(LiveCapableRecitationEngine engine) async {
    // على macOS تفعيل echoCancel/autoGain يشغّل setVoiceProcessingEnabled،
    // وتثبيت الـ tap بتنسيق مأخوذ قبل استقرار تنسيق VPIO قد يُسدّم أصفارًا
    // مستمرة (peak=0) — التسميع يلتقط من الميكروفون مباشرة فلا حاجة
    // لإلغاء الصدى هناك. بقية المنصات تحتفظ بالمعالجة.
    final useVoiceProcessing = kLiveVoiceProcessing &&
        defaultTargetPlatform != TargetPlatform.macOS &&
        !kIsWeb;
    final settings = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      autoGain: useVoiceProcessing,
      echoCancel: useVoiceProcessing,
      noiseSuppress: useVoiceProcessing,
    );
    // record v6: startStream يُعيد Future<Stream> — انتظر الشبكة ثم اشترك.
    final pcmStream = await _liveRecorder!.startStream(settings);
    _liveSub = pcmStream.listen((chunk) {
      if (_disposed || _liveCaptureFailure != null) return;
      // قد تنقسم عينة بين دفعتين أو تصل الدفعة بعرض غير محاذٍ.
      _liveChunkCount++;
      _liveTotalBytes += chunk.lengthInBytes;
      final floats = _livePcm.add(chunk);
      var peak = 0.0;
      for (final v in floats) {
        final a = v < 0 ? -v : v;
        if (a > peak) peak = a;
      }
      if (peak > _livePeak) _livePeak = peak;
      if (floats.isNotEmpty) engine.feedPcm(floats);
    }, onError: (Object error, StackTrace stack) {
      _liveCaptureFailure ??= error;
    }, onDone: () {
      _liveCaptureFailure ??=
          StateError('Microphone stream ended unexpectedly');
    });
  }

  /// يجمّد بثّ الميكروفون مؤقتًا دون إنهاء الجلسة أو تقييمها — مثلاً
  /// لتصحيح كلمة في نمط المصحح دون أن يسمع الميكروفون نطق الكلمة من
  /// السماعة. يُستأنف بـ [resumeLive] من نفس نقطة المحاذاة.
  Future<void> pauseLive() => _pauseLiveFuture ??= _pauseLiveImpl();

  Future<void> _pauseLiveImpl() async {
    if (!isLive.value || state.value != RecitationState.recording) {
      log(
        'RecitationSession pauseLive skipped — '
        'isLive=${isLive.value} state=${state.value}',
        name: 'RecitationSession',
      );
      return;
    }
    try {
      await _liveSub?.cancel();
      _liveSub = null;
      await _liveRecorder?.stop();
      if (_livePcm.hasIncompleteSample) {
        _liveCaptureFailure ??= StateError('Incomplete PCM sample');
      }
      if (_liveCaptureFailure != null) {
        throw StateError('تعذّر استقبال الصوت كاملًا من الميكروفون.');
      }
      final engine = _engine;
      if (engine is TajweedFormerRecitationEngine) {
        _v4Segments.add(await _finishV4Take(engine));
      }
      state.value = RecitationState.paused;
      log('RecitationSession paused LIVE streaming', name: 'RecitationSession');
    } catch (e, s) {
      final engine = _engine;
      if (engine is TajweedFormerRecitationEngine) {
        await engine.cancelLive();
        _v4TakeOpen = false;
      }
      state.value = RecitationState.error;
      lastError.value = e.toString();
      log(
        'RecitationSession pauseLive error: $e',
        name: 'RecitationSession',
        stackTrace: s,
      );
    } finally {
      _pauseLiveFuture = null;
    }
  }

  /// يستأنف بثّ الميكروفون بعد [pauseLive] — المحرّك احتفظ بحالة
  /// المحاذاة فتُكمل التلاوة من حيث توقفت.
  Future<void> resumeLive() async {
    final engine = _engine;
    if (engine is! LiveCapableRecitationEngine ||
        !isLive.value ||
        state.value != RecitationState.paused ||
        _liveSub != null) {
      return;
    }
    try {
      // المسجّل المحقون (اختبارات) يُستخدم في المسارين — الإنتاج لا يحقن.
      _liveRecorder ??= _recorder ?? AudioRecorder();
      if (engine is TajweedFormerRecitationEngine) {
        _livePcm = Pcm16StreamDecoder();
        await _startEngineTake(engine);
        if (_disposed) return;
      }
      await _startPcmStreaming(engine);
      // أعد تسليح طور الالتقاط: وحدات انزلقت أثناء انتظار إيقاف
      // الميكروفون عند فتح الشيت قد قدّمت المؤشر أمام المستخدم —
      // الإرساء الجديد يحدّد موضعه الفعلي بعد الإغلاق.
      engine.onLiveResumed();
      state.value = RecitationState.recording;
      log(
        'RecitationSession resumed LIVE streaming',
        name: 'RecitationSession',
      );
    } catch (e, s) {
      if (engine is TajweedFormerRecitationEngine) {
        await engine.cancelLive();
        _v4TakeOpen = false;
      }
      state.value = RecitationState.error;
      lastError.value = e.toString();
      log(
        'RecitationSession resumeLive failed: $e',
        name: 'RecitationSession',
        stackTrace: s,
      );
    }
  }

  /// يُنهي البثّ الحي ويُقيّم اللقطة النهائية بنفس مسار التقييم الكامل.
  Future<void> stopLive() => _stopLiveFuture ??= _stopLiveImpl();

  Future<void> _stopLiveImpl() async {
    final engine = _engine;
    if (engine is! LiveCapableRecitationEngine || !isLive.value) return;
    await _pauseLiveFuture;
    if (state.value == RecitationState.error) {
      await _cleanupLiveRecorder();
      isLive.value = false;
      return;
    }
    var terminal = RecitationState.finished;
    try {
      final wasPaused = state.value == RecitationState.paused;
      state.value = RecitationState.processing;
      await _liveSub?.cancel();
      _liveSub = null;
      if (!wasPaused) await _liveRecorder?.stop();
      if (_liveCaptureFailure != null || _livePcm.hasIncompleteSample) {
        throw StateError('تعذّر استقبال الصوت كاملًا من الميكروفون.');
      }
      if (engine is TajweedFormerRecitationEngine && !_v4TakeOpen) {
        result.value = mergePartialV4Results(_v4Segments);
        return;
      }
      final frame = await engine.endLive();
      if (engine is TajweedFormerRecitationEngine) _v4TakeOpen = false;
      liveUnits.assignAll(frame.units);
      log(
        'RecitationSession LIVE stream stats — '
        'chunks=$_liveChunkCount bytes=$_liveTotalBytes '
        'peak=${_livePeak.toStringAsFixed(3)} '
        'units=${frame.units.length}',
        name: 'RecitationSession',
      );
      final res = await engine.evaluateLive(
        config: config,
        suraIdx: suraIdx,
        ayaIdx: ayaIdx,
        range: range,
        referenceText: referenceText,
        frame: frame,
      );
      // الصمت التام (peak=0) ليس تلاوة صحيحة — كلّف المستخدم بفحص الإذن
      // وجهاز الإدخال بدل النجاح الزائف «أحسنت! لا أخطاء». نتيجة V4 هنا
      // لم تُقيَّم أصلًا: العلامة صراحة false مع سبب «لا إشارة صوتية» في
      // التغطية، فلا يوهم حفظُها أو استرجاعُها أيّ تطبيق أنها اكتملت.
      if (_livePeak <= 0.0) {
        result.value = RecitationResult(
          uthmaniText: res.uthmaniText,
          predictedPhonemes: res.predictedPhonemes,
          noMatchMessage:
              'لم يصل أي صوت من الميكروفون — تأكد من منح التطبيق إذن '
              'الميكروفون (إعدادات النظام ← الخصوصية والأمان ← الميكروفون) '
              'ومن اختيار جهاز الإدخال الصحيح في إعدادات الصوت.',
          assessmentComplete: engine is TajweedFormerRecitationEngine
              ? false
              : res.assessmentComplete,
          coverage: engine is TajweedFormerRecitationEngine
              ? unassessedTajweedFormerCoverage(
                  TajweedFormerCoverageReason.noUsableSignal)
              : res.coverage,
        );
      } else {
        result.value =
            engine is TajweedFormerRecitationEngine && _v4Segments.isNotEmpty
                ? mergePartialV4Results([..._v4Segments, res])
                : res;
      }
      log(
        'RecitationSession live done: ${result.value}',
        name: 'RecitationSession',
      );
    } catch (e, s) {
      if (engine is TajweedFormerRecitationEngine && engine.hasActiveTake) {
        try {
          await engine.cancelLive();
        } catch (_) {}
      }
      lastError.value = e.toString();
      terminal = RecitationState.error;
      log(
        'RecitationSession stopLive error: $e',
        name: 'RecitationSession',
        stackTrace: s,
      );
    } finally {
      isLive.value = false;
      currentWordIdx.value = -1;
      currentVerseIdx.value = -1;
      try {
        await _liveRecorder?.dispose();
      } catch (_) {}
      _liveRecorder = null;
      state.value = terminal;
    }
  }
}
