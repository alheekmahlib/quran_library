import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tajweedformer_client.dart';

/// Opt-in Android 8+ V4 inference. It does not select or judge Tasmee.
/// The application must enable the optional Android build integration.
class TajweedFormerAndroid implements TajweedFormerInferenceClient {
  static const _channel = MethodChannel('quran_library/tajweedformer_android');
  static TajweedFormerAndroid? _owner;
  static TajweedFormerAndroid? _eventSink;
  final _chunks = StreamController<Map<String, dynamic>>.broadcast();
  final _prefetchProgress = StreamController<({int done, int total})>.broadcast();
  Future<Map<String, dynamic>>? _initializing;
  Map<String, dynamic>? _calibration;
  bool _initialized = false;
  bool _closed = false;

  /// Routes native callbacks (chunks, prefetch progress) to the most recent
  /// client, so a short-lived download client works before initialize.
  TajweedFormerAndroid() {
    if (_eventSink == null || _eventSink!._closed) {
      _eventSink = this;
      _channel.setMethodCallHandler(_onNativeCall);
    }
  }

  /// True only when the optional bridge is installed on Android 8 or newer.
  static Future<bool> isAvailable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    if (call.method == 'prefetchProgress') {
      if (!_prefetchProgress.isClosed) {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        _prefetchProgress.add((
          done: (args['done'] as num?)?.toInt() ?? 0,
          total: (args['total'] as num?)?.toInt() ?? 0,
        ));
      }
      return;
    }
    if (_chunks.isClosed) return;
    if (call.method == 'chunk') {
      _chunks.add(Map<String, dynamic>.from(call.arguments as Map));
    } else if (call.method == 'streamError') {
      _chunks.addError(StateError(call.arguments.toString()));
    }
  }

  @override
  Stream<Map<String, dynamic>> get chunks => _chunks.stream;

  @override
  Stream<({int done, int total})> get prefetchProgress =>
      _prefetchProgress.stream;

  @override
  Future<void> prefetch({String key = '', bool unmeteredOnly = false}) async {
    if (_closed) throw StateError('TajweedFormer is closed');
    if (key.trim().isEmpty) throw ArgumentError.value(key, 'key');
    await _channel.invokeMethod<void>('prefetch',
        {'key': key.trim(), 'unmeteredOnly': unmeteredOnly});
  }

  @override
  Future<void> removeModels({String key = ''}) async {
    if (_closed) throw StateError('TajweedFormer is closed');
    if (key.trim().isEmpty) throw ArgumentError.value(key, 'key');
    await _channel.invokeMethod<void>('removeModels', {'key': key.trim()});
  }

  @override
  Future<Map<String, dynamic>> initialize(String key) async {
    if (_closed || _owner != null) {
      throw StateError('TajweedFormer client is already open or closed');
    }
    if (key.trim().isEmpty) throw ArgumentError.value(key, 'key');
    _owner = this;
    _eventSink = this;
    _channel.setMethodCallHandler(_onNativeCall);
    final pending = _initialize(key);
    _initializing = pending;
    try {
      return await pending;
    } finally {
      _initializing = null;
    }
  }

  Future<Map<String, dynamic>> _initialize(String key) async {
    var nativeOpened = false;
    try {
      final value = await _channel.invokeMapMethod<String, dynamic>(
        'initialize',
        {'key': key},
      );
      if (value == null) throw StateError('Missing model metadata');
      nativeOpened = true;
      final json = jsonDecode(value.remove('calibrationJson') as String);
      _calibration = {
        'sha256': value.remove('calibrationSha256'),
        'data': json,
      };
      _initialized = true;
      return value;
    } catch (_) {
      if (nativeOpened) await _channel.invokeMethod<void>('close');
      if (identical(_owner, this)) {
        _owner = null;
        _channel.setMethodCallHandler(null);
        if (identical(_eventSink, this)) _eventSink = null;
      }
      rethrow;
    }
  }

  void _check() {
    if (!_initialized || _closed) {
      throw StateError('TajweedFormer is not initialized');
    }
  }

  Future<Map<String, dynamic>> _map(String method, [Object? args]) async {
    _check();
    final value = await _channel.invokeMapMethod<String, dynamic>(method, args);
    if (value == null) throw StateError('Missing $method result');
    return value;
  }

  @override
  Map<String, dynamic> calibration() {
    _check();
    return Map<String, dynamic>.unmodifiable(_calibration!);
  }

  @override
  Future<Map<String, dynamic>> reference(int surah, int ayah) =>
      _map('reference', {'surah': surah, 'ayah': ayah});
  @override
  Future<Map<String, dynamic>> diagnose() => _map('diagnose');
  @override
  Future<Map<String, dynamic>> sample() => _map('sample');
  @override
  Future<Map<String, dynamic>> recognize(Float32List samples) =>
      _map('recognize', {'samples': samples});
  @override
  Future<void> start() async {
    _check();
    await _channel.invokeMethod<void>('start');
  }

  @override
  Future<void> push(Float32List samples) async {
    _check();
    await _channel.invokeMethod<void>('push', {'samples': samples});
  }

  @override
  Future<Map<String, dynamic>> finish() => _map('finish');
  @override
  Future<void> cancel() async {
    _check();
    await _channel.invokeMethod<void>('cancel');
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      try {
        await _initializing;
      } catch (_) {/* Initialization already reports its failure. */}
      if (_initialized) await _channel.invokeMethod<void>('close');
    } finally {
      _initialized = false;
      if (identical(_owner, this)) {
        _owner = null;
        if (identical(_eventSink, this)) {
          _eventSink = null;
          _channel.setMethodCallHandler(null);
        }
      }
      await _chunks.close();
      await _prefetchProgress.close();
    }
  }
}
