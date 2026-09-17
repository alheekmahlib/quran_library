import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/final_reconciliation.dart';
import 'package:quran_library/src/tasmee/engine/models/recitation_result.dart';
import 'package:quran_library/src/tasmee/engine/phoneme_aligner.dart';
import 'package:quran_library/src/tasmee/engine/quran_reference.dart';
import 'package:quran_library/src/tasmee/engine/quran_units.dart';
import 'package:quran_library/src/tasmee/engine/tasmee_error_kind.dart';

void main() {
  // العينة: 1:1 (4 كلمات)، 2:255 (طويلة)، 36:82 (قصيرة) — تُحاكي نطاق صفحة.
  late QuranReferenceRange range;
  late List<QuranReferenceVerse> verses;

  setUpAll(() async {
    final lex = QuranUnitLexicon.fromTokensText(
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

  String keyOf(int verseIdx, int wordIdx) => 'v$verseIdx:w$wordIdx';

  int verseIndexOf(int suraIdx, int ayaIdx) {
    for (var i = 0; i < verses.length; i++) {
      if (verses[i].verseKey == '$suraIdx:$ayaIdx') return i;
    }
    return -1;
  }

  RecitationError tagged({
    required int suraIdx,
    required int ayaIdx,
    required int wordIdx,
    String errorType = 'normal',
    String speechErrorType = 'replace',
  }) =>
      RecitationError(
        errorType: errorType,
        speechErrorType: speechErrorType,
        suraIdx: suraIdx,
        ayaIdx: ayaIdx,
        wordIdx: wordIdx,
      );

  group('matchedSpansFromOps — تغطية المحاذاة', () {
    test('تلاوة كاملة → كل كلمات النطاق مغطاة', () {
      final ops = alignUnits(range.units, range.units);
      final spans = matchedSpansFromOps(ops, range);
      expect(spans.length, range.wordCount);
      expect(spans.first, (verseIdx: 0, wordIdx: 0));
    });

    test('تلاوة جزئية → فقط الكلمات المُطابَقة مغطاة والباقي يُسقط', () {
      // مطابقات حتى نهاية الكلمة الثالثة ثم حذوف ختامية (توقف مبكر).
      final k = range.wordSpans[2].endUnit + 1;
      final ops = <UnitAlignOp>[
        for (var i = 0; i < k; i++)
          UnitAlignOp(type: 'match', refIdx: i, predIdx: i),
        for (var i = k; i < range.units.length; i++)
          UnitAlignOp(type: 'delete', refIdx: i, predIdx: -1),
      ];
      final spans = matchedSpansFromOps(ops, range);
      expect(spans.length, 3, reason: 'ثلاث كلمات فقط مغطاة');
      expect(
        spans,
        [
          for (final ws in range.wordSpans.take(3))
            (verseIdx: ws.verseIdx, wordIdx: ws.wordIdx),
        ],
      );
    });
  });

  group('recitedVerseRangeFromSpans — المقطع المُتلى فعليًا', () {
    test('من أول وآخر كلمة مغطاة', () {
      final range1 = recitedVerseRangeFromSpans(const [
        (verseIdx: 1, wordIdx: 0),
        (verseIdx: 1, wordIdx: 3),
        (verseIdx: 2, wordIdx: 0)
      ]);
      expect(range1, isNotNull);
      expect(range1!.first, 1);
      expect(range1.last, 2);
    });

    test('فارغ → null', () {
      expect(recitedVerseRangeFromSpans(const []), isNull);
    });
  });

  group('reconcileFinalWordVerdicts — التوفيق النهائي', () {
    test('كلمة مغطاة بلا أخطاء → صحيحة حتى لو لوّنها المتتبع الحي خطأ', () {
      final verdicts = reconcileFinalWordVerdicts(
        coveredSpans: const [(verseIdx: 0, wordIdx: 0)],
        errors: const [],
        verseIndexOf: verseIndexOf,
        keyOf: keyOf,
      );
      expect(verdicts[keyOf(0, 0)]!.correct, isTrue);
      expect(verdicts[keyOf(0, 0)]!.errorKind, isNull);
    });

    test('خطأ موسوم على كلمة مغطاة → خطأ بنوعه', () {
      final verdicts = reconcileFinalWordVerdicts(
        coveredSpans: const [(verseIdx: 0, wordIdx: 0)],
        errors: [tagged(suraIdx: 1, ayaIdx: 1, wordIdx: 0)],
        verseIndexOf: verseIndexOf,
        keyOf: keyOf,
      );
      expect(verdicts[keyOf(0, 0)]!.correct, isFalse);
      expect(verdicts[keyOf(0, 0)]!.errorKind, TasmeeErrorKind.normal);
    });

    test('كلمة محذوفة (غير مغطاة) عليها خطأ delete → تبقى خطأ ولا تُسقط', () {
      final verdicts = reconcileFinalWordVerdicts(
        coveredSpans: const [(verseIdx: 0, wordIdx: 0)],
        errors: [tagged(suraIdx: 36, ayaIdx: 82, wordIdx: 1)],
        verseIndexOf: verseIndexOf,
        keyOf: keyOf,
      );
      expect(verdicts.containsKey(keyOf(0, 0)), isTrue);
      expect(verdicts[keyOf(2, 1)]!.correct, isFalse);
    });

    test('كلمة غير مغطاة وبلا أخطاء → تُسقط (كلمة لم تُتلَ لا تظهر)', () {
      final verdicts = reconcileFinalWordVerdicts(
        coveredSpans: const [(verseIdx: 0, wordIdx: 0)],
        errors: const [],
        verseIndexOf: verseIndexOf,
        keyOf: keyOf,
      );
      expect(verdicts.containsKey(keyOf(1, 0)), isFalse);
      expect(verdicts.containsKey(keyOf(2, 0)), isFalse);
    });

    test('تصحيح مقبول في المصحّح → يبقى صحيحًا وتُتجاهل أخطاؤه الأصلية', () {
      final accepted = {keyOf(0, 1)};
      final verdicts = reconcileFinalWordVerdicts(
        coveredSpans: const [(verseIdx: 0, wordIdx: 0)],
        errors: [tagged(suraIdx: 1, ayaIdx: 1, wordIdx: 1)],
        verseIndexOf: verseIndexOf,
        keyOf: keyOf,
        acceptedCorrectionKeys: accepted,
      );
      expect(verdicts.containsKey(keyOf(0, 1)), isFalse,
          reason: 'التصحيح المقبول يُدار خارج التوفيق ويبقى أخضر');
    });

    test('تعدّد أخطاء على كلمة واحدة → دمج بأعلى أسبقية', () {
      final verdicts = reconcileFinalWordVerdicts(
        coveredSpans: const [(verseIdx: 0, wordIdx: 0)],
        errors: [
          tagged(suraIdx: 1, ayaIdx: 1, wordIdx: 0, errorType: 'tashkeel'),
          tagged(suraIdx: 1, ayaIdx: 1, wordIdx: 0, errorType: 'normal'),
        ],
        verseIndexOf: verseIndexOf,
        keyOf: keyOf,
      );
      expect(verdicts[keyOf(0, 0)]!.errorKind, TasmeeErrorKind.normal);
    });

    test('خطأ بلا وسم موضع (insert) → يُتجاهل في التوفيق', () {
      const untagged = RecitationError(
        errorType: 'normal',
        speechErrorType: 'insert',
      );
      final verdicts = reconcileFinalWordVerdicts(
        coveredSpans: const [(verseIdx: 0, wordIdx: 0)],
        errors: [untagged],
        verseIndexOf: verseIndexOf,
        keyOf: keyOf,
      );
      expect(verdicts[keyOf(0, 0)]!.correct, isTrue);
    });
  });
}
