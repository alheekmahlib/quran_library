import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/quran_reference.dart';
import 'package:quran_library/src/tasmee/engine/quran_units.dart';

/// فحص مصحفي: إسناد كل وحدة إلى فهرس كلمتها **العثمانية** — الكلمات
/// الفونيمية تختلف عن العثمانية في ثلثي المصحف (دمج «هُدًى لِّلْمُتَّقِينَ»
/// في كلمة فونيمية واحدة مثلًا)، فأي خلط بين الفهرستين يُسقط كلمات من
/// التتبّع كليًا (لا تظهر في التسميع إطلاقًا — وتتركز في نهايات الآيات).
void main() {
  final lex = QuranUnitLexicon.fromTokensText(
    File('test/fixtures/tokens.txt').readAsStringSync(),
  );

  test('كل كلمة عثمانية في المصحف لها وحدات وفهارس رتيبة (فحص شامل)', () async {
    final refDb = QuranPhonemeReference(lexicon: lex);
    await refDb.load(
        filePath: 'assets/quran_lab/ordered_quran_phonemes.json.gz');

    var checked = 0;
    final problems = <String>[];
    for (var sura = 1; sura <= 114; sura++) {
      for (var aya = 1;; aya++) {
        final verse = refDb.getReference(suraIdx: sura, ayaIdx: aya);
        if (verse == null) break;
        checked++;
        final wordCount = verse.uthmaniWords.length;
        // كل كلمة عثمانية لها وحدة واحدة على الأقل.
        final covered = List.filled(wordCount, 0);
        var prev = 0;
        for (final w in verse.unitWordIdx) {
          if (w < 0 || w >= wordCount) {
            problems.add('$sura:$aya وحدة بفهرس خارج المدى: $w');
            break;
          }
          if (w < prev) {
            problems.add('$sura:$aya فهارس غير رتيبة');
            break;
          }
          prev = w;
          covered[w]++;
        }
        for (var w = 0; w < wordCount; w++) {
          if (covered[w] == 0) {
            problems.add('$sura:$aya الكلمة العثمانية $w '
                '«${verse.uthmaniWords[w]}» بلا وحدات — لن تظهر في التسميع');
            if (problems.length > 12) break;
          }
        }
        if (problems.length > 12) break;
      }
      if (problems.length > 12) break;
    }
    expect(checked, 6236);
    expect(problems, isEmpty, reason: problems.take(12).join('\n'));
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('هدى للمتقين (2:2): الكلمتان المدموجتان فونيميًا تُفصلان عثمانيًا',
      () async {
    final refDb = QuranPhonemeReference(lexicon: lex);
    await refDb.load(
        filePath: 'assets/quran_lab/ordered_quran_phonemes.json.gz');
    final verse = refDb.getReference(suraIdx: 2, ayaIdx: 2)!;
    // «... هُدًى لِّلْمُتَّقِينَ» — كلمة فونيمية واحدة تكسوهما؛ يجب أن
    // تحمل وحداتُ بدايتها فهرس «هُدًى» ووحدات مدّ المتقيم فهرسها.
    final hdIndex = verse.uthmaniWords.indexWhere((w) => w.startsWith('هُد'));
    expect(hdIndex, greaterThanOrEqualTo(0));
    final mtqIndex = hdIndex + 1;
    expect(verse.uthmaniWords[mtqIndex], contains('مُت'));
    final hdUnits = verse.unitWordIdx.where((w) => w == hdIndex).length;
    final mtqUnits = verse.unitWordIdx.where((w) => w == mtqIndex).length;
    expect(hdUnits, greaterThan(0), reason: '«هُدًى» لها وحدات');
    expect(mtqUnits, greaterThan(0), reason: '«لِّلْمُتَّقِينَ» لها وحدات');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
