/// يتتبّع تقدّم التلاوة على نطاق مرجعي متعدد الآيات (وضع الصفحة).
///
/// منطق نقي (بلا sherpa/ffi) — مُطابِق تزايدي حتمي: التلاوة متسلسلة
/// ومخرجات greedy CTC إلحاقية فقط (لا تُراجَع)، لذا نحافظ على مؤشّر
/// الوحدة المرجعية المتوقَّعة التالية ونطابق كل وحدة متنبأة جديدة:
///
/// 1. **مطابقة فورية عند المتوقَّع بالضبط فقط** (حتى [tightSkipUnits]
///    وهو 0 افتراضيًا): التلاوة السليمة تتقدّم وحدة-وحدة دون أي قفز.
/// 2. **أي تخطٍّ مشروط بتأكيد 3 وحدات متتالية**: تطابق بعيد عن المتوقَّع
///    (حتى [maxSkipUnits] — حذف حرف أو كلمة) لا يُقبل فورًا؛ يُحفظ مؤقتًا
///    ولا يُقرّ إلا إذا طابقت **ثلاث** وحدات متتالية على مواضع متعاقبة
///    بالإزاحة نفسها (دليل تجاوز فعلي)، وإلا عُدَّت الوحدة الأولى إدراجًا.
///    المطابقة بالحرف الأساسي فقط (بلا حركات) والحروف العربية تتكرر
///    كثيرًا — لولا التأكيد المضاعف لانزلق المؤشر وحداتٍ أمامية مع كل
///    حرف متكرر فتظهر كلمات لم تُتلَ بعد. وتُجمع **كل** المواضع المطابقة
///    في النافذة ويُقبل الموضع المتعاقب المتوقع إن كان بينها — أول
///    تطابق كثيرًا ما يكون حرفًا زائدًا لا الموضع الحقيقي.
/// 3. **لا تطابق** → تُجمَّع الوحدة في بافر إدراجات مؤجَّل (لا خطأ فوريًا):
///    - عادت مطابقة فورية عند المتوقَّع → البافر نطق زائد فعلي (زيادة).
///    - امتلأ البافر ([maxBufferedInserts]) → مُحاولة **إعادة إرساء**
///      تبحث عن أطول سلسلة وحدات متتالية متطابقة داخل نافذة أمام
///      المتوقَّع ([reanchorWindowUnits]) — سلسلة بطول كافٍ
///      ([minReanchorMatches]): يُقفز المؤشر إليها (انزلاق تزامن أو
///      تخطٍّ كبير)؛ لا سلسلة كافية: تُوسم الإدراجات وتصفَّر.
///
/// **طور الالتقاط** ([isAcquiring]): قبل تحديد نقطة بداية المستخدم
/// الفعلية لا تُوسم أخطاء ولا تُقبل مطابقات فورية أو قفزات إطلاقًا —
/// كل وحدة (حتى المطابقة الضيّقة عند أول النطاق) تُجمَّع في البافر، فمطابقة
/// واحدة ليست دليل بداية: الحروف متكررة وضوضاء CTC الافتتاحية تصادف حرف
/// أول الصفحة غالبًا فتُظهر أول كلمة زورًا. الالتقاط يُقفل **بإعادة إرساء
/// ناجحة وحدها**: أطول سلسلة وحدات متتالية متطابقة عبر النطاق كاملًا —
/// بسملة وضوضاء البداية تُتجاهل، و**بداية من منتصف النطاق** تُلتقط على
/// موضعها، وكلمات ما قبل نقطة البداية تُبتلع بصمت (لم تُتلَ فلا تُبلَّغ
/// صحيحة ولا خاطئة).
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

import 'dart:developer' show log;

import 'quran_reference.dart';
import 'quran_units.dart';
import 'tasmee_error_kind.dart';

class RangeLiveTracker {
  RangeLiveTracker({
    required this.range,
    this.tightSkipUnits = 0,
    this.maxSkipUnits = 8,
    this.confirmUnits = 3,
    this.maxBufferedInserts = 12,
    this.reanchorContextUnits = 24,
    this.reanchorWindowUnits = 24,
    this.minReanchorMatches = 4,
    this.reanchorPreferNearestMargin = 4,
    this.fastAnchorUnits = 5,
    this.fastAnchorLeadTolerance = 3,
    this.fastAnchorMissTolerance = 4,
    this.coldAcquireNearUnits = 45,
    this.coldAcquireFarMinMatches = 7,
    this.resumeBackUnits = 8,
    this.resumeAheadUnits = 30,
    this.acquisitionTrimUnits = 8,
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

  /// عدد الوحدات المتتالية على الإزاحة نفسها اللازمة لتأكيد قفزة واسعة.
  final int confirmUnits;

  /// سقف بافر الإدراجات المؤجَّلة قبل محاولة إعادة الإرساء ثم الوسم.
  final int maxBufferedInserts;

  /// اتساع سياق الوصول لإعادة الإرساء (وحدات متنبأة حديثًا بترتيبها).
  final int reanchorContextUnits;

  /// اتساع نافذة إعادة الإرساء (وحدات مرجعية أمام المتوقَّع).
  final int reanchorWindowUnits;

  /// الحد الأدنى لطول سلسلة الوحدات المتتالية المتطابقة لقبول الإرساء.
  final int minReanchorMatches;

  /// تفاضل الطول الذي تُزيح به سلسلةٌ أبعد السلسلةَ الأقرب (تفضيل
  /// الأقرب أمام تكرار النص القرآني).
  final int reanchorPreferNearestMargin;

  /// عدد الوحدات المتطابقة **بالحرف الأساسي** (بلا حركات) المتتالية من
  /// نقطة البداية المرجَّحة التي تُرسّي المؤشر فورًا دون انتظار امتلاء
  /// البافر — إرساء على مستوى الحرف: وحدة زائدة في أول المخزن (نفَس/
  /// همزة/صمت) أو حركة مختلفة لا تُسقط الإرساء لبقية الجلسة.
  final int fastAnchorUnits;

  /// أقصى وحدات **زائدة** تُغتفر في أول بافر الالتقاط قبل سلسلة الإرساء.
  final int fastAnchorLeadTolerance;

  /// أقصى وحدات **ساقطة** من بداية المرجع يُغتفر تخطّيها (تأخر بدء
  /// الميكروفون يبتلع أول وحدات النطق).
  final int fastAnchorMissTolerance;

  /// البداية الباردة: ضمن أول هذا العدد من وحدات النطاق تكفي سلسلة
  /// [minReanchorMatches] — فرضية «بدأ المستخدم من أول النطاق».
  final int coldAcquireNearUnits;

  /// البداية الباردة بعيدًا عن أول النطاق: تشترط سلسلة بهذا الطول على
  /// الأقل (مطابقة قصيرة بعيدة سهلة المصادفة في النص المتكرر).
  final int coldAcquireFarMinMatches;

  /// استئناف بعد إعادة تسليح الالتقاط: نافذة الإرساء خلف المؤشر.
  final int resumeBackUnits;

  /// استئناف بعد إعادة تسليح الالتقاط: نافذة الإرساء أمام المؤشر.
  final int resumeAheadUnits;

  /// فشل إعادة الإرساء أثناء الالتقاط: يُبقى على آخر هذا العدد من
  /// وحدات البافر (انزلاقي) بدل إهداره.
  final int acquisitionTrimUnits;

  final void Function(int verseIdx, int wordIdx)? onRangeWord;
  final void Function(
    int verseIdx,
    int wordIdx,
    TasmeeErrorKind kind,
    TasmeeWordMistake? mistake,
  )? onWordDone;
  final void Function()? onRangeComplete;

  /// تسامح اكتمال آخر كلمة في النطاق (وحدات): تكتمل باستُهلاك كل وحداتها
  /// **إلا هذا العدد** — وحدة الختام كثيرًا ما تسقط من التعرّف أو تُستبدل.
  static const int lastWordTailTolerance = 1;

  /// عدد وحدات كل كلمة الموسومة بخطأ — دليل الحكم في المصحّح: الحذف أو
  /// الاستبدال المعزول الأول لا يفتح شيتًا؛ يلزم دليلان.
  final Map<QuranRangeWordSpan, int> _wordMarkedUnitCounts = {};

  /// فهرس الوحدة المرجعية المتوقَّعة التالية (0-based).
  int _nextRef = 0;

  /// عدد الوحدات المتنبأة المستهلَكة حتى الآن.
  int _consumedPred = 0;

  /// فهرس المطابقة المرشَّح لقفزة واسعة مؤقتة بانتظار تأكيد (-1 = لا شيء).
  int _pendingK = -1;

  /// الوحدة المتنبأة المؤقتة المرتبطة بِـ [_pendingK] (لِلتصنيف عند التأكيد).
  QuranUnit? _pendingUnit;

  /// وحدات التأكيد المتتالية بعد الوحدة المؤقتة الأولى.
  final List<QuranUnit> _confirmUnits = [];

  /// بافر الإدراجات المؤجَّلة — وحدات بلا أي مطابقة قريبة، لم تُوسم بعد.
  final List<QuranUnit> _insertBuffer = [];

  /// آخر الوحدات المتنبأة **بترتيب وصولها** (استُهلكت أو تأجّلت) —
  /// كلام المستخدم متجاورٌ فيه حتمًا مهما تشعّبت مسارات الاستهلاك،
  /// فسلسلته الحقيقية عند موضعه تطابق السياق كاملًا وتغلب أي توافق
  /// مصادفة — أساس إعادة الإرساء.
  final List<QuranUnit> _recentPred = [];

  /// طور الالتقاط: لم يُرسَ المحاذي على موضع المستخدم الفعلي بعد.
  bool _acquiring = true;

  /// أول وحدة مرجعية اكتمل بها الالتقاط (-1 ما دام الالتقاط جاريًا).
  int _firstConsumedRefIdx = -1;

  /// مؤشر كلمات النطاق المُبلَّغ عن اكتمالها.
  int _doneCursor = 0;

  /// آخر (آية، كلمة) جارية مُبلَّغة.
  int _lastVerse = -1;
  int _lastWord = -1;
  bool _completeFired = false;

  /// أسوأ نوع خطأ لكل كلمة شهدت حذفًا/إدراجًا/اختلاف رمز على وحداتها.
  final Map<QuranRangeWordSpan, TasmeeErrorKind> _wordKinds = {};

  /// تفصيل الخطأ المعتمد لكل كلمة (يرافق [TasmeeErrorKind] في onWordDone)
  /// — يُستبدل عند ورود خطأ أعلى أسبقية.
  final Map<QuranRangeWordSpan, TasmeeWordMistake> _wordMistakes = {};

  /// عدد الكلمات المكتملة حتى الآن.
  int get completedWords => _doneCursor;

  /// هل اكتمل النطاق كله؟
  bool get isComplete => _completeFired;

  /// هل ما زال المحاذي في طور الالتقاط (لم تُحدَّد نقطة البداية بعد)؟
  bool get isAcquiring => _acquiring;

  /// أول وحدة مرجعية التُقطت (نقطة بداية التلاوة الفعلية) أو -1.
  int get firstConsumedRefIdx => _firstConsumedRefIdx;

  /// فهرس الوحدة المرجعية المتوقَّعة التالية الآن (0-based) — حدّ التقدّم
  /// الفعلي، أساس نافذة المقطع المتلو عند التقييم النهائي.
  int get nextExpectedRefIdx => _nextRef;

  /// يعيد تسليح طور الالتقاط بعد استئناف البثّ (إغلاق شيت المصحّح).
  ///
  /// فتح الشيت لا يوقف الميكروفون فورًا — وحدات تنزلق للمحاذاة وتُقدّم
  /// المؤشر أمام المستخدم الذي يواصل بعد الإغلاق من موضعه هو. إعادة
  /// التسليح تجعل الاستئناف بدايةَ جلسةٍ مصغّرة: الكلام الانتقالي (إعادة
  /// الكلمة المصحَّحة/المواصلة/الانتقال للآية التالية) يتجمّع في البافر
  /// حتى إرساء جديد على موضع المستخدم الفعلي — بلا وسم حذوف لما قفز
  /// فوقه المؤشر، وبلا أحداث للكلمات المتخطَّاة (لم يُنطق مضمونها أمام
  /// المؤشر الجديد). بعده يتتابع التتبّع الطبيعي.
  void rearmAcquisition() {
    if (_completeFired) return;
    _acquiring = true;
    _clearPending();
    _insertBuffer.clear();
    // سياق ما قبل الإيقاف يُفرَّغ أيضًا: بقاؤه يجعل إعادة الإرساء أثناء
    // الالتقاط تغلب تتابعًا قديمًا (يظهر أولًا في المسح) على كلام
    // المستخدم الجديد فيُرمى كلامه وُتعوَّض الكلمات السليمة وسمًا كاذبًا.
    _recentPred.clear();
  }

  /// يُغذّى بِالقائمة الكاملة المتنامية للوحدات المتعرَّف عليها.
  void onUnits(List<QuranUnit> predUnits) {
    if (_completeFired) return;
    for (var p = _consumedPred; p < predUnits.length; p++) {
      final pred = predUnits[p];
      _recentPred.add(pred);
      if (_recentPred.length > reanchorContextUnits) {
        _recentPred.removeAt(0);
      }
      _matchOne(pred);
    }
    _consumedPred = predUnits.length;
    _reportCompleted();
    _fireComplete();
  }

  /// يطابق وحدة متنبأة واحدة.
  ///
  /// أثناء طور الالتقاط تُجمَّع **كل** الوحدات في بافر الإدراجات المؤجَّل
  /// (حتى المطابقة الضيّقة عند أول وحدة) — مطابقة ضيّقة واحدة ليست دليل
  /// بداية: الحروف العربية متكررة وضوضاء CTC الافتتاحية تصادف حرفَ أول
  /// الصفحة غالبًا فتُظهر أول كلمة زورًا. الالتقاط يُقفل بإعادة الإرساء
  /// وحدها (سلسلة متتالية كافية من الكلام الفعلي) — انظر [_tryReanchor].
  void _matchOne(QuranUnit pred) {
    if (_nextRef >= range.units.length) return; // النطاق انتهى — فائض.

    // طور الالتقاط: لا مطابقة فورية ولا قفزات — جمّع في البافر حتى
    // يُعاد الإرساء على موضع المستخدم الفعلي.
    if (_acquiring) {
      _bufferInsert(pred);
      return;
    }

    // 1) مطابقة فورية — عند الوحدة المتوقَّعة (أو ضمن الهامش الضيق).
    final tight = _findMatch(pred, tightSkipUnits);
    if (tight >= 0) {
      if (_pendingK >= 0) _discardPending();
      _flushInserts();
      _consume(tight, pred);
      return;
    }

    // 2) قفزة واسعة — تحتاج تأكيد وحدات متتالية على مواضع متعاقبة.
    // تُجمع **كل** المواضع المطابقة في النافذة لا أولها: الحروف
    // العربية تتكرر داخل الكلمة الواحدة، وأول تطابق صادفه المسح كثيرًا
    // ما يكون حرفًا متقدمًا زائدًا لا الموضع المتعاقب الحقيقي — فيُفقد
    // التزامن على حذف وحدة واحدة ويتسلسل الوسم الكاذب.
    final cands = _allMatches(pred, maxSkipUnits);
    if (cands.isEmpty) {
      // 3) لا مطابقة → بافر إدراجات مؤجَّل (والقفزة المؤقتة ساقطة).
      if (_pendingK >= 0) _resolvePendingAsInsert();
      _bufferInsert(pred);
      return;
    }
    if (_pendingK >= 0) {
      final expected = _pendingK + _confirmUnits.length + 1;
      if (cands.contains(expected)) {
        // تأكيد جزئي: وحدة إضافية على الموضع المتعاقب التالي.
        _confirmUnits.add(pred);
        // قرب نهاية النطاق لا يُمكن جمع [confirmUnits] كاملة — بقيت
        // القفزة معلَّقة تُحلّ إدراجات فلا يكتمل النطاق أبدًا؛ تُقبل
        // بالمتاح متى قلّ الباقي عن المطلوب.
        final unitsAfterExpected = range.units.length - expected;
        if (_confirmUnits.length + 1 >= confirmUnits ||
            (unitsAfterExpected < confirmUnits && _confirmUnits.isNotEmpty)) {
          // تأكيد كامل — بشرط مسافة الكلمة الواحدة: حذف حرف أو كلمة
          // يقفز كلمةً واحدة على الأكثر. قفزة تعبر أكثر من كلمة ليست
          // حذفًا بل انزلاق كبير (النص القرآني متكرر فثلاث وحدات
          // متزامنة مصادفةً شائعة) — تُدار بإعادة الإرساء وحدها وإلا
          // مشى المؤشر قفزاتٍ زائفة ووسم ما بينها حذفًا.
          final spanDistance =
              range.spanIndexAt(_pendingK) - range.spanIndexAt(_nextRef);
          if (spanDistance > 1) {
            final leaked = <QuranUnit>[
              if (_pendingUnit != null) _pendingUnit!,
              ..._confirmUnits,
              pred,
            ];
            _clearPending();
            _insertBuffer.addAll(leaked);
            _drainInsertsIfNeeded();
            return;
          }
          // تجاوز فعلي ضمن كلمة/كلمتين.
          _flushInserts();
          _consume(_pendingK, _pendingUnit ?? pred);
          for (var i = 0; i < _confirmUnits.length; i++) {
            _consume(_pendingK + 1 + i, _confirmUnits[i]);
          }
          _clearPending();
        }
      } else {
        // إزاحتان مختلفتان → الأولى إدراج مؤجَّل، والثانية قفزة جديدة.
        _resolvePendingAsInsert();
        _pendingUnit = pred;
        _pendingK = cands.first;
        _confirmUnits.clear();
      }
      return;
    }
    _pendingUnit = pred;
    _pendingK = cands.first;
    _confirmUnits.clear();
  }

  /// كل المواضع المرجعية (من المتوقَّع حتى [skip] بعده) التي يطابق
  /// حرفها الأساسي حرف الوحدة.
  List<int> _allMatches(QuranUnit pred, int skip) {
    final limit = (_nextRef + skip < range.units.length)
        ? _nextRef + skip
        : range.units.length - 1;
    final out = <int>[];
    for (var k = _nextRef; k <= limit; k++) {
      if (range.units[k].letter == pred.letter) out.add(k);
    }
    return out;
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
    _markDeletes(_nextRef, k);
    final ref = range.units[k];
    if (ref.symbol != pred.symbol) {
      _markError(
        k,
        _classifyUnitDiff(ref, pred),
        expectedSymbol: ref.symbol,
        predictedSymbol: pred.symbol,
        errorType: 'replace',
      );
    }
    if (_acquiring) {
      _acquiring = false;
      _firstConsumedRefIdx = k;
    }
    _nextRef = k + 1;
    _reportCurrentWord();
  }

  /// يوسم الوحدات المرجعية [from..to) حذفًا — تجاوزها المستخدم.
  void _markDeletes(int from, int to) {
    for (var d = from; d < to; d++) {
      final ref = range.units[d];
      final tajweedish = ref.isMadd ||
          ref.isShadda ||
          ref.qalqalah ||
          ref.ghunna ||
          ref.ikhfaa;
      _markError(
        d,
        tajweedish ? TasmeeErrorKind.tajweed : TasmeeErrorKind.normal,
        expectedSymbol: ref.symbol,
        errorType: 'delete',
      );
    }
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

  /// القفزة المؤقتة ساقطة → وحدتها الأولى تنتقل لبافر الإدراجات المؤجَّل.
  void _resolvePendingAsInsert() {
    final unit = _pendingUnit;
    _clearPending();
    if (unit != null) _bufferInsert(unit);
  }

  /// إسقاط القفزة المؤقتة بصمت — الوحدة التالية طابقت المتوقَّع
  /// بالضبط فالقفزة كانت حرفًا أماميًا متكررًا صادف التنبؤ، لا نطقًا
  /// زائدًا يستحق وسْم خطأ.
  void _discardPending() {
    _clearPending();
  }

  void _clearPending() {
    _pendingUnit = null;
    _pendingK = -1;
    _confirmUnits.clear();
  }

  // ── بافر الإدراجات المؤجَّلة وإعادة الإرساء ──────────────────────

  /// يضيف وحدة بلا مطابقة إلى البافر — لا وسم فوريًا: قد تتضح لاحقًا
  /// سابقة إرساء (انزلاق/بداية متأخرة) فتُستهلك، أو نطقًا زائدًا فعليًا
  /// فتُوسم عند عودة المطابقة للمتوقَّع أو عند امتلاء البافر.
  void _bufferInsert(QuranUnit pred) {
    _insertBuffer.add(pred);
    if (_maybeFastAnchor()) return;
    _drainInsertsIfNeeded();
  }

  /// إرساء فوري أثناء الالتقاط: سلسلة وحدات متطابقة **بالحرف الأساسي**
  /// (بلا حركات) من نقطة البداية المرجَّحة — فاتحة النطاق عند بدء
  /// الجلسة، أو موضع المؤشر بعد إغلاق شيت المصحّح (الاستئناف المعتاد
  /// من الكلمة التالية). يلغي تأخّر الإظهار (~كلمتين بانتظار امتلاء
  /// البافر) دون فتح باب القفل الزائف.
  ///
  /// تسامح الحواف: حتى [fastAnchorLeadTolerance] وحدات زائدة في أول
  /// المخزن (نفَس/همزة/صمت تسبق الكلام)، وحتى [fastAnchorMissTolerance]
  /// وحدات ساقطة من بداية المرجع (تأخر الميكروفون يبتلع أول النطق —
  /// وضع المعلم خاصة). أفضل مرشّح بأصغر (زائد+ساقط)؛ الوحدات المخالفة
  /// داخل السلسلة تُصنَّف عند الاستهلاك تشكيلًا/تجويدًا فلا تمرّ صامتة.
  bool _maybeFastAnchor() {
    if (!_acquiring || _insertBuffer.length < fastAnchorUnits) return false;
    final base = _firstConsumedRefIdx < 0 ? 0 : _nextRef;
    final units = range.units;
    final maxLead = _insertBuffer.length - fastAnchorUnits;
    final leadCap =
        fastAnchorLeadTolerance < maxLead ? fastAnchorLeadTolerance : maxLead;
    var bestLead = -1;
    var bestMiss = 0;
    var bestCost = -1;
    for (var lead = 0; lead <= leadCap; lead++) {
      for (var miss = 0; miss <= fastAnchorMissTolerance; miss++) {
        if (base + miss + fastAnchorUnits > units.length) continue;
        var ok = true;
        for (var i = 0; i < fastAnchorUnits; i++) {
          if (_insertBuffer[lead + i].letter != units[base + miss + i].letter) {
            ok = false;
            break;
          }
        }
        if (ok && (bestCost < 0 || lead + miss < bestCost)) {
          bestCost = lead + miss;
          bestLead = lead;
          bestMiss = miss;
        }
      }
    }
    if (bestLead < 0) return false;
    final start = base + bestMiss;
    final anchored = _insertBuffer.sublist(bestLead);
    _insertBuffer.clear();
    _acquiring = false;
    // نقطة بداية المقطع راسخية: أول إرساء في الجلسة يبقى البداية —
    // إعادة التسليح بعد شيت المصحّح توسّع نافذة التقييم ولا تُزيحها.
    _firstConsumedRefIdx = _firstConsumedRefIdx >= 0
        ? (_firstConsumedRefIdx < start ? _firstConsumedRefIdx : start)
        : start;
    // ابتلع بصمت ما قبل نقطة الإرساء — كلماتٌ لم تُتلَ.
    while (_doneCursor < range.wordSpans.length &&
        range.wordSpans[_doneCursor].endUnit < start) {
      _doneCursor++;
    }
    for (var i = 0; i < anchored.length; i++) {
      if (start + i >= units.length) break;
      _consume(start + i, anchored[i]);
    }
    return true;
  }

  /// عند امتلاء البافر: محاولة إرساء ثم الوسم.
  void _drainInsertsIfNeeded() {
    if (_insertBuffer.length < maxBufferedInserts) return;
    // إرساء واحد بمسح النطاق من المتوقَّع إلى نهايته بأطول سلسلة —
    // النافذة المحلية القصيرة كانت «تنجح» زورًا على سلاسل مصادفة قصيرة
    // داخل النص المتكرر فتستهلك مواضع خاطئة ويتسلسل الخطأ، والانزلاقات
    // الكبيرة كانت تفشل فيها فيُصفَّر البافر ويواصل المستخدم تقدّمه
    // فتتسع الفجوة وتتوقف كل الكلمات التالية عن الظهور. موضع المستخدم
    // الحقيقي يطابق البافر كاملًا تقريبًا فتغلبه أطولُ سلسلة.
    _tryReanchor();
    if (_insertBuffer.length >= maxBufferedInserts) {
      if (_acquiring) {
        // أثناء الالتقاط لا يُهدر المخزن: احتفظ بآخر وحداته (انزلاقي)
        // — بداية كلام المستخدم الفعلية قد تكون في آخره وما قبلها
        // ضوضاء افتتاح تُقلَّم تدريجيًا حتى ينجح الإرساء.
        if (_insertBuffer.length > acquisitionTrimUnits) {
          _insertBuffer.removeRange(
              0, _insertBuffer.length - acquisitionTrimUnits);
        }
      } else {
        // لا مرساة واثقة — نطق زائد فعلي على الكلمة المتوقعة.
        _flushInserts();
      }
    }
  }

  /// يوسم محتوى البافر إدراجات على الكلمة المتوقَّعة ويصفّره.
  ///
  /// أثناء طور الالتقاط يُتجاهل المحتوى (بسملة/ضوضاء بداية — لا تُنسب
  /// لأي كلمة قبل تحديد نقطة البداية). وإعادة نطق آخر كلمة مستهلَكة
  /// (تردد/إعادة الكلمة المصحَّحة بعد الشيت) تُتجاهل صمتًا — ليست
  /// «زيادة» على الكلمة التالية.
  void _flushInserts() {
    if (_insertBuffer.isEmpty) return;
    if (!_acquiring) {
      final units =
          _insertBuffer.where((u) => !u.isNoiseInsert).toList(growable: false);
      if (units.isNotEmpty && !_isRepeatOfLastWord(units)) {
        for (final pred in units) {
          _markError(
            _nextRef,
            TasmeeErrorKind.normal,
            predictedSymbol: pred.symbol,
            errorType: 'insert',
          );
        }
      }
    }
    _insertBuffer.clear();
  }

  /// هل الوحدات إعادةُ نطقٍ لآخر كلمة مستهلَكة (بالحرف الأساسي)؟
  bool _isRepeatOfLastWord(List<QuranUnit> units) {
    final last = _nextRef - 1;
    if (last < 0 || last >= range.units.length) return false;
    final span = range.spanOfUnit(last);
    if (span == null) return false;
    final wordLen = span.endUnit - span.startUnit + 1;
    if (wordLen != units.length) return false;
    for (var i = 0; i < wordLen; i++) {
      if (range.units[span.startUnit + i].letter != units[i].letter) {
        return false;
      }
    }
    return true;
  }

  /// سلسلة وحدات متتالية متطابقة بالحرف الأساسي: بافر عند [predStart]
  /// مقابل مرجع عند [refStart] بطول [length].
  /// [nearUnits] (بداية باردة): أفضلية موضعية — فرضية «بدأ المستخدم من
  /// أول النطاق»: ضمن أول [nearUnits] وحدة تكفي سلسلة [minReanchorMatches]
  ///، وبعدها تشترط [coldAcquireFarMinMatches].
  ({int refStart, int predStart, int length})? _bestDiagonalRun(
    List<QuranUnit> refWindow,
    List<QuranUnit> buffer, {
    int? nearUnits,
  }) {
    var bestLen = 0;
    var bestRef = -1;
    var bestPred = -1;
    var found = false;
    for (var b = 0; b < buffer.length; b++) {
      for (var w = 0; w < refWindow.length; w++) {
        if (refWindow[w].letter != buffer[b].letter) continue;
        var len = 0;
        while (b + len < buffer.length &&
            w + len < refWindow.length &&
            refWindow[w + len].letter == buffer[b + len].letter) {
          len++;
        }
        final need = nearUnits == null || w < nearUnits
            ? minReanchorMatches
            : coldAcquireFarMinMatches;
        if (!found) {
          if (len >= need) {
            bestLen = len;
            bestRef = w;
            bestPred = b;
            found = true;
          }
        } else if (len > bestLen + reanchorPreferNearestMargin) {
          // تفضيل الأقرب: النص القرآني يتكرر، وسياق المستخدم قد ينكسر
          // عند الحدود — سلسلة أبعد لا تزيح الأقرب إلا بفارق حاسم.
          bestLen = len;
          bestRef = w;
          bestPred = b;
        }
      }
    }
    if (!found) return null;
    return (refStart: bestRef, predStart: bestPred, length: bestLen);
  }

  /// يحاول إعادة إرساء المؤشر على موضع المستخدم الفعلي: البحث عن أطول
  /// سلسلة وحدات متتالية متطابقة (بالحرف الأساسي) بين **سياق الوصول**
  /// (آخر الوحدات بترتيب وصولها — كلام المستخدم متجاورٌ فيه حتمًا مهما
  /// تشعّبت مسارات الاستهلاك، فسلسلته الحقيقية تطابق السياق كاملًا
  /// وتغلب أي توافق مصادفة داخل النص المتكرر) ومرجعٍ من المتوقَّع إلى
  /// نهاية النطاق (أو من بدايته أثناء الالتقاط).
  ///
  /// الوسم: حذوف للفجوة المرجعية بين المتوقَّع والمرساة (ما تخطّاه
  /// المستخدم فعلًا)، واستبدالات داخل السلسلة (فروق الحركة/المدّ
  /// الحية). أما ما قبل بداية السلسلة في سياق الوصول فيُتجاهل صمتًا —
  /// تاريخٌ مستهلَك خلطته مطابقاتٌ زائفة أثناء الانزلاق لا تلاوةُ
  /// المستخدم، والتقييم النهائي عند الإيقاف يحكم على منطقته من الصوت.
  /// الالتقاط يُنهيه الإرساء نفسه مع ابتلاع ما قبله بصمتًا.
  void _tryReanchor() {
    if (_insertBuffer.isEmpty || _nextRef >= range.units.length) return;
    // نافذة البحث:
    // - استئناف بعد إعادة تسليح الالتقاط (بداية راسخة سابقًا): نافذة
    //   محلية حول المؤشر [next-resumeBackUnits, next+resumeAheadUnits]
    //   — فحص الصفحة كلها يقدّم توافقًا مصادفةً بعيدًا على كلام المستخدم
    //   الجديد قرب موقعه الفعلي.
    // - بداية باردة: النطاق كله مع أفضلية موضعية (قرب أول النطاق سلسلة
    //   قصيرة تكفي، وبعيدًا تشترط الأطول).
    // - تتبّع عادي: من المتوقَّع إلى نهاية النطاق.
    int windowStart;
    var windowEnd = range.units.length;
    int? nearUnits;
    if (_acquiring && _firstConsumedRefIdx >= 0) {
      windowStart = _nextRef - resumeBackUnits;
      if (windowStart < 0) windowStart = 0;
      final ahead = _nextRef + resumeAheadUnits;
      if (ahead < windowEnd) windowEnd = ahead;
    } else if (_acquiring) {
      windowStart = 0;
      nearUnits = coldAcquireNearUnits;
    } else {
      windowStart = _nextRef;
    }
    final refWindow = range.units.sublist(windowStart, windowEnd);
    final run = _bestDiagonalRun(refWindow, _recentPred, nearUnits: nearUnits);
    if (run == null) return;

    final gRef = windowStart + run.refStart;
    final newNext = gRef + run.length;
    // لا تراجع: إرساء لا يتقدّم بالمؤشر لا معنى له (تكرار محتوى خلفي).
    if (!_acquiring && newNext <= _nextRef) return;
    // دليل متدرج بالمسافة: القفز ضمن نافذة الإرساء ([reanchorWindowUnits])
    // يكفيه الحد الأدنى [minReanchorMatches]، وكل نافذة إضافية تطلب مطابقة
    // إضافية — سلسلة قصيرة بعيدة توافق مصادفةً نصًّا قرآنيًّا متكررًا فلا
    // يُقفز إليها المؤشر (وإلا وُسمت كلمات صحيحة حذفًا وظهرت كلمات لاحقة
    // قبل سابقاتها)، بينما الانزلاق الحقيقي يولّد سلسلة طويلة من كلام
    // المستخدم الفعلي فتُقبل دومًا. أثناء الالتقاط لا حدّ — بداية
    // المستخدم قد تكون في أي موضع من النطاق.
    if (!_acquiring) {
      final jump = gRef - _nextRef;
      final extraWindows = jump > reanchorWindowUnits
          ? ((jump - reanchorWindowUnits) / reanchorWindowUnits).ceil()
          : 0;
      if (run.length < minReanchorMatches + extraWindows) return;
    }
    final wasAcquiring = _acquiring;
    if (!wasAcquiring) {
      // ما بين المتوقَّع والمرساة تخطّاه المستخدم فعليًا → حذف.
      _markDeletes(_nextRef, gRef);
    }
    for (var i = 0; i < run.length; i++) {
      final ref = range.units[gRef + i];
      final pred = _recentPred[run.predStart + i];
      if (ref.symbol != pred.symbol) {
        _markError(
          gRef + i,
          _classifyUnitDiff(ref, pred),
          expectedSymbol: ref.symbol,
          predictedSymbol: pred.symbol,
          errorType: 'replace',
        );
      }
    }
    if (wasAcquiring) {
      _acquiring = false;
      // نقطة بداية المقطع راسخية: أول إرساء في الجلسة يبقى البداية —
      // إعادة تسليح الالتقاط بعد شيت المصحّح توسّع نافذة التقييم ولا
      // تُزيح بدايتها (وإلا سقط ما قبل الإرساء الجديد من النتائج).
      _firstConsumedRefIdx = (_firstConsumedRefIdx >= 0)
          ? (_firstConsumedRefIdx < gRef ? _firstConsumedRefIdx : gRef)
          : gRef;
      // ابتلع بصمت ما قبل نقطة الإرساء — كلمات سلسلة الإرساء نفسها
      // تُلِي فعلًا وتُبلَّغ طبيعيًا عبر _reportCompleted.
      while (_doneCursor < range.wordSpans.length &&
          range.wordSpans[_doneCursor].endUnit < gRef) {
        _doneCursor++;
      }
    }
    _nextRef = newNext;
    _clearPending();
    _insertBuffer.clear();
    _reportCurrentWord();
  }

  /// يسجّل خطأ بنوعه وتفصيله على الكلمة التي تضم الوحدة المرجعية
  /// [unitIdx] (الأعلى أسبقية يبقى — ومعه تفصيله — عند تعدد الأخطاء).
  void _markError(
    int unitIdx,
    TasmeeErrorKind kind, {
    String? expectedSymbol,
    String? predictedSymbol,
    String errorType = 'delete',
  }) {
    final span = range.spanOfUnit(unitIdx);
    if (span == null) return;
    _wordMarkedUnitCounts[span] = (_wordMarkedUnitCounts[span] ?? 0) + 1;
    final prev = _wordKinds[span];
    if (prev == null || mergeTasmeeErrorKinds(prev, kind) != prev) {
      _wordKinds[span] =
          prev == null ? kind : mergeTasmeeErrorKinds(prev, kind);
      _wordMistakes[span] = TasmeeWordMistake(
        kind: _wordKinds[span]!,
        errorType: errorType,
        expectedSymbol: expectedSymbol,
        predictedSymbol: predictedSymbol,
        wrongUnits: _wordMarkedUnitCounts[span]!,
      );
    } else if (_wordMistakes[span] != null) {
      // عدّد الدليل ارتفع — حدّثه في التفصيل المعتمد نفسه.
      _wordMistakes[span] = TasmeeWordMistake(
        kind: _wordMistakes[span]!.kind,
        errorType: _wordMistakes[span]!.errorType,
        expectedSymbol: _wordMistakes[span]!.expectedSymbol,
        predictedSymbol: _wordMistakes[span]!.predictedSymbol,
        wrongUnits: _wordMarkedUnitCounts[span]!,
      );
    }
  }

  /// يبلّغ الكلمة الجارية عند تغيّرها — وقبلها اكتمال ما تجاوزه المؤشر:
  /// القفزات وإعادة الإرساء كانت تُبرز الكلمة الهابطة قبل وسم الكلمات
  /// المتخطاة، فتظهر في الواجهة كلمة متأخرة قبل كلمات تسبقها في التلاوة.
  void _reportCurrentWord() {
    _reportCompleted();
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
  /// مع نوع خطأها وتفصيله (correct وبلا تفصيل إن كانت سليمة).
  ///
  /// الكلمة الأخيرة من النطاق يكفيها تسامح [lastWordTailTolerance]
  /// على وحداتها الختامية — وحدة الختام كثيرًا ما تسقط من التعرّف.
  void _reportCompleted() {
    final onWordDone = this.onWordDone;
    final lastSpan = range.wordSpans.length - 1;
    while (_doneCursor < range.wordSpans.length) {
      final span = range.wordSpans[_doneCursor];
      final tailTolerance = _doneCursor == lastSpan ? lastWordTailTolerance : 0;
      if (span.endUnit >= _nextRef + tailTolerance) break;
      final kind = _wordKinds[span] ?? TasmeeErrorKind.correct;
      if (kind != TasmeeErrorKind.correct) {
        _debugLogMarkedWord(span, kind, _wordMistakes[span]);
      }
      onWordDone?.call(span.verseIdx, span.wordIdx, kind, _wordMistakes[span]);
      _doneCursor++;
    }
  }

  /// تشخيص (debug فقط): كل كلمة موسومة تُسجَّل بوحداتها المرجعية وآخر
  /// ما تنبَّأ به المحرك وسبب الوسم — لمعايرة العتبات من حالات تعثر
  /// حقيقية على الجهاز.
  void _debugLogMarkedWord(
    QuranRangeWordSpan span,
    TasmeeErrorKind kind,
    TasmeeWordMistake? mistake,
  ) {
    var debugMode = false;
    assert(() {
      debugMode = true;
      return true;
    }());
    if (!debugMode) return;
    final expected = range.units
        .sublist(span.startUnit, span.endUnit + 1)
        .map((u) => u.symbol)
        .join(' ');
    final recent = _recentPred.map((u) => u.symbol).join(' ');
    log(
      'MARKED v${span.verseIdx} w${span.wordIdx} kind=$kind '
      'type=${mistake?.errorType} expected=[$expected] '
      'expectedSym=${mistake?.expectedSymbol} gotSym=${mistake?.predictedSymbol} '
      'wrongUnits=${mistake?.wrongUnits} recentPred=[$recent] next=$_nextRef',
      name: 'RangeLiveTracker',
    );
  }

  /// يبلّغ اكتمال النطاق مرة واحدة فقط.
  void _fireComplete() {
    if (_completeFired || _doneCursor < range.wordSpans.length) return;
    _completeFired = true;
    onRangeComplete?.call();
  }
}
