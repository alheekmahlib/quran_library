/// CTC sequence likelihood for TajweedFormer calibration.
///
/// The caller must use the model's own vocabulary and prepare each head as
/// specified by its signed calibration. This primitive makes no verdicts.
library;

import 'dart:math' as math;
import 'dart:typed_data';

/// Single-edit CTC rescoring with shared forward/backward paths.
/// Recurrences follow Quran-Lab/tajweedformer-engine, tajweed/src/tj_ctc.c,
/// commit e7abb569a860ebf4455cb05940194889a4c45a5e (NPL-1.2; see NOTICE).
class TajweedFormerCtcRescorer {
  TajweedFormerCtcRescorer(this.head, this.tokens, this.blank) {
    // Reuse the canonical implementation's validation, including empty heads.
    logLikelihood = tajweedFormerCtcLogLikelihood(
        logProbabilities: head, tokens: tokens, blankId: blank);
    if (head.isEmpty) return;
    final tCount = head.length, states = tokens.length * 2 + 1;
    _alpha = Float64List(tCount * states)
      ..fillRange(0, tCount * states, double.negativeInfinity);
    _beta = Float64List(tCount * states)
      ..fillRange(0, tCount * states, double.negativeInfinity);
    int symbol(int s) => s.isEven ? blank : tokens[s ~/ 2];
    bool skip(int s) =>
        s >= 3 && s.isOdd && tokens[s ~/ 2] != tokens[s ~/ 2 - 1];
    _alpha[0] = head[0][blank];
    if (tokens.isNotEmpty) _alpha[1] = head[0][tokens[0]];
    for (var t = 1; t < tCount; t++) {
      for (var s = 0; s < states; s++) {
        var v = _alpha[(t - 1) * states + s];
        if (s > 0) v = _logAdd(v, _alpha[(t - 1) * states + s - 1]);
        if (skip(s)) v = _logAdd(v, _alpha[(t - 1) * states + s - 2]);
        _alpha[t * states + s] = v + head[t][symbol(s)];
      }
    }
    final last = (tCount - 1) * states;
    _beta[last + states - 1] = head.last[blank];
    if (tokens.isNotEmpty) _beta[last + states - 2] = head.last[tokens.last];
    for (var t = tCount - 2; t >= 0; t--) {
      for (var s = 0; s < states; s++) {
        var v = _beta[(t + 1) * states + s];
        if (s + 1 < states) v = _logAdd(v, _beta[(t + 1) * states + s + 1]);
        if (s + 2 < states && skip(s + 2)) {
          v = _logAdd(v, _beta[(t + 1) * states + s + 2]);
        }
        _beta[t * states + s] = v + head[t][symbol(s)];
      }
    }
  }
  final List<List<double>> head;
  final List<int> tokens;
  final int blank;
  late final double logLikelihood;
  late final Float64List _alpha, _beta;

  double delete(int k) {
    if (k < 0 || k >= tokens.length) throw RangeError.index(k, tokens);
    if (head.isEmpty) return tokens.length == 1 ? 0 : double.negativeInfinity;
    final j = tokens.length, s = 2 * j + 1, tCount = head.length;
    if (k == 0) return j >= 2 ? _logAdd(_beta[2], _beta[3]) : _beta[2];
    final skip = k + 1 < j && tokens[k - 1] != tokens[k + 1];
    var value = double.negativeInfinity;
    for (var t = 0; t + 1 < tCount; t++) {
      var next = _beta[(t + 1) * s + 2 * k + 2];
      if (skip) next = _logAdd(next, _beta[(t + 1) * s + 2 * k + 3]);
      value = _logAdd(value, _alpha[t * s + 2 * k - 1] + next);
    }
    if (k == j - 1) {
      value = _logAdd(value, _alpha[(tCount - 1) * s + 2 * k - 1]);
    }
    return value;
  }

  double replace(int k, int token) => _bridge(k, token, false);
  double insertAfter(int k, int token) => _bridge(k, token, true);

  double _bridge(int k, int token, bool insert) {
    if (k < 0 || k >= tokens.length) throw RangeError.index(k, tokens);
    if (token < 0 ||
        token == blank ||
        (head.isNotEmpty && token >= head.first.length)) {
      throw ArgumentError('Invalid token');
    }
    if (head.isEmpty) return double.negativeInfinity;
    final j = tokens.length, s = 2 * j + 1, tCount = head.length;
    final pb = insert ? 2 * k + 2 : 2 * k;
    final pl = insert ? 2 * k + 1 : (k > 0 ? 2 * k - 1 : -1);
    final sb = 2 * k + 2, sl = k + 1 < j ? 2 * k + 3 : -1;
    final skipIn = pl >= 0 && tokens[insert ? k : k - 1] != token;
    final skipOut = sl >= 0 && tokens[k + 1] != token;
    var x = pl < 0 ? head[0][token] : double.negativeInfinity;
    var sum = double.negativeInfinity;
    for (var t = 0; t < tCount; t++) {
      if (t > 0) {
        var input = _alpha[(t - 1) * s + pb];
        if (skipIn) input = _logAdd(input, _alpha[(t - 1) * s + pl]);
        x = _logAdd(x, input) + head[t][token];
      }
      if (t + 1 < tCount) {
        var next = _beta[(t + 1) * s + sb];
        if (skipOut) next = _logAdd(next, _beta[(t + 1) * s + sl]);
        sum = _logAdd(sum, x + next);
      }
    }
    if (sl < 0) sum = _logAdd(sum, x);
    return sum;
  }
}

double _logAdd(double a, double b) {
  if (a == double.negativeInfinity) return b;
  if (b == double.negativeInfinity) return a;
  final high = math.max(a, b);
  return high + math.log(math.exp(a - high) + math.exp(b - high));
}

/// Merge the word-bar probability into blank, as required for V4's inter1 head.
/// The input is not modified; the word-bar entry is set to negative infinity.
List<List<double>> tajweedFormerMergeWordBarIntoBlank({
  required List<List<double>> logProbabilities,
  required int blankId,
  required int wordBarId,
}) {
  if (blankId < 0 || wordBarId < 0 || blankId == wordBarId) {
    throw ArgumentError('Invalid CTC special token IDs');
  }
  final result = <List<double>>[];
  int? classes;
  for (final frame in logProbabilities) {
    classes ??= frame.length;
    if (frame.length != classes ||
        blankId >= frame.length ||
        wordBarId >= frame.length ||
        frame.any((p) => p.isNaN || p == double.infinity || p > 0)) {
      throw ArgumentError('Invalid CTC log probability head');
    }
    final merged = List<double>.of(frame);
    merged[blankId] = _logAdd(frame[blankId], frame[wordBarId]);
    // The SDK returns float32 values, so a mathematically normalized pair can
    // sum slightly above one after rounding. Reject larger inconsistencies.
    if (merged[blankId] > 0) {
      if (merged[blankId] > 1e-6) {
        throw ArgumentError('Invalid CTC probabilities for blank and word bar');
      }
      merged[blankId] = 0;
    }
    merged[wordBarId] = double.negativeInfinity;
    result.add(List.unmodifiable(merged));
  }
  return List.unmodifiable(result);
}

/// Log P([tokens] | [logProbabilities]) under CTC, summing all valid paths.
///
/// Each row is a frame and contains log probabilities in token-ID order.
/// Repeated adjacent labels must be separated by a blank in the CTC path.
double tajweedFormerCtcLogLikelihood({
  required List<List<double>> logProbabilities,
  required List<int> tokens,
  required int blankId,
}) {
  if (blankId < 0 || tokens.any((id) => id < 0 || id == blankId)) {
    throw ArgumentError('Invalid CTC token or blank ID');
  }
  if (logProbabilities.isEmpty) {
    return tokens.isEmpty ? 0 : double.negativeInfinity;
  }
  final classes = logProbabilities.first.length;
  if (blankId >= classes || tokens.any((id) => id >= classes)) {
    throw ArgumentError('CTC token ID is outside the head vocabulary');
  }
  for (final frame in logProbabilities) {
    if (frame.length != classes ||
        frame.any((p) => p.isNaN || p == double.infinity || p > 0)) {
      throw ArgumentError('Invalid CTC log probability head');
    }
  }
  final states = List<int>.filled(tokens.length * 2 + 1, blankId);
  for (var i = 0; i < tokens.length; i++) {
    states[2 * i + 1] = tokens[i];
  }
  var previous = List<double>.filled(states.length, double.negativeInfinity);
  previous[0] = logProbabilities.first[blankId];
  if (tokens.isNotEmpty) previous[1] = logProbabilities.first[tokens.first];
  for (var t = 1; t < logProbabilities.length; t++) {
    final next = List<double>.filled(states.length, double.negativeInfinity);
    for (var s = 0; s < states.length; s++) {
      var sum = previous[s];
      if (s > 0) sum = _logAdd(sum, previous[s - 1]);
      if (s > 1 && states[s] != blankId && states[s] != states[s - 2]) {
        sum = _logAdd(sum, previous[s - 2]);
      }
      next[s] = sum + logProbabilities[t][states[s]];
    }
    previous = next;
  }
  return states.length == 1
      ? previous[0]
      : _logAdd(previous[states.length - 1], previous[states.length - 2]);
}
