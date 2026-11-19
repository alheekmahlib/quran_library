import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_coverage.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_qalqalah.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference.dart';

void main() {
  const names = ['<blk>', 'a', 'د'];
  const reference = [
    TajweedFormerReferenceUnit(tokenId: 1, verseIndex: 0, wordIndex: 0),
    TajweedFormerReferenceUnit(tokenId: 2, verseIndex: 0, wordIndex: 0),
  ];
  final path = [0, 1, 2, ...List<int>.filled(17, 0)];
  final heads = {
    'timing_log_probs': {
      'frames': path.length,
      'classes': names.length,
      'frameMs': 20,
      'values': [
        for (final token in path)
          for (var i = 0; i < names.length; i++) token == i ? 0.0 : -50.0,
      ],
    },
    'attr_qalqalah': {
      'frames': path.length,
      'classes': 3,
      'frameMs': 20,
      'values': [
        for (final _ in path) ...[0.8, 0.1, 0.1]
      ],
    },
  };
  final calibration = {
    'contexts': {
      'ctx': {
        'qalqalah': {
          'status': 'experimental',
          'preset_tau': {'balanced': 0.5},
          'tau': 0.5,
        },
      },
    },
  };
  final timing = {
    '1:1': {
      'tokens': ['a', 'د']
    }
  };
  dynamic evaluate({
    bool allowExperimental = false,
    List<int> heard = const [1, 2],
    Map<String, dynamic>? metadata,
  }) =>
      evaluateTajweedFormerQalqalah(
        reference: reference,
        heard: heard,
        tokenNames: names,
        blankId: 0,
        heads: heads,
        calibration: calibration,
        context: 'ctx',
        verses: [(surah: 1, ayah: 1)],
        timingReferences: metadata ?? timing,
        allowExperimental: allowExperimental,
      );

  test('experimental evidence is opt-in and retains the displayed position',
      () {
    final blocked = evaluate();
    expect(blocked.errors, isEmpty);
    expect(blocked.coverage.reason,
        TajweedFormerCoverageReason.calibrationExperimental);
    expect(blocked.coverage.state, TajweedFormerCoverageState.notEvaluated);
    final result = evaluate(allowExperimental: true);
    expect(result.errors, hasLength(1));
    expect(result.errors.single.wordIdx, 0);
    expect(result.errors.single.refTajweedRules.single.nameAr, 'القلقلة');
    expect(result.coverage.state,
        TajweedFormerCoverageState.candidateNeedsReview);
    expect(result.coverage.sites, 1,
        reason: 'the flagged branch must still report its measured sites');
  });

  test('does not measure a mismatched or incomplete path', () {
    final mismatched = evaluate(allowExperimental: true, heard: [1]);
    expect(mismatched.errors, isEmpty);
    expect(mismatched.coverage.reason,
        TajweedFormerCoverageReason.pathNotEligible);
    final noReference = evaluate(allowExperimental: true, metadata: {
      '1:1': {
        'tokens': ['د']
      }
    });
    expect(noReference.errors, isEmpty);
    expect(noReference.coverage.reason,
        TajweedFormerCoverageReason.missingReference);
  });

  test('an evidence window outside the head frames has its own reason', () {
    // المرجع القانوني موجود والآية مقارَنة؛ التعذّر أن نافذة الدليل بعد
    // نهاية الحرف تقع خارج رؤوس النموذج — سبب موضعي لا «غياب مرجع».
    final path = [1, 2, 0, 0];
    final localHeads = {
      'timing_log_probs': {
        'frames': path.length,
        'classes': names.length,
        'frameMs': 20,
        'values': [
          for (final token in path)
            for (var i = 0; i < names.length; i++) token == i ? 0.0 : -50.0,
        ],
      },
      'attr_qalqalah': {
        'frames': path.length,
        'classes': 3,
        'frameMs': 20,
        'values': [
          for (final _ in path) ...[0.8, 0.1, 0.1]
        ],
      },
    };
    final result = evaluateTajweedFormerQalqalah(
      reference: reference,
      heard: const [1, 2],
      tokenNames: names,
      blankId: 0,
      heads: localHeads,
      calibration: calibration,
      context: 'ctx',
      verses: const [(surah: 1, ayah: 1)],
      timingReferences: timing,
      allowExperimental: true,
    );
    expect(result.errors, isEmpty);
    expect(result.coverage.state, TajweedFormerCoverageState.inconclusive);
    expect(result.coverage.reason, TajweedFormerCoverageReason.pathNotEligible,
        reason: 'the canonical verse matched; the site itself could not be '
            'measured');
    expect(result.coverage.unassessed, 1);
  });
}
