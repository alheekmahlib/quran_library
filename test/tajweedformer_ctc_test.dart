import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_ctc.dart';

// Enumerating every path provides an independent oracle for tiny CTC heads.
double exhaustiveProbability(List<List<double>> frames, List<int> target) {
  var total = 0.0;
  void visit(int t, List<int> path, double probability) {
    if (t == frames.length) {
      final collapsed = <int>[];
      var previous = -1;
      for (final id in path) {
        if (id != 0 && id != previous) collapsed.add(id);
        previous = id;
      }
      if (collapsed.length == target.length &&
          List.generate(target.length, (i) => collapsed[i] == target[i])
              .every((equal) => equal)) {
        total += probability;
      }
      return;
    }
    for (var id = 0; id < frames[t].length; id++) {
      visit(t + 1, [...path, id], probability * frames[t][id]);
    }
  }

  visit(0, [], 1);
  return total;
}

void main() {
  test('handles float32 rounding when merging the word bar', () {
    final merged = tajweedFormerMergeWordBarIntoBlank(
      logProbabilities: [
        [-0.69314716, -0.69314716]
      ],
      blankId: 0,
      wordBarId: 1,
    );
    expect(merged[0][0], 0);
    expect(
      () => tajweedFormerMergeWordBarIntoBlank(
        logProbabilities: [
          [-0.1, -0.1]
        ],
        blankId: 0,
        wordBarId: 1,
      ),
      throwsArgumentError,
    );
  });

  test('merges word bars into blank in probability space without mutation', () {
    final input = [
      [math.log(0.2), math.log(0.3), math.log(0.5)]
    ];
    final merged = tajweedFormerMergeWordBarIntoBlank(
      logProbabilities: input,
      blankId: 0,
      wordBarId: 1,
    );
    expect(math.exp(merged[0][0]), closeTo(0.5, 1e-12));
    expect(merged[0][1], double.negativeInfinity);
    expect(math.exp(merged[0][2]), closeTo(0.5, 1e-12));
    expect(math.exp(input[0][0]), closeTo(0.2, 1e-12));
  });

  test('matches exhaustive CTC path probabilities including repeats', () {
    const frames = [
      [0.3, 0.5, 0.2],
      [0.4, 0.4, 0.2],
      [0.2, 0.6, 0.2],
      [0.5, 0.2, 0.3],
    ];
    final logFrames = frames.map((f) => f.map(math.log).toList()).toList();
    for (final target in <List<int>>[
      [],
      [1],
      [1, 1],
      [1, 2],
      [2, 1, 2]
    ]) {
      final result = tajweedFormerCtcLogLikelihood(
          logProbabilities: logFrames, tokens: target, blankId: 0);
      expect(math.exp(result),
          closeTo(exhaustiveProbability(frames, target), 1e-12));
    }
  });

  test('handles impossible and empty sequences', () {
    expect(
        tajweedFormerCtcLogLikelihood(
            logProbabilities: [], tokens: [], blankId: 0),
        0);
    expect(
        tajweedFormerCtcLogLikelihood(
            logProbabilities: [], tokens: [1], blankId: 0),
        double.negativeInfinity);
    expect(
        tajweedFormerCtcLogLikelihood(logProbabilities: [
          [-1, -1]
        ], tokens: [
          1,
          1
        ], blankId: 0),
        double.negativeInfinity);
  });

  test('rejects malformed heads and token IDs', () {
    expect(
        () => tajweedFormerCtcLogLikelihood(logProbabilities: [
              [0, -1],
              [0]
            ], tokens: [
              1
            ], blankId: 0),
        throwsArgumentError);
    expect(
        () => tajweedFormerCtcLogLikelihood(logProbabilities: [
              [0, double.nan]
            ], tokens: [
              1
            ], blankId: 0),
        throwsArgumentError);
    expect(
        () => tajweedFormerCtcLogLikelihood(logProbabilities: [
              [0, -1]
            ], tokens: [
              0
            ], blankId: 0),
        throwsArgumentError);
  });
}
