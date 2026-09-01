import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/quran_reference.dart';
import 'package:quran_library/src/tasmee/engine/quran_units.dart';

void main() {
  late QuranPhonemeReference ref;
  late QuranUnitLexicon lex;
  setUpAll(() async {
    lex = QuranUnitLexicon.fromTokensText(
      File('test/fixtures/tokens.txt').readAsStringSync(),
    );
    ref = QuranPhonemeReference(lexicon: lex);
    await ref.load(filePath: 'test/fixtures/quran_phonemes_sample.json.gz');
  });

  test('يحمّل 5 آيات', () {
    expect(ref.verseCount, 5);
    expect(ref.isLoaded, isTrue);
  });

  test('1:1 — النص والكلمات والوحدات ونِسب الوحدات للكلمات', () {
    final v = ref.getReference(suraIdx: 1, ayaIdx: 1)!;
    expect(v.verseKey, '1:1');
    // البسملة تبدأ بـ «بِسْمِ» ونصها العثماني 4 كلمات.
    expect(v.uthmani.runes.first, 0x628); // ب
    expect(v.uthmani.split(' ').length, 4);
    expect(v.phonemeWords.length, 4);
    expect(v.uthmaniWords.length, 4);
    expect(v.unitWordIdx.length, v.units.length);
    for (var i = 0; i < v.unitWordIdx.length; i++) {
      expect(v.unitWordIdx[i], inInclusiveRange(0, 3));
    }
    // آخر وحدة تنتمي للكلمة الأخيرة (ررَحِۦۦۦۦم).
    expect(v.unitWordIdx.last, 3);
    // كلمة الوحدة الأخيرة هي الكلمة العثمانية الرابعة.
    expect(v.wordAt(v.units.length - 1), v.uthmaniWords[3]);
  });

  test('آية غير موجودة → null', () {
    expect(ref.getReference(suraIdx: 1, ayaIdx: 99), isNull);
  });

  test('عدد كلمات النص == عدد كلمات الفونيمات في كل العينة', () {
    final v = ref.getReference(suraIdx: 112, ayaIdx: 1)!;
    expect(v.uthmaniWords.length, v.phonemeWords.length);
  });
}
