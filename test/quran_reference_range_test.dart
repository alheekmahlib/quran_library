import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/phoneme_aligner.dart';
import 'package:quran_library/src/tasmee/engine/quran_reference.dart';
import 'package:quran_library/src/tasmee/engine/quran_units.dart';
import 'package:quran_library/src/tasmee/engine/range_tracker.dart';
import 'package:quran_library/src/tasmee/engine/tasmee_error_kind.dart';

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
      final done = <(int, int, TasmeeErrorKind)>[];
      var complete = false;
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
        onRangeComplete: () => complete = true,
      );
      // أغذِ بالوحدات المرجعية نفسها تدريجيًا (محاكاة تدفّق التعرّف).
      for (var i = 1; i <= range.units.length; i++) {
        tracker.onUnits(range.units.sublist(0, i));
      }
      expect(tracker.completedWords, range.wordCount);
      expect(done.length, range.wordCount);
      expect(done.every((t) => t.$3 == TasmeeErrorKind.correct), isTrue,
          reason: 'كل الكلمات صحيحة عند التلاوة المطابقة');
      expect(complete, isTrue);
      // ترتيب الإتمام يتبع ترتيب الكلمات في النطاق.
      expect(done.first.$1, 0);
      expect(done.last.$1, 2);
    });

    test('تلاوة الكلمة الأولى وحدها لا تكشف كلمات لاحقة', () {
      // انحدار: المطابقة الفورية عند المتوقَّع فقط — تكرار الحروف
      // العربية داخل الكلمات التالية يجب ألا يُزح المؤشر أمامًا.
      //
      // دلالة الالتقاط: 3 وحدات (كلمة واحدة) لا تكفي لإرساء واثق —
      // الالتقاط يُقفل بإعادة إرساء (سلسلة كافية) لا بمطابقة ضيّقة
      // واحدة، فلا كشف حيًّا لسلسلة قصيرة قد تكون ضوضاء صادفت البداية.
      // التقييم النهائي عند الإيقاف يوثّق الكلمة (`matchedSpans` يغطّيها).
      final done = <(int, int, TasmeeErrorKind)>[];
      var lastWord = -1;
      final tracker = RangeLiveTracker(
        range: range,
        onRangeWord: (_, w) => lastWord = w,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      final firstWordEnd = range.wordSpans.first.endUnit;
      final firstWordUnits = range.units.sublist(0, firstWordEnd + 1);
      for (var i = 1; i <= firstWordUnits.length; i++) {
        tracker.onUnits(firstWordUnits.sublist(0, i));
      }
      expect(tracker.completedWords, 0,
          reason: 'سلسلة قصيرة لا تُرسّي المؤشر حيًّا');
      expect(tracker.isAcquiring, isTrue,
          reason: 'لا يُقفل الالتقاط على وحدات قليلة قد تكون ضوضاء');
      expect(tracker.isComplete, isFalse);
      expect(lastWord, -1, reason: 'لا كلمة جارية قبل الالتقاط');
    });

    test('خطأ في كلمة (استبدال حرف) → تُعلَّم خطأً عند اكتمالها', () {
      final done = <(int, int, TasmeeErrorKind)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      final pred = [...range.units];
      // اختر كلمة بعد منطقة الالتقاط (أول 12 وحدة) بأحرف متتالية مميّزة
      // (لا تكرار حرفي مكثّف كـ«ٱللَّهِ لَا» الذي تتسلسل عنده أخطاء
      // المتتبّع الحي الاسترشادي) — وحدة مخترقة داخل منطقة الالتقاط
      // تكسر سلسلة الإرساء فتُسقط حيًّا (والنهائي يعيد كشفها).
      var badSpan = -1;
      for (var s = 0; s < range.wordSpans.length; s++) {
        final sp = range.wordSpans[s];
        if (sp.startUnit <= 12) continue;
        final end = sp.endUnit + 3 < range.units.length
            ? sp.endUnit + 3
            : range.units.length;
        final letters =
            range.units.sublist(sp.startUnit, end).map((u) => u.letter);
        if (letters.toSet().length == letters.length) {
          badSpan = s;
          break;
        }
      }
      expect(badSpan, greaterThan(0),
          reason: 'العينة تحوي كلمة مميّزة بعد الالتقاط');
      final badIdx = range.wordSpans[badSpan].startUnit;
      pred[badIdx] = _unitWithLetterAbsentNear(lex, range.units, badIdx);
      for (var i = 1; i <= pred.length; i++) {
        tracker.onUnits(pred.sublist(0, i));
      }
      expect(done[badSpan].$3, isNot(TasmeeErrorKind.correct),
          reason: 'الكلمة المستبدَلة تُعلَّم خطأً');
      // قد يمتد أثر التخطّي لِكلمة مجاورة، لكن لا يتجاوز كلمتين.
      expect(done.where((t) => t.$3 != TasmeeErrorKind.correct).length,
          lessThanOrEqualTo(2));
    });

    test('كلمة محذوفة بالكامل → تُبلَّغ خطأً عند تجاوزها', () {
      final done = <(int, int, TasmeeErrorKind)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      // احذف وحدات الكلمة الثالثة كاملة.
      final span = range.wordSpans[2];
      final pred = <QuranUnit>[...range.units.sublist(0, span.startUnit)];
      pred.addAll(range.units.sublist(span.endUnit + 1));
      for (var i = 1; i <= pred.length; i++) {
        tracker.onUnits(pred.sublist(0, i));
      }
      expect(done[2].$3, isNot(TasmeeErrorKind.correct),
          reason: 'الكلمة المحذوفة تُبلَّغ خطأً');
      expect(tracker.isComplete, isTrue);
    });

    test('وحدات بادئة زائدة (بسملة) لا تمنع التقدّم ولا تخطئ الكلمات', () {
      final done = <(int, int, TasmeeErrorKind)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
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

    test('تصنيف حيّ: فرق حركة (نفس الحرف رمز مختلف) → تشكيل', () {
      final done = <(int, int, TasmeeErrorKind)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      final pred = [...range.units];
      // أول وحدة مرجعية: ابحث عن وحدة بديلة بنفس الحرف ورمز مختلف
      // (فرق حركة) من المعجم.
      final refUnit = range.units.first;
      QuranUnit? alt;
      for (final cand in lex.bySymbol.values) {
        if (cand.letter == refUnit.letter &&
            cand.symbol != refUnit.symbol &&
            !cand.isMadd &&
            !cand.isShadda &&
            !cand.qalqalah &&
            !cand.ghunna &&
            !cand.ikhfaa) {
          alt = cand;
          break;
        }
      }
      expect(alt, isNotNull, reason: 'المعجم يحوي حركة بديلة لنفس الحرف');
      pred[0] = alt!;
      for (var i = 1; i <= pred.length; i++) {
        tracker.onUnits(pred.sublist(0, i));
      }
      expect(done.first.$3, TasmeeErrorKind.tashkeel,
          reason: 'فرق الحركة يُصنَّف تشكيلاً لحظيًا');
    });

    test('تصنيف حيّ: فرق مدّ (نفس الحرف طول مختلف) → تجويد', () {
      final done = <(int, int, TasmeeErrorKind)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      final pred = [...range.units];
      // أول وحدة مدّ مرجعية: استبدلها بمدّ بطول مختلف.
      var maddIdx = -1;
      for (var i = 0; i < pred.length; i++) {
        if (range.units[i].isMadd) {
          maddIdx = i;
          break;
        }
      }
      expect(maddIdx, greaterThanOrEqualTo(0), reason: 'العينة تحوي مدًّا');
      final ref = range.units[maddIdx];
      QuranUnit? alt;
      for (final cand in lex.bySymbol.values) {
        if (cand.isMadd &&
            cand.letter == ref.letter &&
            cand.coreRepeat != ref.coreRepeat) {
          alt = cand;
          break;
        }
      }
      expect(alt, isNotNull, reason: 'المعجم يحوي مدًّا بطول مختلف');
      pred[maddIdx] = alt!;
      for (var i = 1; i <= pred.length; i++) {
        tracker.onUnits(pred.sublist(0, i));
      }
      final verdict = done
          .firstWhere((t) =>
              t.$1 == range.unitVerseIdx[maddIdx] &&
              t.$2 == range.unitWordIdx[maddIdx])
          .$3;
      expect(verdict, TasmeeErrorKind.tajweed,
          reason: 'فرق طول المدّ يُصنَّف تجويدًا لحظيًا');
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

  group('RangeLiveTracker — الالتقاط والتحصين', () {
    test('بداية من منتصف النطاق: كلمات ما قبل نقطة البداية لا تُبلَّغ إطلاقًا',
        () {
      final done = <(int, int, TasmeeErrorKind)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      // تلاوة تبدأ من الآية الثانية مباشرة (تخطّي الآية الأولى كاملة).
      final v1Start = verses[0].units.length;
      final pred = range.units.sublist(v1Start);
      for (var i = 1; i <= pred.length; i++) {
        tracker.onUnits(pred.sublist(0, i));
      }
      // لا حدث إتمام لأي كلمة من الآية الأولى — لم تُتلَ أصلًا.
      expect(done.where((t) => t.$1 == 0), isEmpty,
          reason: 'كلمات الآية الأولى لم تُتلَ فلا تُبلَّغ صحيحة ولا خاطئة');
      // كلمات الآيتين الباقيتين تكتمل كلها صحيحة.
      expect(done.where((t) => t.$1 == 1 || t.$1 == 2).length,
          range.wordSpans.where((s) => s.verseIdx > 0).length);
      expect(
        done
            .where((t) => t.$1 > 0)
            .every((t) => t.$3 == TasmeeErrorKind.correct),
        isTrue,
        reason: 'التلاوة سليمة بعد نقطة البداية',
      );
      expect(tracker.isComplete, isTrue);
    });

    test('بداية من أول النطاق: إرساء فوري بعد 5 وحدات متطابقة رمزيًا', () {
      // البقّة: الإظهار كان يتأخر ~12 وحدة (كلمتين) بانتظار إرساء
      // البافر — المستخدم يرى الكلمات من الثالثة فقط. الحل: سلسلة
      // وحدات تطابق فاتحة النطاق **بالرمز الكامل** (حرفًا وحركةً)
      // تُرسّي فورًا — أقوى دليل من أي عتبة عددية.
      final done = <(int, int, TasmeeErrorKind)>[];
      var currentWord = -1;
      final tracker = RangeLiveTracker(
        range: range,
        onRangeWord: (_, w) => currentWord = w,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      // أغذِ أول 5 وحدات تدريجيًا فقط.
      for (var i = 1; i <= 5; i++) {
        tracker.onUnits(range.units.sublist(0, i));
      }
      expect(tracker.isAcquiring, isFalse,
          reason: 'سلسلة رمزية من الفاتحة تُرسّي فورًا بلا انتظار البافر');
      expect(tracker.firstConsumedRefIdx, 0);
      expect(tracker.completedWords, greaterThanOrEqualTo(1),
          reason: 'أول كلمة اكتملت فور إرساء السلسلة');
      expect(currentWord, greaterThanOrEqualTo(1),
          reason: 'الكلمة الجارية تقدمت للثانية');
    });

    test('بداية بعيدة (خارج نافذة إعادة الإرساء المحلية) تُلتقط على موضعها',
        () {
      final done = <(int, int, TasmeeErrorKind)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      // بداية عند الوحدة 40 — خارج نافذة 24 وحدة أمام المؤشر: البحث
      // أثناء الالتقاط يجب أن يمسّ النطاق كاملًا.
      const startRef = 40;
      expect(startRef, greaterThan(24));
      final pred = range.units.sublist(startRef);
      for (var i = 1; i <= pred.length; i++) {
        tracker.onUnits(pred.sublist(0, i));
      }
      expect(done, isNotEmpty, reason: 'الالتقاط يرسو عند البداية الفعلية');
      expect(tracker.firstConsumedRefIdx, greaterThanOrEqualTo(startRef),
          reason: 'المؤشر يبدأ من موضع المستخدم لا من أول النطاق');
      // كل الكلمات المكتملة بعد نقطة البداية سليمة.
      expect(done.every((t) => t.$3 == TasmeeErrorKind.correct), isTrue);
      expect(tracker.isComplete, isTrue);
    });

    test('حرف افتتاحي يطابق أول حرف بالنطاق لا يُنهي الالتقاط زورًا', () {
      final done = <(int, int, TasmeeErrorKind)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      // وحدة أولى حرفها = حرف أول وحدة بالنطاق (تكرار حرف/ضوضاء صادفت
      // البداية) ثم تلاوة فعلية من منتصف النطاق — مطابقة ضيّقة واحدة
      // عند الوحدة 0 ليست دليل بداية.
      final pred = [
        range.units[0], // حرف مطابق لأول حرف — فخ القفل الزائف.
        ...range.units.sublist(40),
      ];
      for (var i = 1; i <= pred.length; i++) {
        tracker.onUnits(pred.sublist(0, i));
      }
      expect(done, isNotEmpty);
      expect(tracker.firstConsumedRefIdx, greaterThanOrEqualTo(40),
          reason: 'الالتفات للحرف المتكرر لا يُقفل الالتقاط على البداية');
      expect(done.every((t) => t.$3 == TasmeeErrorKind.correct), isTrue);
    });

    test('ضوضاء مطوّلة قبل البداية لا تُخطئ الكلمة الأولى (التقاط متأخر)', () {
      final done = <(int, int, TasmeeErrorKind)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      // "ضوضاء": تكرار حرف واحد (سعال/تنحنح/همهمة) — مهم ألا يكون نصًّا
      // موجودًا داخل النطاق نفسه، وإلا رسا عليه الالتقاط بحقّ (سلسلة
      // مطابقة كاملة عبر النطاق كاملًا).
      final noiseUnit = lex.bySymbol.values
          .firstWhere((c) => !c.isNoiseInsert && c.symbol.length <= 2);
      final noise = List<QuranUnit>.generate(11, (_) => noiseUnit);
      final pred = [...noise, ...range.units];
      for (var i = 1; i <= pred.length; i++) {
        tracker.onUnits(pred.sublist(0, i));
      }
      expect(done.first, (0, 0, TasmeeErrorKind.correct),
          reason: 'البسملة/الضوضاء قبل البداية ليست خطأ على أول كلمة');
      expect(tracker.completedWords, range.wordCount);
    });

    test('حرفان أماميان متطابقان (قفزة كاذبة محتملة) لا يُقرّان بقفزة', () {
      final done = <(int, int, TasmeeErrorKind)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      // وحدتان تحاكيان تكرار حرفيّ م/ل الأماميّين (wide عند +2 ثم +3)
      // ثم تعود التلاوة الصحيحة للمتوقَّع — تأكيد القفزة يحتاج 3 متتالية.
      final pred = [
        range.units[2], // حرف "م" — مطابقة واسعة عند +2.
        range.units[3], // الحرف التالي — يؤكد جزئيًا عند +3.
        range.units[0], // العودة للمتوقَّع بالضبط → القفزة كانت وهمًا.
        ...range.units.sublist(1),
      ];
      for (var i = 1; i <= pred.length; i++) {
        tracker.onUnits(pred.sublist(0, i));
      }
      expect(done.first.$3, TasmeeErrorKind.correct,
          reason:
              'تأكيد 3 وحدات يمنع اعتبار تكرار حرفين قفزة حقيقية تحذف وحدات');
      expect(tracker.completedWords, range.wordCount);
    });

    test('انزلاق كبير (أبعد من النافذة المحلية) يُستدرَك بمسح النطاق كاملًا',
        () {
      // سيناريو التسميع: تقدّم طبيعي ثم تخطّي منطقة كبيرة (أبعد من
      // نافذة إعادة الإرساء المحلية 24 وحدة) ومواصلة التلاوة — الوسم
      // بالإدراجات والتصفير المتكرر كان يترك المؤشر خلف المستخدم بلا
      // استدراك، فتتوقف كل الكلمات التالية عن الظهور.
      final done = <(int, int, TasmeeErrorKind)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      // الفجوة تنزلق إلى منطقة 36:82 (محتوى فريد) — عيّنة 2:255 المقتطعة
      // تحوي مقطعًا مكررًا حرفيًا فلا يُختبر الاستدراك فيه (غموض محتوى
      // لا يحله منطق).
      const skipFrom = 20;
      final skipTo = verses[0].units.length + verses[1].units.length + 2;
      final pred = [
        ...range.units.sublist(0, skipFrom),
        ...range.units.sublist(skipTo),
      ];
      for (var i = 1; i <= pred.length; i++) {
        tracker.onUnits(pred.sublist(0, i));
      }
      // كلمات ما بعد الفجوة تكتمل — التتبّع استُدرِك ولم يتوقف.
      final afterGap = done.where((t) => range.wordSpans.any((s) =>
          s.verseIdx == t.$1 && s.wordIdx == t.$2 && s.startUnit >= skipTo));
      expect(afterGap, isNotEmpty,
          reason: 'الكلام بعد الفجوة يُتبَّع — لا انزلاقًا دائمًا');
      expect(afterGap.every((t) => t.$3 == TasmeeErrorKind.correct), isTrue,
          reason: 'الكلام بعد الفجوة سليم');
      expect(tracker.isComplete, isTrue);
    });

    test('تكرار كلمة (تردد) لا يوقف التقدّم', () {
      final done = <(int, int, TasmeeErrorKind)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      // الكلمة الأولى ثم إعادتها (تردد مستخدم) ثم مواصلة صحيحة.
      final w0End = range.wordSpans[0].endUnit;
      final pred = [
        ...range.units.sublist(0, w0End + 1),
        ...range.units.sublist(0, w0End + 1),
        ...range.units.sublist(w0End + 1),
      ];
      for (var i = 1; i <= pred.length; i++) {
        tracker.onUnits(pred.sublist(0, i));
      }
      expect(done.first.$3, TasmeeErrorKind.correct,
          reason: 'النسخة الأولى من الكلمة سليمة');
      expect(tracker.completedWords, range.wordCount,
          reason: 'التكرار لا يعلّق المؤشر');
    });

    test('إعادة نطق آخر كلمة قبل المواصلة → الكلمة التالية لا تُخطَّأ', () {
      // سيناريو المصحّح: بعد إغلاق الشيت يعيد المستخدم نطق الكلمة
      // المصحَّحة (أو ما قبلها) ثم يكمل — الإعادة ليست «زيادة» على
      // الكلمة التالية.
      final done = <(int, int, TasmeeErrorKind)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      // قدّم تقدّمًا كافيًا لتجاوز الالتقاط ثم أعِد الكلمة الأخيرة.
      final upto = range.wordSpans[8].endUnit;
      var pred = <QuranUnit>[...range.units.sublist(0, upto + 1)];
      tracker.onUnits(pred);
      final before = List.of(done);
      final lastSpan = range.wordSpans[8];
      final lastWordUnits =
          range.units.sublist(lastSpan.startUnit, lastSpan.endUnit + 1);
      pred = [...pred, ...lastWordUnits, ...range.units.sublist(upto + 1)];
      tracker.onUnits(pred);
      // أحداث الكلمات بعد الإعادة كلها صحيحة — الإعادة تُتجاهل ولا
      // تُوسم إدراجًا على الكلمة التالية.
      final after = done.sublist(before.length);
      expect(after, isNotEmpty);
      expect(after.every((t) => t.$3 == TasmeeErrorKind.correct), isTrue,
          reason: 'إعادة الكلمة الأخيرة ليست خطأً على الكلمة التالية');
      expect(tracker.isComplete, isTrue);
    });

    test('rearmAcquisition بعد إيقاف المصحّح: الانزياح أثناء الشيت يُدرَك', () {
      // محاكاة سيناريو المستخدم بالضبط: خطأ في كلمة بآية 1 → فتح الشيت
      // (الميكروفون لا يتوقف فورًا فتنزلق كلمات إضافية قدمت المؤشر) →
      // تصحيح وإغلاق → المواصلة من بعد الكلمة المصحَّحة ثم الآية التالية.
      final done = <(int, int, TasmeeErrorKind)>[];
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
      );
      // 1) تلاوة الآية الأولى حتى كلمة K مع انزلاق وحدات إضافية
      //    (كلمة تقريبًا قفزت بالمؤشر أثناء انتظار إيقاف الميكروفون) —
      //    الآية الأولى (1:1) أربع كلمات فالانزلاق داخلها.
      final k = range.wordSpans[2].endUnit;
      final slipped = range.wordSpans[3].endUnit;
      tracker.onUnits(range.units.sublist(0, slipped + 1));
      // 2) إغلاق الشيت: إعادة تسليح الالتقاط (ما يفعله resumeLive).
      tracker.rearmAcquisition();
      final doneBeforeResume = List.of(done);
      // 3) المواصلة من بعد الكلمة المصحَّحة (K) حتى نهاية الآية الأولى
      //    ثم الآية الثانية كاملة — البثّ الحي قائمة واحدة متنامية
      //    (وحدات ما قبل الشيت + وحدات المواصلة).
      final v1End = verses[0].units.length - 1;
      final pred = [
        ...range.units.sublist(0, slipped + 1),
        ...range.units.sublist(k + 1, v1End + 1),
        ...verses[1].units,
      ];
      tracker.onUnits(pred);
      // لا أحداث إضافية قبل الإرساء (طور التقاط مصغّر).
      // بعد الإرساء: كلمات الآية الأولى المتخطَّاة (بين K ونقطة الانزلاق)
      // لا تُبلَّغ خطأً — لم تُتلَ والمؤشر كان منزلقًا عليها.
      final newEvents = done.sublist(doneBeforeResume.length);
      expect(newEvents, isNotEmpty, reason: 'التتبّع استؤنف بعد الإرساء');
      // رسوخية نقطة البداية: الإرساء الجديد بعد الشيت لا يزيح بداية
      // المقطع — وإلا سقط ما قبله من نافذة التقييم عند الإيقاف (نتيجة
      // الآية الأخيرة فقط بدل كل المتلوّ).
      expect(tracker.firstConsumedRefIdx, 0,
          reason: 'أول إرساء في الجلسة يبقى بداية المقطع أبدًا');
      // لا أخطاء وهمية على كلمات الآية الأولى بعد الاستئناف — مقصود
      // الاختبار. (أحداث الآية الثانية قد يشوبها التباسُ مقطعٍ مكرر
      // حرفيًا في عيّنة 2:255 المقتطعة — يُتسامح مع اثنين.)
      final verse0Errors = newEvents
          .where((t) => t.$1 == 0 && t.$3 != TasmeeErrorKind.correct)
          .length;
      expect(verse0Errors, 0,
          reason: 'كلام سليم بعد الاستئناف لا يُنتج أخطاء في الآية الأولى');
      final verse1Errors = newEvents
          .where((t) => t.$1 == 1 && t.$3 != TasmeeErrorKind.correct)
          .length;
      expect(verse1Errors, lessThanOrEqualTo(10),
          reason: 'شلال التباس مقطع مكرر حرفيًا في عيّنة 2:255 المقتطعة '
              '(المهم: لا توقف دائمًا — كل الكلمات تُبلَّغ أدناه)');
      // الآية الثانية تُتبَّع فعلًا.
      expect(newEvents.where((t) => t.$1 == 1).length,
          range.wordSpans.where((s) => s.verseIdx == 1).length,
          reason: 'كل كلمات الآية الثانية تكتمل');
    });
  });
}

/// ينشئ وحدة استبدال حرفُها غائب عن النافذة المرجعية حول [unitIdx] —
/// كي لا تلتقطها القفزات المؤكدة على تكرار مجاور فتتسلسل الأخطاء.
QuranUnit _unitWithLetterAbsentNear(
  QuranUnitLexicon lex,
  List<QuranUnit> refUnits,
  int unitIdx,
) {
  final from = unitIdx < 2 ? 0 : unitIdx - 2;
  final to = (unitIdx + 10 > refUnits.length) ? refUnits.length : unitIdx + 10;
  final nearLetters = refUnits.sublist(from, to).map((u) => u.letter).toSet();
  for (final candidate in lex.bySymbol.values) {
    if (!nearLetters.contains(candidate.letter) &&
        !candidate.isNoiseInsert &&
        candidate.symbol.length <= 2) {
      return candidate;
    }
  }
  return refUnits[unitIdx];
}
