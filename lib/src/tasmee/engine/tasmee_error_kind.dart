/// نوع خطأ التسميع لكل كلمة — يُشتق حيًّا من المتتبّع ويُرقَّع من
/// التقييم النهائي (المرجع).
library;

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
