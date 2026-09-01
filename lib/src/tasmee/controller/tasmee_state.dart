/// حالة وضع التسميع (متغيرات GetX التفاعلية).
library;

import 'package:get/get.dart';

import '../engine/models/recitation_result.dart';
import '../engine/recitation_state.dart';

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

class TasmeeState {
  /// هل وضع التسميع مفعّل الآن؟
  final RxBool isTasmeeMode = false.obs;

  /// إظهار كل كلمات الصفحة مؤقتًا (زر العين) أثناء وضع التسميع.
  final RxBool showAllWords = false.obs;

  /// حالة الجلسة الحالية (خمول/تسجيل/معالجة/خطأ/منتهية).
  final Rx<RecitationState> sessionState = RecitationState.idle.obs;

  /// حالة كل كلمة في الصفحة بمفتاح `'$ayahUq:$wordNumber'` (كلمة 1-based).
  final RxMap<String, TasmeeWordStatus> wordStatuses =
      <String, TasmeeWordStatus>{}.obs;

  /// الكلمة الجارية (مفتاح) — أو null.
  final Rxn<String> currentWordKey = Rxn<String>();

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
