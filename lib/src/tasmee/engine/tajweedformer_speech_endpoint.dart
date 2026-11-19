import 'dart:async';

/// Converts the SDK's chunk speech indicator into one silence endpoint.
/// No endpoint is emitted before speech or after disposal; renewed speech
/// cancels the pending endpoint and permits a later one.
class TajweedFormerSpeechEndpoint {
  TajweedFormerSpeechEndpoint(this.onEndpoint,
      {this.silence = const Duration(milliseconds: 1200)});

  final void Function() onEndpoint;
  final Duration silence;
  Timer? _timer;
  bool _heardSpeech = false;
  bool _emitted = false;
  bool _disposed = false;

  void update(bool? speech) {
    if (_disposed || speech == null) return;
    if (speech) {
      _heardSpeech = true;
      _emitted = false;
      _timer?.cancel();
      _timer = null;
    } else if (_heardSpeech && !_emitted && _timer == null) {
      _timer = Timer(silence, () {
        _timer = null;
        if (_disposed) return;
        _emitted = true;
        onEndpoint();
      });
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
