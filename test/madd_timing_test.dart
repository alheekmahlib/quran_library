import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/madd_timing.dart';
import 'package:quran_library/src/tasmee/engine/phoneme_aligner.dart';
import 'package:quran_library/src/tasmee/engine/quran_units.dart';

QuranUnit u(String s) => QuranUnit.parse(s, 0);

void main() {
  // بيانات حقيقية مقيسة من تلاوة الفاتحة (العفاسي، 16k):
  // وحدات: بِ س مِ للَ اا هِ ررَ ح مَ اا نِ ررَ حِ ۦۦۦۦ م
  // طوابع: 0.28 0.48 0.64 1.08 1.28 1.40 1.84 2.04 2.16 2.40 2.56 2.96 3.20 5.92 6.04
  group('معايرة على تسجيل حقيقي (العفاسي — البسملة)', () {
    final ref = [
      u('بِ'),
      u('س'),
      u('مِ'),
      u('للَ'),
      u('اا'),
      u('هِ'),
      u('ررَ'),
      u('ح'),
      u('مَ'),
      u('اا'),
      u('نِ'),
      u('ررَ'),
      u('حِ'),
      u('ۦۦۦۦ'),
      u('م')
    ];
    final ts = [
      0.28,
      0.48,
      0.64,
      1.08,
      1.28,
      1.40,
      1.84,
      2.04,
      2.16,
      2.40,
      2.56,
      2.96,
      3.20,
      5.92,
      6.04
    ];
    final ops = [
      for (var i = 0; i < ref.length; i++)
        UnitAlignOp(type: 'match', refIdx: i, predIdx: i),
    ];

    List<MaddTimingVerdict> run({MaddTimingConfig? cfg}) => judgeMaddTimings(
          ops: ops,
          refUnits: ref,
          predCount: ref.length,
          predTimestamps: ts,
          totalDurationSec: 6.2,
          config: cfg ?? const MaddTimingConfig(),
        );

    test('المدود القصيرة (golden=2) لا تُقاس زمنيًا', () {
      final v = run();
      expect(v.every((x) => x.goldenHarakat >= 3), isTrue);
      expect(v.length, 1); // ۦۦۦۦ فقط
    });

    test('المدّ الطويل الموجود فعلًا (فجوة 2.72s) → ok', () {
      final v = run();
      expect(v.single.ok, isTrue);
      expect(v.single.goldenHarakat, 4);
      expect(v.single.actualHarakat, greaterThan(2.0));
    });

    test('مدّ مفقود فعلًا (فجوة ≈ إيقاع القارئ) → غير ok', () {
      // نفس التسجيل لكن المدّ الطويل أُلغي زمنيًا: ۦۦۦۦ يطلق بعد 0.2s فقط.
      final brokenTs = [...ts]..[13] = 3.40; // حِ@3.20 → ۦۦۦۦ@3.40
      final v = judgeMaddTimings(
        ops: ops,
        refUnits: ref,
        predCount: ref.length,
        predTimestamps: brokenTs,
        totalDurationSec: 3.6,
      );
      expect(v.single.ok, isFalse);
    });

    test('minTimedGolden قابل للضبط: golden=2 يُقاس عند خفضه', () {
      final v = run(cfg: const MaddTimingConfig(minTimedGolden: 2));
      expect(v.length, 3); // اا، اا، ۦۦۦۦ
    });
  });

  test('مدّ أول وحدة: فجوته من الصفر', () {
    final ops = [const UnitAlignOp(type: 'match', refIdx: 0, predIdx: 0)];
    final v = judgeMaddTimings(
      ops: ops,
      refUnits: [u('اااااا')],
      predCount: 1,
      predTimestamps: [2.0],
      totalDurationSec: 2.5,
    );
    // لا فجوات إيقاع → احتياطي harakaSec=0.5: gap=2.0 >= 0.5*2 → ok.
    expect(v.single.ok, isTrue);
  });

  test('طوابع فارغة → لا أحكام', () {
    expect(
      judgeMaddTimings(
          ops: const [],
          refUnits: [u('اا')],
          predCount: 0,
          predTimestamps: const [],
          totalDurationSec: 4.0),
      isEmpty,
    );
  });
}
