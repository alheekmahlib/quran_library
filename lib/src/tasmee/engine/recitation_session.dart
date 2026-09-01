import 'dart:async';
import 'dart:developer' show log;

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
  AudioRecorder? _recorder;
  bool _ownsRecorder = false;
  String? _recordingPath;

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
  /// Records WAV (16kHz mono) to a temp file. Doesn't send anything to the
  /// server until [stop].
  Future<void> start() async {
    if (state.value.isActive) {
      log('RecitationSession already active', name: 'RecitationSession');
      return;
    }
    try {
      result.value = null;
      lastError.value = '';
      _recorder ??= AudioRecorder();
      _ownsRecorder = true;

      final hasMic = await _recorder!.hasPermission();
      if (!hasMic) {
        throw StateError('Microphone permission denied');
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
      state.value = RecitationState.recording;
      log('RecitationSession started recording: $_recordingPath',
          name: 'RecitationSession');
    } catch (e, s) {
      state.value = RecitationState.error;
      lastError.value = e.toString();
      log('RecitationSession start failed: $e',
          name: 'RecitationSession', stackTrace: s);
    }
  }

  /// أوقف التسجيل ومرّر الصوت لِلمحرّك لِلتصحيح.
  ///
  /// Stop recording and pass the audio to the engine for correction.
  ///
  /// يقرأ ملف WAV كاملاً، يُمرّره لِلمحرّك (online: HTTP، offline: ONNX)،
  /// ويخزّن النتيجة في [result].
  /// Reads the full WAV file, passes it to the engine (online: HTTP,
  /// offline: ONNX), and stores the result in [result].
  Future<void> stop() async {
    try {
      state.value = RecitationState.processing;
      _recordingPath = await _recorder?.stop() ?? _recordingPath;
      log('RecitationSession stopped. Sending to server...',
          name: 'RecitationSession');

      if (_recordingPath == null) {
        throw StateError('No recording file');
      }

      // اقرأ ملف WAV كاملاً.
      // Read the full WAV file.
      final wavBytes = await PlatformIo.readFile(_recordingPath!);
      log('RecitationSession: read ${wavBytes.length} bytes',
          name: 'RecitationSession');

      // 🔍 تشخيص: احتفظ بنسخة من التسجيل في مجلد واضح لِتحليلها offline.
      // Diagnostic: keep a copy in Documents for offline Python analysis.
      try {
        final docDir = await PlatformIo.documentsDir;
        final diagPath = '$docDir/last_recitation.wav';
        await PlatformIo.writeFile(diagPath, wavBytes);
        log('RecitationSession: DIAG copy saved → $diagPath',
            name: 'RecitationSession');
      } catch (_) {}

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
      log('RecitationSession stop error: $e',
          name: 'RecitationSession', stackTrace: s);
    } finally {
      // تنظيف: احذف الملف المؤقّت وتصرّف بالمسجّل.
      // Cleanup: delete the temp file and dispose the recorder.
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
    if (isLive.value) {
      stopLive();
    } else if (state.value == RecitationState.recording) {
      stop();
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
  /// آخر وحدة فيها — ومعها صحة نطقها. اربطه لِتلوين الكلمة أخضر/أحمر.
  ///
  /// Called when a word is fully pronounced (range mode) with its verdict.
  void Function(int verseIdx, int wordIdx, bool correct)? onWordDone;

  /// يُستدعى عند اكتمال كل كلمات النطاق (إتمام الصفحة).
  ///
  /// Called when every word in the range has been completed.
  void Function()? onRangeComplete;

  /// هل الجلسة في الوضع الحي؟
  /// Is the session in live mode?
  final RxBool isLive = false.obs;

  StreamSubscription<dynamic>? _liveSub;
  AudioRecorder? _liveRecorder;

  // تشخيص البث (لِملاحقة جودة ما يسلّمه الميكروفون).
  int _liveChunkCount = 0;
  int _liveTotalBytes = 0;
  double _livePeak = 0.0;

  /// يبدأ التسجيل الحي — يغذّي المحرّك بِـ PCM ويحدّث [liveUnits] لحظيًا.
  ///
  /// يرمي [StateError] إن كان المحرّك لا يدعم البثّ (الأونلاين).
  Future<void> startLive() async {
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
      liveUnits.clear();
      currentWordIdx.value = -1;
      currentVerseIdx.value = -1;
      _liveRecorder ??= AudioRecorder();
      if (!await _liveRecorder!.hasPermission()) {
        throw StateError('Microphone permission denied');
      }
      var lastLoggedCount = 0;
      engine.startLive(
        suraIdx: suraIdx,
        ayaIdx: ayaIdx,
        range: range,
        onPartial: (frame) {
          liveUnits.assignAll(frame.units);
          // سجّل وصول الوحدات كل 5 لِملاحظة الحيّية فورًا في الكونسول.
          if (frame.units.length - lastLoggedCount >= 5 ||
              (frame.units.isNotEmpty && lastLoggedCount == 0)) {
            lastLoggedCount = frame.units.length;
            log(
                'RecitationSession LIVE partial — '
                'units=${frame.units.length} last=${frame.units.last}',
                name: 'RecitationSession');
          }
        },
        onWord: (wordIdx) => currentWordIdx.value = wordIdx,
        onRangeWord: (verseIdx, wordIdx) {
          currentVerseIdx.value = verseIdx;
          currentWordIdx.value = wordIdx;
        },
        onWordDone: onWordDone,
        onRangeComplete: onRangeComplete,
      );
      const settings = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      );
      // record v6: startStream يُعيد Future<Stream> — انتظر الشبكة ثم اشترك.
      final pcmStream = await _liveRecorder!.startStream(settings);
      _liveSub = pcmStream.listen((chunk) {
        // ملاحظة حرجة: دفعات record قد تكون عروضًا داخل ذاكرة أكبر وبإزاحة
        // غير زوجية أحيانًا — pcm16ToFloats ينسخها إلى ذاكرة محاذية.
        _liveChunkCount++;
        _liveTotalBytes += chunk.lengthInBytes;
        final floats = pcm16ToFloats(chunk);
        var peak = 0.0;
        for (final v in floats) {
          final a = v < 0 ? -v : v;
          if (a > peak) peak = a;
        }
        if (peak > _livePeak) _livePeak = peak;
        engine.feedPcm(floats);
      });
      isLive.value = true;
      state.value = RecitationState.recording;
      _liveChunkCount = 0;
      _liveTotalBytes = 0;
      _livePeak = 0.0;
      log('RecitationSession started LIVE streaming',
          name: 'RecitationSession');
    } catch (e, s) {
      state.value = RecitationState.error;
      lastError.value = e.toString();
      log('RecitationSession startLive failed: $e',
          name: 'RecitationSession', stackTrace: s);
    }
  }

  /// يُنهي البثّ الحي ويُقيّم اللقطة النهائية بنفس مسار التقييم الكامل.
  Future<void> stopLive() async {
    final engine = _engine;
    if (engine is! LiveCapableRecitationEngine || !isLive.value) return;
    try {
      state.value = RecitationState.processing;
      await _liveSub?.cancel();
      _liveSub = null;
      await _liveRecorder?.stop();
      final frame = await engine.endLive();
      liveUnits.assignAll(frame.units);
      log(
          'RecitationSession LIVE stream stats — '
          'chunks=$_liveChunkCount bytes=$_liveTotalBytes '
          'peak=${_livePeak.toStringAsFixed(3)} '
          'units=${frame.units.length}',
          name: 'RecitationSession');
      result.value = await engine.evaluateLive(
        config: config,
        suraIdx: suraIdx,
        ayaIdx: ayaIdx,
        range: range,
        referenceText: referenceText,
        frame: frame,
      );
      log('RecitationSession live done: ${result.value}',
          name: 'RecitationSession');
      state.value = RecitationState.finished;
    } catch (e, s) {
      state.value = RecitationState.error;
      lastError.value = e.toString();
      log('RecitationSession stopLive error: $e',
          name: 'RecitationSession', stackTrace: s);
    } finally {
      isLive.value = false;
      currentWordIdx.value = -1;
      currentVerseIdx.value = -1;
      try {
        await _liveRecorder?.dispose();
      } catch (_) {}
      _liveRecorder = null;
    }
  }
}
