import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/quran_units.dart';

void main() {
  late QuranUnitLexicon lex;
  setUpAll(() {
    lex = QuranUnitLexicon.fromTokensText(
      File('test/fixtures/tokens.txt').readAsStringSync(),
    );
  });

  group('lexicon', () {
    test('يحمّل 250 رمزًا بدون <blank> (251 فئة = 250 + blank)', () {
      expect(lex.bySymbol.length, 250);
      expect(lex.bySymbol.containsKey('<blank>'), isFalse);
    });
  });

  group('قواعد الرموز', () {
    test('حرف بحركة: بَ → letter=ب haraka=فتحة', () {
      final u = lex.bySymbol['بَ']!;
      expect(u.letter, 'ب');
      expect(u.haraka, 'َ');
      expect(u.isShadda, isFalse);
    });
    test('شدة: ببَ → isShadda وletter=ب وcoreRepeat=2', () {
      final u = lex.bySymbol['ببَ']!;
      expect(u.isShadda, isTrue);
      expect(u.letter, 'ب');
      expect(u.coreRepeat, 2);
    });
    test('مدّ: اااااا → isMadd وmaddLength=6', () {
      final u = lex.bySymbol['اااااا']!;
      expect(u.isMadd, isTrue);
      expect(u.maddLength, 6);
      expect(u.letter, 'ا');
    });
    test('مدّ واو بحركة: وووَ → maddLength=3 وharaka=فتحة', () {
      final u = lex.bySymbol['وووَ']!;
      expect(u.maddLength, 3);
      expect(u.haraka, 'َ');
    });
    test('قلقلة: ققڇ → qalqalah وisShadda', () {
      final u = lex.bySymbol['ققڇ']!;
      expect(u.qalqalah, isTrue);
      expect(u.isShadda, isTrue);
    });
    test('غنّة: ننن → ghunna وletter=ن', () {
      final u = lex.bySymbol['ننن']!;
      expect(u.ghunna, isTrue);
      expect(u.letter, 'ن');
    });
    test('إخفاء: ااۜ → isMadd وmaddLength=2 وikhfaa', () {
      final u = lex.bySymbol['ااۜ']!;
      expect(u.ikhfaa, isTrue);
      expect(u.maddLength, 2);
    });
    test('سكوت: ؙ → isSilence وisNoiseInsert', () {
      final u = lex.bySymbol['ؙ']!;
      expect(u.isSilence, isTrue);
      expect(u.isNoiseInsert, isTrue);
    });
    test('حركة مفردة: َ → isHarakaOnly', () {
      expect(lex.bySymbol['َ']!.isHarakaOnly, isTrue);
    });
    test('ٲ → letter=ا وisMadd', () {
      final u = lex.bySymbol['ٲ']!;
      expect(u.letter, 'ا');
      expect(u.isMadd, isTrue);
    });
  });

  group('segment', () {
    test('الفاتحة 1:1 تُقطَّع ويعاد تركيبها', () {
      const s = 'بِسمِ للَااهِ ررَحمَاانِ ررَحِۦۦۦۦم';
      final units = lex.segment(s);
      expect(units.map((u) => u.symbol).join(), s.replaceAll(' ', ''));
      expect(units.first.symbol, 'بِ');
      expect(units.map((u) => u.symbol), contains('اا'));
      // آخر وحدة: ميم «رحيم» ساكنة بلا حركة (الكسرة قبل مدّ الياء).
      expect(units.last.symbol, 'م');
    });
    test('أطول مطابقة: تتَ لا تُقطَّع ت+تَ', () {
      final units = lex.segment('تتَ');
      expect(units.map((u) => u.symbol).join(), 'تتَ');
      expect(units.length, 1);
    });
    test('نص غير قابل للتقطيع يُعيد []', () {
      expect(lex.segment('XYZ'), isEmpty);
    });
  });

  test('كل آيات القرآن تُقطَّع كاملة (فحص شامل)', () {
    final bytes = File('assets/quran_lab/ordered_quran_phonemes.json.gz')
        .readAsBytesSync();
    final json = gzip.decode(bytes);
    final map = jsonDecode(utf8.decode(json)) as Map<String, dynamic>;
    var checked = 0;
    for (final v in map.values) {
      final s = (v as Map)['aya_phoneme'] as String;
      expect(lex.segmentsFully(s), isTrue, reason: 'فشل تقطيع: $s');
      checked++;
    }
    expect(checked, 6236);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
