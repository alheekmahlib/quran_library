/// التوفيق النهائي بين التقييم الشامل (المحاذاة الكاملة عند الإيقاف)
/// وحالات الكلمات المعروضة — منطق نقي بلا GetX ليُختبر مباشرة.
///
/// المبدأ: التقييم النهائي هو المرجع **ثنائي الاتجاه**:
/// - كلمة لوّنها المتتبّع الحي خطأً وحلّتها المحاذاة الكاملة تطابقًا →
///   تُصحَّح خضراء.
/// - كلمة مغطاة بلا أخطاء موسومة → صحيحة.
/// - كلمة عليها خطأ موسوم → خطأة (بنوع أعلى أسبقية عند التعدّد).
/// - كلمة بلا تغطية ولا خطأ (لم تُتلَ أصلًا) → تُسقط من الحالات الظاهرة.
/// - كلمة قُبل تصحيحها في شيت المصحّح → تبقى خضراء وتُتجاهل أخطاء نطقها
///   الأصلي المسجَّلة في الصوت.
library;

import 'models/recitation_result.dart';
import 'phoneme_aligner.dart';
import 'quran_reference.dart';
import 'tasmee_error_kind.dart';

/// كلمة داخل نطاق التسميع (فهرس الآية والكلمة 0-based داخل النطاق).
typedef FinalWordSpan = ({int verseIdx, int wordIdx});

/// حكم نهائي لكلمة واحدة: صحيحة أم لا، ونوع أسوأ خطأ عليها إن وُجد.
typedef FinalWordVerdict = ({bool correct, TasmeeErrorKind? errorKind});

/// يستخرج الكلمات التي شملتها مطابقات المحاذاة (match/replace) بترتيبها.
///
/// هذه هي "التغطية الفعلية" للتلاوة — أساس إبقاء الكلمات الظاهرة بعد
/// الإيقاف، بديلًا عن اعتماد اكتمال المتتبّع الحي الاسترشادي وحده.
/// [refOffset] يزيح فهارس العمليات إلى الفهارس العالمية للنطاق (عند
/// التقييم على نافذة جزئية منه).
List<FinalWordSpan> matchedSpansFromOps(
  List<UnitAlignOp> ops,
  QuranReferenceRange range, {
  int refOffset = 0,
}) {
  final seen = <FinalWordSpan>{};
  final ordered = <FinalWordSpan>[];
  for (final op in ops) {
    if (op.type != 'match' && op.type != 'replace') continue;
    final span = range.spanOfUnit(op.refIdx + refOffset);
    if (span == null) continue;
    final s = (verseIdx: span.verseIdx, wordIdx: span.wordIdx);
    if (seen.add(s)) ordered.add(s);
  }
  return ordered;
}

/// يبني الأحكام النهائية لكل كلمة من نتيجة التقييم الشاملة.
///
/// [coveredSpans] الكلمات التي شملتها مطابقات المحاذاة (من
///   [matchedSpansFromOps] أو نتيجة المحرك).
/// [errors] أخطاء التقييم النهائي — يُستخدم منها الموسومة بموضع فقط.
/// [verseIndexOf] يحوّل (سورة، آية) إلى فهرس الآية داخل النطاق (أو -1).
/// [keyOf] مفتاح الكلمة في خريطة الحالات المعروضة.
/// [acceptedCorrectionKeys] مفاتيح الكلمات التي قُبل تصحيحها في شيت
///   المصحّح — لا تُداس أحكامها هنا وتبقى خضراء في المتحكم.
Map<String, FinalWordVerdict> reconcileFinalWordVerdicts({
  required List<FinalWordSpan> coveredSpans,
  required List<RecitationError> errors,
  required int Function(int suraIdx, int ayaIdx) verseIndexOf,
  required String Function(int verseIdx, int wordIdx) keyOf,
  Set<String> acceptedCorrectionKeys = const {},
}) {
  final verdicts = <String, FinalWordVerdict>{};
  for (final span in coveredSpans) {
    verdicts[keyOf(span.verseIdx, span.wordIdx)] =
        (correct: true, errorKind: null);
  }
  for (final error in errors) {
    if (error.suraIdx == null ||
        error.ayaIdx == null ||
        error.wordIdx == null) {
      continue;
    }
    final verseIdx = verseIndexOf(error.suraIdx!, error.ayaIdx!);
    if (verseIdx < 0) continue;
    final key = keyOf(verseIdx, error.wordIdx!);
    if (acceptedCorrectionKeys.contains(key)) continue;
    final kind = tasmeeErrorKindFromType(error.errorType);
    final prev = verdicts[key];
    if (prev == null || prev.correct) {
      verdicts[key] = (correct: false, errorKind: kind);
    } else {
      verdicts[key] = (
        correct: false,
        errorKind: mergeTasmeeErrorKinds(prev.errorKind ?? kind, kind),
      );
    }
  }
  return verdicts;
}

/// أول وآخر آية تُلت فيهما مطابقات فعلًا — "المقطع المُتلى" الذي تعرضه
/// نتيجة التقييم (بداية المستخدم من منتصف الصفحة تُظهر المدى الفعلي).
({int first, int last})? recitedVerseRangeFromSpans(List<FinalWordSpan> spans) {
  if (spans.isEmpty) return null;
  return (first: spans.first.verseIdx, last: spans.last.verseIdx);
}

/// يصفّي أخطاء الكلمات التي قُبل تصحيحها من نتيجة العرض (bottomSheet
/// النتائج) — الخطأ الأصلي عولج بنطق سليم عبر شيت المصحّح.
List<RecitationError> withoutAcceptedErrors({
  required List<RecitationError> errors,
  required int Function(int suraIdx, int ayaIdx) verseIndexOf,
  required String Function(int verseIdx, int wordIdx) keyOf,
  required Set<String> acceptedCorrectionKeys,
}) {
  if (acceptedCorrectionKeys.isEmpty) return errors;
  return errors.where((error) {
    if (error.suraIdx == null ||
        error.ayaIdx == null ||
        error.wordIdx == null) {
      return true;
    }
    final verseIdx = verseIndexOf(error.suraIdx!, error.ayaIdx!);
    if (verseIdx < 0) return true;
    return !acceptedCorrectionKeys.contains(keyOf(verseIdx, error.wordIdx!));
  }).toList();
}
