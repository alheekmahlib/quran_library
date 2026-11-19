import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_site_candidates.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_window_evaluation.dart';

void main() {
  test('scores only validated classes and retains the selected edit', () {
    const window =
        TajweedFormerSiteWindow(referenceIndex: 0, wordIndex: 0, edits: [
      TajweedFormerSiteEdit(
          kind: TajweedFormerEditKind.substitute,
          siteClass: 'cons_sub',
          position: 0,
          expected: 2,
          alternative: 3),
      TajweedFormerSiteEdit(
          kind: TajweedFormerEditKind.substitute,
          siteClass: 'cons_sub',
          position: 0,
          expected: 2,
          alternative: 4),
      TajweedFormerSiteEdit(
          kind: TajweedFormerEditKind.insertAfter,
          siteClass: 'vowel_ins',
          position: 0,
          expected: 2,
          alternative: 4),
    ]);
    final config = <String, dynamic>{
      'format': 'quranlab.tajweed-calibration/1',
      'contexts': {
        'ctx': {
          'fusion': {
            'heads': ['log_probs', 'inter1_log_probs'],
            'a': {'default': 0.5},
            'clip': [-30, 30],
            'inter1_prep': "'|' merged into blank"
          },
          'sites': {
            'cons_sub': {
              'status': 'validated',
              'thresholds': {'balanced': -1}
            },
            'vowel_ins': {
              'status': 'off',
              'thresholds': {'balanced': 0}
            },
          },
        }
      },
    };
    final head = [
      [0.1, 0.1, 0.2, 0.4, 0.2].map(math.log).toList()
    ];
    final result = evaluateTajweedFormerWindow(
        window: window,
        referencePath: [2],
        logProbs: head,
        inter1LogProbs: head,
        blankId: 0,
        wordBarId: 1,
        calibration: config,
        context: 'ctx',
        preset: 'balanced');
    expect(result.length, 1);
    expect(result.single.siteClass, 'cons_sub');
    expect(result.single.edit.alternative, 3);
    expect(result.single.evidence.llr, closeTo(math.log(2), 1e-12));
    expect(result.single.evidence.exceedsThreshold, isTrue);
  });
}
