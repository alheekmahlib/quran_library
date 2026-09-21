/// تقييم تلاوة على نطاق مرجعي — منطق نقي بلا sherpa/ffi ليُختبر مباشرة.
///
/// المستخلص من مسار النطاق في المحرّك، مع دعم **نافذة المقطع المتلو**:
/// التقييم النهائي بعد الإيقاف يُجرى على الجزء الذي تتبّعه الجلسة الحيّة
/// فعلًا (من أول إرساء إلى مؤشّر التقدّم الحالي بهوامش) بدل النطاق
/// كاملًا — محاذاة كامل الصفحة مقابل صوت مقطعٍ قصير تُطابق حروفَ ضوضاء
/// الذيل مجانًا داخل المنطقة غير المتلوّة فتنزاح «آخر مطابقة» عميقًا
/// ويُفشل اقتطاع ما لم يُتلَ.
library;

import 'error_detector.dart';
import 'final_reconciliation.dart';
import 'live_recitation_engine.dart';
import 'madd_timing.dart';
import 'models/recitation_result.dart';
import 'phoneme_aligner.dart';
import 'quran_reference.dart';
import 'quran_units.dart';

/// نتيجة تقييم نطاق (فهارس ومواضع عالمية للنطاق كاملًا).
class RangeEvaluation {
  const RangeEvaluation({
    required this.stats,
    required this.errors,
    required this.matchedSpans,
    required this.start,
    required this.end,
  });

  /// إحصاءات المحاذاة بعد التسامحات (لِلرفض عند صفر مطابقات).
  final UnitAlignStats stats;

  /// الأخطاء موسومةً بمواضعها في المصحف (سورة/آية/كلمة).
  final List<RecitationError> errors;

  /// الكلمات التي شملتها مطابقات فعلًا (فهارس عالمية).
  final List<FinalWordSpan> matchedSpans;

  /// أول وآخر موضع مُتلى فعلًا.
  final SurahAyahPosition start;
  final SurahAyahPosition end;
}

/// نافذة المقطع المتلو من مؤشّرَي المتتبّع الحي.
///
/// [firstConsumed] أول إرساء، [nextExpected] المؤشر الحالي؛ هامش خلفي
/// يغطي ما نُطق قبل أول إرساء (بداية الالتقاط ابتلعت أول وحدات)، وهامش
/// أمامي صغير يغطي الكلمة الجارية عند الإيقاف — هامش كبير يسمح لمحاذاة
/// الحروف المكررة بإدخال فوضى داخل الكلام المتلو ذاته.
({int start, int end}) recitedWindowFor({
  required int firstConsumed,
  required int nextExpected,
  required int rangeLength,
  int backSlack = 8,
  int frontSlack = 24,
}) {
  var start = firstConsumed <= 0 ? 0 : firstConsumed - backSlack;
  if (start < 0) start = 0;
  var end = nextExpected + frontSlack;
  if (end >= rangeLength) end = rangeLength;
  if (end <= start) end = rangeLength;
  return (start: start, end: end);
}

/// يقيّم تلاوة على نطاق: محاذاة + تسامحات + كشف أخطاء + مدّ زمني + وسم.
///
/// [window] نافذة المقص من المرجع (من المتتبّع الحي للجلسات الحيّة) أو
/// null لتقييم النطاق كاملًا (دفعات بلا متتبّع). المواضع والأخطاء
/// والسپانات المُعادة كلها بفهارس النطاق الكامل.
RangeEvaluation evaluateRangeAlignment({
  required QuranReferenceRange range,
  required List<QuranUnit> predUnits,
  required LiveRecognitionFrame frame,
  required double durationSec,
  required MaddTimingConfig maddTimingConfig,
  ({int start, int end})? window,
}) {
  final winStart = window?.start ?? 0;
  final winEnd = window?.end ?? range.units.length;
  final windowUnits = (winStart == 0 && winEnd == range.units.length)
      ? range.units
      : range.units
          .sublist(winStart, winEnd.clamp(winStart, range.units.length));
  String? wordAtGlobal(int i) => range.wordAt(winStart + i);
  QuranRangeWordSpan? spanOfGlobal(int i) => range.spanOfUnit(winStart + i);

  // تسامحات النطاقات متعددة الكلمات: بادئة الإدراج (بسملة/بداية متأخرة)،
  // بادئة الحذف (بداية من منتصف النطاق)، وختام غير المتلوّ مع ضوضاء CTC
  // الختامية. إعادة نطق كلمة واحدة تبقى صارمة بلا تسامح حذف.
  final multiWord = range.wordSpans.length > 1;
  final rawOps = alignUnits(windowUnits, predUnits);
  final ops = multiWord
      ? dropLeadingDeletes(dropTrailingUnmatched(dropLeadingInserts(rawOps)))
      : dropTrailingInserts(dropLeadingInserts(rawOps), maxUnits: 2);
  final stats = computeUnitStats(ops);

  final windowErrors = <RecitationError>[
    ...buildErrorsFromUnitAlignment(
      ops: ops,
      refUnits: windowUnits,
      predUnits: predUnits,
      wordAt: wordAtGlobal,
      spanOfUnit: spanOfGlobal,
    ),
    if (multiWord)
      ..._timingErrors(ops, windowUnits, wordAtGlobal, predUnits, frame,
          durationSec, maddTimingConfig),
  ];
  // أعِد فهارس النافذة إلى الفهارس العالمية ثم وسِم المواضع.
  final errors = windowErrors.map((e) => e.shiftUthmaniPos(winStart)).toList();
  final tagged = _tagErrorPositions(errors, range);
  final matchedSpans = matchedSpansFromOps(ops, range, refOffset: winStart);
  final recited = recitedVerseRangeFromSpans(matchedSpans);
  final first = range.keyOfVerse(recited?.first ?? 0);
  final last = range.keyOfVerse(recited?.last ?? range.verses.length - 1);
  return RangeEvaluation(
    stats: stats,
    errors: tagged,
    matchedSpans: matchedSpans,
    start: SurahAyahPosition(suraIdx: first.suraIdx, ayaIdx: first.ayaIdx),
    end: SurahAyahPosition(suraIdx: last.suraIdx, ayaIdx: last.ayaIdx),
  );
}

/// يوسم كل خطأ بِموضعه في المصحف (سورة/آية/كلمة) من موضع وحدته المرجعية.
///
/// الإدراجات المدموجة (من error_detector) تحمل موضع الكلمة المنسوبة
/// إليها فتُوسم وترسم تحتها؛ غير الموسوم (بلا موضع صالح) يُترك كما هو.
List<RecitationError> _tagErrorPositions(
  List<RecitationError> errors,
  QuranReferenceRange range,
) {
  return errors.map((e) {
    if (e.uthmaniPos.isEmpty || e.uthmaniPos[0] < 0) {
      return e;
    }
    final span = range.spanOfUnit(e.uthmaniPos[0]);
    if (span == null) return e;
    final key = range.keyOfVerse(span.verseIdx);
    return e.withPosition(
      suraIdx: key.suraIdx,
      ayaIdx: key.ayaIdx,
      wordIdx: span.wordIdx,
    );
  }).toList();
}

/// يدمج أحكام المدّ الزمنية كأخطاء (المدّ الرمزي المتطابق يبقى بلا خطأ
/// إلا إذا خان الزمنُ المُسموعَ).
List<RecitationError> _timingErrors(
  List<UnitAlignOp> ops,
  List<QuranUnit> refUnits,
  String? Function(int unitIdx) wordAt,
  List<QuranUnit> predUnits,
  LiveRecognitionFrame frame,
  double durationSec,
  MaddTimingConfig config,
) {
  if (frame.timestamps.isEmpty) return const [];
  final verdicts = judgeMaddTimings(
    ops: ops,
    refUnits: refUnits,
    predCount: predUnits.length,
    predTimestamps: frame.timestamps,
    totalDurationSec: durationSec,
    config: config,
  );
  final out = <RecitationError>[];
  for (final v in verdicts.where((v) => !v.ok)) {
    out.add(RecitationError(
      errorType: 'tajweed',
      speechErrorType: 'replace',
      uthmaniPos: [v.refIdx, v.refIdx + 1],
      phPos: [v.predIdx, v.predIdx + 1],
      expectedPh: refUnits[v.refIdx].symbol,
      predictedPh:
          v.predIdx < predUnits.length ? predUnits[v.predIdx].symbol : null,
      expectedLen: v.goldenHarakat,
      predictedLen: v.actualHarakat.round(),
      wordText: wordAt(v.refIdx),
      refTajweedRules: [
        TajweedRule(
          nameAr: 'المدّ (زمني)',
          nameEn: 'Madd (timed)',
          goldenLen: v.goldenHarakat,
          correctnessType: 'count',
        ),
      ],
    ));
  }
  return out;
}
