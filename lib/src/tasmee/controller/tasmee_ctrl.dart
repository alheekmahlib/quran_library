/// متحكم وضع التسميع — يدير الجلسة وحالات الكلمات والنطاق الصفحي.
///
/// الدورة: [toggleTasmeeMode] (دخول الوضع: إخفاء الكلمات وإيقاف الصوت
/// والسكرول التلقائي) → [startRecording] (تسجيل حيّ مع كشف الكلمات) →
/// [stopRecording] (تقييم نهائي + فتح bottomSheet النتائج) → إعادة أو خروج.
library;

import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart'
    show kIsWeb, visibleForTesting, debugPrint;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../quran.dart' as q;
import '../../audio/audio.dart' as qa;
import '../constants/tasmee_storage_constants.dart';
import '../core/services/tajweedformer_prefetch_service.dart';
import '../core/services/tasmee_model_service.dart';
import '../core/services/tasmee_reference_store.dart';
import '../engine/final_reconciliation.dart';
import '../engine/models/recitation_result.dart';
import '../engine/models/muaalem_config.dart';
import '../engine/models/tasmee_tolerance.dart';
import '../engine/quran_reference.dart';
import '../engine/recitation.dart';
import '../engine/recitation_session.dart';
import '../engine/recitation_state.dart';
import '../engine/tasmee_error_kind.dart';
import '../engine/tajweedformer_key_source.dart';
import 'tasmee_mode.dart';
import 'tasmee_state.dart';
import 'word_retry_policy.dart';

/// معرّفات تحديث الواجهة لِـ GetBuilder.
class TasmeeUpdateIds {
  static const String control = 'tasmee_control';
  static String page(int pageIndex) => 'tasmee_page_$pageIndex';
}

/// هل يُنفَّذ إيقاف مؤجَل أصدرته [issuer]؟ — فقط إن كانت ما تزال الجلسة
/// الحالية للمتحكم والتسجيل جارٍ.
///
/// ردود جلسة سابقة (اكتمل نطاقها قبل انتهائها واستبدالها) تصل بعد مهلة
/// قد تكون الجلسة الجديدة قد بدأت خلالها؛ دون ربط الإيقاف بهوية المالك
/// توقف الردّ القديم تسجيل الجديدة. منطق نقي يُختبر بمعزل عن الصوت.
bool tasmeeDeferredStopAppliesToCurrentSession({
  required RecitationSession? current,
  required RecitationSession issuer,
  required bool recording,
}) =>
    current != null && identical(current, issuer) && recording;

class TasmeeCtrl extends GetxController {
  TasmeeCtrl({
    TasmeeModelService? modelService,
    TajweedFormerPrefetchService? v4PrefetchService,
  })  : _modelService = modelService ?? TasmeeModelService(),
        _v4PrefetchService = v4PrefetchService ?? TajweedFormerPrefetchService();

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
  final TajweedFormerPrefetchService _v4PrefetchService;
  final TasmeeState state = TasmeeState();
  final GetStorage _storage = GetStorage();

  RecitationSession? _session;
  QuranReferenceRange? _range;

  /// خطاف التقدّم الآلي لحلقة المعلم (اختياري، يضبطه التطبيق المضيف):
  /// يُستدعى بعد كل تقييم آية كامل التقييم (`assessmentComplete` مع
  /// تطابق)، وإعادته true تعني أن مصدر حكمه يغطي شروط الانتقال للآية
  /// التالية تلقائيًا. بلا خطاف (null) يبقى القرار يدويًا صريحًا عبر
  /// [selectTeacherAyah].
  bool Function(RecitationResult result)? teacherAdvancePolicy;

  /// جلسة إعادة نطق كلمة واحدة (نمط المصحح) — منفصلة عن الجلسة
  /// الرئيسية المتوقفة مؤقتًا.
  RecitationSession? _retrySession;
  Worker? _retryStateWorker;
  Timer? _retryTimer;
  Future<void> _retryRelease = Future.value();

  /// مفاتيح الكلمات المكتملة بترتيب إتمامها (لِتقليم ما يظهر بعد الإيقاف).
  final List<String> _doneWordKeys = [];

  /// مفاتيح الكلمات التي قُبل تصحيحها في شيت المصحّح — التقييم النهائي
  /// يحترمها: تبقى خضراء وتُصفّى أخطاؤها الأصلية من نتيجة العرض.
  final Set<String> _acceptedCorrections = {};

  /// تصحيح قيد الفتح (بين حدث الكلمة الخاطئة وضبط الشيت) — يمنع فتح
  /// تصحيح ثانٍ أثناء انتظار إيقاف الميكروفون (سباق الأحداث المتتالية).
  bool _correctionPending = false;

  /// كلمات عليها دليل خطأ أول (وحدة واحدة) ولم تُفتح بعد — سياسة
  /// الدليلين: الحذف أو الاستبدال المعزول الأول يعلِّم حمراء بلا شيت،
  /// ويُفتح التصحيح عند دليل ثانٍ (حرفان خاطئان أو تكرار الكلمة).
  final Set<String> _wordFirstEvidence = {};
  final Set<String> _v4MatchedKeys = {};

  /// إزاحة فهارس الآيات لجلسة النطاق الفرعي (نمط المعلم) — لتأطير
  /// أحداث الكلمات وتغطية التقييم النهائي على مواضعها الصفحية.
  int _sessionVerseOffset = 0;

  /// آيات الصفحة مرتبة بترتيب النطاق (لِتحويل فهرس الآية → ayahUq).
  List<q.AyahModel> _rangeAyahs = const [];

  Worker? _stateWorker;
  Worker? _pageWorker;

  /// هل التسجيل جارٍ الآن؟
  bool get isRecording => state.sessionState.value == RecitationState.recording;

  /// هل المعالجة جارية (بعد الإيقاف)؟
  bool get isProcessing =>
      state.sessionState.value == RecitationState.processing;

  /// عدد آيات نطاق الصفحة الحالية (لِحلقة المعلم).
  int get rangeAyahCount => _rangeAyahs.length;

  /// رقم الآية الفريد (UQ) لآية داخل النطاق — أو -1.
  int rangeAyahUQ(int verseIdx) =>
      verseIdx >= 0 && verseIdx < _rangeAyahs.length
          ? _rangeAyahs[verseIdx].ayahUQNumber
          : -1;

  // ── التهيئة ────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    final mode = _storage.read<String>(TasmeeStorageConstants.engineMode);
    state.engineMode.value = switch (mode) {
      'online' => TasmeeEngineMode.online,
      'tajweedFormer' => TasmeeEngineMode.tajweedFormer,
      _ => TasmeeEngineMode.offline,
    };
    state.serverUrl.value =
        _storage.read<String>(TasmeeStorageConstants.serverUrl) ?? '';
    state.mode.value = tasmeeModeFromName(
      _storage.read<String>(TasmeeStorageConstants.tasmeeMode),
    );
    state.nonBlockingCorrector.value =
        _storage.read<bool>(TasmeeStorageConstants.nonBlockingCorrector) ??
            false;
    ever<bool>(state.nonBlockingCorrector, (v) {
      _storage.write(TasmeeStorageConstants.nonBlockingCorrector, v);
    });
    state.strictness.value = TasmeeStrictness.fromName(
      _storage.read<String>(TasmeeStorageConstants.strictness),
    );
    ever<TasmeeStrictness>(state.strictness, (v) {
      _storage.write(TasmeeStorageConstants.strictness, v.storageName);
    });
    state.tolerance.value = TasmeeToleranceProfile.fromJson(
      _storage.read(TasmeeStorageConstants.tolerance),
      fallback: TasmeeToleranceLevel.parse(
          state.strictness.value.name, TasmeeToleranceLevel.balanced),
    );
    ever<TasmeeToleranceProfile>(state.tolerance, (v) {
      _storage.write(TasmeeStorageConstants.tolerance, v.toJson());
    });
    state.isV4ModelReady.value =
        _storage.read<bool>(TasmeeStorageConstants.v4ModelReady) ?? false;
    ever<bool>(state.isV4ModelReady, (v) {
      _storage.write(TasmeeStorageConstants.v4ModelReady, v);
    });
    state.v4WifiOnly.value =
        _storage.read<bool>(TasmeeStorageConstants.v4WifiOnly) ?? true;
    ever<bool>(state.v4WifiOnly, (v) {
      _storage.write(TasmeeStorageConstants.v4WifiOnly, v);
    });
    if (!kIsWeb) {
      _modelService.isModelReady().then((ready) {
        state.isModelReady.value = ready;
      });
    }
  }

  /// عتبة القبول النسبي لإعادة نطق الكلمة بحسب [TasmeeState.strictness]:
  /// صارم 0.85 / متوازن 0.75 (مدى فحص التسميع) / متسامح 0.70.
  double get wordRetryMinAccuracy => switch (state.strictness.value) {
        TasmeeStrictness.strict => 0.85,
        TasmeeStrictness.balanced => 0.75,
        TasmeeStrictness.lenient => 0.70,
      };

  /// يبدّل نمط التسميع (تسميع/مصحح/معلم) ويحفظ الاختيار.
  ///
  /// إن كان التسجيل نشطًا يُوقف ويُقيَّم أولًا — فتُحفظ نتيجة الصفحة عبر
  /// مستمع الاكتمال في التطبيق — ثم يُصفَّر النطاق بالنمط الجديد:
  /// المصحح والمعلم يفرضان إظهار الكلمات، والتسميع يخفيها.
  /// Apply a general preset to all diagnostic categories.
  void setTolerancePreset(TasmeeStrictness preset) {
    state.strictness.value = preset;
    state.tolerance.value = TasmeeToleranceProfile.uniform(
      TasmeeToleranceLevel.parse(preset.name, TasmeeToleranceLevel.balanced),
    );
    update([TasmeeUpdateIds.control]);
  }

  void setToleranceProfile(TasmeeToleranceProfile profile) {
    state.tolerance.value = profile;
    update([TasmeeUpdateIds.control]);
  }

  Future<void> setMode(TasmeeMode mode) async {
    if (state.mode.value == mode) return;
    _disposeRetrySession();
    state.activeWordCorrection.value = null;
    state.wordRetryOutcome.value = null;
    state.wordRetryFeedback.value = null;
    // اضبط النمط قبل الإيقاف كي تحترس مستمعات المعلم في التطبيق من
    // تقييم جلسةٍ تنتمي لنمطٍ قديم.
    state.mode.value = mode;
    _storage.write(TasmeeStorageConstants.tasmeeMode, mode.storageName);
    // الآيات ظاهرة دائمًا في المصحح والمعلم؛ والتسميع يبدأ مخفيًا
    // (وزر العين للمستخدم فيه).
    state.showAllWords.value = mode.showsWordsByDefault;
    if (isRecording ||
        isProcessing ||
        state.sessionState.value == RecitationState.connecting ||
        state.sessionState.value == RecitationState.paused) {
      await stopRecording();
    }
    await retryTasmee();
    update([TasmeeUpdateIds.control]);
  }

  /// يغيّر المحرك ويحفظ الاختيار.
  void setEngineMode(TasmeeEngineMode mode) {
    if (isRecording ||
        isProcessing ||
        state.isPreparingEngine.value ||
        state.sessionState.value == RecitationState.paused ||
        state.sessionState.value == RecitationState.connecting) {
      return;
    }
    state.engineMode.value = mode;
    _storage.write(TasmeeStorageConstants.engineMode, mode.name);
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

    // إظهار الكلمات افتراضيًا في المصحح والمعلم، وإخفاؤها في التسميع.
    state.showAllWords.value = state.mode.value.showsWordsByDefault;
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
    // أبطِل أي بناء نطاق جارٍ: الخروج يصفّر الحالة والمرجع، وبناء قديم
    // يكتمل بعده لا يعيد تطبيق مرجعه فوق الحالة المنتهية — رفعُ الجيل
    // يجعل حرّاس البناء تُهمِل ناتجه، وعلامات الاكتمال لم تعد تصف شيئًا.
    // ورفعُ دورة التسميع يمنع حلقات الاستقرار الجارية من استهلال بناء
    // بديل بعد الخروج.
    _rangeBuildGeneration++;
    _rangeAppliedPage = -1;
    _rangeAppliedGeneration = 0;
    _tasmeeCycle++;
    _disposeRetrySession();
    state.activeWordCorrection.value = null;
    state.wordRetryOutcome.value = null;
    state.wordRetryFeedback.value = null;
    _cancelSession();
    _pageWorker?.dispose();
    _pageWorker = null;
    state.isTasmeeMode.value = false;
    state.wordStatuses.clear();
    state.wordErrorKinds.clear();
    _wordFirstEvidence.clear();
    state.currentWordKey.value = null;
    state.lastError.value = '';
    state.completedWords.value = 0;
    state.totalWords.value = 0;
    state.sessionState.value = RecitationState.idle;
    _acceptedCorrections.clear();
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
      // تغيير الصفحة أثناء التسجيل — أوقف وقيّم ما تُلِي، ثم ابنِ نطاق
      // الصفحة الجديدة؛ العودة دون بنائه تُبقي مرجع الصفحة السابقة
      // فتبدأ المحاولة التالية على مرجع خاطئ رغم تغيّر المعروض.
      stopRecording().whenComplete(() {
        if (!state.isTasmeeMode.value || isRecording || isProcessing) return;
        _buildRangeForCurrentPage();
        _refreshQuranPages();
      });
      return;
    }
    _buildRangeForCurrentPage();
    _refreshQuranPages();
  }

  // ── بناء النطاق ────────────────────────────────────────────────

  /// آخر بناء نطاق مُستأل (الأحدث دائمًا) — يُنتظر قبل بدء أي تسجيل.
  Future<void>? _rangeBuild;

  /// رقم جيل بناء النطاق — يُهمَل ناتج أي بناء يكتمل بعد استهلال أحدث.
  int _rangeBuildGeneration = 0;

  /// الصفحة التي **اكتمل** بناء نطاقها فعلًا وطُبِّق على `_range`/`_rangeAyahs`.
  ///
  /// تختلف عن `currentRangePage` التي تُحدَّث في **بداية** البناء: مقارنة
  /// الرقم الأخير وحدها تجتاز الفحص وبنفسها قائمة آيات قديمة، لأن البناء
  /// يحدّث رقم الصفحة أولًا والنطاق في نهايته.
  int _rangeAppliedPage = -1;

  /// جيل آخر بناء **طبّق** نطاقه — إن استُهل جيل أحدث بعده فالمرجع الحالي
  /// قد يكون قيد الاستبدال مهما قال رقم الصفحة.
  int _rangeAppliedGeneration = 0;

  /// رقم دورة دخول/خروج التسميع — يرتفع عند الخروج. يلتقطه طلب البدء
  /// عند انطلاقه، وتُلغى محاولات الاستقرار والبناء إن انتهت دورته: لا
  /// يبدأ بناء نطاق بديل بعد الخروج فيعيد ملء المرجع والحالات فوق وضع
  /// منتهٍ (حرّاس الجيل تُبطل البناء الجاري، وهذا يمنع استهلال بديله).
  int _tasmeeCycle = 0;

  /// يبني النطاق المرجعي لآيات الصفحة الحالية ويصفّر حالات الكلمات.
  ///
  /// كل استدعاء يرقّم بناءه؛ إذا اكتمل بناء قديم بعد استهلال أحدث (تقليب
  /// صفحات سريع) هُمل ناتجه دون تطبيق حالاته على الصفحة الأحدث.
  Future<void> _buildRangeForCurrentPage() {
    final generation = ++_rangeBuildGeneration;
    return _rangeBuild = _buildRangeForPage(generation);
  }

  /// هل مرجع الصفحة الحالية مكتملاً؟ — نطاق مطبَّق لهذه الصفحة تحديدًا،
  /// بجيل هو الأحدث فعلًا (لا بناء أحدث استُهل بعده).
  bool get _hasFreshRangeForCurrentPage {
    if (_range == null) return false;
    if (_rangeAppliedPage !=
        q.QuranCtrl.instance.state.currentPageNumber.value) {
      return false;
    }
    return _rangeAppliedGeneration == _rangeBuildGeneration;
  }

  /// ينتظر استقرار مرجع الصفحة الحالية: ينجز أحدث بناء جارٍ، ويبني من
  /// جديد ما لم يكتمل مرجعها، حتى يستقر أحدث جيل بلا بناء أحدث منه.
  ///
  /// [tasmeeCycle] دورة التسميع التي انطلق بها طلب البدء — إن خرج
  /// المستخدم أثناء الانتظار تُلغى الحلقة فورًا ولا يُستهل بناء بديل
  /// بعد الخروج. تعيد false أيضًا إن ظلت الصفحة تتقلب خلال المحاولات —
  /// الطلب غير مستقر الآن، ودعوة البدء تُلغى.
  Future<bool> _ensureCurrentPageRange({required int tasmeeCycle}) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      await _rangeBuild;
      // انتهت دورة هذا الطلب (خروج) — ألغِ ولا تبنِ بعد الخروج.
      if (tasmeeCycle != _tasmeeCycle || !state.isTasmeeMode.value) {
        return false;
      }
      if (_hasFreshRangeForCurrentPage) return true;
      await _buildRangeForCurrentPage();
    }
    await _rangeBuild;
    return tasmeeCycle == _tasmeeCycle &&
        state.isTasmeeMode.value &&
        _hasFreshRangeForCurrentPage;
  }

  Future<void> _buildRangeForPage(int generation) async {
    final prevPage = state.currentRangePage;
    final page = q.QuranCtrl.instance.state.currentPageNumber.value;
    state.currentRangePage = page;
    state.teacherAyahIndex.value = -1;
    state.teacherAyahTotal.value = 0;
    state.teacherPhase.value = TasmeeTeacherPhase.idle;
    state.wordStatuses.clear();
    state.wordErrorKinds.clear();
    state.currentWordKey.value = null;
    state.completedWords.value = 0;
    state.totalWords.value = 0;
    _acceptedCorrections.clear();
    _wordFirstEvidence.clear();

    try {
      await TasmeeReferenceStore.instance.load();
      if (generation != _rangeBuildGeneration) return;
      // جهّز متغير الخط الشفاف للصفحة (إخفاء الكلمات دون المساس
      // بالمواضع) — تحميل كسول عند الطلب فقط.
      state.transparentFontsReady.value =
          await q.QuranFontsService.ensureTransparentFont(page);
      if (generation != _rangeBuildGeneration) return;
      final ayahs = q.QuranCtrl.instance.getAyahsByPage(page)
        ..sort((a, b) => a.ayahUQNumber.compareTo(b.ayahUQNumber));
      _rangeAyahs = ayahs;
      state.teacherAyahTotal.value = ayahs.length;
      state.teacherAyahIndex.value = ayahs.isEmpty ? -1 : 0;
      _range = TasmeeReferenceStore.instance.buildRange([
        for (final a in ayahs)
          if (a.surahNumber != null)
            (suraIdx: a.surahNumber!, ayaIdx: a.ayahNumber),
      ]);
      state.totalWords.value = _range?.wordCount ?? 0;
      if (_range != null) {
        // علامتا الاكتمال: النطاق والقائمة يخصّان هذه الصفحة وهذا الجيل
        // **فعليًا** (لا مجرد بناء بدأ) — عليهما يبني فحص الاستقرار.
        _rangeAppliedPage = page;
        _rangeAppliedGeneration = generation;
      }
      if (_range == null) {
        state.lastError.value =
            'تعذّر تجهيز مرجع التسميع لهذه الصفحة (قد تكون البيانات غير محمّلة بعد)';
        log('TasmeeCtrl: range build failed for page $page',
            name: 'TasmeeCtrl');
      }
    } catch (e) {
      if (generation != _rangeBuildGeneration) return;
      _range = null;
      state.lastError.value = 'خطأ في تجهيز التسميع: $e';
    } finally {
      // حدّث الصفحة الجديدة — والقديمة أيضًا (تبقى حيّة في PageView وقد
      // تكون كلماتها مخفية على كاش السطر). البناء المهمل لا يحدّث شيئًا.
      if (generation == _rangeBuildGeneration) {
        _refreshQuranPages();
        if (prevPage > 0 && prevPage != page) {
          update([TasmeeUpdateIds.page(prevPage - 1)]);
        }
      }
    }
  }

  // ── التسجيل ────────────────────────────────────────────────────

  /// يبدأ التسجيل بعد التأكد من جاهزية المحرك والنموذج.
  Future<void> startRecording() async {
    if (state.isTasmeeMode.value == false ||
        // نمط المعلم يُدار آية-بآية عبر [startAyahRecording].
        state.mode.value == TasmeeMode.teacher ||
        isRecording ||
        isProcessing ||
        // جلسة قائمة متوقفة (تصحيح كلمة) أو قيد الاتصال — لا تبدأ جلسة
        // ثانية فوقها؛ قد يرفضها المحرك فتُفسد الأولى.
        state.sessionState.value == RecitationState.paused ||
        state.sessionState.value == RecitationState.connecting ||
        state.isPreparingEngine.value) {
      return;
    }
    // الحارس قبل أي انتظار: طلبان متقاربان لا يجتازان الفحص معًا أثناء
    // انتظار بناء المرجع أو تهيئة المحرك. والدورة تُلتقط الآن: إن خرج
    // المستخدم أثناء أي انتظار لاحق تُلغى محاولات الاستقرار والبناء.
    final tasmeeCycle = _tasmeeCycle;
    state.isPreparingEngine.value = true;
    update([TasmeeUpdateIds.control]);
    try {
      state.lastError.value = '';
      state.lastResult.value = null;

      if (kIsWeb && state.engineMode.value != TasmeeEngineMode.tajweedFormer) {
        state.lastError.value =
            'اختر TajweedFormer V4 من إعدادات التسميع للويب.';
        return;
      }

      if (state.engineMode.value == TasmeeEngineMode.tajweedFormer &&
          state.mode.value == TasmeeMode.corrector) {
        state.lastError.value =
            'التصحيح الفوري للكلمات غير متاح مع TajweedFormer بعد؛ اختر نمط التسميع.';
        return;
      }

      // مرجع الصفحة الحالية لا بد أن يكون **مكتملًا** لا جاريًا — البناء
      // يحدّث رقم الصفحة في بدايته والنطاق في نهايته، فمقارنة الأرقام
      // وحدها تجتاز الفحص بقائمة قديمة. مساعد الاستقرار ينتظر أحدث جيل
      // ويبني من جديد حتى يستقر.
      if (!await _ensureCurrentPageRange(tasmeeCycle: tasmeeCycle)) return;

      // أعِد فحص الوضع بعد الانتظارات — قد تغيّر أثناء بناء المرجع.
      if (!state.isTasmeeMode.value ||
          state.mode.value == TasmeeMode.teacher ||
          isRecording ||
          isProcessing) {
        return;
      }

      final ready = await _ensureEngineReady();
      if (!ready) return;
      if (!state.isTasmeeMode.value) return;
      // أعِد التحقق بعد تهيئة المحرك مباشرة: الصفحة والنمط قد تغيّرا
      // أثناءها — لا تُطلق جلسة بمرجع الصفحة المغادرة ولا بمسار نمط
      // لم يعد مختارًا (المعلم، أو مصحّح V4 المحجوب).
      if (!await _ensureCurrentPageRange(tasmeeCycle: tasmeeCycle)) return;
      // الاستقرار انتظارٌ آخر: الخروج أو تغيّر النمط أثناءه يُلغي الطلب
      // أيضًا — بناء النطاق المُلغى عند الخروج لا يعيد تطبيق مرجعه،
      // وهذا الفحص يمنع استمرار المسار بعد الخروج.
      if (!state.isTasmeeMode.value || isRecording || isProcessing) {
        return;
      }
      if (state.mode.value == TasmeeMode.teacher) return;
      if (state.engineMode.value == TasmeeEngineMode.tajweedFormer &&
          state.mode.value == TasmeeMode.corrector) {
        state.lastError.value =
            'التصحيح الفوري للكلمات غير متاح مع TajweedFormer بعد؛ اختر نمط التسميع.';
        return;
      }

      state.completedWords.value = 0;
      await _launchLiveSession(range: _range!, verseIdxOffset: 0);
    } finally {
      state.isPreparingEngine.value = false;
      update([TasmeeUpdateIds.control]);
    }
  }

  /// يبدأ تسجيل تسميع آية واحدة داخل نطاق الصفحة (نمط المعلم) — جلسة
  /// حيّة بمدى الآية وحدها؛ أحداث كلماتها تُسقَط على مواضعها الصفحية
  /// فتتراكم حالات الكلمات عبر الآيات المتقنة.
  Future<void> startAyahRecording(int verseIdx) async {
    if (!state.isTasmeeMode.value ||
        state.mode.value != TasmeeMode.teacher ||
        isRecording ||
        isProcessing ||
        state.isPreparingEngine.value ||
        (kIsWeb && state.engineMode.value != TasmeeEngineMode.tajweedFormer)) {
      return;
    }
    // الحارس قبل أي انتظار — مسار المعلم كذلك: طلبان متقاربان لا يفتحان
    // جلستَي آية معًا فوق انتظار المرجع أو الصوت. والدورة تُلتقط الآن
    // كذلك: الخروج أثناء أي انتظار لاحق يلغي الاستقرار والبناء.
    final tasmeeCycle = _tasmeeCycle;
    state.isPreparingEngine.value = true;
    update([TasmeeUpdateIds.control]);
    try {
      if (verseIdx < 0 || verseIdx >= _rangeAyahs.length) return;
      try {
        await qa.AudioCtrl.instance.state.audioPlayer.stop();
      } catch (_) {}
      if (!state.isTasmeeMode.value || state.mode.value != TasmeeMode.teacher) {
        return;
      }

      // مرجع الصفحة الحالية يجب أن يكون **مكتملًا** — البناء الجاري يحدّث
      // رقم الصفحة في بدايته وقائمة الآيات في نهايته، فاختيار الآية قبل
      // الاستقرار يسجّل آية الصفحة المغادرة على مواضع الجديدة.
      if (!await _ensureCurrentPageRange(tasmeeCycle: tasmeeCycle)) return;
      if (verseIdx < 0 || verseIdx >= _rangeAyahs.length) return;
      final ayah = _rangeAyahs[verseIdx];
      if (ayah.surahNumber == null) return;
      if (!state.isTasmeeMode.value ||
          state.mode.value != TasmeeMode.teacher ||
          isRecording ||
          isProcessing) {
        return;
      }

      state.lastError.value = '';
      state.lastResult.value = null;
      final ready = await _ensureEngineReady();
      if (!ready ||
          !state.isTasmeeMode.value ||
          state.mode.value != TasmeeMode.teacher) {
        return;
      }
      // أعِد التحقق بعد تهيئة المحرك مباشرة: الصفحة قد تغيّرت أثناءها —
      // استقر المرجع من جديد وأعد اختيار الآية من القائمة المكتملة.
      if (!await _ensureCurrentPageRange(tasmeeCycle: tasmeeCycle)) return;
      // الاستقرار انتظارٌ آخر: الخروج أو تغيّر النمط أثناءه يُلغي الطلب —
      // لا تبدأ جلسة معلّم بعد أن صار المستخدم خارج التسميع أو في نمط آخر.
      if (!state.isTasmeeMode.value ||
          state.mode.value != TasmeeMode.teacher ||
          isRecording ||
          isProcessing) {
        return;
      }
      if (verseIdx < 0 || verseIdx >= _rangeAyahs.length) return;
      final ayahNow = _rangeAyahs[verseIdx];
      if (ayahNow.surahNumber == null) return;

      final ayahRange = TasmeeReferenceStore.instance.buildRange([
        (suraIdx: ayahNow.surahNumber!, ayaIdx: ayahNow.ayahNumber),
      ]);
      if (ayahRange == null) {
        state.lastError.value = 'تعذّر تجهيز مرجع الآية للتسميع';
        return;
      }
      await _launchLiveSession(
        range: ayahRange,
        verseIdxOffset: verseIdx,
        teacherEndpoint: true,
      );
      if (isRecording) {
        state.teacherAyahIndex.value = verseIdx;
        state.teacherPhase.value = TasmeeTeacherPhase.userRecording;
      }
      // يحدد معالج الصمت المربوط قبل بدء الجلسة متى ينتهي الالتقاط؛
      // إنجاز الالتقاط لا يعني اكتمال تقييم التجويد أو إتقان الآية.
    } finally {
      state.isPreparingEngine.value = false;
      update([TasmeeUpdateIds.control]);
    }
  }

  /// Move between ayahs by the learner's choice, without a mastery verdict.
  void selectTeacherAyah(int verseIdx) {
    if (state.mode.value != TasmeeMode.teacher ||
        isRecording ||
        isProcessing ||
        state.isPreparingEngine.value ||
        verseIdx < 0 ||
        verseIdx >= _rangeAyahs.length) {
      return;
    }
    state.teacherAyahIndex.value = verseIdx;
    state.teacherPhase.value = TasmeeTeacherPhase.idle;
    state.lastResult.value = null;
    state.lastError.value = '';
    state.sessionState.value = RecitationState.idle;
    update([TasmeeUpdateIds.control]);
  }

  /// يشغّل جلسة حيّة على النطاق المعطى مع إسقاط فهارس الآيات على
  /// مواضعها داخل نطاق الصفحة ([verseIdxOffset] لنطاق الآية الواحدة).
  Future<void> _launchLiveSession({
    required QuranReferenceRange range,
    int verseIdxOffset = 0,
    bool teacherEndpoint = false,
  }) async {
    try {
      final session = Recitation.createSession(
        range: range,
        config: MuaalemConfig(
          tajweedFormerPreset: state.strictness.value.tajweedFormerPreset,
          tajweedFormerTolerance: state.tolerance.value,
        ),
      );
      _attachSession(session,
          verseIdxOffset: verseIdxOffset, teacherEndpoint: teacherEndpoint);
      if (Recitation.isOffline) {
        await session.startLive();
        // الوضع الحيّ: طور الالتقاط حتى أول كلمة جارية (بداية المستخدم
        // الفعلية — قد تكون من منتصف الصفحة).
        state.isAwaitingStart.value = true;
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

  /// يربط جلسةً بالمتحكم: تُصبح الجلسة الحالية وتُوصَّل ردودها بحالات
  /// الكلمات والواجهة. يستبدل عامل الجلسة السابقة (كان قد فُكّ بإنهائها).
  void _attachSession(
    RecitationSession session, {
    required int verseIdxOffset,
    required bool teacherEndpoint,
  }) {
    _session = session;
    _sessionVerseOffset = verseIdxOffset;
    // فكّ عامل الجلسة السابقة إن بقيت — الإنتاج يفكّها في `_cancelSession`
    // قبل أي إطلاق جديد؛ الاستبدال المباشر (الاختبار) يحتاجه هنا.
    _stateWorker?.dispose();
    if (teacherEndpoint) {
      session.onEndpoint = () {
        if (!identical(_session, session) || !isRecording) return;
        final progress = session.liveRangeProgress;
        // V4 progress is matched reference coverage, not a verdict. Require
        // full coverage to end capture; the result remains partial.
        final minimum = Recitation.isTajweedFormer ? 1.0 : 0.8;
        if (progress != null && progress >= minimum) stopRecording();
      };
    }
    _stateWorker = ever<RecitationState>(session.state, (s) {
      // انسخ النتيجة قبل إعلان الحالة كي تجدها مستمعات الواجهة
      // (وإلا فاتها فتح bottomSheet النتائج).
      if (s == RecitationState.finished) {
        state.lastResult.value = _session?.result.value;
      }
      state.sessionState.value = s;
      update([TasmeeUpdateIds.control]);
    });
    session.onWordDone = (v, w, kind, mistake) =>
        _onWordDone(v + verseIdxOffset, w, kind, mistake);
    session.onRangeComplete = () {
      // أكمل النطاق — أوقف بعد مهلة قصيرة تسمح بآخر وحدة. المهلة
      // المؤجلة تخص هذه الجلسة وحدها: إن استُبدلت بجلسة جديدة خلالها
      // فلا يحق لردّ القديمة إيقاف الجديدة.
      Future.delayed(const Duration(milliseconds: 800), () {
        if (tasmeeDeferredStopAppliesToCurrentSession(
          current: _session,
          issuer: session,
          recording: isRecording,
        )) {
          stopRecording();
        }
      });
    };

    // الكلمة الجارية (الوضع الحيّ فقط — offline): نداء واحد ذري
    // بالفهرسين معًا — عاملان منفصلان على RxInt يقرأ أحدهما الآخر
    // بقيمة قديمة عند انتقال الآية فتكشف كلمة متأخرة قبل أختها.
    session.onRangeWord = (v, w) => markCurrentWord(v + verseIdxOffset, w);
    session.onMatchedWords = (words, revised) {
      final next = <String>{};
      for (final word in words) {
        final verse = word.verseIndex + verseIdxOffset;
        if (verse < 0 || verse >= _rangeAyahs.length) continue;
        next.add(_wordKey(verse, word.wordIndex));
      }
      for (final key in _v4MatchedKeys.difference(next)) {
        if (state.wordStatuses[key] == TasmeeWordStatus.heard ||
            state.wordStatuses[key] == TasmeeWordStatus.current) {
          state.wordStatuses.remove(key);
        }
      }
      for (final key in next) {
        if (state.wordStatuses[key] == null ||
            state.wordStatuses[key] == TasmeeWordStatus.hidden) {
          state.wordStatuses[key] = TasmeeWordStatus.heard;
        }
      }
      _v4MatchedKeys
        ..clear()
        ..addAll(next);
      _refreshQuranPages();
    };
  }

  /// يركّب جلسة جاهزة على المتحكم — نقطة حقن لاختبارات دورة الإيقاف
  /// فقط؛ الإنتاج يمرّ عبر [_launchLiveSession] التي تنشئ الجلسة وتشغّلها.
  @visibleForTesting
  void attachSessionForTesting(RecitationSession session,
      {int verseIdxOffset = 0}) {
    _attachSession(session,
        verseIdxOffset: verseIdxOffset, teacherEndpoint: false);
  }

  /// يوقف التسجيل ويُقيّم — النتيجة في [TasmeeState.lastResult].
  ///
  /// التقييم النهائي (المحاذاة الشاملة) هو المرجع **ثنائي الاتجاه**:
  /// يصحّح الكلمات التي لوّنها التتبّع الحي خطأً، ويسقط ما لم يُتلَ فعلًا،
  /// ويحفظ الكلمات المقبولة في شيت المصحّح خضراء.
  ///
  /// إيقاف مذكَّر: طلبان متداخلان (صمت نقطة النهاية + زر الإيقاف +
  /// تغيير الصفحة/النمط) يُنفَّذ أحدهما فقط — التطبيق المزدوج كان يقيّم
  /// مرتين ويقرّر قرار المعلم مرتين فيتقدم آيتين بطلب واحد.
  ///
  /// الطلب المحفوظ يخص جلسته وحدها: جلسة استُبدلت أثناء انتظار تقييم
  /// القديمة لها إيقافها الخاص — إعادة طلب القديم كانت تبتلع إيقاف
  /// الجديدة فتستمر بالتسجيل بلا من يوقفها.
  Future<void> stopRecording() {
    final pending = _stopRecordingFuture;
    if (pending != null && identical(_stopRecordingSession, _session)) {
      return pending;
    }
    if (_session == null) {
      // لا جلسة حالية: انتظر إيقافًا قديمًا جاريًا (يصرّف موارده هو) ولا
      // تُحفظ عملية جديدة فوق غياب الجلسة.
      return pending ?? Future.value();
    }
    final future = _stopRecordingImpl();
    _stopRecordingFuture = future;
    _stopRecordingSession = _session;
    // المحو مضمون في كل المسارات (اكتمال أو خطأ): طلب الإيقاف التالي
    // لجلسة جديدة يسلك مساره كاملًا لا يرث مستقبل طلب سابق.
    future.whenComplete(() {
      if (identical(_stopRecordingFuture, future)) {
        _stopRecordingFuture = null;
        _stopRecordingSession = null;
      }
    });
    return future;
  }

  Future<void>? _stopRecordingFuture;
  RecitationSession? _stopRecordingSession;

  Future<void> _stopRecordingImpl() async {
    final session = _session;
    if (session == null) return;
    try {
      if (state.mode.value == TasmeeMode.teacher) {
        state.teacherPhase.value = TasmeeTeacherPhase.evaluating;
      }
      _disposeRetrySession();
      await _retryRelease;
      if (session.isLive.value) {
        await session.stopLive();
      } else if (session.state.value == RecitationState.recording) {
        await session.stop();
      }
      // استُبدلت الجلسة أثناء انتظار التقييم (خروج من الوضع ودخول وبدء
      // تسجيل جديد) — نتيجة القديمة لا تُطبَّق على الوضع الجديد.
      if (!identical(_session, session)) return;
      final result = session.result.value;
      if (result == null || !result.hasMatch) {
        state.lastResult.value = result;
        state.lastError.value =
            result?.noMatchMessage ?? session.lastError.value;
        // لا تقييم شاملًا — أبقِ ما أكمله التتبّع الحي فقط.
        _trimToCompletedWords();
      } else {
        state.lastResult.value = _resultWithoutAcceptedErrors(result);
        _applyFinalVerdictsToStatuses(result);
      }
    } catch (e) {
      // خطأ إيقاف جلسة استُبدلت لا يُعرض فوق تسجيل جارٍ في الوضع الحالي.
      if (identical(_session, session)) {
        state.lastError.value = 'خطأ في التقييم: $e';
        _trimToCompletedWords();
      }
    } finally {
      // تنظيف ما بعد الإيقاف يخص الجلسة التي أوقفتها وحدها: اكتمال إيقاف
      // جلسة منتهية لا يلغي جلسةً استُبدلت بها ولا يقرّر قرار معلّمها.
      if (identical(_session, session)) {
        if (state.mode.value == TasmeeMode.teacher) {
          _applyTeacherDecision();
        }
        _cancelSession();
        _refreshQuranPages();
        update([TasmeeUpdateIds.control]);
      }
    }
  }

  /// يطبّق قرار نهاية دورة المعلم: انتهاء الالتقاط والتقييم ليس إتقانًا؛
  /// بلا خطاف حكم مثبت يبقى الطور `awaitingDecision` والقرار يدويًا.
  void _applyTeacherDecision() {
    final result = state.lastResult.value;
    final decision = tasmeeTeacherDecisionAfterEvaluation(
      result: result,
      ayahIndex: state.teacherAyahIndex.value,
      ayahTotal: rangeAyahCount,
      verdictAccepted: result != null &&
          result.hasMatch &&
          result.assessmentComplete &&
          (teacherAdvancePolicy?.call(result) ?? false),
    );
    state.teacherAyahIndex.value = decision.nextAyahIndex;
    state.teacherPhase.value = decision.phase;
  }

  /// يقصِر الحالات الظاهرة على الكلمات المكتملة فقط — الكلمة "الجارية"
  /// الأخيرة غير المؤكَّدة تُخفى، فلا يظهر بعد الإيقاف إلا ما تُلِي فعلًا.
  void _trimToCompletedWords() {
    final done = _doneWordKeys.toSet();
    final ayahPrefix = state.mode.value == TasmeeMode.teacher &&
            _sessionVerseOffset < _rangeAyahs.length
        ? '${_rangeAyahs[_sessionVerseOffset].ayahUQNumber}:'
        : null;
    state.wordStatuses.removeWhere((key, _) =>
        (ayahPrefix == null || key.startsWith(ayahPrefix)) &&
        !done.contains(key));
    state.currentWordKey.value = null;
  }

  /// إعادة التسميع من البداية (الكلمات تُخفى من جديد) — تُنهي أي جلسة
  /// نشطة أو متوقفة لتصحيح كلمة وتصفّر حالة التصحيح أولًا.
  Future<void> retryTasmee() async {
    if (isRecording ||
        isProcessing ||
        state.sessionState.value == RecitationState.paused) {
      await stopRecording();
    }
    _disposeRetrySession();
    state.activeWordCorrection.value = null;
    state.wordRetryOutcome.value = null;
    state.wordRetryFeedback.value = null;
    state.lastResult.value = null;
    state.lastError.value = '';
    state.wordErrorKinds.clear();
    _doneWordKeys.clear();
    _acceptedCorrections.clear();
    await _buildRangeForCurrentPage();
    _refreshQuranPages();
    update([TasmeeUpdateIds.control]);
  }

  void _cancelSession() {
    _stateWorker?.dispose();
    _stateWorker = null;
    state.isAwaitingStart.value = false;
    try {
      _session?.dispose();
    } catch (_) {}
    _session = null;
    _v4MatchedKeys.clear();
    _sessionVerseOffset = 0;
    if (state.sessionState.value == RecitationState.recording ||
        state.sessionState.value == RecitationState.processing) {
      state.sessionState.value = RecitationState.idle;
    }
  }

  // ── جاهزية المحرك ──────────────────────────────────────────────

  Future<bool> _ensureEngineReady() async {
    try {
      await _retryRelease;
      if (state.engineMode.value == TasmeeEngineMode.tajweedFormer) {
        // مثل نموذج Zipformer: يُنزَّل نموذج V4 وقت التشغيل عند أول جلسة
        // إن لم يكن المستخدم نزّله مسبقًا من الإعدادات.
        if (!state.isV4ModelReady.value &&
            await _v4PrefetchService.isAvailable()) {
          final ok = await downloadV4Model();
          if (!ok) return false;
        }
        if (!Recitation.isTajweedFormer) {
          await Recitation.initTajweedFormer(
              key: resolveQuranLabKeyForPlatform());
        }
        return true;
      }
      if (state.engineMode.value == TasmeeEngineMode.offline) {
        if (kIsWeb) {
          state.lastError.value =
              'اختر TajweedFormer V4 من إعدادات التسميع للويب.';
          return false;
        }
        if (!state.isModelReady.value) {
          final ok = await downloadModelIfNeeded();
          if (!ok) return false;
        }
        if (!(Recitation.isInitialized &&
            Recitation.isOffline &&
            !Recitation.isTajweedFormer)) {
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
    } catch (e, st) {
      // علامة مميزة + التتبع الكامل في طرفية flutter run لنسخها عند التشخيص.
      debugPrint('╔═══════ TASMEE ENGINE INIT ERROR ═══════');
      debugPrint('║ engine: ${state.engineMode.value.name}');
      debugPrint('║ error: $e');
      debugPrint('║ stack: $st');
      debugPrint('╚════════════════════════════════════════');
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

  /// ينزّل نموذج V4 مسبقًا عبر SDK Quran Lab (وقت التشغيل — مثل نهتدي).
  Future<bool> downloadV4Model() async {
    if (state.isDownloadingV4Model.value) return false;
    state.isDownloadingV4Model.value = true;
    state.v4ModelDownloadProgress.value = 0;
    update([TasmeeUpdateIds.control]);
    try {
      final ok = await _v4PrefetchService.prefetch(
        unmeteredOnly: state.v4WifiOnly.value,
        onProgress: (p) {
          state.v4ModelDownloadProgress.value = p;
          update([TasmeeUpdateIds.control]);
        },
      );
      if (!ok) {
        state.lastError.value = 'جسر TajweedFormer غير متوفر على هذا الجهاز.';
        return false;
      }
      state.isV4ModelReady.value = true;
      state.v4ModelDownloadProgress.value = 1;
      return true;
    } catch (e) {
      state.lastError.value = _v4DownloadErrorMessage(e);
      return false;
    } finally {
      state.isDownloadingV4Model.value = false;
      update([TasmeeUpdateIds.control]);
    }
  }

  String _v4DownloadErrorMessage(Object e) {
    final text = e.toString();
    if (text.contains('key is not configured') ||
        text.contains('missing_key') ||
        text.contains('QuranLabKey') ||
        text.contains('A key is required')) {
      return 'مفتاح Quran Lab غير مضبوط للتطبيق (QURANLAB_KEY).';
    }
    return 'فشل تنزيل نموذج TajweedFormer: $e';
  }

  /// يحذف ملفات نموذج V4 من مخزن SDK — تُعاد عند أول استخدام قادم.
  Future<void> removeV4Model() async {
    try {
      await _v4PrefetchService.removeModels();
    } catch (e) {
      state.lastError.value = 'فشل حذف نموذج TajweedFormer: $e';
      update([TasmeeUpdateIds.control]);
      return;
    }
    state.isV4ModelReady.value = false;
    state.v4ModelDownloadProgress.value = 0;
    update([TasmeeUpdateIds.control]);
  }

  /// يضبط تنزيل نموذج V4 عبر Wi-Fi فقط (مثل نهتدي) ويحفظ الاختيار.
  void setV4WifiOnly(bool value) {
    state.v4WifiOnly.value = value;
    update([TasmeeUpdateIds.control]);
  }

  /// يبدّل إظهار كل كلمات الصفحة مؤقتًا (زر العين).
  void toggleShowAllWords() {
    // التسميع وحده يسمح بإخفاء/إظهار الكلمات — في المصحح والمعلم
    // الآيات ظاهرة دائمًا.
    if (state.mode.value != TasmeeMode.tasmee) return;
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

  void _onWordDone(
    int verseIdx,
    int wordIdx,
    TasmeeErrorKind kind,
    TasmeeWordMistake? mistake,
  ) {
    if (verseIdx < 0 || verseIdx >= _rangeAyahs.length) return;
    final key = _wordKey(verseIdx, wordIdx);
    // بلا تكرارات — يُستخدم لاحقًا كمجموعة تقليم بعد الإيقاف.
    if (_doneWordKeys.isEmpty || _doneWordKeys.last != key) {
      _doneWordKeys.add(key);
    }
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
    // نمط المصحح: الكلمة الخاطئة توقف الجلسة بانتظار تصحيحها — لكن لا
    // لأول حذف/استبدال معزول: سياسة الدليلين (حرفان خاطئان، أو الكلمة
    // نفسها في موضعين) تحمي من وسم كاذب من التتبّع الحي يفتح شيتًا على
    // كلمة سليمة ويوهم المستخدم بالعلق.
    if (state.mode.value == TasmeeMode.corrector) {
      log(
          'TasmeeCtrl corrector word-done — v=$verseIdx w=$wordIdx '
          'kind=$kind wrongUnits=${mistake?.wrongUnits ?? 1} '
          'active=${state.activeWordCorrection.value != null} '
          'pending=$_correctionPending',
          name: 'TasmeeCtrl');
      if (kind != TasmeeErrorKind.correct) {
        final wrongUnits = mistake?.wrongUnits ?? 1;
        // الصرامة الصارمة: أول دليل يكفي لفتح الشيت (سلوك ما قبل الفحص).
        final requireTwoEvidences =
            state.strictness.value != TasmeeStrictness.strict;
        final twoEvidences = !requireTwoEvidences ||
            wrongUnits >= 2 ||
            _wordFirstEvidence.contains(key);
        if (!twoEvidences) {
          // دليل وحيد معزول: علِّم حمراء (فوق) وتابع التلاوة بلا شيت؛
          // التقييم النهائي عند الإيقاف هو المرجع في تأكيدها أو رفعها.
          _wordFirstEvidence.add(key);
          return;
        }
        if (state.nonBlockingCorrector.value) {
          // وضع غير حاجز (خيار): الشارة الحمراء تكفي والجلسة تتابع —
          // تقدّم المتتبّع بعدها يتركها كما هي بلا شيت أصلًا.
          return;
        }
        // بلا انتظار — onWordDone متزامن التوقيع؛ الحارس داخل
        // _beginWordCorrection (علم متزامن) يمنع الفتح المزدوج أثناء
        // انتظار إيقاف الميكروفون.
        _beginWordCorrection(verseIdx, wordIdx, kind, mistake);
      } else {
        _wordFirstEvidence.remove(key);
      }
    }
  }

  // ── تصحيح الكلمة (نمط المصحح) ──────────────────────────────────

  /// يضبط الكلمة الخاطئة المنتظرة تصحيحًا ويجمّد الجلسة الرئيسية —
  /// الميكروفون يتوقف فلا يسمع نطق الكلمة من السماعة أثناء الشيت.
  ///
  /// الإيقاف يجب أن يكتمل **قبل** ضبط الحالة (الذي يفتح الشيت ويشغّل
  /// النطق): مسجّل `record` يفكّ جلسة الصوت عند الإيقاف، وتشغيل الصوت
  /// بالتوازي معها يُقتل أو يتحوّل لسماعة الأذن فيبدو صامتًا.
  Future<void> _beginWordCorrection(
    int verseIdx,
    int wordIdx,
    TasmeeErrorKind kind,
    TasmeeWordMistake? mistake,
  ) async {
    if (verseIdx < 0 || verseIdx >= _rangeAyahs.length) return;
    // حارس سباق: أحداث كلمات متتالية أثناء انتظار pauseLive لا تفتح
    // تصحيحًا ثانيًا — العلم يُضبط متزامنًا قبل أي await.
    if (_correctionPending || state.activeWordCorrection.value != null) {
      return;
    }
    _correctionPending = true;
    try {
      final ayah = _rangeAyahs[verseIdx];
      final verse = _range != null && verseIdx < _range!.verses.length
          ? _range!.verses[verseIdx]
          : null;
      final wordText = verse != null && wordIdx < verse.uthmaniWords.length
          ? verse.uthmaniWords[wordIdx]
          : '';
      // الكلمة السابقة سياقًا لإعادة النطق (تُقرأ معها وصلًا) — إعادة
      // النطق المنفردة تقف على الكلمة فيخفق التنوين والإدغام وهمزة الوصل.
      final contextWordText =
          verse != null && wordIdx > 0 ? verse.uthmaniWords[wordIdx - 1] : '';
      // سجل تشغيلي فقط — بلا نص الكلمة ولا رموز النطق المتوقع/المنطوق.
      log(
        'TasmeeCtrl corrector begin — ($verseIdx:$wordIdx) '
        'kind=${kind.name} mistake=${mistake?.errorType}',
        name: 'TasmeeCtrl',
      );
      await _session?.pauseLive();
      // غيّر المستخدم النمط/أعاد أثناء انتظار الإيقاف — لا تفتح شيتًا
      // لجلسة لم تعد قائمة.
      if (state.mode.value != TasmeeMode.corrector ||
          _session?.state.value != RecitationState.paused) {
        return;
      }
      if (Recitation.isTajweedFormer) _v4MatchedKeys.clear();
      log('TasmeeCtrl corrector paused, opening sheet', name: 'TasmeeCtrl');
      state.wordRetryOutcome.value = null;
      state.wordRetryFeedback.value = null;
      state.wordRetryAttempts.value = 0;
      state.activeWordCorrection.value = TasmeeWordCorrection(
        key: _wordKey(verseIdx, wordIdx),
        wordText: wordText,
        contextWordText: contextWordText,
        errorKind: kind,
        suraIdx: ayah.surahNumber ?? 1,
        ayaIdx: ayah.ayahNumber,
        wordNumber: wordIdx + 1,
        verseIdx: verseIdx,
        wordIdx: wordIdx,
        errorType: mistake?.errorType ?? 'replace',
        expectedSymbol: mistake?.expectedSymbol,
        predictedSymbol: mistake?.predictedSymbol,
      );
    } finally {
      _correctionPending = false;
    }
  }

  /// يبدأ محاولة إعادة نطق الكلمة المنتظرة — تسجيل دفعي قصير بمدى الكلمة
  /// وحدها يتوقف تلقائيًا بعد النطق والسكون، ثم يُقيَّم بالمسار المرجعي
  /// الكامل (محاذاة + كشف أخطاء) — لا بالتتبّع الحيّ الاسترشادي، ولا
  /// يمسّ بثّ الجلسة الرئيسية المتوقفة (المسار الدفعي يستخدم Stream خاصًا
  /// به داخل المحرك). الحكم في [TasmeeState.wordRetryOutcome].
  Future<void> startWordRetry() async {
    await _retryRelease;
    final correction = state.activeWordCorrection.value;
    if (correction == null || _retrySession != null) return;
    final verse = _range != null && correction.verseIdx < _range!.verses.length
        ? _range!.verses[correction.verseIdx]
        : null;
    final wordRange = verse == null
        ? null
        : QuranReferenceRange.fromWordWithContext(verse, correction.wordIdx);
    final targetUnitCount = wordRange?.wordUnitCount(correction.wordIdx) ?? 0;
    if (wordRange == null) {
      state.wordRetryOutcome.value = TasmeeWordRetryOutcome.incorrect;
      return;
    }
    final session = Recitation.createSession(
      range: wordRange,
      config: MuaalemConfig(
        tajweedFormerPreset: state.strictness.value.tajweedFormerPreset,
        tajweedFormerTolerance: state.tolerance.value,
      ),
    );
    _retrySession = session;
    // سياسة القبول: V4 غير حاسمة دائمًا (نتيجة جزئية ليست حكمًا)؛ Zipformer
    // يقبل نسبيًا على وحدات الكلمة المستهدفة. التوصيل لا يُحدث حكمًا.
    final acceptance = Recitation.isTajweedFormer
        ? const InconclusiveWordRetryPolicy()
        : const ContextWordRatioAcceptancePolicy();
    state.wordRetryOutcome.value = null;
    state.wordRetryFeedback.value = null;
    state.isWordRetryListening.value = true;
    _retryStateWorker = ever<RecitationState>(session.state, (s) {
      if (s == RecitationState.finished) {
        final result = session.result.value;
        final outcome = acceptance.decide(WordRetryAttempt(
          result: result,
          targetWordIdx: correction.wordIdx,
          targetUnitCount: targetUnitCount,
          minAccuracy: wordRetryMinAccuracy,
        ));
        state.wordRetryOutcome.value = outcome;
        if (outcome != TasmeeWordRetryOutcome.correct) {
          state.wordRetryAttempts.value++;
        }
        if (outcome == TasmeeWordRetryOutcome.inconclusive) {
          state.wordRetryFeedback.value = null;
          _disposeRetrySession();
          return;
        }
        // خطأ هذه المحاولة بالذات (قد يختلف عن خطأ التلاوة الأول:
        // أصلح المستخدم النطق فصار الخطأ تشكيلًا أو تجويدًا) — يُعرض
        // في الشيت ليعرف ما يصحّحه الآن.
        state.wordRetryFeedback.value =
            outcome == TasmeeWordRetryOutcome.correct
                ? null
                : retryFeedbackFromErrors(
                    (result?.errors ?? const [])
                        .where((e) => e.wordIdx == correction.wordIdx)
                        .toList(),
                  );
        _disposeRetrySession();
      } else if (s == RecitationState.error) {
        state.lastError.value = session.lastError.value;
        state.wordRetryOutcome.value = Recitation.isTajweedFormer
            ? TasmeeWordRetryOutcome.inconclusive
            : TasmeeWordRetryOutcome.incorrect;
        state.wordRetryFeedback.value = null;
        _disposeRetrySession();
      }
    });
    if (Recitation.isTajweedFormer) {
      final startedAt = DateTime.now();
      session.onEndpoint = () {
        if (identical(_retrySession, session) &&
            session.state.value == RecitationState.recording &&
            DateTime.now().difference(startedAt) >=
                const Duration(milliseconds: 400)) {
          unawaited(session.stopLive());
        }
      };
      await session.startLive();
      if (identical(_retrySession, session) &&
          session.state.value == RecitationState.recording) {
        _retryTimer = Timer(const Duration(seconds: 8), () {
          if (identical(_retrySession, session) &&
              session.state.value == RecitationState.recording) {
            unawaited(session.stopLive());
          }
        });
      }
      return;
    }
    await session.start(
      stopAfterSilence: const Duration(milliseconds: 1200),
      maxDuration: const Duration(seconds: 8),
      // تصاهر بادئ: صدى نطق الكلمة من السماعة (الشيت يشغّله) لا يُحسب
      // كلامًا فيُقطع التسجيل قبل أن ينطق المستخدم.
      ignoreInitial: const Duration(milliseconds: 400),
    );
  }

  void _disposeRetrySession() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryStateWorker?.dispose();
    _retryStateWorker = null;
    final session = _retrySession;
    _retrySession = null;
    state.isWordRetryListening.value = false;
    if (session == null) return;
    // تحرير منتظَر لمحاولة الكلمة (إيقاف مسجّلها وتفكيكه، وإلغاء محاولة
    // V4 بلا تقييم) — يُنتظر عبر _retryRelease في كل المسارات قبل أي
    // استئناف للميكروفون الرئيسي، فلا يتنازع المسجّلان على قناة الصوت.
    _retryRelease = _retryRelease.then((_) => session.release());
  }

  /// يحلّ الكلمة المنتظرة: قبول نطقها الصحيح (تُعلَّم خضراء ويُحمى من
  /// التقييم النهائي عند الإيقاف) أو تخطّيها (تبقى حمراء) — ثم يستأنف
  /// الجلسة الرئيسية المتوقفة.
  Future<void> resolveWordCorrection({required bool accepted}) async {
    final correction = state.activeWordCorrection.value;
    if (correction == null) return;
    _disposeRetrySession();
    await _retryRelease;
    if (!identical(state.activeWordCorrection.value, correction)) return;
    if (accepted && !Recitation.isTajweedFormer) {
      state.wordStatuses[correction.key] = TasmeeWordStatus.correct;
      state.wordErrorKinds.remove(correction.key);
      // الصوت الأصلي ما يزال يحوي النطق الخاطئ الأول — احمِ القبول من
      // التقييم النهائي لاحقًا (البق: نجاح التصحيح كان يُلغى عند الإيقاف).
      _acceptedCorrections.add(correction.key);
      _refreshQuranPages();
    }
    state.wordRetryOutcome.value = null;
    state.wordRetryFeedback.value = null;
    state.wordRetryAttempts.value = 0;
    state.activeWordCorrection.value = null;
    // أوقف نطق الكلمة (إن كان مشغّلًا من الشيت — تخطٍّ أو إغلاق خارجي
    // أثناء التشغيل التلقائي) وانتظر توقفه قبل فتح ميكروفون الجلسة
    // الرئيسية — الاستئناف فوق صوت السماعة يلتقطه الميكروفون كلامًا.
    try {
      await q.QuranLibrary().stopWordAudio();
    } catch (_) {}
    final session = _session;
    if (session != null &&
        session.isLive.value &&
        session.state.value == RecitationState.paused) {
      await session.resumeLive();
    }
  }

  /// الكلمة الجارية (من محاذاة الوضع الحيّ) — تُبرز لحظيًا.
  void markCurrentWord(int verseIdx, int wordIdx) {
    if (verseIdx < 0 || verseIdx >= _rangeAyahs.length) return;
    // أول كلمة جارية = انتهى طور الالتقاط (حددت بداية التلاوة الفعلية).
    if (state.isAwaitingStart.value) {
      state.isAwaitingStart.value = false;
    }
    final key = _wordKey(verseIdx, wordIdx);
    if (Recitation.isTajweedFormer) {
      final previous = state.currentWordKey.value;
      if (previous != null &&
          previous != key &&
          state.wordStatuses[previous] == TasmeeWordStatus.current) {
        state.wordStatuses[previous] = TasmeeWordStatus.heard;
      }
    }
    // الكلمة الجارية تُبرَز فور ظهورها (الحالات النهائية تُدار من
    // onWordDone ولا تُداس هنا).
    if (state.wordStatuses[key] == null ||
        state.wordStatuses[key] == TasmeeWordStatus.hidden ||
        (Recitation.isTajweedFormer &&
            state.wordStatuses[key] == TasmeeWordStatus.heard)) {
      state.wordStatuses[key] = TasmeeWordStatus.current;
    }
    state.currentWordKey.value = key;
    _refreshQuranPages();
  }

  /// يرقّع حالات الكلمات من التقييم النهائي (المرجع المعتمد ثنائي
  /// الاتجاه): الكلمة المغطاة بلا أخطاء → صحيحة (حتى لو أخطأ التتبّع الحي
  /// في وسمها)، وعليها خطأ → خطأة بنوع أعلى أسبقية، وبلا تغطية ولا خطأ →
  /// تُسقط (لم تُتلَ أصلًا)، والمقبولة في المصحّح تبقى خضراء.
  void _applyFinalVerdictsToStatuses(RecitationResult result) {
    // جلسات نطاق فرعي (المعلم): أطِر التغطية على مواضعها الصفحية.
    final offset = _sessionVerseOffset;
    final covered = offset == 0
        ? result.matchedWordSpans
        : [
            for (final s in result.matchedWordSpans)
              (verseIdx: s.verseIdx + offset, wordIdx: s.wordIdx),
          ];
    final verdicts = reconcileFinalWordVerdicts(
      coveredSpans: covered,
      errors: result.errors,
      verseIndexOf: _verseIndexOf,
      keyOf: _wordKey,
      acceptedCorrectionKeys: _acceptedCorrections,
    );
    // أسقط ما لم يُتلَ فعلًا (بلا تغطية ولا خطأ) — مع حفظ المقبول تصحيحها.
    final ayahPrefix =
        state.mode.value == TasmeeMode.teacher && offset < _rangeAyahs.length
            ? '${_rangeAyahs[offset].ayahUQNumber}:'
            : null;
    bool shouldRemove(String key) =>
        (ayahPrefix == null || key.startsWith(ayahPrefix)) &&
        !verdicts.containsKey(key) &&
        !_acceptedCorrections.contains(key);
    state.wordStatuses.removeWhere((key, _) => shouldRemove(key));
    state.wordErrorKinds.removeWhere((key, _) => shouldRemove(key));
    for (final entry in verdicts.entries) {
      final v = entry.value;
      state.wordStatuses[entry.key] = finalTasmeeWordStatus(
        assessmentComplete: result.assessmentComplete,
        correct: v.correct,
        showUnverifiedErrors: showTasmeeDiagnostics(state.engineMode.value),
      );
      if (state.wordStatuses[entry.key] != TasmeeWordStatus.incorrect ||
          v.errorKind == null) {
        state.wordErrorKinds.remove(entry.key);
      } else {
        state.wordErrorKinds[entry.key] = v.errorKind!;
      }
    }
    // الكلمات المقبولة في المصحّح: خضراء دائمًا حتى لو ظهر لها خطأ في
    // الصوت الأصلي المسجَّل قبل التصحيح.
    for (final key in _acceptedCorrections) {
      if (state.wordStatuses.containsKey(key)) {
        state.wordStatuses[key] = TasmeeWordStatus.correct;
        state.wordErrorKinds.remove(key);
      }
    }
    state.currentWordKey.value = null;
    state.completedWords.value =
        result.assessmentComplete ? state.wordStatuses.length : 0;
    _refreshQuranPages();
  }

  /// نسخة عرض من النتيجة بلا أخطاء الكلمات التي قُبل تصحيحها في المصحّح.
  RecitationResult _resultWithoutAcceptedErrors(RecitationResult result) {
    final filtered = withoutAcceptedErrors(
      errors: result.errors,
      verseIndexOf: _verseIndexOf,
      keyOf: _wordKey,
      acceptedCorrectionKeys: _acceptedCorrections,
    );
    if (identical(filtered, result.errors)) return result;
    return RecitationResult(
      start: result.start,
      end: result.end,
      predictedPhonemes: result.predictedPhonemes,
      referencePhonemes: result.referencePhonemes,
      uthmaniText: result.uthmaniText,
      errors: filtered,
      noMatchMessage: result.noMatchMessage,
      matchedWordSpans: result.matchedWordSpans,
      unitAccuracy: result.unitAccuracy,
      assessmentComplete: result.assessmentComplete,
      coverage: result.coverage,
    );
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
    // حرّر جلسة إعادة نطق الكلمة إن كانت جارية (مؤقّتها وعاملها) قبل
    // إلغاء الجلسة الرئيسية — الإغلاق أثناء محاولة كلمة كان يترك مسجّلها.
    _disposeRetrySession();
    _cancelSession();
    _pageWorker?.dispose();
    _pageWorker = null;
    super.onClose();
  }
}
