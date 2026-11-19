/// حالة وضع التسميع (متغيرات GetX التفاعلية).
library;

import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../engine/models/recitation_result.dart';
import '../engine/models/muaalem_config.dart';
import '../engine/models/tasmee_tolerance.dart';
import '../engine/tasmee_error_kind.dart';
import '../engine/recitation_state.dart';
import 'tasmee_mode.dart';

/// وضع محرّك التسميع.
enum TasmeeEngineMode {
  /// نموذج Zipformer محلي — عرض حيّ ويعمل دون إنترنت.
  offline,

  /// Quran Lab TajweedFormer V4, enabled explicitly by the host/user.
  tajweedFormer,

  /// خادم quran-muaalem — تصحيح دفعي بعد الإيقاف (بلا عرض حيّ).
  online,
}

/// Unverified V4 evidence is visible only in explicitly enabled debug builds.
bool showTasmeeDiagnostics(TasmeeEngineMode engine) =>
    kDebugMode &&
    const bool.fromEnvironment('TAJWEEDFORMER_SHOW_DIAGNOSTICS') &&
    engine == TasmeeEngineMode.tajweedFormer;

/// صرامة معايير التسميع — عتبة القبول النسبي وإلزام دليلَي الخطأ.
enum TasmeeStrictness {
  /// عتبة قبول 0.85 وأول دليل يفتح شيت التصحيح.
  strict,

  /// الافتراضي: عتبة 0.75 (مدى فحص التسميع) وسياسة الدليلين.
  balanced,

  /// عتبة 0.70 — كلمات أطول نفَسًا في القبول النسبي.
  lenient;

  String get storageName => name;

  /// A stricter learner setting requests more sensitive V4 evidence; V4's
  /// own `strict` preset is the most conservative about raising flags.
  TajweedFormerFeedbackPreset get tajweedFormerPreset => switch (this) {
        TasmeeStrictness.strict => TajweedFormerFeedbackPreset.sensitive,
        TasmeeStrictness.balanced => TajweedFormerFeedbackPreset.balanced,
        TasmeeStrictness.lenient => TajweedFormerFeedbackPreset.strict,
      };

  static TasmeeStrictness fromName(String? n) => switch (n) {
        'strict' => TasmeeStrictness.strict,
        'lenient' => TasmeeStrictness.lenient,
        _ => TasmeeStrictness.balanced,
      };
}

/// حالة الكلمة أثناء التسميع.
enum TasmeeWordStatus {
  /// مخفية — لم يُتَل عليها بعد.
  hidden,

  /// الكلمة الجارية التي يُتلوها الآن (مُبرزة).
  current,

  /// Matched in the live stream; the final evaluation has not judged it yet.
  heard,

  /// اكتمل نطقها صحيحة (أخضر).
  correct,

  /// اكتمل نطقها وفيها خطأ (أحمر) — التقييم النهائي هو المرجع.
  incorrect,
}

/// Partial assessments reveal matched words without asserting correctness.
TasmeeWordStatus finalTasmeeWordStatus({
  required bool assessmentComplete,
  required bool correct,
  bool showUnverifiedErrors = false,
}) =>
    !assessmentComplete
        ? (!correct && showUnverifiedErrors
            ? TasmeeWordStatus.incorrect
            : TasmeeWordStatus.heard)
        : correct
            ? TasmeeWordStatus.correct
            : TasmeeWordStatus.incorrect;

/// كلمة تنتظر تصحيحًا في نمط المصحح — تُضبط عند أول كلمة خاطئة (مع
/// تجميد الجلسة الرئيسية) وتُصفَّر عند حلّها (قبول/تخطٍّ).
class TasmeeWordCorrection {
  const TasmeeWordCorrection({
    required this.key,
    required this.wordText,
    required this.errorKind,
    required this.suraIdx,
    required this.ayaIdx,
    required this.wordNumber,
    required this.verseIdx,
    required this.wordIdx,
    this.contextWordText = '',
    this.errorType = 'replace',
    this.expectedSymbol,
    this.predictedSymbol,
  });

  /// مفتاح الكلمة في خرائط الحالات `'$ayahUq:$wordNumber'`.
  final String key;

  /// نص الكلمة العثماني.
  final String wordText;

  /// الكلمة السابقة (سياق إعادة النطق: تُقرأ مع المستهدفة وصلًا) — أو
  /// '' إن لم توجد. إعادة النطق المنفردة تخفق على مرجع متصل (تنوين
  /// ساقط/همزة وصل/بلا إدغام) مهما أُعيدت.
  final String contextWordText;

  /// نوع الخطأ المكتشف حيًّا.
  final TasmeeErrorKind errorKind;

  /// موضع الكلمة في المصحف (سورة/آية 1-based وكلمة 1-based) — لتشغيل
  /// نطقها عبر WordInfoCtrl.
  final int suraIdx;
  final int ayaIdx;
  final int wordNumber;

  /// موضعها داخل نطاق الجلسة (0-based) — لِبناء جلسة إعادة النطق.
  final int verseIdx;
  final int wordIdx;

  /// نوع خطأ النطق: 'insert' (زيادة) أو 'delete' (نقص) أو 'replace'
  /// (استبدال) — من تفصيل المتتبّع الحي.
  final String errorType;

  /// رمز الوحدة المرجعية المتوقعة (null عند الزيادة) — لعرض «المتوقع».
  final String? expectedSymbol;

  /// رمز الوحدة المنطوقة فعلًا (null عند النقص) — لعرض «المنطوق».
  final String? predictedSymbol;
}

/// نتيجة محاولة إعادة نطق كلمة في نمط المصحح.
enum TasmeeWordRetryOutcome {
  correct,
  incorrect,

  /// The recording was evaluated only partially; no pass/fail is available.
  inconclusive,
}

/// أطوار جلسة معلم القرآن (آية بآية داخل صفحة النطاق).
enum TasmeeTeacherPhase {
  /// لا جلسة معلم جارية.
  idle,

  /// القارئ يتلو الآية الحالية.
  qariPlaying,

  /// المستخدم يتلو الآية (التسجيل جارٍ).
  userRecording,

  /// جارٍ تقييم محاولة المستخدم.
  evaluating,

  /// انتهى الالتقاط والتقييم بلا حكم إتقان — القرار (إعادة الآية أو
  /// الانتقال) بيد المتعلم. تغطية الكلمات أو غياب المرشحات ليست إتقانًا.
  awaitingDecision,

  /// أُتقنت كل آيات الصفحة واكتمل التسميع — بقرار مصدر حكم مثبت فقط
  /// (خطاف التقدّم الآلي)، لا بمجرد تغطية الكلمات.
  pageDone,
}

/// قرار طور المعلم بعد اكتمال تقييم محاولة آية — منطق نقي بلا GetX.
///
/// [verdictAccepted] قرار مصدر حكم مثبت (خطاف التقدّم الآلي) بأن الآية
/// أُتقنت؛ يُطلب فقط بعد [RecitationResult.assessmentComplete] وتطابق.
/// بلا مصدر حكم يبقى false والطور [TasmeeTeacherPhase.awaitingDecision]:
/// قرار المتابعة يدوي صريح، والنتيجة الجزئية لا تُتقن شيئًا.
({TasmeeTeacherPhase phase, int nextAyahIndex})
    tasmeeTeacherDecisionAfterEvaluation({
  required RecitationResult? result,
  required int ayahIndex,
  required int ayahTotal,
  bool verdictAccepted = false,
}) {
  final accepted = result != null &&
      result.hasMatch &&
      result.assessmentComplete &&
      verdictAccepted;
  if (!accepted) {
    return (
      phase: TasmeeTeacherPhase.awaitingDecision,
      nextAyahIndex: ayahIndex,
    );
  }
  if (ayahIndex + 1 >= ayahTotal) {
    return (phase: TasmeeTeacherPhase.pageDone, nextAyahIndex: ayahIndex);
  }
  return (phase: TasmeeTeacherPhase.idle, nextAyahIndex: ayahIndex + 1);
}

class TasmeeState {
  /// هل وضع التسميع مفعّل الآن؟
  final RxBool isTasmeeMode = false.obs;

  /// نمط التسميع الحالي — يحدّد سلوك الجلسة وإظهار الكلمات الافتراضي.
  final Rx<TasmeeMode> mode = TasmeeMode.tasmee.obs;

  /// صرامة المعايير (عتبة القبول النسبي + سياسة الأدلة) — يُثبَّت عبر
  /// GetStorage (خيار في إعدادات التسميع بالتطبيق المضيف).
  final Rx<TasmeeStrictness> strictness = TasmeeStrictness.balanced.obs;

  /// Per-category V4 diagnostic sensitivity, persisted independently.
  final Rx<TasmeeToleranceProfile> tolerance =
      const TasmeeToleranceProfile().obs;

  /// وضع المصحّح غير الحاجز: الكلمة الخاطئة تُعلَّم حمراء بشارة صغيرة
  /// دون إيقاف الجلسة وفتح شيت مانع — وإن واصل المستخدم القراءة وتقدّم
  /// المتتبّع مرّت كما هي. يُثبَّت عبر GetStorage (خيار في إعدادات
  /// التسميع بالتطبيق المضيف).
  final RxBool nonBlockingCorrector = false.obs;

  /// إظهار كل كلمات الصفحة مؤقتًا (زر العين) أثناء وضع التسميع.
  final RxBool showAllWords = false.obs;

  /// هل متغير الخط الشفاف جاهز لصفحة النطاق؟ (إخفاء مثالي؛ وإلا حذف
  /// المقاطع احتياطًا).
  final RxBool transparentFontsReady = false.obs;

  /// حالة الجلسة الحالية (خمول/تسجيل/معالجة/خطأ/منتهية).
  final Rx<RecitationState> sessionState = RecitationState.idle.obs;

  /// حالة كل كلمة في الصفحة بمفتاح `'$ayahUq:$wordNumber'` (كلمة 1-based).
  final RxMap<String, TasmeeWordStatus> wordStatuses =
      <String, TasmeeWordStatus>{}.obs;

  /// نوع خطأ كل كلمة خاطئة (بنفس مفتاح [wordStatuses]) — للخط السفلي
  /// الملوّن؛ الكلمات الصحيحة بلا مدخل.
  final RxMap<String, TasmeeErrorKind> wordErrorKinds =
      <String, TasmeeErrorKind>{}.obs;

  /// الكلمة الجارية (مفتاح) — أو null.
  final Rxn<String> currentWordKey = Rxn<String>();

  /// الكلمة المنتظرة تصحيحها في نمط المصحح (أو null) — الجلسة الرئيسية
  /// متوقفة مؤقتًا طوال وجودها.
  final Rxn<TasmeeWordCorrection> activeWordCorrection =
      Rxn<TasmeeWordCorrection>();

  /// نتيجة آخر محاولة إعادة نطق للكلمة المنتظرة (null أثناء الاستماع
  /// أو قبل أي محاولة).
  final Rxn<TasmeeWordRetryOutcome> wordRetryOutcome =
      Rxn<TasmeeWordRetryOutcome>();

  /// خطأ أحدث محاولة إعادة نطق فاشلة (null عند الصحة أو قبل أي محاولة)
  /// — يُحدَّث مع كل محاولة ليعرف المستخدم خطأه الحالي: أصلح النطق
  /// فصار الخطأ تشكيلًا أو تجويدًا.
  final Rxn<TasmeeRetryFeedback> wordRetryFeedback = Rxn<TasmeeRetryFeedback>();

  /// جلسة إعادة نطق الكلمة تستمع الآن؟
  final RxBool isWordRetryListening = false.obs;

  /// عدد محاولات إعادة نطق الكلمة المنتظرة الفاشلة المتتالية — يُصفَّر
  /// عند فتح تصحيح جديد وعند حلّه. يقرؤه التطبيق المضيف للتخطّي التلقائي
  /// بعد سقف محاولات فلا تتعطّل الجلسة على كلمة يرفضها التعرف.
  final RxInt wordRetryAttempts = 0.obs;

  /// الجلسة الحيّة تستمع لموضع بداية المستخدم (طور الالتقاط — انطلق
  /// بأي آية تشاء) — يتغيّر إلى false عند أول كلمة جارية. لِلمؤشرات في
  /// التطبيق المضيف.
  final RxBool isAwaitingStart = false.obs;

  /// طور جلسة المعلم الجاري (نمط المعلم).
  final Rx<TasmeeTeacherPhase> teacherPhase = TasmeeTeacherPhase.idle.obs;

  /// فهرس الآية الجارية داخل صفحة المعلم (0-based، أو -1).
  final RxInt teacherAyahIndex = (-1).obs;

  /// إجمالي آيات صفحة المعلم.
  final RxInt teacherAyahTotal = 0.obs;

  /// نتيجة آخر تسميع (تُملأ بعد الإيقاف).
  final Rx<RecitationResult?> lastResult = Rx<RecitationResult?>(null);

  /// آخر رسالة خطأ (إن وُجدت).
  final RxString lastError = ''.obs;

  /// المحرك المختار.
  final Rx<TasmeeEngineMode> engineMode = TasmeeEngineMode.offline.obs;

  /// عنوان الخادم (online).
  final RxString serverUrl = ''.obs;

  /// هل نموذج Zipformer جاهز على القرص؟
  final RxBool isModelReady = false.obs;

  /// جارٍ تنزيل النموذج؟
  final RxBool isDownloadingModel = false.obs;

  /// تقدّم تنزيل النموذج (0.0–1.0).
  final RxDouble modelDownloadProgress = 0.0.obs;

  /// جارٍ تهيئة المحرك (تحميل النموذج في الذاكرة)؟
  final RxBool isPreparingEngine = false.obs;

  /// هل نُزِّل نموذج V4 مسبقًا عبر SDK؟
  final RxBool isV4ModelReady = false.obs;

  /// جارٍ تنزيل نموذج V4 (prefetch)؟
  final RxBool isDownloadingV4Model = false.obs;

  /// تقدّم تنزيل نموذج V4 (0.0–1.0؛ 0 حيث لا تدعم المنصة التقدم).
  final RxDouble v4ModelDownloadProgress = 0.0.obs;

  /// تنزيل نموذج V4 عبر Wi-Fi فقط؟
  final RxBool v4WifiOnly = true.obs;

  /// عدد الكلمات المكتملة في الجلسة الحالية.
  final RxInt completedWords = 0.obs;

  /// إجمالي كلمات نطاق الصفحة الحالية.
  final RxInt totalWords = 0.obs;

  /// رقم الصفحة التي بُني لها النطاق الحالي (داخلي).
  int currentRangePage = -1;
}
