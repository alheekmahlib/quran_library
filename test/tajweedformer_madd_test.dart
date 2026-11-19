import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_coverage.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_madd.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference.dart';

void main() {
  test('uses the model cuts and reference allowed lengths for a whole verse',
      () {
    const tokens = ['<blk>', 'a', 'i', 'u', 'aa'];
    const units = [
      TajweedFormerReferenceUnit(tokenId: 1, verseIndex: 0, wordIndex: 0),
      TajweedFormerReferenceUnit(tokenId: 2, verseIndex: 0, wordIndex: 0),
      TajweedFormerReferenceUnit(tokenId: 3, verseIndex: 0, wordIndex: 0),
      TajweedFormerReferenceUnit(tokenId: 4, verseIndex: 0, wordIndex: 0),
    ];
    const path = [0, 1, 2, 3, 4, 4, 4, 4, 0];
    final heads = {
      'timing_log_probs': {
        'frames': path.length,
        'classes': tokens.length,
        'frameMs': 20,
        'values': [
          for (final p in path)
            for (var c = 0; c < tokens.length; c++) p == c ? 0.0 : -100.0
        ],
      }
    };
    final calibration = {
      'contexts': {
        'ctx': {
          'madd': {
            'status': 'validated',
            'min_short_vowels': 3,
            'cuts': {
              'fixed2': {'2|4': 3.0, '4|6': 6.0}
            },
          }
        }
      }
    };
    final metadata = {
      '1:1': {
        'tokens': ['a', 'i', 'u', 'aa'],
        'madd': [
          {
            'unit': 3,
            'class': 'fixed2',
            'allowed': [2],
            'name_ar': 'test',
            'name_en': 'test'
          }
        ]
      }
    };
    dynamic evaluate(Map<String, dynamic> refs,
            {List<int> heard = const [1, 2, 3, 4]}) =>
        evaluateTajweedFormerMadd(
          reference: units,
          heard: heard,
          tokenNames: tokens,
          blankId: 0,
          heads: heads,
          calibration: calibration,
          context: 'ctx',
          verses: [(surah: 1, ayah: 1)],
          timingReferences: refs,
        );
    final result = evaluate(metadata);
    expect(result.errors.length, 1);
    expect(result.errors.single.expectedLen, 2);
    expect(result.errors.single.predictedLen, 4);
    expect(result.errors.single.wordIdx, 0);
    expect(result.coverage.state,
        TajweedFormerCoverageState.candidateNeedsReview);
    expect(result.coverage.sites, 1,
        reason: 'the flagged branch must still report its measured sites');
    // ناتج المقيّم نفسه (لا سجل اصطناعي) عبر الدمج: العدادات تصل كاملة.
    final merged = mergeTajweedFormerCoverage(
        [TajweedFormerTakeCoverage(categories: {'madd': result.coverage})]);
    expect(merged.categories['madd']!.sites, 1);
    expect(merged.categories['madd']!.state,
        TajweedFormerCoverageState.candidateNeedsReview);
    // A forced alignment can assign a plausible duration to a missing,
    // replaced, or extra sound; none is safe to classify as a madd error.
    // The category stays unassessed with its reason instead of an
    // empty-looking pass.
    final partial = evaluate(metadata, heard: [1, 2, 3]);
    expect(partial.errors, isEmpty);
    expect(partial.coverage.reason,
        TajweedFormerCoverageReason.pathNotEligible);
    expect(evaluate(metadata, heard: [1, 2, 3, 3]).errors, isEmpty);
    expect(evaluate(metadata, heard: [1, 2, 3, 4, 3]).errors, isEmpty);
    final noCanonical = evaluate({
      '1:1': {
        'tokens': ['a'],
        'madd': []
      }
    });
    expect(noCanonical.errors, isEmpty);
    expect(noCanonical.coverage.reason,
        TajweedFormerCoverageReason.missingReference);
  });

  test('a skipped site keeps the category undecidable, not clear', () {
    const tokens = ['<blk>', 'a', 'i', 'u', 'aa'];
    const units = [
      TajweedFormerReferenceUnit(tokenId: 1, verseIndex: 0, wordIndex: 0),
      TajweedFormerReferenceUnit(tokenId: 2, verseIndex: 0, wordIndex: 0),
      TajweedFormerReferenceUnit(tokenId: 3, verseIndex: 0, wordIndex: 0),
      TajweedFormerReferenceUnit(tokenId: 4, verseIndex: 0, wordIndex: 0),
    ];
    const path = [0, 1, 2, 3, 4, 4, 4, 4, 0];
    final heads = {
      'timing_log_probs': {
        'frames': path.length,
        'classes': tokens.length,
        'frameMs': 20,
        'values': [
          for (final p in path)
            for (var c = 0; c < tokens.length; c++) p == c ? 0.0 : -100.0
        ],
      }
    };
    TajweedFormerCategoryCoverage coverage(List<int> fixedAllowed) {
      final result = evaluateTajweedFormerMadd(
        reference: units,
        heard: const [1, 2, 3, 4],
        tokenNames: tokens,
        blankId: 0,
        heads: heads,
        calibration: const {
          'contexts': {
            'ctx': {
              'madd': {
                'status': 'validated',
                'min_short_vowels': 3,
                'cuts': {
                  'fixed2': {'2|4': 3.0, '4|6': 6.0},
                  'optional4': {'status': 'off'},
                },
              }
            }
          }
        },
        context: 'ctx',
        verses: const [(surah: 1, ayah: 1)],
        timingReferences: {
          '1:1': {
            'tokens': ['a', 'i', 'u', 'aa'],
            'madd': [
              {
                'unit': 3,
                'class': 'optional4',
                'allowed': [4],
                'name_ar': 'اختياري',
                'name_en': 'optional'
              },
              {
                'unit': 2,
                'class': 'fixed2',
                'allowed': fixedAllowed,
                'name_ar': 'لازم',
                'name_en': 'lazem'
              },
            ]
          }
        },
      );
      return result.coverage;
    }

    // الموقع المقيس داخل أطواله المسموحة والموقع الآخر معطّل: غير حاسم.
    final clearWithinAllowed = coverage(const [2, 4, 6]);
    expect(clearWithinAllowed.state,
        TajweedFormerCoverageState.inconclusive,
        reason: 'one site was measured and one is calibration-disabled: '
            'the category is not "checked clear"');
    expect(clearWithinAllowed.reason,
        TajweedFormerCoverageReason.calibrationDisabled);
    expect(clearWithinAllowed.sites, 1);
    expect(clearWithinAllowed.unassessed, 1);

    // مرشّح مُلوَّن (المد المقيس أقصر من المسموح) مع الموقع المعطّل نفسه:
    // المواضع المقيسة والوحدات المتعذرة معًا وسببهما، عبر المقيّم والدمج.
    final flagged = coverage(const [4]);
    expect(flagged.state, TajweedFormerCoverageState.candidateNeedsReview);
    expect(flagged.sites, 1,
        reason: 'the flagged branch must still report its measured sites');
    expect(flagged.unassessed, 1);
    expect(
        flagged.reason, TajweedFormerCoverageReason.calibrationDisabled);
    final merged = mergeTajweedFormerCoverage([
      TajweedFormerTakeCoverage(categories: {'madd': flagged})
    ]);
    expect(merged.categories['madd']!.sites, 1);
    expect(merged.categories['madd']!.unassessed, 1);
    expect(merged.categories['madd']!.state,
        TajweedFormerCoverageState.candidateNeedsReview);
  });
}
