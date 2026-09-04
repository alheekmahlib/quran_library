/// يتتبّع تقدّم التلاوة على نطاق مرجعي متعدد الآيات (وضع الصفحة).
///
/// منطق نقي (بلا sherpa/ffi) — مُطابِق تزايدي حتمي: التلاوة متسلسلة
/// ومخرجات greedy CTC إلحاقية فقط (لا تُراجَع)، لذا نحافظ على مؤشّر
/// الوحدة المرجعية المتوقَّعة التالية ونطابق كل وحدة متنبأة جديدة:
///
/// 1. **مطابقة فورية عند المتوقَّع بالضبط فقط** (حتى [tightSkipUnits]
///    وهو 0 افتراضيًا): التلاوة السليمة تتقدّم وحدة-وحدة دون أي قفز.
/// 2. **أي تخطٍّ مشروط بالتأكيد**: تطابق بعيد عن المتوقَّع (حتى
///    [maxSkipUnits] — حذف حرف أو كلمة) لا يُقبل فورًا؛ يُحفظ مؤقتًا
///    ولا يُقرّ إلا إذا طابقت الوحدة التالية على الإزاحة نفسها (دليل
///    تجاوز فعلٍي)، وإلا عُدَّت الوحدة الأولى إدراجًا (نطقًا زائدًا).
///    المطابقة بالحرف الأساسي فقط (بلا حركات) والحروف العربية تتكرر
///    كثيرًا — لولا التأكيد لانزلق المؤشر وحداتٍ أمامية مع كل حرف
///    متكرر فتظهر كلمات لم تُتلَ بعد.
/// 3. **لا تطابق** → إدراج يُنسب لِلكلمة المتوقَّعة دون تحريك المؤشّر.
///
/// يُبلّغ:
/// - [onRangeWord]: الكلمة الجارية (فهرس الآية داخل النطاق + فهرس الكلمة).
/// - [onWordDone]: اكتمال نطق كلمة بَعد تجاوز المتتبّع آخر وحدة فيها،
///   ومعها صحة نطقها (لا حذف/إدراج على وحداتها = صحيح).
/// - [onRangeComplete]: اكتمال كل كلمات النطاق.
///
/// ملاحظة: هذا التتبّع لِلعرض اللحظي فقط — التقييم النهائي الكامل
/// (المحاذاة الشاملة عند الإيقاف) يبقى المرجع.
library;

import 'quran_reference.dart';
import 'quran_units.dart';
import 'tasmee_error_kind.dart';

class RangeLiveTracker {
  RangeLiveTracker({
    required this.range,
    this.tightSkipUnits = 0,
    this.maxSkipUnits = 8,
    this.onRangeWord,
    this.onWordDone,
    this.onRangeComplete,
  });

  /// النطاق المرجعي (آيات الصفحة).
  final QuranReferenceRange range;

  /// أقصى تخطٍّ فوري غير مؤكَّد حول المتوقَّع (وحدات) — الافتراضي 0:
  /// لا قفز فوري إطلاقًا؛ الحذوف الحقيقية تُلتقط عبر القفزات المؤكَّدة.
  final int tightSkipUnits;

  /// أقصى تخطٍّ واسع مؤكَّد (وحدات) — يغطي حذف كلمة–كلمتين.
  final int maxSkipUnits;

  final void Function(int verseIdx, int wordIdx)? onRangeWord;
  final void Function(int verseIdx, int wordIdx, TasmeeErrorKind kind)?
      onWordDone;
  final void Function()? onRangeComplete;

  /// فهرس الوحدة المرجعية المتوقَّعة التالية (0-based).
  int _nextRef = 0;

  /// عدد الوحدات المتنبأة المستهلَكة حتى الآن.
  int _consumedPred = 0;

  /// فهرس المطابقة المرشَّح لقفزة واسعة مؤقتة بانتظار تأكيد (-1 = لا شيء).
  int _pendingK = -1;

  /// الوحدة المتنبأة المؤقتة المرتبطة بِـ [_pendingK] (لِلتصنيف عند التأكيد).
  QuranUnit? _pendingUnit;

  /// مؤشر كلمات النطاق المُبلَّغ عن اكتمالها.
  int _doneCursor = 0;

  /// آخر (آية، كلمة) جارية مُبلَّغة.
  int _lastVerse = -1;
  int _lastWord = -1;
  bool _completeFired = false;

  /// أسوأ نوع خطأ لكل كلمة شهدت حذفًا/إدراجًا/اختلاف رمز على وحداتها.
  final Map<QuranRangeWordSpan, TasmeeErrorKind> _wordKinds = {};

  /// عدد الكلمات المكتملة حتى الآن.
  int get completedWords => _doneCursor;

  /// هل اكتمل النطاق كله؟
  bool get isComplete => _completeFired;

  /// يُغذّى بِالقائمة الكاملة المتنامية للوحدات المتعرَّف عليها.
  void onUnits(List<QuranUnit> predUnits) {
    if (_completeFired) return;
    for (var p = _consumedPred; p < predUnits.length; p++) {
      _matchOne(predUnits[p]);
    }
    _consumedPred = predUnits.length;
    _reportCompleted();
    _fireComplete();
  }

  /// يطابق وحدة متنبأة واحدة (ضيقة → واسعة مؤكَّدة → إدراج).
  void _matchOne(QuranUnit pred) {
    if (_nextRef >= range.units.length) return; // النطاق انتهى — فائض.

    // 1) مطابقة فورية — عند الوحدة المتوقَّعة (أو ضمن الهامش الضيق
    //    غير المؤكَّد إن فُتح صراحةً). الوحدة المطابِقة للمتوقَّع تُنهي
    //    أي قفزة مؤقتة معلَّقة (كانت ضوضاء صادفت حرفًا أماميًا).
    final tight = _findMatch(pred, tightSkipUnits);
    if (tight >= 0) {
      if (_pendingK >= 0) _discardPending();
      _consume(tight, pred);
      return;
    }

    // 2) قفزة واسعة — تحتاج تأكيد الوحدة التالية على الإزاحة نفسها.
    final wide = _findMatch(pred, maxSkipUnits);
    if (wide < 0) {
      // 3) لا مطابقة → إدراج على الكلمة المتوقَّعة (والقفزة المؤقتة ساقطة).
      if (_pendingK >= 0) _resolvePendingAsInsert();
      _markError(_nextRef, TasmeeErrorKind.normal);
      return;
    }
    // وحدة بلا أي مطابقة قريبة مع قفزة معلَّقة: القفزة كانت ضوضاء —
    // أسقطها بصمت (ستُعالَج هذه الوحدة في الفرع أعلاه/أدناه).
    if (_pendingK >= 0) {
      if (wide == _pendingK + 1) {
        // تأكيد: وحدتان متتاليتان على الإزاحة نفسها → تجاوز فعلي.
        _consume(_pendingK, _pendingUnit ?? pred);
        _pendingUnit = null;
        _pendingK = -1;
        _consume(wide, pred);
      } else {
        // إزاحتان مختلفتان → الأولى إدراج، والثانية تنتظر تأكيدًا
        // (نخزّن وحدتها لِلتصنيف عند التأكيد).
        _resolvePendingAsInsert();
        _pendingUnit = pred;
        _pendingK = wide;
      }
      return;
    }
    _pendingUnit = pred;
    _pendingK = wide;
  }

  /// أول فهرس مرجعي (من المتوقَّع حتى [skip] بعده) يطابق حرف الوحدة.
  int _findMatch(QuranUnit pred, int skip) {
    final limit = (_nextRef + skip < range.units.length)
        ? _nextRef + skip
        : range.units.length - 1;
    for (var k = _nextRef; k <= limit; k++) {
      if (range.units[k].letter == pred.letter) return k;
    }
    return -1;
  }

  /// يستهلك مطابقة عند [k] مع تصنيف الكلمات المتأثرة:
  /// الوحدات المتخطَّاة قبله حذف (تجويدية = تجويد وإلا نطق)، والوحدة
  /// المطابِقة نفسها: رمز مطابق = سليمة، نفس الحرف برمز مختلف =
  /// تشكيل أو تجويد بحسب طبيعة الفرق (منطق error_detector نفسه).
  void _consume(int k, QuranUnit pred) {
    for (var d = _nextRef; d < k; d++) {
      final ref = range.units[d];
      final tajweedish = ref.isMadd ||
          ref.isShadda ||
          ref.qalqalah ||
          ref.ghunna ||
          ref.ikhfaa;
      _markError(
          d, tajweedish ? TasmeeErrorKind.tajweed : TasmeeErrorKind.normal);
    }
    final ref = range.units[k];
    if (ref.symbol != pred.symbol) {
      _markError(k, _classifyUnitDiff(ref, pred));
    }
    _nextRef = k + 1;
    _reportCurrentWord();
  }

  /// يصنّف فرق رمزين بنفس الحرف الأساسي: فروق التجويد (مدّ/شدة/قلقلة/
  /// غنّة/إخفاء) → تجويد، وإلا ففرق الحركة → تشكيل.
  TasmeeErrorKind _classifyUnitDiff(QuranUnit ref, QuranUnit pred) {
    final tajweedDiff = (ref.isMadd != pred.isMadd) ||
        (ref.isShadda != pred.isShadda) ||
        (ref.qalqalah != pred.qalqalah) ||
        (ref.ghunna != pred.ghunna) ||
        (ref.ikhfaa != pred.ikhfaa) ||
        (ref.isMadd && pred.isMadd && ref.coreRepeat != pred.coreRepeat);
    return tajweedDiff ? TasmeeErrorKind.tajweed : TasmeeErrorKind.tashkeel;
  }

  /// القفزة المؤقتة ساقطة → الوحدة نطق زائد على الكلمة المتوقَّعة.
  void _resolvePendingAsInsert() {
    _markError(_nextRef, TasmeeErrorKind.normal);
    _pendingUnit = null;
    _pendingK = -1;
  }

  /// إسقاط القفزة المؤقتة بصمت — الوحدة التالية طابقت المتوقَّع
  /// بالضبط فالقفزة كانت حرفًا أماميًا متكررًا صادف التنبؤ، لا نطقًا
  /// زائدًا يستحق وسْم خطأ.
  void _discardPending() {
    _pendingUnit = null;
    _pendingK = -1;
  }

  /// يسجّل خطأ بنوعه على الكلمة التي تضم الوحدة المرجعية [unitIdx]
  /// (الأعلى أسبقية يبقى عند تعدد الأخطاء في الكلمة).
  void _markError(int unitIdx, TasmeeErrorKind kind) {
    final span = range.spanOfUnit(unitIdx);
    if (span == null) return;
    final prev = _wordKinds[span];
    _wordKinds[span] = prev == null ? kind : mergeTasmeeErrorKinds(prev, kind);
  }

  /// يبلّغ الكلمة الجارية عند تغيّرها.
  void _reportCurrentWord() {
    final onRangeWord = this.onRangeWord;
    if (onRangeWord == null) return;
    final last = _nextRef - 1;
    if (last < 0 || last >= range.units.length) return;
    final v = range.unitVerseIdx[last];
    final w = range.unitWordIdx[last];
    if (v != _lastVerse || w != _lastWord) {
      _lastVerse = v;
      _lastWord = w;
      onRangeWord(v, w);
    }
  }

  /// يبلّغ الكلمات التي تجاوزها المؤشّر (آخر وحدة فيها مُطابَقة)
  /// مع نوع خطأها (correct إن كانت سليمة).
  void _reportCompleted() {
    final onWordDone = this.onWordDone;
    while (_doneCursor < range.wordSpans.length &&
        range.wordSpans[_doneCursor].endUnit < _nextRef) {
      final span = range.wordSpans[_doneCursor];
      onWordDone?.call(span.verseIdx, span.wordIdx,
          _wordKinds[span] ?? TasmeeErrorKind.correct);
      _doneCursor++;
    }
  }

  /// يبلّغ اكتمال النطاق مرة واحدة فقط.
  void _fireComplete() {
    if (_completeFired || _doneCursor < range.wordSpans.length) return;
    _completeFired = true;
    onRangeComplete?.call();
  }
}
