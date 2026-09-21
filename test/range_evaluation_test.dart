import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/final_reconciliation.dart';
import 'package:quran_library/src/tasmee/engine/live_recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/madd_timing.dart';
import 'package:quran_library/src/tasmee/engine/models/recitation_result.dart';
import 'package:quran_library/src/tasmee/engine/phoneme_aligner.dart';
import 'package:quran_library/src/tasmee/engine/quran_reference.dart';
import 'package:quran_library/src/tasmee/engine/quran_units.dart';
import 'package:quran_library/src/tasmee/engine/range_evaluation.dart';

void main() {
  // العينة: 1:1 (4 كلمات)، 2:255 (طويلة)، 36:82 — تُحاكي صفحة.
  late QuranReferenceRange range;
  late List<QuranReferenceVerse> verses;
  late QuranUnitLexicon lex;

  setUpAll(() async {
    lex = QuranUnitLexicon.fromTokensText(
        File('test/fixtures/tokens.txt').readAsStringSync());
    final refDb = QuranPhonemeReference(lexicon: lex);
    await refDb.load(filePath: 'test/fixtures/quran_phonemes_sample.json.gz');
    verses = [
      refDb.getReference(suraIdx: 1, ayaIdx: 1)!,
      refDb.getReference(suraIdx: 2, ayaIdx: 255)!,
      refDb.getReference(suraIdx: 36, ayaIdx: 82)!,
    ];
    range = QuranReferenceRange.fromVerses(verses)!;
  });

  RangeEvaluation evaluate(
    List<QuranUnit> predUnits, {
    ({int start, int end})? window,
  }) =>
      evaluateRangeAlignment(
        range: range,
        predUnits: predUnits,
        frame: LiveRecognitionFrame(
          units: predUnits.map((u) => u.symbol).toList(),
          timestamps: const [],
        ),
        durationSec: predUnits.length * 0.2,
        maddTimingConfig: const MaddTimingConfig(),
        window: window,
      );

  group('recitedWindowFor — نافذة المقطع المتلو', () {
    test('من أول إرساء (بهامش خلفي) إلى المؤشر + هامش أمامي', () {
      final w = recitedWindowFor(
          firstConsumed: 40, nextExpected: 100, rangeLength: 300);
      expect(w.start, 32);
      expect(w.end, 124); // 100 + frontSlack(24).
    });

    test('يُشبك عند حدود النطاق', () {
      final w =
          recitedWindowFor(firstConsumed: 0, nextExpected: 5, rangeLength: 10);
      expect(w.start, 0);
      expect(w.end, 10);
    });

    test('مؤشر متقدم لأقصى النطاق', () {
      final w = recitedWindowFor(
          firstConsumed: 50, nextExpected: 300, rangeLength: 300);
      expect(w.start, 42);
      expect(w.end, 300);
    });
  });

  group('evaluateRangeAlignment — تقييم بنافذة المتتبّع الحي', () {
    test(
        'إيقاف بعد آية واحدة: ضوضاء ختامية مطابِقة لذيل الصفحة لا تغرق النتائج',
        () {
      // المستخدم تلا الآية الأولى فقط ثم أوقف — ووحدة ضوضاء ختامية
      // حرفُها موجود عميقًا في الآية الثالثة (فخ محاذاة كامل الصفحة:
      // المطابقة المجانية تُزيح «آخر مطابقة» عميقًا فيفشل الاقتطاع).
      final deepLetter = verses[2].units[verses[2].units.length ~/ 2].letter;
      final noise = lex.bySymbol.values.firstWhere(
        (c) => c.letter == deepLetter && !c.isNoiseInsert,
      );
      final predUnits = [...verses[0].units, noise];
      // نافذة المتتبّع الحي عند الإيقاف: من البداية حتى بعد مؤشر الآية
      // الأولى بهامش.
      final window = (start: 0, end: verses[0].units.length + 10);

      final eval = evaluate(predUnits, window: window);

      expect(eval.errors, isEmpty,
          reason: 'ضوضاء ختامية واحدة تُغتفر ولا تُظهر الصفحة مفقودة');
      expect(eval.matchedSpans.length,
          range.wordSpans.where((s) => s.verseIdx == 0).length);
      expect(eval.start.suraIdx, 1);
      expect(eval.start.ayaIdx, 1);
      expect(eval.end.suraIdx, 1);
      expect(eval.end.ayaIdx, 1);
    });

    test('بدون نافذة (دفعة كاملة): لا وسوم لكلمات ما لم يُتلَ', () {
      // الجلسات الحيّة تُقيَّم دائمًا بنافذة المتتبّع؛ هذا المسار للدفعات
      // البرمجية بلا متتبّع — محاذاة النطاق كاملًا مقابل مقطع قصير قد
      // تُداخل حذوفًا بين مطابقات المقطع ذاته (تعادل الحروف المكررة)
      // فتنقص التغطية، لكن الضمانة الأساسية قائمة: لا وسوم لأي كلمة
      // خارج المقطع المتلو.
      final predUnits = [...verses[0].units];
      final eval = evaluate(predUnits);
      expect(
          eval.errors.where((e) => e.uthmaniPos[0] >= verses[0].units.length),
          isEmpty,
          reason: 'لا أخطاء موسومة خارج الآية المتلوّة');
      expect(
        eval.matchedSpans.every((s) => s.verseIdx == 0),
        isTrue,
        reason: 'التغطية لا تتجاوز الآية المتلوّة فتُظهر الصفحة مكتملة',
      );
    });

    test('خطأ داخل المقطع المتلو يُوسم بموضعه العالمي الصحيح', () {
      // أفسد وحدة في منتصف الآية الأولى (استبدال بحرف غائب محليًا).
      final predUnits = [...verses[0].units];
      final badIdx = predUnits.length ~/ 2;
      final near = range.units
          .sublist(badIdx - 2, badIdx + 10)
          .map((u) => u.letter)
          .toSet();
      predUnits[badIdx] = lex.bySymbol.values.firstWhere(
        (c) => !near.contains(c.letter) && !c.isNoiseInsert,
      );
      final eval = evaluate(
        predUnits,
        window: (start: 0, end: verses[0].units.length + 10),
      );
      expect(eval.errors, isNotEmpty);
      final e = eval.errors.first;
      expect(e.uthmaniPos[0], lessThan(verses[0].units.length),
          reason: 'الموضع العالمي داخل الآية الأولى');
      expect(e.suraIdx, 1);
      expect(e.ayaIdx, 1);
      expect(e.wordIdx, isNotNull);
    });
  });

  group('RecitationError.shiftUthmaniPos', () {
    test('يُزيح موضع البداية والنهاية ويحفظ الحقول', () {
      const e = RecitationError(
        errorType: 'normal',
        speechErrorType: 'replace',
        uthmaniPos: [4, 5],
      );
      final shifted = e.shiftUthmaniPos(40);
      expect(shifted.uthmaniPos, [44, 45]);
      expect(shifted.errorType, 'normal');
      expect(shifted.speechErrorType, 'replace');
      // الحارس (بلا موضع) لا يُزاح.
      const raw = RecitationError(
        errorType: 'normal',
        speechErrorType: 'insert',
        uthmaniPos: [-1, -1],
      );
      expect(raw.shiftUthmaniPos(40).uthmaniPos, [-1, -1]);
    });
  });

  group('matchedSpansFromOps — refOffset', () {
    test('يفهرس السپانات بإزاحة نافذة', () {
      // وحدتان في كلمتين مختلفتين من الآية الثانية (فهارس نافذية
      // بإزاحة طول الآية الأولى).
      final winStart = verses[0].units.length;
      final s0 = range.wordSpans[4]; // أول كلمة بالآية الثانية.
      final s1 = range.wordSpans[5]; // الكلمة التالية.
      final ops = [
        UnitAlignOp(type: 'match', refIdx: s0.startUnit - winStart, predIdx: 0),
        UnitAlignOp(type: 'match', refIdx: s1.startUnit - winStart, predIdx: 1),
      ];
      final spans = matchedSpansFromOps(ops, range, refOffset: winStart);
      expect(spans.length, 2);
      expect(spans.first.verseIdx, 1);
      expect(spans.first.wordIdx, s0.wordIdx);
      expect(spans.last.wordIdx, s1.wordIdx);
    });
  });
}
