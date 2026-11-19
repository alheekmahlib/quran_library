import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_coverage.dart';
import 'package:quran_library/src/tasmee/engine/models/tasmee_tolerance.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_evaluation.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference.dart';

void main() {
  const names = [
    '<blk>',
    '|',
    'ء',
    'ب',
    'ت',
    'ث',
    'ج',
    'ح',
    'خ',
    'د',
    'ذ',
    'ر',
    'ز',
    'س',
    'ش',
    'ص',
    'ض',
    'ط',
    'ظ',
    'ع',
    'غ',
    'ف',
    'ق',
    'ك',
    'ل',
    'م',
    'ن',
    'ه',
    'و',
    'ي',
    'ں',
    'a',
    'i',
    'u',
    'aa',
    'ii',
    'uu',
    '<foreign>'
  ];
  const reference = [
    TajweedFormerReferenceUnit(tokenId: 3, verseIndex: 0, wordIndex: 0)
  ];
  final values = List<double>.filled(names.length, math.log(0.001));
  values[3] = math.log(0.01);
  values[4] = math.log(0.8);
  final head = {
    'frames': 1,
    'classes': names.length,
    'frameMs': 40,
    'values': values
  };
  final calibration = {
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
            'thresholds': {'balanced': 0.5}
          },
          'cons_del': {
            'status': 'off',
            'thresholds': {'balanced': 0.5}
          },
          'vowel_ins': {
            'status': 'off',
            'thresholds': {'balanced': 0.5}
          },
        }
      }
    }
  };
  test('independent sensitivity changes consonant evidence and skips vowels',
      () {
    final config = jsonDecode(jsonEncode(calibration)) as Map<String, dynamic>;
    final sites = ((config['contexts'] as Map)['ctx'] as Map)['sites'] as Map;
    sites['cons_sub']['thresholds'] = {
      'strict': 100.0,
      'balanced': 0.5,
      'sensitive': 0.5,
    };
    sites['cons_del']['thresholds'] = {
      'strict': 100.0,
      'balanced': 0.5,
      'sensitive': 0.5,
    };
    ({List<dynamic> errors, dynamic coverage}) evaluate(
        TasmeeToleranceLevel level) {
      final result = evaluateTajweedFormerTake(
        reference: reference,
        heard: [4],
        tokenNames: names,
        blankId: 0,
        wordBarId: 1,
        heads: {'log_probs': head, 'inter1_log_probs': head},
        calibration: config,
        context: 'ctx',
        surah: 1,
        ayah: 1,
        tolerance: TasmeeToleranceProfile(
            letters: level, tashkeel: TasmeeToleranceLevel.skip),
      );
      return (errors: result.errors, coverage: result.coverage);
    }

    final lenient = evaluate(TasmeeToleranceLevel.lenient);
    final strict = evaluate(TasmeeToleranceLevel.strict);
    expect(lenient.errors, isEmpty);
    expect(strict.errors, hasLength(1));
    for (final key in [
      'vowel_sub',
      'vowel_del',
      'vowel_ins',
      'short_to_long',
      'long_to_short'
    ]) {
      expect(
          strict.coverage[key].state, TajweedFormerCoverageState.notEvaluated);
      expect(strict.coverage[key].reason,
          TajweedFormerCoverageReason.skippedByUser);
    }
    expect(strict.coverage['cons_sub'].state,
        TajweedFormerCoverageState.candidateNeedsReview);
  });

  test('reports a calibrated consonant substitution at the displayed word', () {
    final result = evaluateTajweedFormerTake(
      reference: reference,
      heard: [4],
      tokenNames: names,
      blankId: 0,
      wordBarId: 1,
      heads: {'log_probs': head, 'inter1_log_probs': head},
      calibration: calibration,
      context: 'ctx',
      surah: 1,
      ayah: 1,
    );
    expect(result.incomplete, isFalse);
    expect(result.errors.single.wordIdx, 0);
    expect(result.errors.single.errorType, 'normal');
    expect(result.errors.single.predictedPh, 'ت');
    expect(result.coverage['cons_sub']!.state,
        TajweedFormerCoverageState.candidateNeedsReview);
    expect(result.coverage['cons_del']!.reason,
        TajweedFormerCoverageReason.calibrationDisabled);
    expect(result.coverage['vowel_ins']!.reason,
        TajweedFormerCoverageReason.calibrationDisabled);
    // Classes with no candidate in this one-consonant path are reported
    // with a reason instead of missing from the map: their absence from
    // the calibration is the precise cause here.
    expect(result.coverage['vowel_sub']!.state,
        TajweedFormerCoverageState.notEvaluated);
    expect(result.coverage['vowel_sub']!.reason,
        TajweedFormerCoverageReason.missingCalibration);
    expect(result.coverage['vowel_del']!.reason,
        TajweedFormerCoverageReason.missingCalibration);
    expect(result.coverage['unsupported_differences']!.state,
        TajweedFormerCoverageState.evaluatedNoCandidate);
  });
  test('scores acoustic evidence even when the decoder matches the reference',
      () {
    final result = evaluateTajweedFormerTake(
      reference: reference,
      heard: [3],
      tokenNames: names,
      blankId: 0,
      wordBarId: 1,
      heads: {'log_probs': head, 'inter1_log_probs': head},
      calibration: calibration,
      context: 'ctx',
      surah: 1,
      ayah: 1,
    );
    expect(result.errors.single.predictedPh, 'ت');
  });
  test('reports only the strongest flagged class in a window', () {
    final config = jsonDecode(jsonEncode(calibration)) as Map<String, dynamic>;
    final sites = ((config['contexts'] as Map)['ctx'] as Map)['sites'] as Map;
    sites['cons_del'] = {
      'status': 'validated',
      'thresholds': {'balanced': -10}
    };
    final result = evaluateTajweedFormerTake(
      reference: reference,
      heard: [3],
      tokenNames: names,
      blankId: 0,
      wordBarId: 1,
      heads: {'log_probs': head, 'inter1_log_probs': head},
      calibration: config,
      context: 'ctx',
      surah: 1,
      ayah: 1,
    );
    expect(result.errors, hasLength(1));
    expect(result.errors.single.speechErrorType, 'replace');
  });
  test('does not label an unsupported consonant insertion as correct', () {
    final result = evaluateTajweedFormerTake(
      reference: reference,
      heard: [3, 4],
      tokenNames: names,
      blankId: 0,
      wordBarId: 1,
      heads: {'log_probs': head, 'inter1_log_probs': head},
      calibration: calibration,
      context: 'ctx',
      surah: 1,
      ayah: 1,
    );
    expect(result.incomplete, isTrue);
    // The incompleteness is preserved as coverage, not lost to an empty
    // error list that could read as "checked and clear".
    expect(result.coverage['unsupported_differences']!.state,
        TajweedFormerCoverageState.inconclusive);
    expect(result.coverage['unsupported_differences']!.reason,
        TajweedFormerCoverageReason.unsupportedDifference);
  });

  test('a clean validated class reports assessed sites, not an empty guess',
      () {
    final result = evaluateTajweedFormerTake(
      reference: reference,
      heard: [3],
      tokenNames: names,
      blankId: 0,
      wordBarId: 1,
      heads: {'log_probs': head, 'inter1_log_probs': head},
      calibration: calibration,
      context: 'ctx',
      surah: 1,
      ayah: 1,
    );
    expect(result.coverage['cons_sub']!.state,
        TajweedFormerCoverageState.candidateNeedsReview);
    // عدد المواقع لا عدد بدائل التعديل: 27 بديلًا لصنف استبدال الحروف
    // على موضع واحد = موقع واحد.
    expect(result.coverage['cons_sub']!.sites, 1);
  });

  test('a calibrated class absent from this path is reported unattempted', () {
    final config = jsonDecode(jsonEncode(calibration)) as Map<String, dynamic>;
    final sites = ((config['contexts'] as Map)['ctx'] as Map)['sites'] as Map;
    sites['vowel_sub'] = {
      'status': 'validated',
      'thresholds': {'balanced': 0.5}
    };
    final result = evaluateTajweedFormerTake(
      reference: reference,
      heard: [3],
      tokenNames: names,
      blankId: 0,
      wordBarId: 1,
      heads: {'log_probs': head, 'inter1_log_probs': head},
      calibration: config,
      context: 'ctx',
      surah: 1,
      ayah: 1,
    );
    expect(result.coverage['vowel_sub']!.reason,
        TajweedFormerCoverageReason.noEligibleSites,
        reason: 'calibrated but no vowel site exists in this path');
  });

  test('a decoded difference on an uncalibrated class records its reason', () {
    // صنف له مرشحون في المسار لكن المعايرة لا تعرفه: الفرق المنطوق عليه
    // لا يفشل التقييم باستثناء، بل يُسجَّل غير حاسم بسببه.
    final config = jsonDecode(jsonEncode(calibration)) as Map<String, dynamic>;
    final sites = ((config['contexts'] as Map)['ctx'] as Map)['sites'] as Map;
    sites.remove('cons_del');
    final result = evaluateTajweedFormerTake(
      reference: reference,
      heard: [],
      tokenNames: names,
      blankId: 0,
      wordBarId: 1,
      heads: {'log_probs': head, 'inter1_log_probs': head},
      calibration: config,
      context: 'ctx',
      surah: 1,
      ayah: 1,
    );
    expect(result.incomplete, isTrue);
    expect(result.coverage['cons_del']!.state,
        TajweedFormerCoverageState.inconclusive);
    expect(result.coverage['cons_del']!.reason,
        TajweedFormerCoverageReason.missingCalibration);
    // لا خطأ محذوفًا من الصنف غير المعاير؛ ما قد يُلوَّن من صنف معاير
    // آخر شأنه الخاص.
    expect(
      result.errors.every((e) => e.speechErrorType != 'delete'),
      isTrue,
    );
  });
}
