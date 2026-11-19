import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_calibration.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_site_evidence.dart';

Map<String, dynamic> calibration(String status) => {
      'format': 'quranlab.tajweed-calibration/1',
      'contexts': {
        'ctx': {
          'fusion': {
            'heads': ['log_probs', 'inter1_log_probs'],
            'a': {'cons_sub': 0.5, 'default': 0.8},
            'clip': [-30, 30],
            'inter1_prep': "'|' merged into blank (logaddexp), then -inf",
          },
          'sites': {
            'cons_sub': {
              'status': status,
              'thresholds': {'balanced': 0.5}
            },
          },
        },
      },
    };

void main() {
  TajweedFormerSiteCalibration read(String status) =>
      readTajweedFormerSiteCalibration(
          calibration: calibration(status),
          context: 'ctx',
          preset: 'balanced',
          siteClass: 'cons_sub');

  test('reads the model-provided weights and evaluates validated classes', () {
    final c = read('validated');
    expect(c.isValidated, isTrue);
    final evidence = evaluateCalibratedTajweedFormerSite(
      logProbs: [
        [0.1, 0.1, 0.2, 0.6].map(math.log).toList()
      ],
      inter1LogProbs: [
        [0.1, 0.1, 0.4, 0.4].map(math.log).toList()
      ],
      expected: [2],
      alternatives: [
        [3]
      ],
      blankId: 0,
      wordBarId: 1,
      calibration: c,
    );
    expect(evidence?.exceedsThreshold, isTrue);
  });

  test('reused expected likelihood gives the same calibrated evidence', () {
    final rows = [
      [0.1, 0.1, 0.2, 0.6].map(math.log).toList()
    ];
    final settings = read('validated');
    final direct = evaluateCalibratedTajweedFormerSite(
      logProbs: rows,
      inter1LogProbs: rows,
      expected: [2],
      alternatives: [
        [3]
      ],
      blankId: 0,
      wordBarId: 1,
      calibration: settings,
    );
    final cached = TajweedFormerSiteScorer(
      logProbs: rows,
      inter1LogProbs: rows,
      expected: [2],
      blankId: 0,
      wordBarId: 1,
    ).evaluate(alternatives: [
      [3]
    ], calibration: settings);
    expect(cached?.llr, closeTo(direct!.llr, 1e-12));
    expect(cached?.exceedsThreshold, direct.exceedsThreshold);
  });

  test('disabled and experimental classes never generate feedback', () {
    for (final status in ['off', 'experimental']) {
      final result = evaluateCalibratedTajweedFormerSite(
        logProbs: [],
        inter1LogProbs: [],
        expected: [2],
        alternatives: [
          [3]
        ],
        blankId: 0,
        wordBarId: 1,
        calibration: read(status),
      );
      expect(result, isNull);
    }
  });

  test('rejects unknown preset, status and incompatible heads', () {
    expect(() => read('unrecognized'), throwsFormatException);
    expect(
        () => readTajweedFormerSiteCalibration(
            calibration: calibration('validated'),
            context: 'ctx',
            preset: 'missing',
            siteClass: 'cons_sub'),
        throwsFormatException);
    final c = calibration('validated');
    ((c['contexts'] as Map)['ctx'] as Map)['fusion'] = {
      'heads': ['other']
    };
    expect(
        () => readTajweedFormerSiteCalibration(
            calibration: c,
            context: 'ctx',
            preset: 'balanced',
            siteClass: 'cons_sub'),
        throwsFormatException);
  });

  group('tryRead distinguishes absence from malformed data', () {
    // نسخة JSON بعمق ديناميكي: تسمح بحقن القيم المشوّهة دون قيود
    // الاستدلال على أنواع المباني الأصلية.
    Map<String, dynamic> copy() =>
        jsonDecode(jsonEncode(calibration('validated')))
            as Map<String, dynamic>;

    TajweedFormerSiteCalibration? tryRead(Map<String, dynamic> c) =>
        tryReadTajweedFormerSiteCalibration(
            calibration: c,
            context: 'ctx',
            preset: 'balanced',
            siteClass: 'cons_sub');

    test('a genuinely absent class key returns null', () {
      expect(tryRead(copy()), isNotNull);
      expect(
        tryReadTajweedFormerSiteCalibration(
            calibration: copy(),
            context: 'ctx',
            preset: 'balanced',
            siteClass: 'cons_del'),
        isNull,
        reason: 'absence alone is a recordable coverage reason',
      );
    });

    test('a class key present with a wrong type throws, never reads as absent',
        () {
      final c = copy();
      (((c['contexts'] as Map)['ctx'] as Map)['sites'] as Map)['cons_sub'] =
          'garbage';
      expect(() => tryRead(c), throwsFormatException);
    });

    test('malformed surrounding structure throws before any absence answer',
        () {
      final noSites = copy();
      ((noSites['contexts'] as Map)['ctx'] as Map).remove('sites');
      expect(() => tryRead(noSites), throwsFormatException);

      final wrongSites = copy();
      ((wrongSites['contexts'] as Map)['ctx'] as Map)['sites'] = 'not a map';
      expect(() => tryRead(wrongSites), throwsFormatException);

      final noFormat = copy()..remove('format');
      expect(() => tryRead(noFormat), throwsFormatException,
          reason: 'the early return must not skip the format check');

      final unknownContext = copy();
      expect(
          () => tryReadTajweedFormerSiteCalibration(
              calibration: unknownContext,
              context: 'missing',
              preset: 'balanced',
              siteClass: 'cons_sub'),
          throwsFormatException);
    });

    test('an absent class cannot mask a corrupted fusion structure', () {
      // مفتاح صنف غائب (cons_del) مع fusion مفقودة أو مشوّهة: التشوّه
      // يُكتشف قبل إجابة الغياب — لا يُسجَّل missingCalibration لبيانات
      // فاسدة.
      TajweedFormerSiteCalibration? tryAbsent(Map<String, dynamic> c) =>
          tryReadTajweedFormerSiteCalibration(
              calibration: c,
              context: 'ctx',
              preset: 'balanced',
              siteClass: 'cons_del');

      final noFusion = copy();
      ((noFusion['contexts'] as Map)['ctx'] as Map).remove('fusion');
      expect(() => tryAbsent(noFusion), throwsFormatException);

      final wrongHeads = copy();
      final ctx = (wrongHeads['contexts'] as Map)['ctx'] as Map;
      (ctx['fusion'] as Map)['heads'] = ['other'];
      expect(() => tryAbsent(wrongHeads), throwsFormatException);

      final noPrep = copy();
      ((noPrep['contexts'] as Map)['ctx'] as Map)['fusion']['inter1_prep'] =
          'untouched';
      expect(() => tryAbsent(noPrep), throwsFormatException,
          reason: 'the shared structure must be fully validated even when '
              'the class key itself is absent');
    });

    test('an absent class cannot mask corrupted clip values', () {
      void clipIn(Map<String, dynamic> c, dynamic value) =>
          (((c['contexts'] as Map)['ctx'] as Map)['fusion']
                  as Map)['clip'] = value;
      TajweedFormerSiteCalibration? tryAbsent(Map<String, dynamic> c) =>
          tryReadTajweedFormerSiteCalibration(
              calibration: c,
              context: 'ctx',
              preset: 'balanced',
              siteClass: 'cons_del');

      final wrongType = copy();
      clipIn(wrongType, ['bad', 30]);
      expect(() => tryAbsent(wrongType), throwsFormatException);

      final wrongOrder = copy();
      clipIn(wrongOrder, [30, -30]);
      expect(() => tryAbsent(wrongOrder), throwsFormatException);

      final nonFinite = copy();
      clipIn(nonFinite, [double.infinity, 30]);
      expect(() => tryAbsent(nonFinite), throwsFormatException,
          reason: 'clip value finiteness is shared structure, not per-site');
    });
  });
}
