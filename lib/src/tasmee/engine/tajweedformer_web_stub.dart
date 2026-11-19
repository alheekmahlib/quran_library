import 'dart:async';
import 'dart:typed_data';

import 'tajweedformer_client.dart';

/// The V4 web inference API is not available on this platform.
class TajweedFormerWeb implements TajweedFormerInferenceClient {
  static bool get isSupported => false;
  @override
  Stream<Map<String, dynamic>> get chunks => const Stream.empty();
  @override
  Future<Map<String, dynamic>> initialize(String key) async => _unsupported();
  @override
  Future<Map<String, dynamic>> reference(int surah, int ayah) async =>
      _unsupported();
  @override
  Future<Map<String, dynamic>> sample() async => _unsupported();
  @override
  Future<Map<String, dynamic>> recognize(Float32List samples) async =>
      _unsupported();
  @override
  Map<String, dynamic> calibration() => _unsupported();
  @override
  Future<Map<String, dynamic>> diagnose() async => _unsupported();
  @override
  Future<void> start() async => _unsupported();
  @override
  Future<void> push(Float32List samples) async => _unsupported();
  @override
  Future<Map<String, dynamic>> finish() async => _unsupported();
  @override
  Future<void> cancel() async => _unsupported();
  @override
  Future<void> prefetch({String key = '', bool unmeteredOnly = false}) async =>
      _unsupported();
  @override
  Stream<({int done, int total})> get prefetchProgress => const Stream.empty();
  @override
  Future<void> removeModels({String key = ''}) async => _unsupported();
  @override
  Future<void> close() async {}
  Never _unsupported() =>
      throw UnsupportedError('TajweedFormer web requires a browser');
}
