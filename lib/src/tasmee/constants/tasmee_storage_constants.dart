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
}
