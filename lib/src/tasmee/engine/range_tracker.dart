/// يتتبّع تقدّم التلاوة على نطاق مرجعي متعدد الآيات (وضع الصفحة).
///
/// منطق نقي (بلا sherpa/ffi) — مُطابِق تزايدي حتمي: التلاوة متسلسلة
/// ومخرجات greedy CTC إلحاقية فقط (لا تُراجَع)، لذا نحافظ على مؤشّر
/// الوحدة المرجعية المتوقَّعة التالية ونطابق كل وحدة متنبأة جديدة:
///
/// 1. **مطابقة ضيقة** (حتى [tightSkipUnits] حول المتوقَّع): تطابق الحروف
///    يُستهلك فورًا (مع تسجيل الوحدات المتخطَّاة حذفًا).
/// 2. **قفزة واسعة مشروطة بالتأكيد**: تطابق بعيد (حتى [maxSkipUnits] —
///    تخطّي كلمة مثلًا) لا يُقبل فورًا؛ يُحفظ مؤقتًا ولا يُقرّ إلا إذا
///    طابقت الوحدة التالية على الإزاحة نفسها (دليل تجاوز فعلٍي)، وإلا
///    عُدَّت الوحدة الأولى إدراجًا (نطقًا زائدًا) — هذا يمنع انزياح
///    التتبّع كاملًا بسبب حرف خاطئ صادف حرفًا بعيدًا.
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

class RangeLiveTracker {
  RangeLiveTracker({
    required this.range,
    this.tightSkipUnits = 2,
    this.maxSkipUnits = 8,
    this.onRangeWord,
    this.onWordDone,
    this.onRangeComplete,
  });

  /// النطاق المرجعي (آيات الصفحة).
  final QuranReferenceRange range;

  /// أقصى تخطٍّ فوري حول المتوقَّع (وحدات) — يغطي اهتزاز نطق بسيط.
  final int tightSkipUnits;

  /// أقصى تخطٍّ واسع مؤكَّد (وحدات) — يغطي حذف كلمة–كلمتين.
  final int maxSkipUnits;

  final void Function(int verseIdx, int wordIdx)? onRangeWord;
  final void Function(int verseIdx, int wordIdx, bool correct)? onWordDone;
  final void Function()? onRangeComplete;

  /// فهرس الوحدة المرجعية المتوقَّعة التالية (0-based).
  int _nextRef = 0;

  /// عدد الوحدات المتنبأة المستهلَكة حتى الآن.
  int _consumedPred = 0;

  /// فهرس المطابقة المرشَّح لقفزة واسعة مؤقتة بانتظار تأكيد (-1 = لا شيء).
  int _pendingK = -1;

  /// مؤشر كلمات النطاق المُبلَّغ عن اكتمالها.
  int _doneCursor = 0;

  /// آخر (آية، كلمة) جارية مُبلَّغة.
  int _lastVerse = -1;
  int _lastWord = -1;
  bool _completeFired = false;

  /// الكلمات التي شهدت حذفًا أو إدراجًا على وحداتها.
  final Set<QuranRangeWordSpan> _erroredSpans = {};

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

    // 1) مطابقة ضيقة فورية.
    final tight = _findMatch(pred, tightSkipUnits);
    if (tight >= 0) {
      if (_pendingK >= 0) _resolvePendingAsInsert();
      _consume(tight);
      return;
    }

    // 2) قفزة واسعة — تحتاج تأكيد الوحدة التالية على الإزاحة نفسها.
    final wide = _findMatch(pred, maxSkipUnits);
    if (wide < 0) {
      // 3) لا مطابقة → إدراج على الكلمة المتوقَّعة (والقفزة المؤقتة ساقطة).
      if (_pendingK >= 0) _resolvePendingAsInsert();
      _markError(_nextRef);
      return;
    }
    if (_pendingK >= 0) {
      if (wide == _pendingK + 1) {
        // تأكيد: وحدتان متتاليتان على الإزاحة نفسها → تجاوز فعلي.
        _consume(_pendingK);
        _pendingK = -1;
        _consume(wide);
      } else {
        // إزاحتان مختلفتان → الأولى إدراج، والثانية تنتظر تأكيدًا.
        _resolvePendingAsInsert();
        _pendingK = wide;
      }
      return;
    }
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

  /// يستهلك مطابقة عند [k]: الوحدات قبله حذف، والمؤشّر يتجاوزه.
  void _consume(int k) {
    for (var d = _nextRef; d < k; d++) {
      _markError(d);
    }
    _nextRef = k + 1;
    _reportCurrentWord();
  }

  /// القفزة المؤقتة ساقطة → الوحدة نطق زائد على الكلمة المتوقَّعة.
  void _resolvePendingAsInsert() {
    _markError(_nextRef);
    _pendingK = -1;
  }

  /// يسجّل خطأً على الكلمة التي تضم الوحدة المرجعية [unitIdx].
  void _markError(int unitIdx) {
    final span = range.spanOfUnit(unitIdx);
    if (span != null) _erroredSpans.add(span);
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

  /// يبلّغ الكلمات التي تجاوزها المؤشّر (آخر وحدة فيها مُطابَقة).
  void _reportCompleted() {
    final onWordDone = this.onWordDone;
    while (_doneCursor < range.wordSpans.length &&
        range.wordSpans[_doneCursor].endUnit < _nextRef) {
      final span = range.wordSpans[_doneCursor];
      onWordDone?.call(
          span.verseIdx, span.wordIdx, !_erroredSpans.contains(span));
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
