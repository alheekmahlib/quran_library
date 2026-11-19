import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/models/recitation_result.dart';
import 'package:quran_library/src/tasmee/engine/recitation_session.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_coverage.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_ghunna.dart';

void main() {
  test('category coverage serializes and restores losslessly', () {
    const coverage = TajweedFormerTakeCoverage(categories: {
      'cons_sub': TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.candidateNeedsReview,
        sites: 3,
      ),
      'madd': TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.notEvaluated,
        reason: TajweedFormerCoverageReason.pathNotEligible,
      ),
      'qalqalah': TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.inconclusive,
        reason: TajweedFormerCoverageReason.missingReference,
      ),
      'gemination': TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.evaluatedNoCandidate,
        sites: 0,
      ),
    });
    final restored = TajweedFormerTakeCoverage.fromJson(
        jsonDecode(jsonEncode(coverage.toJson())) as Map<String, dynamic>);
    expect(restored, coverage);
  });

  test('an unexplained non-decision cannot be restored', () {
    expect(
      () => TajweedFormerCategoryCoverage.fromJson(
          {'state': TajweedFormerCoverageState.notEvaluated.name}),
      throwsFormatException,
    );
    expect(
      () => TajweedFormerCategoryCoverage.fromJson(
          {'state': TajweedFormerCoverageState.inconclusive.name}),
      throwsFormatException,
    );
    expect(
      () => TajweedFormerCategoryCoverage.fromJson({'state': 'invented'}),
      throwsFormatException,
    );
  });

  test('unassessed coverage lists every category with the shared reason', () {
    final coverage =
        unassessedTajweedFormerCoverage(TajweedFormerCoverageReason.missingHead);
    expect(coverage.categories.keys,
        containsAll(tajweedFormerCoverageCategoryKeys));
    expect(
      coverage.categories.values.every((entry) =>
          entry.state == TajweedFormerCoverageState.notEvaluated &&
          entry.reason == TajweedFormerCoverageReason.missingHead),
      isTrue,
    );
  });

  test('merging never lets an unassessed segment mask an assessed one', () {
    final merged = mergeTajweedFormerCoverage([
      unassessedTajweedFormerCoverage(
          TajweedFormerCoverageReason.noMatchedPath),
      const TajweedFormerTakeCoverage(categories: {
        'cons_sub': TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.evaluatedNoCandidate,
          sites: 4,
        ),
        'madd': TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.inconclusive,
          reason: TajweedFormerCoverageReason.missingReference,
        ),
      }),
      const TajweedFormerTakeCoverage(categories: {
        'cons_sub': TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.candidateNeedsReview,
          sites: 2,
        ),
      }),
    ]);
    expect(
        merged.categories['cons_sub']!.state,
        TajweedFormerCoverageState.candidateNeedsReview,
        reason: 'a flagged candidate outranks a checked-clear segment');
    expect(merged.categories['cons_sub']!.sites, 6);
    expect(merged.categories['cons_sub']!.unassessed, 1,
        reason: 'the segment that could not assess it is still counted');
    expect(merged.categories['madd']!.state,
        TajweedFormerCoverageState.inconclusive);
    expect(merged.categories['madd']!.reason,
        TajweedFormerCoverageReason.missingReference);
    // A category only present in the unassessed segment keeps its reason.
    expect(
        merged.categories['qalqalah']!.reason,
        TajweedFormerCoverageReason.noMatchedPath,
        reason: 'an unassessed category must not look checked-clear');
  });

  test('a segment assessed where another failed is partial, never clear', () {
    final merged = mergeTajweedFormerCoverage([
      unassessedTajweedFormerCoverage(
          TajweedFormerCoverageReason.noMatchedPath),
      const TajweedFormerTakeCoverage(categories: {
        'madd': TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.evaluatedNoCandidate,
          sites: 5,
        ),
      }),
    ]);
    final madd = merged.categories['madd']!;
    expect(madd.state, TajweedFormerCoverageState.inconclusive,
        reason: 'assessed in one segment and blocked in another: the '
            'failure must not be absorbed into "checked clear"');
    expect(madd.reason, TajweedFormerCoverageReason.noMatchedPath);
    expect(madd.sites, 5);
    expect(madd.unassessed, 1);
  });

  test('a category clear in every segment that mentions it stays clear', () {
    final merged = mergeTajweedFormerCoverage([
      const TajweedFormerTakeCoverage(categories: {
        'madd': TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.evaluatedNoCandidate,
          sites: 3,
        ),
      }),
      const TajweedFormerTakeCoverage(categories: {
        'madd': TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.evaluatedNoCandidate,
          sites: 2,
        ),
      }),
    ]);
    final madd = merged.categories['madd']!;
    expect(madd.state, TajweedFormerCoverageState.evaluatedNoCandidate);
    expect(madd.sites, 5);
    expect(madd.unassessed, isNull);
  });

  test('a single partial entry keeps both counters through the merge', () {
    final merged = mergeTajweedFormerCoverage([
      const TajweedFormerTakeCoverage(categories: {
        'madd': TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.inconclusive,
          reason: TajweedFormerCoverageReason.missingReference,
          sites: 2,
          unassessed: 1,
        ),
      }),
    ]);
    final madd = merged.categories['madd']!;
    expect(madd.state, TajweedFormerCoverageState.inconclusive);
    expect(madd.sites, 2,
        reason: 'the sites an inconclusive segment did assess must survive');
    expect(madd.unassessed, 1);
    expect(madd.reason, TajweedFormerCoverageReason.missingReference);
  });

  test('a flagged entry with unassessed units keeps them and their cause',
      () {
    final single = mergeTajweedFormerCoverage([
      const TajweedFormerTakeCoverage(categories: {
        'qalqalah': TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.candidateNeedsReview,
          reason: TajweedFormerCoverageReason.pathNotEligible,
          sites: 3,
          unassessed: 1,
        ),
      }),
    ]);
    final alone = single.categories['qalqalah']!;
    expect(alone.state, TajweedFormerCoverageState.candidateNeedsReview);
    expect(alone.unassessed, 1,
        reason: 'a flag must not erase that another unit was unassessable');
    expect(alone.sites, 3);
    expect(alone.reason, TajweedFormerCoverageReason.pathNotEligible);

    final merged = mergeTajweedFormerCoverage([
      const TajweedFormerTakeCoverage(categories: {
        'qalqalah': TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.candidateNeedsReview,
          reason: TajweedFormerCoverageReason.pathNotEligible,
          sites: 3,
          unassessed: 1,
        ),
      }),
      const TajweedFormerTakeCoverage(categories: {
        'qalqalah': TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.evaluatedNoCandidate,
          sites: 4,
        ),
      }),
    ]);
    final combined = merged.categories['qalqalah']!;
    expect(combined.state, TajweedFormerCoverageState.candidateNeedsReview);
    expect(combined.sites, 7);
    expect(combined.unassessed, 1);
    expect(combined.reason, TajweedFormerCoverageReason.pathNotEligible);
  });

  test('result JSON keeps coverage beside the completeness flag', () {
    const result = RecitationResult(
      uthmaniText: 'نص',
      assessmentComplete: false,
      matchedWordSpans: [(verseIdx: 0, wordIdx: 1)],
      coverage: TajweedFormerTakeCoverage(categories: {
        'ghunna': TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.notEvaluated,
          reason: TajweedFormerCoverageReason.signalUnsupported,
        ),
      }),
    );
    final restored =
        RecitationResult.fromJson(jsonDecode(jsonEncode(result.toJson()))
            as Map<String, dynamic>);
    expect(restored.assessmentComplete, isFalse);
    expect(restored.coverage, result.coverage);
    expect(restored.coverage!.categories['ghunna']!.reason,
        TajweedFormerCoverageReason.signalUnsupported);
  });

  test('legacy JSON without coverage restores with none and keeps its flag',
      () {
    final legacyPartial = RecitationResult.fromJson({
      'uthmani_text': 'نص',
      'assessment_complete': false,
    });
    expect(legacyPartial.coverage, isNull);
    expect(legacyPartial.assessmentComplete, isFalse,
        reason: 'a restored partial V4 result must not become complete');
    final legacyComplete = RecitationResult.fromJson({'uthmani_text': 'نص'});
    expect(legacyComplete.coverage, isNull);
    expect(legacyComplete.assessmentComplete, isTrue);
  });

  group('mergePartialV4Results keeps coverage and failure reasons', () {
    RecitationResult segment({
      required bool match,
      TajweedFormerTakeCoverage? coverage,
    }) =>
        RecitationResult(
          uthmaniText: match ? 'نص' : null,
          noMatchMessage: match ? null : 'تعذّر مطابقة التلاوة.',
          assessmentComplete: false,
          matchedWordSpans:
              match ? const [(verseIdx: 0, wordIdx: 0)] : const [],
          coverage: coverage,
        );

    test('a failed segment does not erase the assessed one', () {
      final merged = mergePartialV4Results([
        segment(
          match: false,
          coverage: unassessedTajweedFormerCoverage(
              TajweedFormerCoverageReason.noMatchedPath),
        ),
        segment(
          match: true,
          coverage: const TajweedFormerTakeCoverage(categories: {
            'cons_sub': TajweedFormerCategoryCoverage(
              state: TajweedFormerCoverageState.evaluatedNoCandidate,
              sites: 5,
            ),
          }),
        ),
      ]);
      expect(merged.hasMatch, isTrue);
      expect(merged.assessmentComplete, isFalse);
      final consSub = merged.coverage!.categories['cons_sub']!;
      expect(consSub.state, TajweedFormerCoverageState.inconclusive,
          reason: 'the failed segment must surface, not vanish under the '
              'assessed one');
      expect(consSub.reason, TajweedFormerCoverageReason.noMatchedPath);
      expect(consSub.sites, 5);
      expect(consSub.unassessed, 1);
    });

    test('all-unmatched keeps the last failure message and its reasons', () {
      final merged = mergePartialV4Results([
        segment(
          match: false,
          coverage: unassessedTajweedFormerCoverage(
              TajweedFormerCoverageReason.noMatchedPath),
        ),
        segment(
          match: false,
          coverage: unassessedTajweedFormerCoverage(
              TajweedFormerCoverageReason.missingHead),
        ),
      ]);
      expect(merged.hasMatch, isFalse);
      expect(merged.noMatchMessage, 'تعذّر مطابقة التلاوة.');
      // The stronger evidence (heads existed but matched no path in segment
      // one) is kept per the merge precedence for inconclusive states.
      expect(merged.coverage, isNotNull);
    });

    test('no segments at all still reports an unassessed take', () {
      final merged = mergePartialV4Results([]);
      expect(merged.noMatchMessage, 'لم تُسجّل تلاوة.');
      expect(merged.assessmentComplete, isFalse);
      expect(
          merged.coverage!.categories['madd']!.reason,
          TajweedFormerCoverageReason.noMatchedPath,
          reason: 'an empty take must not look like a checked-clear one');
    });
  });

  group('ghunna and ikhfa stay declared-unsupported', () {
    test('no calibration section means no signal, not an empty verdict', () {
      final coverage = describeTajweedFormerGhunnaCoverage(
        calibration: const {
          'contexts': {
            'ctx': {'qalqalah': {'status': 'experimental'}}
          }
        },
        context: 'ctx',
      );
      expect(coverage.state, TajweedFormerCoverageState.notEvaluated);
      expect(coverage.reason, TajweedFormerCoverageReason.signalUnsupported);
    });

    test('a served calibration section flips to evaluator-not-implemented',
        () {
      final coverage = describeTajweedFormerGhunnaCoverage(
        calibration: const {
          'contexts': {
            'ctx': {
              'ghunna': {'status': 'validated', 'tau': 0.5}
            }
          }
        },
        context: 'ctx',
      );
      expect(coverage.state, TajweedFormerCoverageState.notEvaluated);
      expect(
          coverage.reason, TajweedFormerCoverageReason.evaluatorNotImplemented,
          reason: 'the extension path must stay visible, never auto-enable');
    });

    test('an off ghunna section reads as disabled', () {
      final coverage = describeTajweedFormerGhunnaCoverage(
        calibration: const {
          'contexts': {
            'ctx': {
              'ghunna': {'status': 'off'}
            }
          }
        },
        context: 'ctx',
      );
      expect(coverage.reason, TajweedFormerCoverageReason.calibrationDisabled);
    });
  });
}
