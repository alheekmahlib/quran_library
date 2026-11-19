import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_site_evidence.dart';

void main() {
  test('chooses the best fused alternative, not a different edit per head', () {
    final main = [
      [0.1, 0.05, 0.25, 0.5, 0.1].map(math.log).toList()
    ];
    final inter = [
      [0.1, 0.05, 0.25, 0.1, 0.5].map(math.log).toList()
    ];
    final result = evaluateTajweedFormerSite(
      logProbs: main,
      inter1LogProbs: inter,
      expected: [2],
      alternatives: [
        [3],
        [4]
      ],
      blankId: 0,
      wordBarId: 1,
      fusionWeight: 0.5,
      threshold: 0,
      clipMin: -30,
      clipMax: 30,
      enabled: true,
    )!;
    expect(result.llr, closeTo(math.log(0.8) / 2, 1e-12));
    expect(result.exceedsThreshold, isFalse);
  });

  test('removes word bars from the target for both CTC heads', () {
    final head = [
      [0.1, 0.1, 0.5, 0.2, 0.1].map(math.log).toList(),
      [0.1, 0.1, 0.1, 0.4, 0.3].map(math.log).toList(),
    ];
    final result = evaluateTajweedFormerSite(
      logProbs: head,
      inter1LogProbs: head,
      expected: [2, 1, 3],
      alternatives: [
        [2, 1, 4]
      ],
      blankId: 0,
      wordBarId: 1,
      fusionWeight: 0.5,
      threshold: 0,
      clipMin: -30,
      clipMax: 30,
      enabled: true,
    );
    expect(result?.llr, closeTo(math.log(0.3 / 0.4), 1e-12));
  });

  test('fuses per-head likelihood ratios and applies the calibrated threshold',
      () {
    // Classes are blank, word bar, expected, alternative.
    final mainHead = [
      [0.1, 0.1, 0.2, 0.6].map(math.log).toList()
    ];
    final interHead = [
      [0.1, 0.1, 0.4, 0.4].map(math.log).toList()
    ];
    final result = evaluateTajweedFormerSite(
      logProbs: mainHead,
      inter1LogProbs: interHead,
      expected: [2],
      alternatives: [
        [3]
      ],
      blankId: 0,
      wordBarId: 1,
      fusionWeight: 0.5,
      threshold: 0.5,
      clipMin: -30,
      clipMax: 30,
      enabled: true,
    )!;
    expect(result.llr, closeTo(math.log(3) / 2, 1e-12));
    expect(result.exceedsThreshold, isTrue);
  });

  test(
      'off classes are not evaluated; invalid evidence never becomes a verdict',
      () {
    TajweedFormerSiteEvidence? evaluate(bool enabled) =>
        evaluateTajweedFormerSite(
          logProbs: [],
          inter1LogProbs: [],
          expected: [2],
          alternatives: [
            [3]
          ],
          blankId: 0,
          wordBarId: 1,
          fusionWeight: 0.5,
          threshold: 0,
          clipMin: -30,
          clipMax: 30,
          enabled: enabled,
        );
    expect(evaluate(false), isNull);
    expect(() => evaluate(true), throwsStateError);
  });
}
