/// وحدة التسميع بالذكاء الاصطناعي (تصحيح التلاوة).
///
/// The AI recitation-checking (tasmee) module.
///
/// المحرّك منقول من حزمة quran_audio ويعمل بطريقتين:
/// - **Offline**: نموذج Quran-Lab zipformer v3.1 (يُنزَّل وقت التشغيل).
/// - **Online**: خادم quran-muaalem (دفعة واحدة بعد الإيقاف).
///
/// ملاحظة ويب: محرّك sherpa_onnx يتطلب dart:ffi (غير متوفر على الويب)،
/// لذا يُعزل خلف [sherpa_factory] الشرطي ولا يُصدَّر من هنا مباشرة.
library;

// ── المحرك / Engine ──────────────────────────────────────────
export 'engine/recitation.dart';
export 'engine/recitation_engine.dart';
export 'engine/live_recitation_engine.dart';
export 'engine/recitation_session.dart';
export 'engine/recitation_state.dart';
export 'engine/muaalem_client.dart';
export 'engine/sherpa_factory.dart';
export 'engine/zipformer_model.dart';
export 'engine/quran_units.dart';
export 'engine/quran_reference.dart';
export 'engine/phoneme_aligner.dart';
export 'engine/error_detector.dart';
export 'engine/madd_timing.dart';
export 'engine/wav_decoder.dart';
export 'engine/models/muaalem_config.dart';
export 'engine/models/recitation_result.dart';

// ── الخدمات / Services ───────────────────────────────────────
export 'core/services/tasmee_model_service.dart';
