import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// تحقّق تطابق فهرسة الكلمات بين مصدرين:
/// - قاعدة فونيمات التسميع (ordered_quran_phonemes.json.gz): تقسيم
///   `aya_text` بالفراغات — مفتاح التسميع `ayahUq:wordIdx+1`.
/// - بيانات عرض QPC v4 (qpc-v4.json.gz): `wordIndex` لكل كلمة —
///   `QpcV4WordSegment.wordNumber` الذي تقرأه الواجهة.
///
/// أي انزياح بين المصدرين يوسم الكلمة الخطأ بصريًا في التسميع.
void main() {
  test('عدد كلمات كل آية متطابق بين قاعدة الفونيمات وQPC v4 (فحص شامل)', () {
    final dbBytes = File('assets/quran_lab/ordered_quran_phonemes.json.gz')
        .readAsBytesSync();
    final db =
        jsonDecode(utf8.decode(gzip.decode(dbBytes))) as Map<String, dynamic>;
    final qpcBytes = File('assets/jsons/qpc-v4.json.gz').readAsBytesSync();
    final qpc =
        jsonDecode(utf8.decode(gzip.decode(qpcBytes))) as Map<String, dynamic>;

    // كلمات QPC لكل آية + استمرارية فهارسها (1..N بلا فجوات).
    final qpcCounts = <String, int>{};
    final qpcIndexes = <String, Set<int>>{};
    for (final key in qpc.keys) {
      final v = qpc[key] as Map;
      final sk = '${v['surah']}:${v['ayah']}';
      qpcCounts[sk] = (qpcCounts[sk] ?? 0) + 1;
      (qpcIndexes[sk] ??= {}).add(int.parse(v['word'].toString()));
    }

    var checked = 0;
    final anomalies = <String>[];
    for (final e in db.entries) {
      final text = (e.value as Map)['aya_text'] as String;
      final dbWords = text.split(RegExp(r'\s+')).length;
      final qpcWords = qpcCounts[e.key] ?? -1;
      checked++;

      // النمط المتوقع: كلمات QPC = كلمات القاعدة + وسم رقم الآية
      // (يستثنيه العارض). الاستثناء الموثق الوحيد: 37:130 بلا وسم.
      final ok =
          qpcWords == dbWords + 1 || (e.key == '37:130' && qpcWords == dbWords);
      if (!ok) anomalies.add('${e.key}: db=$dbWords qpc=$qpcWords');

      // فهارس QPC متصلة 1..N — أي فجوة تكسر مطابقة wordIdx+1↔wordNumber.
      final idx = qpcIndexes[e.key]!;
      final expected = {for (var i = 1; i <= qpcWords; i++) i};
      if (!idx.containsAll(expected) || idx.length != qpcWords) {
        anomalies.add('${e.key}: indexes not contiguous $idx');
      }
    }
    expect(checked, 6236);
    expect(anomalies, isEmpty,
        reason: 'انزياح فهرسة الكلمات بين المصدرين يوسم الكلمات الخطأ');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
