// يولّد أصل إسناد الوحدات إلى الكلمات العثمانية لكل آية — يُشغَّل مرة
// واحدة خارج التطبيق (كما يفضّل فحص التسميع) ويُشحن بجانب المرجع:
//
//   dart run tool/generate_unit_word_map.dart
//
// الناتج: assets/quran_lab/unit_word_map.json.gz
//   { "1:1": [0, 0, 1, ...], ... }  — فهرس كلمة كل وحدة (نفس طول
//   وحدات الآية) من منطق mapUnitsToUthmaniWords نفسه، فيوفَّر حساب
//   المحاذاة وقت التشغيل وتثبَّت النتيجة للمراجعة والاختبار الذهبي.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:quran_library/src/tasmee/engine/quran_word_mapping.dart';
import 'package:quran_library/src/tasmee/engine/quran_units.dart';

Future<void> main() async {
  final sw = Stopwatch()..start();
  final lexicon = QuranUnitLexicon.fromTokensText(
      File('assets/quran_lab/tokens.txt').readAsStringSync());
  final gz =
      File('assets/quran_lab/ordered_quran_phonemes.json.gz').readAsBytesSync();
  final raw = jsonDecode(utf8.decode(gzip.decode(gz))) as Map<String, dynamic>;

  final out = <String, List<int>>{};
  var totalUnits = 0;
  var countMatchVerses = 0;
  for (final entry in raw.entries) {
    final m = Map<String, dynamic>.from(entry.value as Map);
    final phonemeWords = (m['aya_phonemes_list'] as List).cast<String>();
    final uthmaniWords =
        ((m['aya_text'] as String).trim()).split(RegExp(r'\s+'));
    final units = <QuranUnit>[];
    final phonemeIdx = <int>[];
    for (var w = 0; w < phonemeWords.length; w++) {
      final wordUnits = lexicon.segment(phonemeWords[w]);
      units.addAll(wordUnits);
      phonemeIdx.addAll(List<int>.filled(wordUnits.length, w));
    }
    if (phonemeIdx.toSet().length == uthmaniWords.length) countMatchVerses++;
    final mapping = mapUnitsToUthmaniWords(
      units: units,
      phonemeIdx: phonemeIdx,
      uthmaniWords: uthmaniWords,
    );
    if (mapping.length != units.length) {
      stderr.writeln('طول غير متطابق في ${entry.key} — تخطٍّ');
      continue;
    }
    out[entry.key] = mapping;
    totalUnits += units.length;
    // ضمانات جودة على الناتج النهائي: حدود الفهرس والرتابة.
    for (var k = 0; k < mapping.length; k++) {
      if (mapping[k] < 0 || mapping[k] >= uthmaniWords.length) {
        stderr.writeln('فهرس خارج النطاق في ${entry.key} عند $k');
        break;
      }
      if (k > 0 && mapping[k] < mapping[k - 1]) {
        stderr.writeln('رتابة مكسورة في ${entry.key} عند $k');
        break;
      }
    }
  }

  final json = jsonEncode(out);
  final bytes = utf8.encode(json);
  const outPath = 'assets/quran_lab/unit_word_map.json.gz';
  final encoded = GZipCodec(level: 9).encode(Uint8List.fromList(bytes));
  File(outPath).writeAsBytesSync(encoded);
  stdout.writeln('آيات: ${out.length} (مطابقة عدد: $countMatchVerses، محاذاة: '
      '${out.length - countMatchVerses}) — وحدات: $totalUnits');
  stdout.writeln(
      'raw: ${bytes.length} bytes → gz: ${encoded.length} bytes → $outPath');
  stdout.writeln('استغرق ${sw.elapsed}');
}
