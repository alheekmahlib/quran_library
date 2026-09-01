import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/phoneme_aligner.dart';
import 'package:quran_library/src/tasmee/engine/quran_reference.dart';
import 'package:quran_library/src/tasmee/engine/quran_units.dart';
import 'package:quran_library/src/tasmee/engine/range_tracker.dart';

void main() {
  late QuranUnitLexicon lex;
  late QuranPhonemeReference refDb;
  late List<QuranReferenceVerse> verses;
  late QuranReferenceRange range;

  setUpAll(() async {
    lex = QuranUnitLexicon.fromTokensText(
        File('test/fixtures/tokens.txt').readAsStringSync());
    refDb = QuranPhonemeReference(lexicon: lex);
    await refDb.load(filePath: 'test/fixtures/quran_phonemes_sample.json.gz');
    // العينة متعددة السور: 1:1، 2:255، 36:82، 112:1، 114:6 — تُحاكي
    // نطاق صفحة تضم أكثر من سورة.
    verses = [
      refDb.getReference(suraIdx: 1, ayaIdx: 1)!,
      refDb.getReference(suraIdx: 2, ayaIdx: 255)!,
      refDb.getReference(suraIdx: 36, ayaIdx: 82)!,
    ];
    range = QuranReferenceRange.fromVerses(verses)!;
  });

  group('QuranReferenceRange — البناء', () {
    test('تراكب الوحدات = مجموع وحدات الآيات', () {
      expect(
        range.units.length,
        verses[0].units.length +
            verses[1].units.length +
            verses[2].units.length,
      );
      expect(range.unitVerseIdx.length, range.units.length);
      expect(range.unitWordIdx.length, range.units.length);
    });

    test('خرائط الوحدات تشير لِلآية والكلمة الصحيحتين', () {
      final v0Len = verses[0].units.length;
      final v1Len = verses[1].units.length;
      // كل وحدات الآية الأولى → الآية 0.
      expect(range.unitVerseIdx.take(v0Len).toSet(), {0});
      // وحدات الآية الثانية → الآية 1.
      expect(
        range.unitVerseIdx.sublist(v0Len, v0Len + v1Len).toSet(),
        {1},
      );
      // فهرس كلمة أول وحدة من الآية الثانية = فهرسها داخل آيتها.
      expect(
        range.unitWordIdx[v0Len],
        verses[1].unitWordIdx[0],
      );
    });

    test('wordSpans: عدد الكلمات وحدود الوحدات متصلة ومتصاعدة', () {
      // الكلمات ذات الوحدات فقط — عينة الاختبار مقتطعة الفونيمات لبعض
      // كلمات آخر الآيات الطويلة (الأصل الكامل يغطي كل الكلمات).
      final wordsWithUnits = verses.fold<int>(
          0,
          (sum, v) =>
              sum +
              v.uthmaniWords.where((_) => true).length -
              v.uthmaniWords
                  .where(
                      (w) => !v.unitWordIdx.contains(v.uthmaniWords.indexOf(w)))
                  .length);
      expect(range.wordCount, wordsWithUnits);
      for (var i = 0; i < range.wordSpans.length; i++) {
        final span = range.wordSpans[i];
        expect(span.endUnit, greaterThanOrEqualTo(span.startUnit));
        if (i > 0) {
          expect(
              span.startUnit, greaterThan(range.wordSpans[i - 1].endUnit - 1));
        }
      }
    });

    test('keyOfVerse يعيد مفاتيح السورة/الآية', () {
      expect(range.keyOfVerse(0), (suraIdx: 1, ayaIdx: 1));
      expect(range.keyOfVerse(1), (suraIdx: 2, ayaIdx: 255));
      expect(range.keyOfVerse(2), (suraIdx: 36, ayaIdx: 82));
    });

    test('wordAt يعيد كلمة الآية الصحيحة عبر الحدود', () {
      // آخر وحدة في الآية 0 → آخر كلمة في الآية 0.
      final lastUnitOfV0 = verses[0].units.length - 1;
      final w0 = range.unitWordIdx[lastUnitOfV0];
      expect(range.wordAt(lastUnitOfV0), verses[0].uthmaniWords[w0]);
      // أول وحدة في الآية 1 → أول كلمة فيها.
      final firstUnitOfV1 = verses[0].units.length;
      expect(range.wordAt(firstUnitOfV1), verses[1].uthmaniWords[0]);
      // خارج الحدود → null.
      expect(range.wordAt(-1), isNull);
      expect(range.wordAt(range.units.length), isNull);
    });

    test('getRange يبني النطاق ويرجع null عند غاب آية', () {
      final built =
          refDb.getRange([(suraIdx: 1, ayaIdx: 1), (suraIdx: 2, ayaIdx: 255)]);
      expect(built, isNotNull);
      expect(built!.verses.length, 2);
      expect(refDb.getRange([(suraIdx: 1, ayaIdx: 999)]), isNull);
    });
  });

  group('RangeLiveTracker — التتبّع الحيّ', () {
    test('تلاوة كاملة صحيحة → كل الكلمات done صحيحة + اكتمال النطاق', () {
      final done = <(int, int, bool)>[];
      var complete = false;
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, c) => done.add((v, w, c)),
        onRangeComplete: () => complete = true,
      );
      // أغذِ بالوحدات المرجعية نفسها تدريجيًا (محاكاة تدفّق التعرّف).
      for (var i = 1; i <= range.units.length; i++) {
        tracker.onUnits(range.units.sublist(0, i));
      }
      expect(tracker.completedWords, range.wordCount);
      expect(done.length, range.wordCount);
      expect(done.every((t) => t.$3), isTrue,
          reason: 'كل الكلمات صحيحة عند التلاوة المطابقة');
      expect(complete, isTrue);
      // ترتيب الإتمام يتبع ترتيب الكلمات في النطاق.
      expect(done.first.$1, 0);
      expect(done.last.$1, 2);
    });

    test('خطأ في كلمة (استبدال حرف) → تُعلَّم خطأً عند اكتمالها', () {
      final done = <(int, int, bool)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, c) => done.add((v, w, c)),
      );
      final pred = [...range.units];
      // أفسد حرفًا داخل الكلمة الثانية (استبدال بحرف مختلف).
      final badIdx = range.wordSpans[1].startUnit;
      pred[badIdx] = _unitWithDifferentLetter(lex, pred[badIdx]);
      for (var i = 1; i <= pred.length; i++) {
        tracker.onUnits(pred.sublist(0, i));
      }
      expect(done[1].$3, isFalse, reason: 'الكلمة الثانية فيها استبدال');
      // قد يمتد أثر التخطّي لِكلمة مجاورة، لكن لا يتجاوز كلمتين.
      expect(done.where((t) => !t.$3).length, lessThanOrEqualTo(2));
    });

    test('كلمة محذوفة بالكامل → تُبلَّغ خطأً عند تجاوزها', () {
      final done = <(int, int, bool)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, c) => done.add((v, w, c)),
      );
      // احذف وحدات الكلمة الثالثة كاملة.
      final span = range.wordSpans[2];
      final pred = <QuranUnit>[...range.units.sublist(0, span.startUnit)];
      pred.addAll(range.units.sublist(span.endUnit + 1));
      for (var i = 1; i <= pred.length; i++) {
        tracker.onUnits(pred.sublist(0, i));
      }
      expect(done[2].$3, isFalse, reason: 'الكلمة المحذوفة تُبلَّغ خطأً');
      expect(tracker.isComplete, isTrue);
    });

    test('وحدات بادئة زائدة (بسملة) لا تمنع التقدّم ولا تخطئ الكلمات', () {
      final done = <(int, int, bool)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, c) => done.add((v, w, c)),
      );
      // ادفع وحدات الآية الأولى نفسها كبادئة زائدة قبل التلاوة الفعلية.
      final pred = [...range.units.sublist(0, verses[0].units.length)];
      pred.addAll(range.units);
      // تدفق تدريجي.
      for (var i = 1; i <= pred.length; i++) {
        tracker.onUnits(pred.sublist(0, i));
      }
      // النطاق يكتمل (التقدّم لم يتوقف عند البادئة).
      expect(tracker.completedWords, range.wordCount);
    });

    test('dropLeadingInserts يتسامح مع بادئة قبل أول مطابقة (التقييم النهائي)',
        () {
      final ops = alignUnits(range.units, range.units);
      final withLead = [
        ...List.generate(
            3, (i) => UnitAlignOp(type: 'insert', refIdx: -1, predIdx: i)),
        ...ops,
      ];
      final filtered = dropLeadingInserts(withLead);
      expect(filtered.first.type == 'match', isTrue);
      expect(dropLeadingInserts(withLead.sublist(0, 3)), isEmpty);
    });
  });
}

/// ينشئ وحدة بحرف أساسي مختلف (لِمحاكاة استبدال نطق).
QuranUnit _unitWithDifferentLetter(QuranUnitLexicon lex, QuranUnit unit) {
  for (final candidate in lex.bySymbol.values) {
    if (candidate.letter != unit.letter &&
        !candidate.isNoiseInsert &&
        candidate.symbol.length <= 2) {
      return candidate;
    }
  }
  return unit;
}
