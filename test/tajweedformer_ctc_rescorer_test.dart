import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_ctc.dart';

void main() {
  test('single edits match full CTC including repeats and sequence boundaries',
      () {
    final random = Random(391);
    for (var trial = 0; trial < 300; trial++) {
      final frames = random.nextInt(12);
      final tokens =
          List.generate(1 + random.nextInt(5), (_) => 1 + random.nextInt(3));
      final head = List.generate(
          frames,
          (_) => List.generate(4, (_) {
                return random.nextInt(12) == 0
                    ? double.negativeInfinity
                    : log(.01 + random.nextDouble() * .98);
              }));
      final scorer = TajweedFormerCtcRescorer(head, tokens, 0);
      double full(List<int> path) => tajweedFormerCtcLogLikelihood(
          logProbabilities: head, tokens: path, blankId: 0);
      void same(double actual, double expected) {
        if (expected == double.negativeInfinity) {
          expect(actual, expected);
        } else {
          expect(actual, closeTo(expected, 1e-9));
        }
      }

      for (var i = 0; i < tokens.length; i++) {
        same(scorer.delete(i), full(List.of(tokens)..removeAt(i)));
        for (var token = 1; token <= 3; token++) {
          same(scorer.replace(i, token), full(List.of(tokens)..[i] = token));
          same(scorer.insertAfter(i, token),
              full(List.of(tokens)..insert(i + 1, token)));
        }
      }
    }
  });
}
