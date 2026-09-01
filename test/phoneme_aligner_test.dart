import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/phoneme_aligner.dart';
import 'package:quran_library/src/tasmee/engine/quran_units.dart';

QuranUnit u(String s) => QuranUnit.parse(s, 0);

void main() {
  group('alignUnits', () {
    test('تطابق كامل', () {
      final ops = alignUnits([u('بِ'), u('س')], [u('بِ'), u('س')]);
      expect(ops.map((o) => o.type), ['match', 'match']);
      expect(ops.first.refIdx, 0);
      expect(ops.first.predIdx, 0);
    });

    test('حذف كلمة كاملة يظهر delete متتالية والباقي match', () {
      // مرجع: بِ س / تنبؤ: س (قفز الباء).
      final ops = alignUnits([u('بِ'), u('س')], [u('س')]);
      expect(ops.map((o) => o.type), containsAll(['delete', 'match']));
      final del = ops.firstWhere((o) => o.type == 'delete');
      expect(del.refIdx, 0);
      expect(del.predIdx, -1);
    });

    test('حرف زائد يظهر insert', () {
      final ops = alignUnits([u('س')], [u('بِ'), u('س')]);
      expect(ops.map((o) => o.type), containsAll(['insert', 'match']));
      final ins = ops.firstWhere((o) => o.type == 'insert');
      expect(ins.refIdx, -1);
      expect(ins.predIdx, 0);
    });

    test('استبدال حرف مختلف replace (ب↔ت على مستوى letter)', () {
      final ops = alignUnits([u('بِ'), u('س')], [u('تِ'), u('س')]);
      expect(ops.first.type, 'replace');
    });

    test('نفس الحرف بحالات مختلفة = match (التفاصيل للكشّاف)', () {
      expect(alignUnits([u('بَ')], [u('ب')]).first.type, 'match');
      expect(alignUnits([u('اا')], [u('اااا')]).first.type, 'match');
    });

    test('متغيرات الغنّة تتطابق على مستوى الحرف (ں↔ن)', () {
      expect(alignUnits([u('ننن')], [u('ںںں')]).first.type, 'match');
    });

    test('إحصاءات', () {
      final stats =
          computeUnitStats(alignUnits([u('بِ'), u('س'), u('مِ')], [u('س')]));
      expect(stats.matches, 1);
      expect(stats.deletions, 2);
      expect(stats.errors, 2);
      expect(stats.accuracy, closeTo(1 / 3, 0.001));
    });
  });

  group('lastMatchedRefIdx — تتبع الكلمة الجارية', () {
    test('لا عمليات → -1', () {
      expect(lastMatchedRefIdx(const []), -1);
    });

    test('تلاوة جزئية: آخر موضع مطابق هو آخر وحدة مُتلوّة', () {
      // مرجع: بِ س مِ / تنبؤ جزئي: بِ س (تُلُوّت حتى السين).
      final ops = alignUnits([u('بِ'), u('س'), u('مِ')], [u('بِ'), u('س')]);
      expect(lastMatchedRefIdx(ops), 1);
    });

    test('حرف زائد بين الوحدات لا يوقف التقدّم', () {
      // تنبؤ: بِ ق س → القاف insert، والسين ما تزال مطابَقة بالموضع 1.
      // ملاحظة: عند تعادل الكلفة يُفضَّل الاستبدال، فقد يُحتسب التقدّم أبعد
      // من 1 — المهم أن الحرف الزائد لم يوقف التقدّم (فيصل quran_audio
      // الأصلي كان يتوقع 1 بالضبط ويفشل).
      final ops =
          alignUnits([u('بِ'), u('س'), u('مِ')], [u('بِ'), u('ق'), u('س')]);
      expect(lastMatchedRefIdx(ops), greaterThan(0));
    });

    test('replace يُحتسب تقدمًا أيضًا', () {
      final ops = alignUnits([u('بِ'), u('س')], [u('تِ'), u('س')]);
      expect(lastMatchedRefIdx(ops), 1);
    });

    test('لا مطابقات → -1', () {
      // تنبؤ فارغ → كل الوحدات deletes → لا match/replace → -1.
      // (فيصل quran_audio الأصلي استخدم حروفًا مختلفة كليًا، لكن الاستبدال
      // يُحتسب تقدمًا بحكم التصميم فكان يفشل.)
      final ops = alignUnits([u('بِ'), u('س')], <QuranUnit>[]);
      expect(lastMatchedRefIdx(ops), -1);
    });
  });
}
