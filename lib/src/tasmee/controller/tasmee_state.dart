/// حالة وضع التسميع (متغيرات GetX التفاعلية).
library;

import 'package:get/get.dart';

import '../engine/models/recitation_result.dart';
import '../engine/tasmee_error_kind.dart';
import '../engine/recitation_state.dart';
import 'tasmee_mode.dart';

/// وضع محرّك التسميع.
enum TasmeeEngineMode {
  /// نموذج Zipformer محلي — عرض حيّ ويعمل دون إنترنت.
  offline,

  /// خادم quran-muaalem — تصحيح دفعي بعد الإيقاف (بلا عرض حيّ).
  online,
}

/// حالة الكلمة أثناء التسميع.
enum TasmeeWordStatus {
  /// مخفية — لم يُتَل عليها بعد.
  hidden,

  /// الكلمة الجارية التي يُتلوها الآن (مُبرزة).
  current,

  /// اكتمل نطقها صحيحة (أخضر).
  correct,

  /// اكتمل نطقها وفيها خطأ (أحمر) — التقييم النهائي هو المرجع.
  incorrect,
}

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
    this.errorType = 'replace',
    this.expectedSymbol,
    this.predictedSymbol,
  });

  /// مفتاح الكلمة في خرائط الحالات `'$ayahUq:$wordNumber'`.
  final String key;

  /// نص الكلمة العثماني.
  final String wordText;

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
enum TasmeeWordRetryOutcome { correct, incorrect }

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

  /// أُتقنت كل آيات الصفحة واكتمل التسميع.
  pageDone,
}

class TasmeeState {
  /// هل وضع التسميع مفعّل الآن؟
  final RxBool isTasmeeMode = false.obs;

  /// نمط التسميع الحالي — يحدّد سلوك الجلسة وإظهار الكلمات الافتراضي.
  final Rx<TasmeeMode> mode = TasmeeMode.tasmee.obs;

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

  /// جلسة إعادة نطق الكلمة تستمع الآن؟
  final RxBool isWordRetryListening = false.obs;

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

  /// عدد الكلمات المكتملة في الجلسة الحالية.
  final RxInt completedWords = 0.obs;

  /// إجمالي كلمات نطاق الصفحة الحالية.
  final RxInt totalWords = 0.obs;

  /// رقم الصفحة التي بُني لها النطاق الحالي (داخلي).
  int currentRangePage = -1;
}
