/// كشّاف أخطاء التلاوة على أبجدية Quran-Lab ‏(250 وحدة + blank).
///
/// التصنيف لِكلّ عمليّة محاذاة:
/// - match بِنفس الرمز → لا خطأ رمزي (المدّ الزمني يُقاس في madd_timing).
/// - نفس الحرف: فرق حركة → tashkeel؛ فرق حالة (شدة/قلقلة/غنّة/إخفاء أو
///   طول مدّ خارج التسامح) → tajweed؛ مدّ golden>=4 متسامح 2..golden+2.
/// - insert: ضوضاء (سكوت/حركة/همزة/شرطة) تُتجاهل، وإلاّ normal/insert.
/// - delete: تسامح الوحدة الأولى القصيرة، وإلاّ tajweed إن لها حالة وإلاّ normal.
/// - replace: حرف مختلف → normal؛ نفس الحرف بِحالة مختلفة → فروع match نفسها.
library;

import 'models/recitation_result.dart';
import 'phoneme_aligner.dart';
import 'quran_reference.dart';
import 'quran_units.dart';

/// قاعدة مدّ جاهزة (تُستخدم أيضًا في madd_timing).
TajweedRule _maddRule(int goldenLen) => TajweedRule(
    nameAr: 'المدّ',
    nameEn: 'Madd',
    goldenLen: goldenLen,
    correctnessType: 'count');

TajweedRule _rule(String ar, String en) =>
    TajweedRule(nameAr: ar, nameEn: en, correctnessType: 'match');

/// يبني الأخطاء من عمليات محاذاة الوحدات.
List<RecitationError> buildErrorsFromUnitAlignment({
  required List<UnitAlignOp> ops,
  required List<QuranUnit> refUnits,
  required List<QuranUnit> predUnits,
  required QuranReferenceVerse reference,
}) {
  final errors = <RecitationError>[];
  for (final op in ops) {
    switch (op.type) {
      case 'match':
      case 'replace':
        if (op.refIdx < 0 || op.predIdx < 0) continue;
        _handleSameLetterOrReplace(op, refUnits, predUnits, reference, errors);
      case 'insert':
        if (op.predIdx < 0) continue;
        _handleInsert(op, predUnits, errors);
      case 'delete':
        if (op.refIdx < 0) continue;
        _handleDelete(op, refUnits, reference, errors);
    }
  }
  return errors;
}

/// فرعا match/replace: نفس الحرف (تفاصيل) أو حرف مختلف.
void _handleSameLetterOrReplace(
  UnitAlignOp op,
  List<QuranUnit> refUnits,
  List<QuranUnit> predUnits,
  QuranReferenceVerse reference,
  List<RecitationError> errors,
) {
  final ref = refUnits[op.refIdx];
  final pred = predUnits[op.predIdx];
  final word = reference.wordAt(op.refIdx);
  final pos = [op.refIdx, op.refIdx + 1];

  // حرفان أساسيان مختلفان → normal/replace.
  if (ref.letter != pred.letter) {
    errors.add(RecitationError(
      errorType: 'normal',
      speechErrorType: 'replace',
      uthmaniPos: pos,
      phPos: [op.predIdx, op.predIdx + 1],
      expectedPh: ref.symbol,
      predictedPh: pred.symbol,
      wordText: word,
    ));
    return;
  }

  // نفس الرمز تمامًا → لا خطأ رمزي (الزمني لاحقًا).
  if (ref.symbol == pred.symbol) return;

  // مدّ مختلف الطول.
  if (ref.isMadd && pred.isMadd) {
    final golden = ref.maddLength!;
    final actual = pred.maddLength!;
    // المدّ الحر (golden>=4): الوصل يجعله 2 مشروعًا والإفراط بِحركتين متسامح.
    final ok =
        golden >= 4 ? (actual >= 2 && actual <= golden + 2) : actual == golden;
    if (!ok) {
      errors.add(RecitationError(
        errorType: 'tajweed',
        speechErrorType: 'replace',
        uthmaniPos: pos,
        phPos: [op.predIdx, op.predIdx + 1],
        expectedPh: ref.symbol,
        predictedPh: pred.symbol,
        expectedLen: golden,
        predictedLen: actual,
        wordText: word,
        refTajweedRules: [_maddRule(golden)],
      ));
    }
    return;
  }

  // فرق حالة تجويدية: شدة/قلقلة/غنّة/إخفاء.
  final diffs = <TajweedRule>[];
  if (ref.isShadda != pred.isShadda) diffs.add(_rule('الشدة', 'Shaddah'));
  if (ref.qalqalah != pred.qalqalah) diffs.add(_rule('القلقلة', 'Qalqalah'));
  if (ref.ghunna != pred.ghunna) diffs.add(_rule('الغنّة', 'Ghunnah'));
  if (ref.ikhfaa != pred.ikhfaa) diffs.add(_rule('الإخفاء', 'Ikhfaa'));
  if (diffs.isNotEmpty) {
    errors.add(RecitationError(
      errorType: 'tajweed',
      speechErrorType: 'replace',
      uthmaniPos: pos,
      phPos: [op.predIdx, op.predIdx + 1],
      expectedPh: ref.symbol,
      predictedPh: pred.symbol,
      wordText: word,
      refTajweedRules: diffs,
    ));
    return;
  }

  // بقي فرق الحركة (أو حركة ناقصة/زائدة) → tashkeel.
  final String spTp;
  if (pred.haraka == null && ref.haraka != null) {
    spTp = 'delete';
  } else if (pred.haraka != null && ref.haraka == null) {
    spTp = 'insert';
  } else {
    spTp = 'replace';
  }
  errors.add(RecitationError(
    errorType: 'tashkeel',
    speechErrorType: spTp,
    uthmaniPos: pos,
    phPos: [op.predIdx, op.predIdx + 1],
    expectedPh: ref.symbol,
    predictedPh: pred.symbol,
    wordText: word,
  ));
}

/// فرع insert: ضوضاء CTC شائعة تُتجاهل.
void _handleInsert(
  UnitAlignOp op,
  List<QuranUnit> predUnits,
  List<RecitationError> errors,
) {
  final pred = predUnits[op.predIdx];
  if (pred.isNoiseInsert) return;
  errors.add(RecitationError(
    errorType: 'normal',
    speechErrorType: 'insert',
    uthmaniPos: const [0, 0],
    phPos: [op.predIdx, op.predIdx + 1],
    expectedPh: '',
    predictedPh: pred.symbol,
  ));
}

/// فرع delete: تسامح الوحدة الأولى + تصنيف حسب حالة الوحدة.
void _handleDelete(
  UnitAlignOp op,
  List<QuranUnit> refUnits,
  QuranReferenceVerse reference,
  List<RecitationError> errors,
) {
  final ref = refUnits[op.refIdx];

  // تسامح الوحدة الأولى القصيرة (نمط معروف في النماذج الصغيرة).
  if (op.refIdx == 0 && ref.symbol.length <= 2) return;

  final word = reference.wordAt(op.refIdx);
  final rules = <TajweedRule>[
    if (ref.isMadd) _maddRule(ref.maddLength ?? 2),
    if (ref.isShadda) _rule('الشدة', 'Shaddah'),
    if (ref.qalqalah) _rule('القلقلة', 'Qalqalah'),
    if (ref.ghunna) _rule('الغنّة', 'Ghunnah'),
    if (ref.ikhfaa) _rule('الإخفاء', 'Ikhfaa'),
  ];
  errors.add(RecitationError(
    errorType: rules.isNotEmpty ? 'tajweed' : 'normal',
    speechErrorType: 'delete',
    uthmaniPos: [op.refIdx, op.refIdx + 1],
    phPos: [op.refIdx, op.refIdx + 1],
    expectedPh: ref.symbol,
    predictedPh: '',
    wordText: word,
    refTajweedRules: rules,
  ));
}
