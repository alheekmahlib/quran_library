/// نوع خطأ التسميع لكل كلمة — يُشتق حيًّا من المتتبّع ويُرقَّع من
/// التقييم النهائي (المرجع).
library;

import 'models/recitation_result.dart';

/// نوع حكم كلمة التسميع.
enum TasmeeErrorKind {
  /// نُطقت سليمة — بلا خطأ.
  correct,

  /// نطق خاطئ: حرف مستبدل أو زائد أو ناقص.
  normal,

  /// خطأ تشكيل (حركة).
  tashkeel,

  /// خطأ تجويد (مدّ/شدة/قلقلة/غنّة/إخفاء).
  tajweed,
}

/// يحوّل نص `errorType` من التقييم النهائي إلى النوع المقابل.
TasmeeErrorKind tasmeeErrorKindFromType(String errorType) {
  switch (errorType) {
    case 'tajweed':
      return TasmeeErrorKind.tajweed;
    case 'tashkeel':
      return TasmeeErrorKind.tashkeel;
    default:
      return TasmeeErrorKind.normal;
  }
}

/// تفصيل خطأ كلمة واحد من التتبّع الحي — ما نُطق فعلًا مقابل المتوقع،
/// لعرضه في شيت تصحيح الكلمة (نمط المصحح).
class TasmeeWordMistake {
  const TasmeeWordMistake({
    required this.kind,
    required this.errorType,
    this.expectedSymbol,
    this.predictedSymbol,
  });

  /// أسوأ نوع خطأ في الكلمة (المستخدم للون والشارة).
  final TasmeeErrorKind kind;

  /// نوع خطأ النطق: 'insert' (زيادة) أو 'delete' (نقص) أو 'replace'
  /// (استبدال/اختلاف رمز).
  final String errorType;

  /// رمز الوحدة المرجعية المتوقعة (null عند الزيادة).
  final String? expectedSymbol;

  /// رمز الوحدة المنطوقة فعلًا (null عند النقص).
  final String? predictedSymbol;
}

/// أسبقية الدمج عند تعدد أنواع الأخطاء في كلمة واحدة
/// (تجويد > نطق > تشكيل) — يُعرض لون الأعلى أسبقية.
TasmeeErrorKind mergeTasmeeErrorKinds(TasmeeErrorKind a, TasmeeErrorKind b) {
  if (a == b) return a;
  const order = <TasmeeErrorKind, int>{
    TasmeeErrorKind.correct: 0,
    TasmeeErrorKind.tashkeel: 1,
    TasmeeErrorKind.normal: 2,
    TasmeeErrorKind.tajweed: 3,
  };
  return order[a]! >= order[b]! ? a : b;
}

/// خطأ أحدث محاولة إعادة نطق كلمة في شيت المصحّح — قد يختلف عن خطأ
/// التلاوة الأول: أصلح المستخدم النطق فصار خطؤه تشكيلًا أو تجويدًا،
/// فيعرض له الخطأ **الحالي** ليعرف ما يصحّحه الآن.
class TasmeeRetryFeedback {
  const TasmeeRetryFeedback({
    required this.kind,
    required this.errorType,
    this.expectedSymbol,
    this.predictedSymbol,
    this.ruleName,
  });

  /// نوع خطأ هذه المحاولة (تجويد/نطق/تشكيل) — للشارة واللون.
  final TasmeeErrorKind kind;

  /// نوع خطأ النطق: 'insert' (زيادة) أو 'delete' (نقص) أو 'replace'
  /// (استبدال/اختلاف رمز).
  final String errorType;

  /// الرمز/الرموز المتوقعة ('' أو null عند الزيادة).
  final String? expectedSymbol;

  /// الرمز/الرموز المنطوقة فعلًا ('' أو null عند النقص).
  final String? predictedSymbol;

  /// اسم قاعدة التجويد المخطوءة (الشدة/المدّ/القلقلة…) إن كان الخطأ
  /// تجويديًا — يُؤخذ من قواعد الخطأ المنتقى.
  final String? ruleName;
}

/// ينتقي من أخطاء محاولة إعادة النطق الخطأ **الرادع** الأعلى أسبقية
/// (تجويد > نطق > تشكيل — منطق [mergeTasmeeErrorKinds] نفسه) ويردّه
/// ملقّطًا للعرض في شيت المصحّح — أو null إن لا خطأ رادعًا (المحاولة
/// صحيحة أو أخطاؤها كلها مُغتفَرة — انظر [isRetryBlockingError]).
TasmeeRetryFeedback? retryFeedbackFromErrors(List<RecitationError> errors) {
  final blocking = errors.where(isRetryBlockingError).toList();
  RecitationError? worst;
  for (final e in blocking) {
    final kind = tasmeeErrorKindFromType(e.errorType);
    final worstKind =
        worst == null ? null : tasmeeErrorKindFromType(worst.errorType);
    if (worst == null || mergeTasmeeErrorKinds(kind, worstKind!) != worstKind) {
      worst = e;
    }
  }
  if (worst == null) return null;
  final rules = [
    ...worst.refTajweedRules,
    ...worst.insertedTajweedRules,
    ...worst.replacedTajweedRules,
    ...worst.missingTajweedRules,
  ];
  return TasmeeRetryFeedback(
    kind: tasmeeErrorKindFromType(worst.errorType),
    errorType: worst.speechErrorType,
    expectedSymbol: worst.expectedPh,
    predictedSymbol: worst.predictedPh,
    ruleName: rules.isNotEmpty ? rules.first.nameAr : null,
  );
}

/// هل الخطأ **رادع** لقبول إعادة نطق الكلمة؟
///
/// الرادع الوحيد: أخطاء الحروف (`normal`: زيادة/نقص/استبدال) — جوهر
/// التصحيح. غير رادع: التشكيل كله (ارتعاج حركة شبه حتمي في نطق
/// معزول)، والتجويد كله رمزيًا وزمنيًا — النموذج لا يفرّق الشدة/
/// الغنّة/القلقلة وطول المدّ بثبات في كلمة منفردة (سجل فعلي: مطابقة
/// 100% مع خطأين رمزيين رُفضا مرارًا فاستحال الاجتياز). التجويد يبقى
/// مُوقفًا ومُعرضًا في الجلسة الرئيسية ونتائجها — هنا ملاحظة فقط.
bool isRetryBlockingError(RecitationError e) =>
    e.errorType != 'tashkeel' && e.errorType != 'tajweed';

/// هل تُقبل محاولة إعادة نطق الكلمة؟ — تطابقٌ وأخطاء كلها غير رادعة
/// ([isRetryBlockingError]). هذا معيار المصحّح المخفَّف موجَّهًا؛
/// [RecitationResult.isFullyCorrect] الصارم يبقى لمساراته الأخرى.
bool isWordRetryAcceptable(RecitationResult result) =>
    isRecitationAcceptable(result);

/// هل التلاوة **مقبولة** (إتقان)؟ — تطابقٌ ولا خطأ رادعًا واحدًا
/// ([isRetryBlockingError]).
///
/// هذا معيار اجتياز الآية/الصفحة المخفَّف موجَّهًا لحلقة معلم القرآن
/// (وبقية مواضع قرار إعادة التلاوة): ملاحظات التشكيل والمدّ الطولي
/// تُعرض في النتيجة لكنها لا تُفشل التلاوة وتُعيد الآية إلى ما لا
/// نهاية — الرادع وحده (حروف/تجويد جوهري) يستوجب الإعادة.
/// [RecitationResult.isFullyCorrect] الصارم (صفر أخطاء مطلقًا) يبقى
/// لمن أراد التقصيَ الصارم.
bool isRecitationAcceptable(RecitationResult result) {
  if (!result.hasMatch) return false;
  return result.errors.every((e) => !isRetryBlockingError(e));
}
