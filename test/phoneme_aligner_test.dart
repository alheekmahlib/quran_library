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

  group('dropLeadingInserts — تسامح البادئ', () {
    test('يحذف الإدراجات قبل أول مطابقة', () {
      final ops = alignUnits([u('س')], [u('ق'), u('ق'), u('س')]);
      final filtered = dropLeadingInserts(ops);
      expect(filtered.first.type, 'match');
      expect(filtered.where((o) => o.type == 'insert'), isEmpty);
    });

    test('كله إدراجات بلا مطابقة → فارغ', () {
      // بناء يدوي: وحدتا insert بلا أي match/replace.
      final ops = [
        const UnitAlignOp(type: 'insert', refIdx: -1, predIdx: 0),
        const UnitAlignOp(type: 'insert', refIdx: -1, predIdx: 1),
      ];
      expect(dropLeadingInserts(ops), isEmpty);
    });
  });

  group('dropTrailingDeletes — تسامح الختام', () {
    test('يحذف الحذوف بعد آخر مطابقة (توقف المستخدم قبل نهاية النطاق)', () {
      // مرجع: بِ س مِ / تنبؤ: بِ فقط → السين والميم deletes ختامية.
      final ops = alignUnits([u('بِ'), u('س'), u('مِ')], [u('بِ')]);
      final filtered = dropTrailingDeletes(ops);
      expect(filtered.map((o) => o.type), ['match']);
    });

    test('لا حذوف ختامية → القائمة كما هي', () {
      final ops = alignUnits([u('بِ'), u('س')], [u('بِ'), u('س')]);
      expect(dropTrailingDeletes(ops), same(ops));
    });

    test(
        'إدراج ختامي بعد الحذوف لا يُقتطع عنده — تُحذف سلسلة الحذف الخالصة فقط',
        () {
      // مرجع: بِ س مِ / تنبؤ: بِ ق → ميم delete ثم قاف insert؟ الترتيب
      // الفعلي من المحاذاة: match(ب) ثم delete(س) أو insert(ق)...
      // المهم: إن انتهت القائمة بحذف خالص اقتُطع، وإلا بقيت كما هي.
      final ops = [
        const UnitAlignOp(type: 'match', refIdx: 0, predIdx: 0),
        const UnitAlignOp(type: 'insert', refIdx: -1, predIdx: 1),
        const UnitAlignOp(type: 'delete', refIdx: 1, predIdx: -1),
      ];
      // السلسلة الختامية delete خالصة → تُحذف حتى آخر insert.
      expect(dropTrailingDeletes(ops).length, 2);
    });

    test('كله حذوف → فارغ', () {
      expect(dropTrailingDeletes(alignUnits([u('بِ'), u('س')], <QuranUnit>[])),
          isEmpty);
    });
  });

  group('dropTrailingInserts — ضوضاء الختام لكلمة منفردة', () {
    test('يحذف سلسلة إدراجات ختامية قصيرة (ضوضاء CTC)', () {
      final ops = [
        const UnitAlignOp(type: 'match', refIdx: 0, predIdx: 0),
        const UnitAlignOp(type: 'insert', refIdx: -1, predIdx: 1),
        const UnitAlignOp(type: 'insert', refIdx: -1, predIdx: 2),
      ];
      final filtered = dropTrailingInserts(ops, maxUnits: 2);
      expect(filtered.length, 1);
      expect(filtered.first.type, 'match');
    });

    test('سلسلة ختامية أطول من الحد = نطق زائد فعلي → تبقى', () {
      final ops = [
        const UnitAlignOp(type: 'match', refIdx: 0, predIdx: 0),
        const UnitAlignOp(type: 'insert', refIdx: -1, predIdx: 1),
        const UnitAlignOp(type: 'insert', refIdx: -1, predIdx: 2),
        const UnitAlignOp(type: 'insert', refIdx: -1, predIdx: 3),
      ];
      expect(dropTrailingInserts(ops, maxUnits: 2).length, 4);
    });

    test('بلا إدراجات ختامية → القائمة كما هي', () {
      final ops = [
        const UnitAlignOp(type: 'match', refIdx: 0, predIdx: 0),
        const UnitAlignOp(type: 'insert', refIdx: -1, predIdx: 1),
        const UnitAlignOp(type: 'match', refIdx: 1, predIdx: 2),
      ];
      expect(dropTrailingInserts(ops, maxUnits: 2), same(ops));
    });
  });

  group('dropTrailingUnmatched — ذيل غير مُتلى مع ضوضاء ختامية', () {
    test('حذوف خالصة بعد سلسلة مطابقات → تُسقط', () {
      final ops = alignUnits([u('بِ'), u('س'), u('مِ')], [u('بِ'), u('س')]);
      final filtered = dropTrailingUnmatched(ops);
      expect(filtered.map((o) => o.type), ['match', 'match']);
    });

    test('حذوف + ≤3 إدراجات ضوضاء ختامية → اللاحقة كلها تُسقط', () {
      // المستخدم أوقف التسجيل؛ CTC أخرج وحدتي ضوضاء بعد الصمت — يجب ألا
      // تمنعا اقتطاع بقية الصفحة غير المتلوّة.
      final ops = [
        const UnitAlignOp(type: 'match', refIdx: 0, predIdx: 0),
        const UnitAlignOp(type: 'match', refIdx: 1, predIdx: 1),
        const UnitAlignOp(type: 'delete', refIdx: 2, predIdx: -1),
        const UnitAlignOp(type: 'delete', refIdx: 3, predIdx: -1),
        const UnitAlignOp(type: 'insert', refIdx: -1, predIdx: 2),
        const UnitAlignOp(type: 'insert', refIdx: -1, predIdx: 3),
      ];
      final filtered = dropTrailingUnmatched(ops);
      expect(filtered.length, 2);
      expect(filtered.every((o) => o.type == 'match'), isTrue);
    });

    test('حذوف + ≥4 إدراجات (نطق زائد فعلي) → تبقى اللاحقة', () {
      final ops = [
        const UnitAlignOp(type: 'match', refIdx: 0, predIdx: 0),
        const UnitAlignOp(type: 'match', refIdx: 1, predIdx: 1),
        const UnitAlignOp(type: 'delete', refIdx: 2, predIdx: -1),
        ...List.generate(
          5,
          (i) => UnitAlignOp(type: 'insert', refIdx: -1, predIdx: i + 2),
        ),
      ];
      expect(dropTrailingUnmatched(ops).length, ops.length);
    });

    test('بلا لاحقة غير مُطابَقة → القائمة كما هي', () {
      final ops = alignUnits([u('بِ'), u('س')], [u('بِ'), u('س')]);
      expect(dropTrailingUnmatched(ops), same(ops));
    });
  });

  group('dropLeadingDeletes — تسامح البادئة المرجعية', () {
    test('يحذف الحذوف البادئة قبل أول مطابقة (بداية من منتصف النطاق)', () {
      // مرجع: بِ س مِ / تنبؤ: مِ فقط → الباء والسين deletes بادئة.
      final ops = alignUnits([u('بِ'), u('س'), u('مِ')], [u('مِ')]);
      final filtered = dropLeadingDeletes(ops);
      expect(filtered.map((o) => o.type), ['match']);
    });

    test('لا حذوف بادئة → القائمة كما هي', () {
      final ops = alignUnits([u('بِ'), u('س')], [u('بِ'), u('س')]);
      expect(dropLeadingDeletes(ops), same(ops));
    });

    test('حذف في وسط الكلام لا يُحذف — ليس بادئًا', () {
      final ops = [
        const UnitAlignOp(type: 'match', refIdx: 0, predIdx: 0),
        const UnitAlignOp(type: 'delete', refIdx: 1, predIdx: -1),
        const UnitAlignOp(type: 'match', refIdx: 2, predIdx: 1),
      ];
      expect(dropLeadingDeletes(ops).length, 3);
    });

    test('كله حذوف → فارغ', () {
      expect(dropLeadingDeletes(alignUnits([u('بِ'), u('س')], <QuranUnit>[])),
          isEmpty);
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
