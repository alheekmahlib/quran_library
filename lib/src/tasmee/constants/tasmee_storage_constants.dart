/// مفاتيح تخزين إعدادات التسميع (GetStorage).
library;

class TasmeeStorageConstants {
  const TasmeeStorageConstants();

  /// المحرك المختار: 'offline' (افتراضي) أو 'online'.
  static const String engineMode = 'TASMEE_ENGINE_MODE';

  /// عنوان خادم Muaalem (لِلوضع online).
  static const String serverUrl = 'TASMEE_SERVER_URL';

  /// نمط التسميع الأخير: 'tasmee' (افتراضي) أو 'corrector' أو 'teacher'.
  static const String tasmeeMode = 'TASMEE_MODE';

  /// وضع المصحّح غير الحاجز (شارة بلا شيت مانع): 'true' لِلتفعيل.
  static const String nonBlockingCorrector = 'TASMEE_NON_BLOCKING_CORRECTOR';

  /// صرامة المعايير: 'strict' أو 'balanced' (افتراضي) أو 'lenient'.
  static const String strictness = 'TASMEE_STRICTNESS';
  static const String tolerance = 'TASMEE_TOLERANCE_V4';

  /// هل نُزِّل نموذج V4 مسبقًا (وقت التشغيل عبر SDK Quran Lab)؟
  static const String v4ModelReady = 'TASMEE_V4_MODEL_READY';

  /// تنزيل نموذج V4 عبر Wi-Fi فقط: 'true' (افتراضي) أو 'false'.
  static const String v4WifiOnly = 'TASMEE_V4_WIFI_ONLY';
}
