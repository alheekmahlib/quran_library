/// Timing alignment for V4's timing head.
///
/// The chain and Viterbi recurrence follow Quran Lab's published scorer,
/// tajweed/src/score.c at e7abb569a860ebf4455cb05940194889a4c45a5e,
/// distributed under NPL-1.2 (see NOTICE). This computes spans only.
library;

import 'dart:typed_data';

import 'tajweedformer_head.dart';
import 'tajweedformer_reference.dart';

/// Returns end-exclusive frame spans for each unit or null if no path exists.
/// Word boundaries permit a blank; an adjacent token can advance directly.
List<({int start, int end})>? alignTajweedFormerTiming({
  required TajweedFormerCtcHead head,
  required List<TajweedFormerReferenceUnit> reference,
  required int blankId,
}) {
  if (blankId < 0 ||
      blankId >= head.classes ||
      reference.any((u) =>
          u.tokenId < 0 || u.tokenId >= head.classes || u.tokenId == blankId)) {
    throw ArgumentError('Invalid timing vocabulary');
  }
  if (head.frames == 0 || reference.isEmpty) return null;
  final states = <int>[blankId];
  final positions = <int>[];
  for (var k = 0; k < reference.length; k++) {
    if (k > 0 &&
        (reference[k].verseIndex != reference[k - 1].verseIndex ||
            reference[k].wordIndex != reference[k - 1].wordIndex)) {
      states.add(blankId);
    }
    positions.add(states.length);
    states.add(reference[k].tokenId);
  }
  states.add(blankId);
  final n = states.length;
  var scores = Float64List(n)..fillRange(0, n, double.negativeInfinity);
  scores[0] = head.values[blankId];
  scores[1] = head.values[states[1]];
  final back = Uint8List(head.frames * n);
  for (var t = 1; t < head.frames; t++) {
    final next = Float64List(n);
    for (var s = 0; s < n; s++) {
      var best = scores[s], step = 0;
      if (s >= 1 && scores[s - 1] > best) {
        best = scores[s - 1];
        step = 1;
      }
      if (s >= 2 && states[s - 1] == blankId && scores[s - 2] > best) {
        best = scores[s - 2];
        step = 2;
      }
      next[s] = best + head.values[t * head.classes + states[s]];
      back[t * n + s] = step;
    }
    scores = next;
  }
  var state = n - 1;
  if (scores[n - 2] > scores[state]) state = n - 2;
  if (!scores[state].isFinite) return null;
  final starts = List<int>.filled(n, -1), ends = List<int>.filled(n, -1);
  for (var t = head.frames - 1; t >= 0; t--) {
    if (ends[state] < 0) ends[state] = t + 1;
    starts[state] = t;
    if (t > 0) state -= back[t * n + state];
  }
  return [for (final p in positions) (start: starts[p], end: ends[p])];
}
