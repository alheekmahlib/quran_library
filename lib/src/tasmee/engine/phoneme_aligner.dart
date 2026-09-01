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
