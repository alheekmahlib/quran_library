/// حالة جلسة التسميع.
///
/// State of a recitation session.
enum RecitationState {
  /// الجلسة لم تبدأ بعد / The session hasn't started.
  idle,

  /// جارٍ الاتصال بِـ qurani.ai / Connecting to qurani.ai.
  connecting,

  /// يُسجّل ويبثّ الصوت / Recording and streaming audio.
  recording,

  /// توقّف مؤقت (يستهلّ لاحقاً) / Paused (resumable later).
  paused,

  /// يُعالج الخادم آخر قطعة / Server is processing the last chunk.
  processing,

  /// خطأ / Error.
  error,

  /// انتهت الجلسة / The session ended.
  finished,
}

/// هل الحالة تعني أن الجلسة نشطة (تسجيل/بثّ)؟
/// Does the state mean the session is active (recording/streaming)?
extension RecitationStateX on RecitationState {
  bool get isActive =>
      this == RecitationState.recording || this == RecitationState.connecting;
  bool get isError => this == RecitationState.error;
  bool get isTerminal =>
      this == RecitationState.error || this == RecitationState.finished;
}
