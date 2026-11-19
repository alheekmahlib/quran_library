import 'dart:async';
import 'dart:typed_data';

/// Platform-neutral inference contract for TajweedFormer V4.
///
/// A client exposes model outputs, not correctness verdicts. Implementations
/// must keep the model's own vocabulary, reference and calibration together.
abstract interface class TajweedFormerInferenceClient {
  Stream<Map<String, dynamic>> get chunks;
  Future<Map<String, dynamic>> initialize(String key);
  Future<Map<String, dynamic>> reference(int surah, int ayah);
  Future<Map<String, dynamic>> sample();
  Future<Map<String, dynamic>> recognize(Float32List samples);
  Map<String, dynamic> calibration();
  Future<Map<String, dynamic>> diagnose();
  Future<void> start();
  Future<void> push(Float32List samples);
  Future<Map<String, dynamic>> finish();
  Future<void> cancel();
  Future<void> close();

  /// Downloads the SDK's protected model files ahead of first use.
  ///
  /// [key] is required on Android and web; the Apple bridge reads the host's
  /// own QuranLabKey when it is empty. Byte progress, where the platform
  /// reports it, arrives on [prefetchProgress] while this future runs.
  Future<void> prefetch({String key = '', bool unmeteredOnly = false});

  /// Byte counters for an ongoing [prefetch]; empty where unsupported.
  Stream<({int done, int total})> get prefetchProgress;

  /// Drops the SDK's downloaded model files so a later use downloads again.
  Future<void> removeModels({String key = ''});
}
