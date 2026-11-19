// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:typed_data';

import 'tajweedformer_client.dart';

@JS('quranLibraryTajweedFormer.initialize')
external JSPromise<JSString> _initialize(JSString key);
@JS('quranLibraryTajweedFormer.reference')
external JSPromise<JSString> _reference(JSNumber surah, JSNumber ayah);
@JS('quranLibraryTajweedFormer.sample')
external JSPromise<JSString> _sample();
@JS('quranLibraryTajweedFormer.recognize')
external JSPromise<JSString> _recognize(JSFloat32Array samples);
@JS('quranLibraryTajweedFormer.calibration')
external JSString _calibration();
@JS('quranLibraryTajweedFormer.diagnose')
external JSPromise<JSString> _diagnose();
@JS('quranLibraryTajweedFormer.start')
external void _start(JSFunction onChunk);
@JS('quranLibraryTajweedFormer.push')
external void _push(JSFloat32Array samples);
@JS('quranLibraryTajweedFormer.finish')
external JSPromise<JSString> _finish();
@JS('quranLibraryTajweedFormer.cancel')
external JSPromise<JSAny?> _cancel();
@JS('quranLibraryTajweedFormer.close')
external JSPromise<JSAny?> _close();
@JS('quranLibraryTajweedFormer.prefetch')
external JSPromise<JSString> _prefetch(
    JSString key, JSBoolean unmeteredOnly, JSFunction? onProgress);
@JS('quranLibraryTajweedFormer.removeModels')
external JSPromise<JSString> _removeModels(JSString key);

/// Optional on-device V4 inference in a browser.
///
/// The SDK returns what it heard. This class does not compare it with the
/// Quran or issue a judgement. Only one SDK client/take may be open at once.
class TajweedFormerWeb implements TajweedFormerInferenceClient {
  static bool get isSupported => true;
  static Future<void>? _loadFuture;
  final _chunks = StreamController<Map<String, dynamic>>.broadcast();
  final _prefetchProgress =
      StreamController<({int done, int total})>.broadcast();
  bool _initialized = false;
  bool _closed = false;

  @override
  Stream<Map<String, dynamic>> get chunks => _chunks.stream;

  @override
  Stream<({int done, int total})> get prefetchProgress =>
      _prefetchProgress.stream;

  /// Downloads the model ahead of the first initialize.
  @override
  Future<void> prefetch({String key = '', bool unmeteredOnly = false}) async {
    if (_closed) throw StateError('TajweedFormer is closed');
    if (key.trim().isEmpty) throw ArgumentError.value(key, 'key');
    await _load();
    await _prefetch(
            key.trim().toJS,
            unmeteredOnly.toJS,
            ((JSNumber done, JSNumber total) {
              if (!_prefetchProgress.isClosed) {
                _prefetchProgress.add((
                  done: done.toDartInt,
                  total: total.toDartInt,
                ));
              }
            }).toJS)
        .toDart;
  }

  @override
  Future<void> removeModels({String key = ''}) async {
    if (_closed) throw StateError('TajweedFormer is closed');
    if (key.trim().isEmpty) throw ArgumentError.value(key, 'key');
    await _load();
    await _removeModels(key.trim().toJS).toDart;
  }

  static Future<void> _load() => _loadFuture ??= _loadScript();

  static Future<void> _loadScript() async {
    final done = Completer<void>();
    final script = html.ScriptElement()
      ..type = 'module'
      ..src = Uri.parse(html.document.baseUri ?? Uri.base.toString())
          .resolve(
              'assets/packages/quran_library/assets/tajweedformer_web/bridge.js')
          .toString();
    script.onLoad.first.then((_) => done.complete());
    script.onError.first.then((_) =>
        done.completeError(StateError('Unable to load TajweedFormer web SDK')));
    html.document.head!.append(script);
    try {
      await done.future;
    } catch (_) {
      script.remove();
      _loadFuture = null;
      rethrow;
    }
  }

  Map<String, dynamic> _parse(String json) =>
      Map<String, dynamic>.from(jsonDecode(json) as Map);

  void _checkInitialized() {
    if (!_initialized || _closed) {
      throw StateError('TajweedFormer is not initialized');
    }
  }

  /// The web key must be scoped to the page origin by Quran Lab.
  @override
  Future<Map<String, dynamic>> initialize(String key) async {
    if (_closed) throw StateError('TajweedFormer is closed');
    if (key.trim().isEmpty) {
      throw ArgumentError.value(key, 'key', 'Must not be empty');
    }
    await _load();
    if (_closed) throw StateError('TajweedFormer is closed');
    final info = (await _initialize(key.toJS).toDart).toDart;
    if (_closed) {
      await _close().toDart;
      throw StateError('TajweedFormer was closed during initialization');
    }
    _initialized = true;
    return _parse(info);
  }

  /// Fetches and verifies the model's own reference before returning a verse.
  @override
  Future<Map<String, dynamic>> reference(int surah, int ayah) async {
    _checkInitialized();
    return _parse((await _reference(surah.toJS, ayah.toJS).toDart).toDart);
  }

  /// Runs the SDK's sample clip, without accessing the microphone.
  @override
  Future<Map<String, dynamic>> sample() async {
    _checkInitialized();
    return _parse((await _sample().toDart).toDart);
  }

  /// Runs caller-provided mono PCM at 16 kHz without using the microphone.
  @override
  Future<Map<String, dynamic>> recognize(Float32List samples) async {
    _checkInitialized();
    return _parse((await _recognize(samples.toJS).toDart).toDart);
  }

  /// The model's verified calibration data; no thresholds are applied here.
  @override
  Map<String, dynamic> calibration() {
    _checkInitialized();
    return _parse(_calibration().toDart);
  }

  @override
  Future<Map<String, dynamic>> diagnose() async {
    _checkInitialized();
    return _parse((await _diagnose().toDart).toDart);
  }

  /// Starts a take. Listen to [chunks] before feeding 16 kHz mono PCM.
  @override
  Future<void> start() async {
    _checkInitialized();
    _start(((JSString value) {
      if (!_chunks.isClosed) _chunks.add(_parse(value.toDart));
    }).toJS);
  }

  @override
  Future<void> push(Float32List samples) async {
    _checkInitialized();
    _push(samples.toJS);
  }

  /// Returns the raw heads; the caller is responsible for evaluation.
  @override
  Future<Map<String, dynamic>> finish() async {
    _checkInitialized();
    return _parse((await _finish().toDart).toDart);
  }

  @override
  Future<void> cancel() async {
    _checkInitialized();
    await _cancel().toDart;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      if (_initialized) {
        await _close().toDart;
      }
    } finally {
      _initialized = false;
      await _chunks.close();
      await _prefetchProgress.close();
    }
  }
}
