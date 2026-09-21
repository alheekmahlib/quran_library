/// تنفيذ أصلي للمصنع — ينشئ محرّك Zipformer الحقيقي (sherpa_onnx).
///
/// Native factory implementation — creates the real Zipformer engine.
library;

import 'recitation_engine.dart';
import 'madd_timing.dart';
import 'sherpa_zipformer_engine.dart';

/// هل محرّك Zipformer مدعوم على هذه المنصة؟
/// Is the Zipformer engine supported on this platform?
bool get sherpaEngineSupported => true;

/// أنشئ وهيكّئ محرّك Zipformer (يُستدعى من Recitation.initZipformer).
///
/// Create and initialize the Zipformer engine.
Future<RecitationEngine> createSherpaZipformerEngine({
  String? modelPath,
  String? tokensPath,
  String? referencePath,
  MaddTimingConfig maddTimingConfig = const MaddTimingConfig(),
}) async {
  final engine = SherpaZipformerEngine(
    modelPath: modelPath,
    tokensPath: tokensPath,
    referencePath: referencePath,
    maddTimingConfig: maddTimingConfig,
  );
  await engine.initialize();
  return engine;
}
