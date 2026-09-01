/// ثوابت نموذج Zipformer المشتركة (web-safe — بلا استيرادات io/ffi).
///
/// Shared Zipformer model constants (web-safe — no io/ffi imports).
library;

/// اسم ملف النموذج في مجلد دعم التطبيق (بعد التنزيل).
const String kZipformerModelFileName = 'zipformer_p_arabic_v3.1.int8.onnx';

/// رابط تنزيل النموذج (GitHub Release عام — نفس إصدار quran_audio).
const String kZipformerModelUrl =
    'https://github.com/alheekmahlib/quran_audio/releases/download/'
    'zipformer-model-v1/zipformer_p_arabic_v3.1.int8.onnx';

/// أقل حجم صالح للنموذج (~60MB) — تحقق من اكتمال التنزيل.
const int kZipformerMinValidBytes = 60 * 1024 * 1024;
