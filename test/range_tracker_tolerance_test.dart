import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/quran_reference.dart';
import 'package:quran_library/src/tasmee/engine/quran_units.dart';
import 'package:quran_library/src/tasmee/engine/range_tracker.dart';
import 'package:quran_library/src/tasmee/engine/tasmee_error_kind.dart';

/// اختبارات حتمية من قسم 5 بتقرير الفحص — لا تحتاج صوتًا:
/// وحدة محذوفة/مستبدلة، الاستئناف بعد المصحح، وسقوط وحدات الأطراف.
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
    verses = [
      refDb.getReference(suraIdx: 1, ayaIdx: 1)!,
      refDb.getReference(suraIdx: 2, ayaIdx: 255)!,
      refDb.getReference(suraIdx: 36, ayaIdx: 82)!,
    ];
    range = QuranReferenceRange.fromVerses(verses)!;
  });

  /// يغذّي المتتبّع بقائمة متنبأءات كاملة تدريجيًا (نمط تدفّق التعرّف).
  void feed(RangeLiveTracker tracker, List<QuranUnit> preds) {
    for (var i = 1; i <= preds.length; i++) {
      tracker.onUnits(preds.sublist(0, i));
    }
  }

  ({List<(int, int)> incorrect, bool complete, int completed}) run(
    List<QuranUnit> preds, {
    void Function(RangeLiveTracker tracker)? midStream,
    QuranReferenceRange? onRange,
  }) {
    final incorrect = <(int, int)>[];
    var complete = false;
    final tracker = RangeLiveTracker(
      range: onRange ?? range,
      onWordDone: (v, w, k, _) {
        if (k != TasmeeErrorKind.correct) incorrect.add((v, w));
      },
      onRangeComplete: () => complete = true,
    );
    if (midStream == null) {
      feed(tracker, preds);
    } else {
      // غذِّ النصف الأول، طبّق التدخل (إعادة تسليح)، ثم أكمل.
      final half = preds.length ~/ 2;
      for (var i = 1; i <= half; i++) {
        tracker.onUnits(preds.sublist(0, i));
      }
      midStream(tracker);
      for (var i = half + 1; i <= preds.length; i++) {
        tracker.onUnits(preds.sublist(0, i));
      }
    }
    return (
      incorrect: incorrect,
      complete: complete,
      completed: tracker.completedWords
    );
  }

  test(
      'C2-أ: وحدة محذوفة واحدة وسط الكلام → علامة واحدة على كلمة واحدة '
      'والمؤشر يتابع حتى الاكتمال', () {
    // زناد انحدار المطابقة الأولى: حرف المحذوفة يختلف عن التالية لها،
    // والتالية يتكرر حرفها بعدها — المسح من المتوقَّع يصادف الحرف
    // المتقدم زائدًا قبل الموضع المتعاقب الحقيقي.
    var drop = -1;
    for (var i = 15; i + 2 < range.units.length; i++) {
      if (range.units[i].letter != range.units[i + 1].letter &&
          range.units[i + 1].letter == range.units[i + 2].letter) {
        drop = i;
        break;
      }
    }
    expect(drop, greaterThan(0), reason: 'العيّنة يجب أن تحوي نمط الزناد');

    final preds = [...range.units]..removeAt(drop);
    final res = run(preds);
    expect(res.complete, isTrue, reason: 'حذف وحدة واحدة لا يمنع الاكتمال');
    expect(res.completed, range.wordSpans.length,
        reason: 'المؤشر يتابع بلا تعثر حتى آخر كلمة');
    expect(res.incorrect.length, 1,
        reason: 'علامة واحدة لا سلسلة أخطاء كاذبة على كلمات سليمة');
    // الكلمة الموسومة هي كلمة الوحدة المحذوفة نفسها.
    final span = range.spanOfUnit(drop)!;
    expect(res.incorrect.first, (span.verseIdx, span.wordIdx));
  });

  test('C2-أ: وحدة مستبدلة (حرف مختلف) → خطأ على كلمتها وحدها + اكتمال', () {
    var target = -1;
    for (var i = 15; i + 2 < range.units.length; i++) {
      if (range.units[i].letter != range.units[i + 1].letter &&
          range.units[i + 1].letter == range.units[i + 2].letter) {
        target = i;
        break;
      }
    }
    expect(target, greaterThan(0));
    final foreign = range.units.firstWhere((u) =>
        u.letter != range.units[target].letter &&
        u.letter != range.units[target + 1].letter);
    final preds = [...range.units];
    preds[target] = foreign;
    final res = run(preds);
    expect(res.complete, isTrue);
    expect(res.completed, range.wordSpans.length);
    expect(res.incorrect.length, 1);
  });

  test(
      'C7: الاستئناف بعد المصحح مع وحدة ضجيج في أول الكلام → لا كلمات '
      'تُوسم خطأً', () {
    // تلُ الآية حتى حدّ كلمة عميقة (فهرس ≥ 10) — موضع شيت واقعي.
    var pauseSpan = -1;
    for (var s = 0; s < range.wordSpans.length; s++) {
      if (range.wordSpans[s].endUnit >= 40) {
        pauseSpan = s;
        break;
      }
    }
    expect(pauseSpan, greaterThan(0));
    final n = range.wordSpans[pauseSpan].endUnit + 1;

    QuranUnit noise = range.units.first;
    for (final u in range.units) {
      if (u.letter != range.units[n].letter &&
          u.letter != range.units[n + 1].letter &&
          u.letter != range.units[n + 2].letter) {
        noise = u;
        break;
      }
    }

    final first = range.units.sublist(0, n);
    final resume = [noise, ...range.units.sublist(n)];
    final incorrect = <(int, int)>[];
    var complete = false;
    final tracker = RangeLiveTracker(
      range: range,
      onWordDone: (v, w, k, _) {
        if (k != TasmeeErrorKind.correct) incorrect.add((v, w));
      },
      onRangeComplete: () => complete = true,
    );
    feed(tracker, first);
    tracker.rearmAcquisition();
    feed(tracker, resume);
    expect(complete, isTrue, reason: 'الاستئناف يتابع حتى الاكتمال');
    expect(incorrect, isEmpty,
        reason: 'وحدة ضجيج أولى بعد الاستئناف لا تُوسم كلمات سليمة خطأً');
  });

  test(
      'C7: الاستئناف بإعادة الكلمة المصحَّحة ثم المواصلة → لا كلمات تُوسم '
      'خطأً', () {
    var pauseSpan = -1;
    for (var s = 0; s < range.wordSpans.length; s++) {
      final sp = range.wordSpans[s];
      final wordLen = sp.endUnit - sp.startUnit + 1;
      if (sp.endUnit >= 40 && wordLen >= 4) {
        pauseSpan = s;
        break;
      }
    }
    expect(pauseSpan, greaterThan(0));
    final span = range.wordSpans[pauseSpan];
    final n = span.endUnit + 1;

    final first = range.units.sublist(0, n);
    final resume = [
      ...range.units.sublist(span.startUnit, n), // إعادة الكلمة المصحَّحة.
      ...range.units.sublist(n),
    ];
    final incorrect = <(int, int)>[];
    var complete = false;
    final tracker = RangeLiveTracker(
      range: range,
      onWordDone: (v, w, k, _) {
        if (k != TasmeeErrorKind.correct) incorrect.add((v, w));
      },
      onRangeComplete: () => complete = true,
    );
    feed(tracker, first);
    tracker.rearmAcquisition();
    feed(tracker, resume);
    expect(complete, isTrue);
    expect(incorrect, isEmpty,
        reason: 'إعادة الكلمة المصحَّحة قبل المواصلة لا تُوسم شيئًا خطأً');
  });

  group('C3 — إرساء الالتقاط على مستوى الحرف', () {
    test('وحدة ضجيج في أول المخزن → أول كلمة خلال ≤ 6 وحدات', () {
      var unitsFed = 0;
      var firstWordAt = -1;
      final tracker = RangeLiveTracker(
        range: range,
        onRangeWord: (v, w) {
          if (firstWordAt < 0) firstWordAt = unitsFed;
        },
      );
      QuranUnit noise = range.units.first;
      for (final u in range.units) {
        if (u.letter != range.units[0].letter &&
            u.letter != range.units[1].letter) {
          noise = u;
          break;
        }
      }
      for (var i = 0; i < 40 && firstWordAt < 0; i++) {
        final stream = [noise, ...range.units.sublist(0, i + 1)];
        unitsFed = i + 2; // الوحدات المُغذّاة فعليًّا (ضوضاء + i+1).
        tracker.onUnits(stream);
      }
      expect(firstWordAt, greaterThan(0));
      expect(firstWordAt, lessThanOrEqualTo(6),
          reason: 'الإرساء بمستوى الحرف يتسامح مع وحدة زائدة أولى — '
              'كان يحتاج امتلاء البافر (12 وحدة)');
    });

    test('سقوط أول 4 وحدات من آية (تأخر الميكروفون) → تُرسى وتكتمل', () {
      final ayah = QuranReferenceRange.fromVerses(
          [refDb.getReference(suraIdx: 36, ayaIdx: 82)!])!;
      final done = <(int, int, TasmeeErrorKind)>[];
      var complete = false;
      final tracker = RangeLiveTracker(
        range: ayah,
        onWordDone: (v, w, k, _) => done.add((v, w, k)),
        onRangeComplete: () => complete = true,
      );
      // أسقط أول 4 وحدات من بداية التلاوة المتعرَّف عليها.
      final preds = ayah.units.sublist(4);
      for (var i = 1; i <= preds.length; i++) {
        tracker.onUnits(preds.sublist(0, i));
      }
      expect(tracker.isAcquiring, isFalse, reason: 'أُرسيت على موضع البداية');
      expect(complete, isTrue, reason: 'الآية تكتمل رغم سقوط البداية');
      // الكلمات قبل نقطة الإرساء ابتُلعت صمتًا (لم تُتلَ) والبقية صحيحة.
      expect(done.length, greaterThan(0));
      expect(done.every((t) => t.$3 == TasmeeErrorKind.correct), isTrue);
      expect(done.length, lessThan(ayah.wordSpans.length));
    });
  });

  group('C6 — إعادة النطق بالسياق وعدّ أدلة الخطأ', () {
    test('fromWordWithContext: الكلمة السابقة + المستهدفة، وعدّ وحداتها', () {
      final verse = verses[1]; // 2:255 — كلمات كثيرة وسياقات دمج.
      // اختر كلمة عميقة (لا أولى) ذات وحدات وسابقة ذات وحدات.
      var target = -1;
      for (var w = 1; w < verse.uthmaniWords.length; w++) {
        if (verse.unitWordIdx.contains(w) &&
            verse.unitWordIdx.contains(w - 1)) {
          target = w;
          break;
        }
      }
      expect(target, greaterThan(0));
      final rangeCtx = QuranReferenceRange.fromWordWithContext(verse, target)!;
      final alone = QuranReferenceRange.fromSingleWord(verse, target)!;
      // النطاق أوسع من الكلمة وحدها (سياق) ويضم الكلمتين.
      expect(rangeCtx.units.length, greaterThan(alone.units.length));
      expect(rangeCtx.wordSpans.length, anyOf(1, 2));
      expect(
        rangeCtx.wordUnitCount(target),
        alone.units.length,
        reason: 'وحدات المستهدفة نفسها في كلا النطاقين',
      );
      if (rangeCtx.wordSpans.length == 2) {
        expect(rangeCtx.wordSpans.first.wordIdx, target - 1);
        expect(rangeCtx.wordSpans.last.wordIdx, target);
      }
      // كلمة أولى بلا سابقة: النطاق = الكلمة وحدها.
      final firstCtx = QuranReferenceRange.fromWordWithContext(verse, 0);
      expect(firstCtx!.wordSpans.length, 1);
      // كلمة بلا وحدات → null (غير قابلة لإعادة النطق).
      var unitless = -1;
      for (var w = 0; w < verse.uthmaniWords.length; w++) {
        if (!verse.unitWordIdx.contains(w)) {
          unitless = w;
          break;
        }
      }
      if (unitless >= 0) {
        expect(
            QuranReferenceRange.fromWordWithContext(verse, unitless), isNull);
      }
    });

    test('wrongUnits: وحدتان مخطئتان في كلمة واحدة → دليلان', () {
      // احذف وحدتين متجاورتين من كلمة عميقة: وسمتان على كلمتها يجب أن
      // يحملهما تفصيل الخطأ (سياسة الدليلين في المصحّح).
      var drop = -1;
      for (var i = 15; i + 3 < range.units.length; i++) {
        final span = range.spanOfUnit(i)!;
        if (span.endUnit >= i + 2) {
          drop = i;
          break;
        }
      }
      expect(drop, greaterThan(0));
      final preds = [...range.units]..removeRange(drop, drop + 2);
      TasmeeWordMistake? marked;
      var complete = false;
      final tracker = RangeLiveTracker(
        range: range,
        onWordDone: (v, w, k, m) {
          if (k != TasmeeErrorKind.correct && marked == null) marked = m;
        },
        onRangeComplete: () => complete = true,
      );
      feed(tracker, preds);
      expect(complete, isTrue);
      expect(marked, isNotNull);
      expect(marked!.wrongUnits, greaterThanOrEqualTo(2),
          reason: 'حذف وحدتين = دليلان على الكلمة نفسها');
    });
  });

  group('C4 — تسامح نهاية النطاق (وضع المعلم)', () {
    late QuranReferenceRange ayahRange;

    setUpAll(() {
      ayahRange = QuranReferenceRange.fromVerses(
          [refDb.getReference(suraIdx: 36, ayaIdx: 82)!])!;
    });

    test('آخر وحدة ساقطة من التعرّف → الآية تكتمل', () {
      final done = <int>[];
      var complete = false;
      final tracker = RangeLiveTracker(
        range: ayahRange,
        onWordDone: (v, w, k, _) {
          if (k != TasmeeErrorKind.correct) done.add(w);
        },
        onRangeComplete: () => complete = true,
      );
      final n = ayahRange.units.length;
      feed(tracker, ayahRange.units.sublist(0, n - 1));
      expect(complete, isTrue,
          reason: 'وحدة الختام كثيرًا ما تسقط؛ الآية يجب أن تكتمل');
      expect(tracker.completedWords, ayahRange.wordSpans.length);
      expect(done, isEmpty,
          reason: 'لا خطأ على تلاوة سليمة حذفت وحدتها الأخيرة');
    });

    test('حذف وحدة قرب النهاية (قبل الأخيرة بقليل) → اكتمال وخطأ واحد', () {
      // آخر موضع قبل النهاية يخالف حرفهُ التالي له — يضمن مسار القفزة
      // الواسعة بدل المطابقة الفورية.
      var drop = -1;
      final n = ayahRange.units.length;
      for (var i = n - 3; i >= n - 8 && i > 0; i--) {
        if (ayahRange.units[i].letter != ayahRange.units[i + 1].letter) {
          drop = i;
          break;
        }
      }
      expect(drop, greaterThan(0));
      final preds = [...ayahRange.units]..removeAt(drop);
      final incorrect = <int>[];
      var complete = false;
      final tracker = RangeLiveTracker(
        range: ayahRange,
        onWordDone: (v, w, k, _) {
          if (k != TasmeeErrorKind.correct) incorrect.add(w);
        },
        onRangeComplete: () => complete = true,
      );
      feed(tracker, preds);
      expect(complete, isTrue,
          reason: 'قرب النهاية لا تُجمع تأكيدات 3 وحدات — تُقبل بالمتاح');
      expect(incorrect.length, 1,
          reason: 'علامة واحدة على كلمة الوحدة المحذوفة فقط');
    });
  });
}
