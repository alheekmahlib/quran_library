/// محاذاة وحدات التلاوة (Unit-Level Alignment) — أبجدية Quran-Lab.
///
/// Wagner-Fischer على مستوى الوحدة بِمفتاح الحرف الأساسي `letter`،
/// على مستوى الآية كاملة (يصمد أمام كلمة محذوفة/زائدة). فروق الحالة
/// (حركة/شدة/مدّ/قلقلة/إخفاء) داخل الـmatch يفصّلها كشّاف الأخطاء.
library;

import 'quran_units.dart';

/// عمليّة محاذاة واحدة بين الوحدات المرجعية والمتنبأة.
class UnitAlignOp {
  const UnitAlignOp({
    required this.type,
    required this.refIdx,
    required this.predIdx,
  });

  /// 'match' | 'insert' | 'delete' | 'replace'
  final String type;

  /// فهرس الوحدة المرجعية أو -1 (insert).
  final int refIdx;

  /// فهرس الوحدة المتنبأة أو -1 (delete).
  final int predIdx;

  @override
  String toString() => '$type(ref=$refIdx, pred=$predIdx)';
}

/// يحاذي وحدات الآية كاملة — المفتاح: الحرف الأساسي.
List<UnitAlignOp> alignUnits(
  List<QuranUnit> refUnits,
  List<QuranUnit> predUnits,
) {
  final n = refUnits.length;
  final m = predUnits.length;
  if (n == 0 && m == 0) return const [];

  final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = 0; i <= n; i++) {
    dp[i][0] = i;
  }
  for (var j = 0; j <= m; j++) {
    dp[0][j] = j;
  }
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      if (refUnits[i - 1].letter == predUnits[j - 1].letter) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] = 1 +
            [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
                .reduce((a, b) => a < b ? a : b);
      }
    }
  }

  // Backtrack — عند تساوي الكلفة نُفضّل replace (يحفظ اقتران 1↔1 بديهيًا)
  // ثم delete ثم insert.
  final ops = <UnitAlignOp>[];
  var i = n;
  var j = m;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && refUnits[i - 1].letter == predUnits[j - 1].letter) {
      ops.add(UnitAlignOp(type: 'match', refIdx: i - 1, predIdx: j - 1));
      i--;
      j--;
    } else if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 1) {
      ops.add(UnitAlignOp(type: 'replace', refIdx: i - 1, predIdx: j - 1));
      i--;
      j--;
    } else if (i > 0 && (j == 0 || dp[i - 1][j] <= dp[i][j - 1])) {
      ops.add(UnitAlignOp(type: 'delete', refIdx: i - 1, predIdx: -1));
      i--;
    } else {
      ops.add(UnitAlignOp(type: 'insert', refIdx: -1, predIdx: j - 1));
      j--;
    }
  }
  return ops.reversed.toList(growable: false);
}

/// إحصاءات المحاذاة.
class UnitAlignStats {
  const UnitAlignStats({
    required this.matches,
    required this.insertions,
    required this.deletions,
    required this.replacements,
  });

  final int matches;
  final int insertions;
  final int deletions;
  final int replacements;

  int get totalOps => matches + insertions + deletions + replacements;
  int get errors => insertions + deletions + replacements;
  double get accuracy => totalOps == 0 ? 0 : matches / totalOps;

  @override
  String toString() =>
      'matches=$matches, ins=$insertions, del=$deletions, rep=$replacements '
      '(${(accuracy * 100).toStringAsFixed(1)}%)';
}

/// يحسب الإحصاءات من قائمة العمليات.
UnitAlignStats computeUnitStats(List<UnitAlignOp> ops) {
  var m = 0, ins = 0, del = 0, rep = 0;
  for (final op in ops) {
    switch (op.type) {
      case 'match':
        m++;
      case 'insert':
        ins++;
      case 'delete':
        del++;
      case 'replace':
        rep++;
    }
  }
  return UnitAlignStats(
    matches: m,
    insertions: ins,
    deletions: del,
    replacements: rep,
  );
}

/// أبعد موضع مرجعي بلَغته التلاوة (آخر match/replace)، أو -1.
///
/// يُستخدم لِتتبّع الكلمة الجارية في الوضع الحي: الوحدات المتنامية
/// تُحاذى مع الآية المرجعية، وهذا الفهرس يحدّد موضع التقدّم ثم كلمته.
int lastMatchedRefIdx(List<UnitAlignOp> ops) {
  var last = -1;
  for (final op in ops) {
    if ((op.type == 'match' || op.type == 'replace') && op.refIdx > last) {
      last = op.refIdx;
    }
  }
  return last;
}

/// يحذف عمليات insert قبل أول match/replace — تسامح البادئ.
///
/// في وضع النطاق (صفحة كاملة) قد يبدأ المستخدم بِـ بسملة أو ينتظر قبل
/// أول كلمة، فتظهر وحدات متوقَّعة قبل أول مطابقة مرجعية؛ هذه العمليات
/// بلا موضع مرجعي أصلاً ولا يجب أن تُحسب أخطاًء "حرف زائد".
///
/// Drops insert ops preceding the first match/replace — leading-insert
/// tolerance for range mode (basmalah / late starts).
List<UnitAlignOp> dropLeadingInserts(List<UnitAlignOp> ops) {
  var first = -1;
  for (var i = 0; i < ops.length; i++) {
    if (ops[i].type != 'insert') {
      first = i;
      break;
    }
  }
  if (first == -1) return const []; // كله inserts بلا أي مطابقة.
  if (first == 0) return ops;
  return ops.sublist(first);
}

/// يحذف سلسلة delete الختامية الخالصة بعد آخر match/replace — تسامح
/// الختام: المستخدم أوقف التلاوة قبل نهاية النطاق، فما بعدها ليس
/// "حروفًا مفقودة" بل غير مُتلوّ أصلًا (تُدار تغطيته في التوفيق النهائي).
///
/// Drops the pure trailing run of delete ops after the last match/replace —
/// trailing-delete tolerance for range mode (user stopped early; the
/// un-recited tail is not a recitation error).
List<UnitAlignOp> dropTrailingDeletes(List<UnitAlignOp> ops) {
  var cut = ops.length;
  while (cut > 0 && ops[cut - 1].type == 'delete') {
    cut--;
  }
  if (cut == ops.length) return ops;
  return ops.sublist(0, cut);
}

/// يحذف سلسلة delete البادئة الخالصة قبل أول match/replace — تسامح
/// البادئة المرجعية: بداية المستخدم من منتصف النطاق ليست "حروفًا
/// مفقودة" (للنطاقات متعددة الكلمات؛ إعادة نطق كلمة تبقى صارمة).
///
/// Drops the pure leading run of delete ops before the first match/replace
/// — mid-range start tolerance (un-recited prefix is not a recitation
/// error). Multi-word ranges only; single-word retries stay strict.
List<UnitAlignOp> dropLeadingDeletes(List<UnitAlignOp> ops) {
  var first = 0;
  while (first < ops.length && ops[first].type == 'delete') {
    first++;
  }
  if (first == 0) return ops;
  return ops.sublist(first);
}

/// يحذف سلسلة insert الختامية الخالصة إن كانت قصيرة ([maxUnits] فأقل) —
/// ضوضاء CTC الذيلية بعد نطق كلمة منفردة ليست خطأ مستخدم. السلاسل
/// الأطول نطق زائد فعلي وتبقى (صرامة إعادة الكلمة).
///
/// Drops a short pure trailing run of insert ops (CTC tail noise after a
/// single-word recitation — not a user error). Longer runs are genuine
/// extra speech and stay flagged.
List<UnitAlignOp> dropTrailingInserts(
  List<UnitAlignOp> ops, {
  int maxUnits = 2,
}) {
  var cut = ops.length;
  while (cut > 0 && ops[cut - 1].type == 'insert') {
    cut--;
  }
  if (cut == ops.length || ops.length - cut > maxUnits) return ops;
  return ops.sublist(0, cut);
}

/// يحذف اللاحقة بعد نهاية آخر **سلسلة مطابقات موثوقة** إذا لم تحوِ
/// إدراجات كثيرة — تسامح ختام النطاقات متعددة الكلمات.
///
/// «موثوقة»: سلسلة match/replace متتالية بطول ≥ [minReliableRun] — كلام
/// المستخدم الفعلي يأتي سلاسلَ متصلة، بينما مطابقة ضوضاء الذيل حرفٌ
/// صادف حرفًا في المنطقة غير المتلوّة فتظهر **معزولة** بين حذوف (المحاذاة
/// تُطابقها مجانًا فتُزيح «آخر مطابقة» عميقًا وتُفشل أي اقتطاع يعتمد
/// عليها). الاقتطاع عند نهاية آخر سلسلة موثوقة يتجاوز الفخ، واللاحقة
/// بعدها (حذوف ما لم يُتلَ + إدراجات ≤ [maxTrailingInserts] ضوضاء)
/// تُسقط كاملة. سلسلة إدراج أكبر (نطق زائد فعلي كإعادة كلمة) تُبقي
/// اللاحقة — خطأ حقيقي يُعرض.
List<UnitAlignOp> dropTrailingUnmatched(
  List<UnitAlignOp> ops, {
  int maxTrailingInserts = 3,
  int minReliableRun = 2,
}) {
  // نهاية آخر سلسلة match/replace متتالية بطول كافٍ.
  var reliableEnd = -1;
  var i = 0;
  while (i < ops.length) {
    if (ops[i].type != 'match' && ops[i].type != 'replace') {
      i++;
      continue;
    }
    var run = 0;
    while (i + run < ops.length &&
        (ops[i + run].type == 'match' || ops[i + run].type == 'replace')) {
      run++;
    }
    if (run >= minReliableRun) reliableEnd = i + run;
    i += run;
  }
  if (reliableEnd < 0 || reliableEnd >= ops.length) return ops;
  var inserts = 0;
  for (var j = reliableEnd; j < ops.length; j++) {
    if (ops[j].type == 'insert') inserts++;
  }
  if (inserts > maxTrailingInserts) return ops;
  return ops.sublist(0, reliableEnd);
}
