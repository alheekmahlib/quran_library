import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_coverage.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_gemination.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference.dart';

void main() {
  test('scores a canonical held consonant only with validated calibration', () {
    const reference = [
      TajweedFormerReferenceUnit(tokenId: 1, verseIndex: 0, wordIndex: 0),
    ];
    final heads = {
      'timing_log_probs': {
        'frames': 3,
        'classes': 2,
        'frameMs': 20,
        'values': [0.0, -50.0, -50.0, 0.0, 0.0, -50.0],
      },
      'gem': {
        'frames': 3,
        'classes': 2,
        'frameMs': 20,
        'values': [0.9, 0.1, 0.9, 0.1, 0.9, 0.1],
      },
    };
    ({List<dynamic> errors, dynamic coverage}) evaluate(String status,
        {List<int> heard = const [1]}) {
      final result = evaluateTajweedFormerGemination(
        reference: reference,
        heard: heard,
        tokenNames: ['<blk>', 'د'],
        blankId: 0,
        heads: heads,
        calibration: {
          'contexts': {
            'ctx': {
              'gemination': {'status': status, 'tau': 0.5},
            },
          },
        },
        context: 'ctx',
        verses: [(surah: 1, ayah: 1)],
        timingReferences: {
          '1:1': {
            'tokens': ['د'],
            'geminated': [0]
          },
        },
      );
      return (errors: result.errors, coverage: result.coverage);
    }

    final off = evaluate('off');
    expect(off.errors, isEmpty);
    expect(off.coverage.reason, TajweedFormerCoverageReason.calibrationDisabled);
    final experimental = evaluate('experimental');
    expect(experimental.errors, isEmpty);
    expect(experimental.coverage.reason,
        TajweedFormerCoverageReason.calibrationExperimental);
    expect(evaluate('validated', heard: []).errors, isEmpty);
    final result = evaluate('validated');
    expect(result.errors, hasLength(1));
    expect(result.errors.single.refTajweedRules.single.nameAr, 'الشدة');
    expect(result.errors.single.wordIdx, 0);
    expect(result.coverage.state,
        TajweedFormerCoverageState.candidateNeedsReview);
    expect(result.coverage.sites, 1,
        reason: 'the flagged branch must still report its measured sites');
  });

  test('a canonical verse without a position list is a reference gap', () {
    // آية قانونية (الرموز تطابق) لكن بلا قائمة مواضع شدة: التعذّر مرجعي
    // على مستوى الآية، لا تعذّر محاذاة موضعي.
    const reference = [
      TajweedFormerReferenceUnit(tokenId: 1, verseIndex: 0, wordIndex: 0),
    ];
    final heads = {
      'timing_log_probs': {
        'frames': 3,
        'classes': 2,
        'frameMs': 20,
        'values': [0.0, -50.0, -50.0, 0.0, 0.0, -50.0],
      },
      'gem': {
        'frames': 3,
        'classes': 2,
        'frameMs': 20,
        'values': [0.9, 0.1, 0.9, 0.1, 0.9, 0.1],
      },
    };
    final result = evaluateTajweedFormerGemination(
      reference: reference,
      heard: const [1],
      tokenNames: const ['<blk>', 'د'],
      blankId: 0,
      heads: heads,
      calibration: const {
        'contexts': {
          'ctx': {
            'gemination': {'status': 'validated', 'tau': 0.5},
          },
        },
      },
      context: 'ctx',
      verses: const [(surah: 1, ayah: 1)],
      timingReferences: const {
        '1:1': {
          'tokens': ['د'],
        },
      },
    );
    expect(result.errors, isEmpty);
    expect(result.coverage.state, TajweedFormerCoverageState.inconclusive);
    expect(result.coverage.reason,
        TajweedFormerCoverageReason.missingReference);
    expect(result.coverage.unassessed, 1);
  });
}
