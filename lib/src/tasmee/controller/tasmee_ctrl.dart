/// متحكم وضع التسميع — يدير الجلسة وحالات الكلمات والنطاق الصفحي.
///
/// الدورة: [toggleTasmeeMode] (دخول الوضع: إخفاء الكلمات وإيقاف الصوت
/// والسكرول التلقائي) → [startRecording] (تسجيل حيّ مع كشف الكلمات) →
/// [stopRecording] (تقييم نهائي + فتح bottomSheet النتائج) → إعادة أو خروج.
library;

import 'dart:developer' show log;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../quran.dart' as q;
import '../../audio/audio.dart' as qa;
import '../constants/tasmee_storage_constants.dart';
import '../core/services/tasmee_model_service.dart';
import '../core/services/tasmee_reference_store.dart';
import '../engine/models/recitation_result.dart';
import '../engine/quran_reference.dart';
import '../engine/recitation.dart';
import '../engine/recitation_session.dart';
import '../engine/recitation_state.dart';
import '../engine/tasmee_error_kind.dart';
import 'tasmee_state.dart';

/// معرّفات تحديث الواجهة لِـ GetBuilder.
class TasmeeUpdateIds {
  static const String control = 'tasmee_control';
  static String page(int pageIndex) => 'tasmee_page_$pageIndex';
}

class TasmeeCtrl extends GetxController {
  TasmeeCtrl({TasmeeModelService? modelService})
      : _modelService = modelService ?? TasmeeModelService();

  static TasmeeCtrl? _cachedInstance;

  /// نسخة واحدة ثابتة طوال عمر التطبيق.
  ///
  /// حالة التسميع عابرة (وضع مفعّل/جلسة جارية)، لذا لا يجوز أن يحذفها
  /// GetX مع مسار مضيف (SmartManagement) ويُنشئ نسخة جديدة فارغة — ما كان
  /// يُبطل وضع التسميع بعد أول خروج عبر Get.offAll. لذلك يُسجَّل الكائن
  /// [permanent] ويُعاد تسجيله إن أُزيل من السجل، مع الحفاظ على نفس الهوية.
  static TasmeeCtrl get instance {
    final instance = _cachedInstance ??= TasmeeCtrl();
    if (!GetInstance().isRegistered<TasmeeCtrl>()) {
      Get.put<TasmeeCtrl>(instance, permanent: true);
    }
    return instance;
  }

  final TasmeeModelService _modelService;
  final TasmeeState state = TasmeeState();
  final GetStorage _storage = GetStorage();

  RecitationSession? _session;
  QuranReferenceRange? _range;

  /// مفاتيح الكلمات المكتملة بترتيب إتمامها (لِتقليم ما يظهر بعد الإيقاف).
  final List<String> _doneWordKeys = [];

  /// آيات الصفحة مرتبة بترتيب النطاق (لِتحويل فهرس الآية → ayahUq).
  List<q.AyahModel> _rangeAyahs = const [];

  Worker? _stateWorker;
  Worker? _verseWorker;
  Worker? _wordWorker;
  Worker? _pageWorker;

  /// هل التسجيل جارٍ الآن؟
  bool get isRecording => state.sessionState.value == RecitationState.recording;

  /// هل المعالجة جارية (بعد الإيقاف)؟
  bool get isProcessing =>
      state.sessionState.value == RecitationState.processing;

  // ── التهيئة ────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    final mode = _storage.read<String>(TasmeeStorageConstants.engineMode);
    state.engineMode.value =
        mode == 'online' ? TasmeeEngineMode.online : TasmeeEngineMode.offline;
    state.serverUrl.value =
        _storage.read<String>(TasmeeStorageConstants.serverUrl) ?? '';
    if (!kIsWeb) {
      _modelService.isModelReady().then((ready) {
        state.isModelReady.value = ready;
      });
    }
  }

  /// يغيّر المحرك ويحفظ الاختيار.
  void setEngineMode(TasmeeEngineMode mode) {
    state.engineMode.value = mode;
    _storage.write(TasmeeStorageConstants.engineMode,
        mode == TasmeeEngineMode.online ? 'online' : 'offline');
    update([TasmeeUpdateIds.control]);
  }

  /// يضبط عنوان الخادم ويحفظه.
  void setServerUrl(String url) {
    state.serverUrl.value = url.trim();
    _storage.write(TasmeeStorageConstants.serverUrl, state.serverUrl.value);
  }

  // ── دخول/خروج الوضع ────────────────────────────────────────────

  /// يبدّل وضع التسميع: دخول (إخفاء الكلمات) أو خروج (استعادة الوضع).
  void toggleTasmeeMode() {
    if (kIsWeb) return; // الميكروفون/sherpa غير مدعومَين على الويب.
    if (state.isTasmeeMode.value) {
      exitTasmeeMode();
    } else {
      enterTasmeeMode();
    }
  }

  Future<void> enterTasmeeMode() async {
    if (state.isTasmeeMode.value) return;
    // أوقف ما يتعارض مع الميكروفون: تشغيل الصوت والسكرول التلقائي.
    try {
      await qa.AudioCtrl.instance.state.audioPlayer.stop();
    } catch (_) {}
    try {
      q.AutoScrollCtrl.instance.stopAutoScroll();
    } catch (_) {}

    state.isTasmeeMode.value = true;
    state.lastError.value = '';
    state.lastResult.value = null;
    state.showAllWords.value = false;
    // جلسة سابقة قد انتهت بـ finished/error تبقى في الحالة — صفّرها لدخول نظيف.
    state.sessionState.value = RecitationState.idle;
    _doneWordKeys.clear();
    await _buildRangeForCurrentPage();
    _pageWorker?.dispose();
    _pageWorker = ever(q.QuranCtrl.instance.state.currentPageNumber,
        (int page) => _onPageChanged(page));
    // حدّث صفحة القراءة (إخفاء الكلمات) وعناصر التحكم.
    _refreshQuranPages();
    // شاشات لا تستخدم Obx (مثل شاشة الصفحات) تُحدَّث عبر هذا المعرف.
    q.QuranCtrl.instance.update(['isShowControl']);
    update([TasmeeUpdateIds.control]);
  }

  void exitTasmeeMode() {
    // التقط رقم الصفحة قبل تصفيره — دونه لا يُحدَّث معرّف الصفحة فتبقى
    // الكلمات مخفية على كاش السطر حتى يلمس المستخدم الشاشة.
    final page = state.currentRangePage;
    _cancelSession();
    _pageWorker?.dispose();
    _pageWorker = null;
    state.isTasmeeMode.value = false;
    state.wordStatuses.clear();
    state.wordErrorKinds.clear();
    state.currentWordKey.value = null;
    state.lastError.value = '';
    state.completedWords.value = 0;
    state.totalWords.value = 0;
    state.sessionState.value = RecitationState.idle;
    _range = null;
    _rangeAyahs = const [];
    state.currentRangePage = -1;
    if (page > 0) update([TasmeeUpdateIds.page(page - 1)]);
    q.QuranCtrl.instance.update(['isShowControl']);
    update([TasmeeUpdateIds.control]);
  }

  void _onPageChanged(int page) {
    if (!state.isTasmeeMode.value) return;
    if (isRecording || isProcessing) {
      // تغيير الصفحة أثناء التسجيل — أوقف وقيّم ما تُلِي.
      stopRecording();
      return;
    }
    _buildRangeForCurrentPage();
    _refreshQuranPages();
  }

  // ── بناء النطاق ────────────────────────────────────────────────

  /// يبني النطاق المرجعي لآيات الصفحة الحالية ويصفّر حالات الكلمات.
  Future<void> _buildRangeForCurrentPage() async {
    final prevPage = state.currentRangePage;
    final page = q.QuranCtrl.instance.state.currentPageNumber.value;
    state.currentRangePage = page;
    state.wordStatuses.clear();
    state.wordErrorKinds.clear();
    state.currentWordKey.value = null;
    state.completedWords.value = 0;
    state.totalWords.value = 0;

    try {
      await TasmeeReferenceStore.instance.load();
      // جهّز متغير الخط الشفاف للصفحة (إخفاء الكلمات دون المساس
      // بالمواضع) — تحميل كسول عند الطلب فقط.
      state.transparentFontsReady.value =
          await q.QuranFontsService.ensureTransparentFont(page);
      final ayahs = q.QuranCtrl.instance.getAyahsByPage(page)
        ..sort((a, b) => a.ayahUQNumber.compareTo(b.ayahUQNumber));
      _rangeAyahs = ayahs;
      _range = TasmeeReferenceStore.instance.buildRange([
        for (final a in ayahs)
          if (a.surahNumber != null)
            (suraIdx: a.surahNumber!, ayaIdx: a.ayahNumber),
      ]);
      state.totalWords.value = _range?.wordCount ?? 0;
      if (_range == null) {
        state.lastError.value =
            'تعذّر تجهيز مرجع التسميع لهذه الصفحة (قد تكون البيانات غير محمّلة بعد)';
        log('TasmeeCtrl: range build failed for page $page',
            name: 'TasmeeCtrl');
      }
    } catch (e) {
      _range = null;
      state.lastError.value = 'خطأ في تجهيز التسميع: $e';
    } finally {
      // حدّث الصفحة الجديدة — والقديمة أيضًا (تبقى حيّة في PageView وقد
      // تكون كلماتها مخفية على كاش السطر).
      _refreshQuranPages();
      if (prevPage > 0 && prevPage != page) {
        update([TasmeeUpdateIds.page(prevPage - 1)]);
      }
    }
  }

  // ── التسجيل ────────────────────────────────────────────────────

  /// يبدأ التسجيل بعد التأكد من جاهزية المحرك والنموذج.
  Future<void> startRecording() async {
    if (state.isTasmeeMode.value == false ||
        isRecording ||
        isProcessing ||
        kIsWeb) {
      return;
    }
    state.lastError.value = '';
    state.lastResult.value = null;

    if (_range == null) await _buildRangeForCurrentPage();
    if (_range == null) {
      update([TasmeeUpdateIds.control]);
      return;
    }

    state.isPreparingEngine.value = true;
    update([TasmeeUpdateIds.control]);
    final ready = await _ensureEngineReady();
    state.isPreparingEngine.value = false;
    if (!ready) {
      update([TasmeeUpdateIds.control]);
      return;
    }

    try {
      final session = Recitation.createSession(range: _range);
      _session = session;
      _stateWorker = ever<RecitationState>(session.state, (s) {
        // انسخ النتيجة قبل إعلان الحالة كي تجدها مستمعات الواجهة
        // (وإلا فاتها فتح bottomSheet النتائج).
        if (s == RecitationState.finished) {
          state.lastResult.value = _session?.result.value;
        }
        state.sessionState.value = s;
        update([TasmeeUpdateIds.control]);
      });
      session.onWordDone = _onWordDone;
      session.onRangeComplete = () {
        // أكمل الصفحة — أوقف بعد مهلة قصيرة تسمح بآخر وحدة.
        Future.delayed(const Duration(milliseconds: 800), () {
          if (isRecording) stopRecording();
        });
      };

      state.completedWords.value = 0;
      // الكلمة الجارية (الوضع الحيّ فقط — offline).
      _verseWorker = ever<int>(session.currentVerseIdx, (v) {
        final w = session.currentWordIdx.value;
        if (v >= 0 && w >= 0) markCurrentWord(v, w);
      });
      _wordWorker = ever<int>(session.currentWordIdx, (w) {
        final v = session.currentVerseIdx.value;
        if (v >= 0 && w >= 0) markCurrentWord(v, w);
      });
      if (Recitation.isOffline) {
        await session.startLive();
      } else {
        // الخادم: دفعة واحدة (بلا كشف حيّ).
        await session.start();
      }
      if (session.state.value == RecitationState.error) {
        state.lastError.value = session.lastError.value;
      }
    } catch (e) {
      state.lastError.value = 'تعذّر بدء التسجيل: $e';
      state.sessionState.value = RecitationState.error;
    }
    update([TasmeeUpdateIds.control]);
  }

  /// يوقف التسجيل ويُقيّم — النتيجة في [TasmeeState.lastResult].
  ///
  /// بعد الإيقاف يبقى ظاهرًا فقط ما أُتمّ نطقه فعلًا (الكلمات المكتملة)
  /// مع تلوينها بحسب التقييم النهائي المعتمد.
  Future<void> stopRecording() async {
    final session = _session;
    if (session == null) return;
    try {
      if (session.isLive.value) {
        await session.stopLive();
      } else if (session.state.value == RecitationState.recording) {
        await session.stop();
      }
      final result = session.result.value;
      state.lastResult.value = result;
      if (result == null || !result.hasMatch) {
        state.lastError.value =
            result?.noMatchMessage ?? session.lastError.value;
      } else {
        _applyFinalErrorsToStatuses(result);
      }
    } catch (e) {
      state.lastError.value = 'خطأ في التقييم: $e';
    } finally {
      _trimToCompletedWords();
      _cancelSession();
      _refreshQuranPages();
      update([TasmeeUpdateIds.control]);
    }
  }

  /// يقصِر الحالات الظاهرة على الكلمات المكتملة فقط — الكلمة "الجارية"
  /// الأخيرة غير المؤكَّدة تُخفى، فلا يظهر بعد الإيقاف إلا ما تُلِي فعلًا.
  void _trimToCompletedWords() {
    final done = _doneWordKeys.toSet();
    state.wordStatuses.removeWhere((key, _) => !done.contains(key));
    state.currentWordKey.value = null;
  }

  /// إعادة التسميع من البداية (الكلمات تُخفى من جديد).
  Future<void> retryTasmee() async {
    state.lastResult.value = null;
    state.lastError.value = '';
    state.wordErrorKinds.clear();
    _doneWordKeys.clear();
    await _buildRangeForCurrentPage();
    _refreshQuranPages();
    update([TasmeeUpdateIds.control]);
  }

  void _cancelSession() {
    _stateWorker?.dispose();
    _stateWorker = null;
    _verseWorker?.dispose();
    _verseWorker = null;
    _wordWorker?.dispose();
    _wordWorker = null;
    try {
      _session?.dispose();
    } catch (_) {}
    _session = null;
    if (state.sessionState.value == RecitationState.recording ||
        state.sessionState.value == RecitationState.processing) {
      state.sessionState.value = RecitationState.idle;
    }
  }

  // ── جاهزية المحرك ──────────────────────────────────────────────

  Future<bool> _ensureEngineReady() async {
    try {
      if (state.engineMode.value == TasmeeEngineMode.offline) {
        if (!state.isModelReady.value) {
          final ok = await downloadModelIfNeeded();
          if (!ok) return false;
        }
        if (!(Recitation.isInitialized && Recitation.isOffline)) {
          await Recitation.initZipformer();
        }
        return true;
      }
      // online — خادم Muaalem.
      final url = state.serverUrl.value.trim();
      if (url.isEmpty) {
        state.lastError.value =
            'أدخل عنوان خادم التسميع من الإعدادات (⚙) قبل البدء';
        return false;
      }
      if (!(Recitation.isInitialized &&
          !Recitation.isOffline &&
          Recitation.serverUrl == url)) {
        Recitation.init(serverUrl: url);
      }
      final healthy = await Recitation.isEngineHealthy();
      if (!healthy) {
        state.lastError.value =
            'لا يمكن الوصول إلى خادم التسميع — تحقّق من العنوان والاتصال';
        return false;
      }
      return true;
    } catch (e) {
      state.lastError.value = 'خطأ في تهيئة محرّك التسميع: $e';
      return false;
    }
  }

  /// ينزّل النموذج (73MB) إن لم يكن جاهزاً — مع تقدّم لحظي في الحالة.
  Future<bool> downloadModelIfNeeded() async {
    if (state.isDownloadingModel.value) return false;
    state.isDownloadingModel.value = true;
    state.modelDownloadProgress.value = 0;
    update([TasmeeUpdateIds.control]);
    try {
      await _modelService.downloadModel(
        onProgress: (p) {
          state.modelDownloadProgress.value = p;
          update([TasmeeUpdateIds.control]);
        },
      );
      state.isModelReady.value = true;
      state.modelDownloadProgress.value = 1;
      return true;
    } catch (e) {
      state.lastError.value = 'فشل تنزيل نموذج التسميع: $e';
      return false;
    } finally {
      state.isDownloadingModel.value = false;
      update([TasmeeUpdateIds.control]);
    }
  }

  /// يبدّل إظهار كل كلمات الصفحة مؤقتًا (زر العين).
  void toggleShowAllWords() {
    state.showAllWords.value = !state.showAllWords.value;
    _refreshQuranPages();
    update([TasmeeUpdateIds.control]);
  }

  /// يفحص اتصال خادم التسميع بالعنوان المحفوظ (لِلواجهة).
  Future<bool> testServerConnection() async {
    final url = state.serverUrl.value.trim();
    if (url.isEmpty) return false;
    try {
      Recitation.init(serverUrl: url);
      return await Recitation.isEngineHealthy();
    } catch (_) {
      return false;
    }
  }

  // ── حالات الكلمات ──────────────────────────────────────────────

  String _wordKey(int verseIdx, int wordIdx) {
    final ayah = _rangeAyahs[verseIdx];
    return '${ayah.ayahUQNumber}:${wordIdx + 1}';
  }

  void _onWordDone(int verseIdx, int wordIdx, TasmeeErrorKind kind) {
    if (verseIdx < 0 || verseIdx >= _rangeAyahs.length) return;
    final key = _wordKey(verseIdx, wordIdx);
    _doneWordKeys.add(key);
    final correct = kind == TasmeeErrorKind.correct;
    state.wordStatuses[key] =
        correct ? TasmeeWordStatus.correct : TasmeeWordStatus.incorrect;
    if (correct) {
      state.wordErrorKinds.remove(key);
    } else {
      state.wordErrorKinds[key] = kind;
    }
    if (state.currentWordKey.value == key) {
      state.currentWordKey.value = null;
    }
    state.completedWords.value = state.wordStatuses.values
        .where((s) => s != TasmeeWordStatus.hidden)
        .length;
    _refreshQuranPages();
  }

  /// الكلمة الجارية (من محاذاة الوضع الحيّ) — تُبرز لحظيًا.
  void markCurrentWord(int verseIdx, int wordIdx) {
    if (verseIdx < 0 || verseIdx >= _rangeAyahs.length) return;
    final key = _wordKey(verseIdx, wordIdx);
    // الكلمة الجارية تُبرَز فور ظهورها (الحالات النهائية تُدار من
    // onWordDone ولا تُداس هنا).
    if (state.wordStatuses[key] == null ||
        state.wordStatuses[key] == TasmeeWordStatus.hidden) {
      state.wordStatuses[key] = TasmeeWordStatus.current;
    }
    state.currentWordKey.value = key;
    _refreshQuranPages();
  }

  /// يرقّع تصنيف الكلمات من التقييم النهائي (المرجع المعتمد) —
  /// يستبدل التصنيف الحيّ الاسترشادي بلون أعلى أسبقية عند تعدد الأخطاء.
  void _applyFinalErrorsToStatuses(RecitationResult result) {
    for (final error in result.errors) {
      if (error.suraIdx == null ||
          error.ayaIdx == null ||
          error.wordIdx == null) {
        continue;
      }
      final verseIdx = _verseIndexOf(error.suraIdx!, error.ayaIdx!);
      if (verseIdx < 0) continue;
      final key = _wordKey(verseIdx, error.wordIdx!);
      state.wordStatuses[key] = TasmeeWordStatus.incorrect;
      final kind = tasmeeErrorKindFromType(error.errorType);
      final prev = state.wordErrorKinds[key];
      state.wordErrorKinds[key] =
          prev == null ? kind : mergeTasmeeErrorKinds(prev, kind);
    }
  }

  int _verseIndexOf(int suraIdx, int ayaIdx) {
    for (var i = 0; i < _rangeAyahs.length; i++) {
      final a = _rangeAyahs[i];
      if (a.surahNumber == suraIdx && a.ayahNumber == ayaIdx) return i;
    }
    return -1;
  }

  /// حالة كلمة بمفتاحها (لِلطبقة العرضية).
  TasmeeWordStatus wordStatusOf(String key) =>
      state.wordStatuses[key] ?? TasmeeWordStatus.hidden;

  /// نوع خطأ كلمة خاطئة بمفتاحها (null للصحيحة/المخفية).
  TasmeeErrorKind? tasmeeErrorKindOf(String key) => state.wordErrorKinds[key];

  /// يحدّث صفحات القراءة المعروضة (إخفاء/إظهار/تلوين الكلمات).
  ///
  /// التحديث موجَّه لِـ `GetBuilder<TasmeeCtrl>` بمعرّف الصفحة — وبصمة
  /// السطر (tasmeeFingerprint) تتكفّل بإعادة البناء عند تغيّر الحالات.
  void _refreshQuranPages() {
    final page = state.currentRangePage;
    if (page > 0) {
      update([TasmeeUpdateIds.page(page - 1)]);
    }
  }

  @override
  void onClose() {
    _cancelSession();
    _pageWorker?.dispose();
    _pageWorker = null;
    super.onClose();
  }
}
