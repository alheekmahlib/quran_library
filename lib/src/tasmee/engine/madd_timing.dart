/// الحكم الزمني على المدود من طوابع الوحدات (ثوان) — معاير على تسجيلات حقيقية.
///
/// اكتشاف المعايرة: رمز المدّ في مخرجات CTC يُصدَر في **نهاية** تطويله
/// (النموذج ينتظر ليسمع كامل الطول قبل حسم العدد)، فمدة المدّ الفعلية ≈
/// الفجوة بين الطابع السابق وطابع المدّ نفسه.
///
/// وطول «الحركة» بالثواني مرن جدًا بين القرّاء (زيادة المدّ مشروعة) — لذا
/// الحكم الفعلي **وجوديّ**: مدّ golden>=4 يُعدّ سليمًا إن بلغت فجوته ضعفَي
/// إيقاع القارئ (وسيط فجوات الحروف غير المديّة في نفس التسجيل)؛ وما دون
/// ذلك «مدّ مفقود زمنيًا». المدود القصيرة (golden=2) يكفيها الحكم الرمزي.
library;

import 'phoneme_aligner.dart';
import 'quran_units.dart';

/// إعدادات القياس الزمني (قابلة لِلمعايرة على تسجيلات حقيقية).
class MaddTimingConfig {
  const MaddTimingConfig({
    this.harakaSec = 0.5,
    this.toleranceRatio = 0.4,
    this.minTimedGolden = 3,
    this.minPaceRatio = 2.0,
  });

  /// تقدير احتياطي لِلحركة (ثوان) إن تعذّر استخراج إيقاع القارئ.
  final double harakaSec;

  /// (توافق قديم) نسبة التسامح — غير مستخدمة في الحكم الوجودي.
  final double toleranceRatio;

  /// أقل طول ذهبي يُقاس زمنيًا (ما دونه يكتفي بالحكم الرمزي).
  final int minTimedGolden;

  /// المدّ سليم إن بلغت فجوته هذا المضاعف من إيقاع القارئ.
  final double minPaceRatio;
}

/// حكم زمني على مدّ واحد.
class MaddTimingVerdict {
  const MaddTimingVerdict({
    required this.refIdx,
    required this.predIdx,
    required this.goldenHarakat,
    required this.actualHarakat,
    required this.ok,
  });

  final int refIdx;
  final int predIdx;

  /// الطول الذهبي (رموز) — للعرض.
  final int goldenHarakat;

  /// الفجوة مقيسة بوحدات إيقاع القارئ (وليست حركات مطلقة) — للعرض.
  final double actualHarakat;
  final bool ok;
}

double _median(List<double> xs) {
  if (xs.isEmpty) return 0;
  final s = xs..sort();
  final n = s.length;
  return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

/// يقيّم كل مدّ مرجعي مُطابَق زمنيًا (الحكم الوجودي).
List<MaddTimingVerdict> judgeMaddTimings({
  required List<UnitAlignOp> ops,
  required List<QuranUnit> refUnits,
  required int predCount,
  required List<double> predTimestamps,
  required double totalDurationSec,
  MaddTimingConfig config = const MaddTimingConfig(),
}) {
  final verdicts = <MaddTimingVerdict>[];
  if (predTimestamps.isEmpty) return verdicts;

  // اجمع المطابقات المرتّبة بمؤشر التنبؤ.
  final matched = [
    ...ops.where((o) =>
        (o.type == 'match' || o.type == 'replace') &&
        o.refIdx >= 0 &&
        o.predIdx >= 0 &&
        o.predIdx < predTimestamps.length),
  ]..sort((a, b) => a.predIdx.compareTo(b.predIdx));
  if (matched.isEmpty) return verdicts;

  // إيقاع القارئ: وسيط الفجوات المتتالية للوحدات غير المديّة مرجعيًا.
  final gaps = <double>[];
  for (var k = 1; k < matched.length; k++) {
    final prev = matched[k - 1];
    final cur = matched[k];
    if (cur.predIdx != prev.predIdx + 1) continue;
    if (refUnits[prev.refIdx].isMadd || refUnits[cur.refIdx].isMadd) continue;
    final g = predTimestamps[cur.predIdx] - predTimestamps[prev.predIdx];
    if (g > 0) gaps.add(g);
  }
  final pace = _median(gaps);
  final paceSec = pace > 0.02 ? pace : config.harakaSec;

  // حكم وجودي على المدود الطويلة: فجوتها (من الطابع السابق) يجب أن تبلغ
  // مضاعف إيقاع القارئ.
  for (final op in matched) {
    final ref = refUnits[op.refIdx];
    if (!ref.isMadd) continue;
    final golden = ref.maddLength!;
    if (golden < config.minTimedGolden) continue;
    final p = op.predIdx;
    final start = p > 0 ? predTimestamps[p - 1] : 0.0;
    final gap = predTimestamps[p] - start;
    if (gap <= 0) continue;
    verdicts.add(MaddTimingVerdict(
      refIdx: op.refIdx,
      predIdx: p,
      goldenHarakat: golden,
      actualHarakat: gap / paceSec,
      ok: gap >= paceSec * config.minPaceRatio,
    ));
  }
  return verdicts;
}
