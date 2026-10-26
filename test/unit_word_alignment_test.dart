import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/quran_reference.dart';
import 'package:quran_library/src/tasmee/engine/quran_units.dart';

/// فحص محاذاة إسناد الوحدات إلى الكلمات العثمانية (استبدال المسار
/// النسبي الأعمى) — ذهبيات آيات التقرير + دقة المعيار على مستوى الوحدات.
void main() {
  final lex = QuranUnitLexicon.fromTokensText(
    File('test/fixtures/tokens.txt').readAsStringSync(),
  );

  /// الذهبيات من الأصل المولد (tool/generate_unit_word_map.dart) بعد
  /// مطابقته 100% مع نسخة Python المُتحقق منها على المصحف كله.
  const goldens = <String, List<int>>{
    '2:2': [
      0,
      0,
      0,
      1,
      1,
      1,
      1,
      1,
      2,
      2,
      3,
      3,
      3,
      4,
      4,
      4,
      5,
      5,
      5,
      6,
      6,
      6,
      6,
      6,
      6,
      6
    ],
    '2:5': [
      0,
      0,
      0,
      0,
      0,
      1,
      1,
      1,
      2,
      2,
      3,
      4,
      4,
      4,
      4,
      5,
      5,
      5,
      5,
      5,
      5,
      6,
      6,
      7,
      7,
      7,
      7,
      7,
      7,
      7
    ],
    '2:7': [
      0,
      0,
      0,
      1,
      1,
      1,
      2,
      2,
      2,
      3,
      3,
      3,
      3,
      3,
      3,
      4,
      4,
      4,
      4,
      5,
      5,
      5,
      5,
      5,
      6,
      6,
      6,
      6,
      7,
      7,
      7,
      7,
      7,
      7,
      7,
      8,
      8,
      8,
      8,
      8,
      9,
      9,
      9,
      9,
      10,
      10,
      10,
      10,
      10,
      11,
      11,
      11,
      11
    ],
    // الحروف المقطعة «طسٓ» — أسوأ حالة في التقرير: وحدتان لكلمة طس.
    '27:1': [
      0,
      0,
      1,
      1,
      1,
      2,
      2,
      2,
      3,
      3,
      3,
      3,
      3,
      4,
      4,
      4,
      4,
      4,
      4,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5
    ],
  };

  test('ذهبيات آيات التقرير عبر أصل الإسناد المولد مسبقًا', () async {
    final refDb = QuranPhonemeReference(lexicon: lex);
    await refDb.load(
      filePath: 'assets/quran_lab/ordered_quran_phonemes.json.gz',
      unitWordMapFilePath: 'assets/quran_lab/unit_word_map.json.gz',
    );
    for (final entry in goldens.entries) {
      final parts = entry.key.split(':');
      final verse = refDb.getReference(
          suraIdx: int.parse(parts[0]), ayaIdx: int.parse(parts[1]))!;
      expect(verse.unitWordIdx, entry.value,
          reason: 'إسناد ${entry.key} يطابق الذهبي المولد');
      // كل كلمة عثمانية ذات حروف مغطاة (لا كلمة تسقط من التسميع).
      final covered = List.filled(verse.uthmaniWords.length, 0);
      for (final w in verse.unitWordIdx) {
        covered[w]++;
      }
      expect(covered.every((c) => c > 0), isTrue,
          reason: 'تغطية كاملة لكلمات ${entry.key}');
    }
  });

  test(
      'دقة المحاذاة ≥ 99% على آيات المعيار (تطابق عدد الكلمات الفونيمية '
      'مع العثمانية) — كان 27% للتوزيع النسبي', () async {
    final refDb = QuranPhonemeReference(lexicon: lex);
    await refDb.load(
        filePath: 'assets/quran_lab/ordered_quran_phonemes.json.gz');
    var ok = 0;
    var total = 0;
    var verses = 0;
    for (var sura = 1; sura <= 114; sura++) {
      for (var aya = 1;; aya++) {
        final verse = refDb.getReference(suraIdx: sura, ayaIdx: aya);
        if (verse == null) break;
        if (verse.phonemeWords.length != verse.uthmaniWords.length) continue;
        // معيار هذه الآيات هو فهرس الكلمة الفونيمية نفسه — قيّم المحاذاة
        // مباشرة (بلا مسارات تطابق العدد/الأوزان).
        final aligned = alignUnitsToUthmaniWords(
          units: verse.units,
          uthmaniWords: verse.uthmaniWords,
        );
        for (var u = 0; u < verse.units.length; u++) {
          // phonemeIdx يُعاد بناؤه من حدود الكلمات الفونيمية.
          total++;
          if (aligned[u] == verse.unitWordIdx[u]) ok++;
        }
        verses++;
      }
    }
    expect(verses, 2121, reason: 'عدد آيات المعيار ثابت في البيانات');
    expect(ok / total, greaterThanOrEqualTo(0.99),
        reason: 'الدقة المقيسة في الفحص: 99.6%');
  });
}
