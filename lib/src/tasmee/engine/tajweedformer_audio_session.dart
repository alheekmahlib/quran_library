import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'tajweedformer_range_session.dart';

/// Experimental microphone input for a caller-owned V4 range session.
///
/// Progress is only an exact-token match, not a correctness verdict. The
/// caller must verify the reference against the displayed Mushaf before using
/// its positions. This API does not select the production Tasmee engine.
class TajweedFormerAudioSession {
  // Bound memory if inference cannot keep up with the microphone. This is a
  // transport limit, not a model or correctness threshold.
  static const _maxPendingSamples = 16000 * 30;
  TajweedFormerAudioSession({
    required this.range,
    required Future<Stream<Uint8List>> Function() openAudio,
    required Future<void> Function() closeAudio,
  })  : _openAudio = openAudio,
        _closeAudio = closeAudio;

  /// Uses the same 16 kHz mono PCM format as the existing live recorder.
  factory TajweedFormerAudioSession.microphone(
      TajweedFormerRangeSession range) {
    final recorder = AudioRecorder();
    var attempted = false;
    return TajweedFormerAudioSession(
      range: range,
      openAudio: () async {
        if (!await recorder.hasPermission()) {
          throw StateError('Microphone permission denied');
        }
        final process =
            !kIsWeb && defaultTargetPlatform != TargetPlatform.macOS;
        attempted = true;
        return recorder.startStream(RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: process,
          echoCancel: process,
          noiseSuppress: process,
        ));
      },
      closeAudio: () async {
        try {
          if (attempted) await recorder.stop();
        } finally {
          await recorder.dispose();
        }
      },
    );
  }

  final TajweedFormerRangeSession range;
  final Future<Stream<Uint8List>> Function() _openAudio;
  final Future<void> Function() _closeAudio;
  final _errors = StreamController<Object>.broadcast();
  StreamSubscription<Uint8List>? _audio;
  int? _pendingByte;
  Object? _failure;
  bool _started = false;
  bool _ended = false;
  bool _opening = false;
  bool _cancelled = false;
  int _queuedSamples = 0;
  Future<void> _pendingPush = Future.value();

  /// Capture or inference errors; a failed capture cannot produce a result.
  Stream<Object> get errors => _errors.stream;

  Future<void> start() async {
    if (_started || _ended) throw StateError('Audio session already used');
    _started = true;
    _opening = true;
    try {
      await range.start();
      final stream = await _openAudio();
      _audio = stream.listen(_feed, onError: (Object error, StackTrace stack) {
        _failure ??= error;
        if (!_errors.isClosed) _errors.add(error);
      }, onDone: () {
        if (!_ended) {
          final error = StateError('Microphone stream ended unexpectedly');
          _failure ??= error;
          if (!_errors.isClosed) _errors.add(error);
        }
      });
    } catch (_) {
      _ended = true;
      try {
        await _closeAudio();
      } finally {
        await range.cancel();
        await _errors.close();
      }
      rethrow;
    } finally {
      _opening = false;
    }
  }

  void _feed(Uint8List bytes) {
    if (_ended || _failure != null) return;
    try {
      final count = (bytes.length + (_pendingByte == null ? 0 : 1)) ~/ 2;
      if (_queuedSamples + count > _maxPendingSamples) {
        throw StateError('V4 inference cannot keep up with audio');
      }
      final samples = Float32List(count);
      var offset = 0;
      var index = 0;
      if (_pendingByte != null && bytes.isNotEmpty) {
        samples[index++] = _sample(_pendingByte!, bytes[offset++]);
        _pendingByte = null;
      }
      while (offset + 1 < bytes.length) {
        samples[index++] = _sample(bytes[offset], bytes[offset + 1]);
        offset += 2;
      }
      if (offset < bytes.length) _pendingByte = bytes[offset];
      if (samples.isNotEmpty) {
        _queuedSamples += samples.length;
        _pendingPush = _pendingPush.then((_) async {
          try {
            if (!_cancelled && _failure == null) await range.push(samples);
          } finally {
            _queuedSamples -= samples.length;
          }
        }).catchError((Object error, StackTrace stack) {
          _failure ??= error;
          if (!_errors.isClosed) _errors.add(error);
        });
      }
    } catch (error) {
      _failure = error;
      if (!_errors.isClosed) _errors.add(error);
    }
  }

  static double _sample(int low, int high) {
    final value = low | (high << 8);
    return (value >= 0x8000 ? value - 0x10000 : value) / 32768.0;
  }

  Future<Map<String, dynamic>> finish() async {
    if (_opening) throw StateError('Audio session is starting');
    if (!_started || _ended) throw StateError('Audio session is not active');
    _ended = true;
    try {
      await _audio?.cancel();
      await _closeAudio();
      await _pendingPush;
      if (_failure != null) throw StateError('Audio capture failed: $_failure');
      if (_pendingByte != null) {
        throw const FormatException('Incomplete PCM sample');
      }
      return await range.finish();
    } catch (_) {
      await range.cancel();
      rethrow;
    } finally {
      await _errors.close();
    }
  }

  Future<void> cancel() async {
    if (_opening) throw StateError('Audio session is starting');
    if (_ended) return;
    _ended = true;
    _cancelled = true;
    try {
      await _audio?.cancel();
      if (_started) await _closeAudio();
      await _pendingPush;
    } finally {
      await range.cancel();
      await _errors.close();
    }
  }
}
