import 'dart:async';
import 'dart:typed_data';

import 'tajweedformer_client.dart';
import 'tajweedformer_live_tracker.dart';
import 'tajweedformer_reference.dart';
import 'tajweedformer_word_progress.dart';

/// A single V4 take with conservative, non-judgmental range tracking.
///
/// The caller initializes and owns [client]. Each session takes an already
/// verified V4 reference whose word positions match the displayed Mushaf.
class TajweedFormerRangeSession {
  TajweedFormerRangeSession({
    required this.client,
    required List<TajweedFormerReferenceUnit> reference,
    required int blankId,
    required int wordBarId,
  })  : _words = TajweedFormerWordProgressMapper(reference),
        _tracker = TajweedFormerLiveTracker(
          reference: reference,
          blankId: blankId,
          wordBarId: wordBarId,
        );

  final TajweedFormerInferenceClient client;
  final TajweedFormerLiveTracker _tracker;
  final TajweedFormerWordProgressMapper _words;
  final _progress = StreamController<TajweedFormerLiveProgress>.broadcast();
  StreamSubscription<Map<String, dynamic>>? _subscription;
  bool _started = false;
  bool _ended = false;
  bool _starting = false;
  Object? _streamFailure;
  StackTrace? _streamFailureStack;

  void _failProgress(Object error, StackTrace stack) {
    _streamFailure ??= error;
    _streamFailureStack ??= stack;
    _progress.addError(error, stack);
  }

  /// Match snapshots only; these never mean that a word is correct.
  Stream<TajweedFormerLiveProgress> get progress => _progress.stream;

  /// The same snapshots projected onto the caller's verified word positions.
  /// These are matches, not correction verdicts or completed results.
  Stream<TajweedFormerWordProgress> get wordProgress =>
      _progress.stream.map(_words.project);

  Future<void> start() async {
    if (_started || _ended) {
      throw StateError('This V4 take has already started');
    }
    _started = true;
    _starting = true;
    _subscription = client.chunks.listen((chunk) {
      try {
        _progress.add(_tracker.updateDecodedChunk(chunk));
      } catch (error, stack) {
        _failProgress(error, stack);
      }
    }, onError: (Object error, StackTrace stack) {
      _failProgress(error, stack);
    });
    try {
      await client.start();
    } catch (_) {
      _ended = true;
      await _subscription?.cancel();
      _subscription = null;
      await _progress.close();
      rethrow;
    } finally {
      _starting = false;
    }
  }

  /// Feeds normalized mono PCM at 16 kHz; microphone capture is the host's.
  Future<void> push(Float32List samples) async {
    if (!_started || _ended || _starting) {
      throw StateError('This V4 take is not active');
    }
    await client.push(samples);
  }

  /// Ends the take and returns the raw heads for the app's separate evaluator.
  Future<Map<String, dynamic>> finish() async {
    if (!_started || _ended || _starting) {
      throw StateError('This V4 take is not active');
    }
    _ended = true;
    try {
      if (_streamFailure != null) {
        await client.cancel();
        Error.throwWithStackTrace(_streamFailure!, _streamFailureStack!);
      }
      final result = await client.finish();
      // Let any final broadcast chunk reach the tracker before unsubscribing.
      await Future<void>.delayed(Duration.zero);
      if (_streamFailure != null) {
        Error.throwWithStackTrace(_streamFailure!, _streamFailureStack!);
      }
      return result;
    } finally {
      await _subscription?.cancel();
      _subscription = null;
      await _progress.close();
    }
  }

  /// Cancels this take without closing the caller-owned model/client.
  Future<void> cancel() async {
    if (_starting) throw StateError('This V4 take is starting');
    if (_ended) return;
    _ended = true;
    try {
      if (_started) await client.cancel();
    } finally {
      await _subscription?.cancel();
      _subscription = null;
      await _progress.close();
    }
  }
}
