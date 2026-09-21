/// تنفيذ بديل للويب — لا محرّك محلياً (sherpa_onnx يتطلب dart:ffi غير متوفر على الويب).
///
/// Web fallback — no offline engine (sherpa_onnx requires dart:ffi, unavailable
/// on the web).
library;

import 'recitation_engine.dart';
import 'madd_timing.dart';

/// هل محرّك Zipformer مدعوم على هذه المنصة؟ (لا على الويب)
/// Is the Zipformer engine supported on this platform? (no on web)
bool get sherpaEngineSupported => false;

/// على الويب ينتهي دائماً بخطأ واضح — استخدم الخادم بدلاً منه.
///
/// On web this always fails clearly — use the server engine instead.
Future<RecitationEngine> createSherpaZipformerEngine({
  String? modelPath,
  String? tokensPath,
  String? referencePath,
  MaddTimingConfig maddTimingConfig = const MaddTimingConfig(),
}) {
  throw UnsupportedError(
      'المحرّك المحلي (Zipformer) غير مدعوم على الويب — استخدم Recitation.init مع خادم');
}
