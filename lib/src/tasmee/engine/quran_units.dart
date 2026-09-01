/// معجم وحدات الأبجدية الصوتية القرآنية (251 رمزًا) — نموذج Quran-Lab zipformer.
///
/// كل رمز = حرف واحد بحالته: الشدة تكرار الحرف، المدّ تكرار حرف المدّ،
/// القلقلة `ڇ`، الإخفاء `ۜ`، الغنّة `ننن/ممم/ں`، والسكوت `ؙ`.
///
/// القراءة من tokens.txt حصرًا (معرّفات phoneme_units.json مزاحة +1
/// عن طبقة CTC — لا تُستخدم في التفكيك).
library;

/// حروف المدّ (الكبيرة والصغيرة ۥ/ۦ).
const Set<String> kMaddLetters = {'ا', 'و', 'ي', 'ۥ', 'ۦ'};

/// الحركات القصيرة.
const Set<String> kHarakat = {'َ', 'ُ', 'ِ'};

/// علامات لاحقة تُنزع قبل عدّ تكرار الحرف الأساسي.
const Set<String> kTrailingMarks = {'َ', 'ُ', 'ِ', '۪', 'ۜ', 'ڇ', 'ؙ'};

/// رمز السكوت/الفاصل الذي يخرجه النموذج.
const String kSilenceSymbol = 'ؙ';

/// وحدة صوتية واحدة من الأبجدية (حرف بحالته).
class QuranUnit {
  const QuranUnit({
    required this.symbol,
    required this.id,
    required this.letter,
    required this.coreRepeat,
    this.haraka,
    this.isMadd = false,
    this.isShadda = false,
    this.isHarakaOnly = false,
    this.isSilence = false,
    this.qalqalah = false,
    this.ghunna = false,
    this.ikhfaa = false,
  });

  /// الرمز كما في tokens.txt (مثل `ببَ`).
  final String symbol;

  /// المعرّف في tokens.txt (يطابق طبقة CTC).
  final int id;

  /// الحرف الأساسي (مُطبَّع: `ٲ`→`ا`، `ں/۾`→`ن`).
  final String letter;

  /// عدد تكرار الحرف الأساسي بعد نزع اللاحقات.
  final int coreRepeat;

  /// الحركة اللاحقة إن وُجدت.
  final String? haraka;

  /// حرف مدّ مكرر (ا/و/ي/ۥ/ۦ × 2+).
  final bool isMadd;

  /// حرف ساكن مكرر (شدة).
  final bool isShadda;

  /// حركة مفردة مستقلة (خارج كلمة).
  final bool isHarakaOnly;

  /// فاصل السكوت `ؙ`.
  final bool isSilence;

  final bool qalqalah;
  final bool ghunna;
  final bool ikhfaa;

  /// طول المدّ بحركات (إن كان مدًّا).
  int? get maddLength => isMadd ? coreRepeat : null;

  /// ضوضاء إقحام شائعة في مخرجات CTC — لا تُعد خطأ تلاوة.
  bool get isNoiseInsert =>
      isSilence ||
      isHarakaOnly ||
      symbol == 'ء' ||
      symbol == 'ـ' ||
      symbol == 'ــ' ||
      symbol == '۾';

  /// يبني الوحدة بتحليل شكل الرمز (القواعد ذاتية التفسير).
  factory QuranUnit.parse(String symbol, int id) {
    if (symbol == kSilenceSymbol) {
      return QuranUnit(
        symbol: symbol,
        id: id,
        letter: symbol,
        coreRepeat: 1,
        isSilence: true,
      );
    }
    if (kHarakat.contains(symbol)) {
      return QuranUnit(
        symbol: symbol,
        id: id,
        letter: symbol,
        coreRepeat: 1,
        isHarakaOnly: true,
      );
    }

    var core = symbol;
    String? haraka;
    if (core.length > 1 && kHarakat.contains(core[core.length - 1])) {
      haraka = core[core.length - 1];
      core = core.substring(0, core.length - 1);
    }
    final qalqalah = core.contains('ڇ');
    final ikhfaa = core.contains('ۜ');
    // الغنّة: علامة صريحة، أو نون/ميم مكررة 3+ (ننن/ممم = شدة+غنّة).
    final ghunna = core.contains('ؙ') ||
        core.contains('ں') ||
        core.contains('۾') ||
        (core.length >= 3 && (core[0] == 'ن' || core[0] == 'م'));
    for (final m in kTrailingMarks) {
      core = core.replaceAll(m, '');
    }

    // مطبَّع الحرف الأساسي — لمحاذاة المتغيرات مع نظيراتها.
    if (core == 'ٲ') core = 'اا'; // ألف بمدّة = مدّ ألف.
    String letter;
    if (core.isEmpty) {
      letter = symbol.contains('ں') || symbol.contains('۾') ? 'ن' : symbol[0];
    } else {
      letter = core[0];
    }
    // نون الغنّة غير المنقوطة (ں/۾) تُحاذى مع النون الصريحة.
    if (letter == 'ں' || letter == '۾') letter = 'ن';
    final repeat = core.isEmpty ? symbol.length : core.length;

    final isMadd = kMaddLetters.contains(letter) && repeat >= 2;
    final isShadda = !kMaddLetters.contains(letter) && repeat >= 2;

    return QuranUnit(
      symbol: symbol,
      id: id,
      letter: letter,
      coreRepeat: repeat,
      haraka: haraka,
      isMadd: isMadd,
      isShadda: isShadda,
      qalqalah: qalqalah,
      ghunna: ghunna,
      ikhfaa: ikhfaa,
    );
  }

  @override
  String toString() => symbol;
}

/// معجم الوحدات + مُقطِّع أطول-مطابقة.
class QuranUnitLexicon {
  QuranUnitLexicon._(this.bySymbol, this._sorted);

  /// symbol → وحدة (بدون `<blank>`).
  final Map<String, QuranUnit> bySymbol;

  /// الوحدات مرتبة تنازليًا بطول الرمز (لِلمطابقة الأطول أولًا).
  final List<QuranUnit> _sorted;

  /// يقرأ نص tokens.txt (سطر لكل رمز: `symbol id`).
  factory QuranUnitLexicon.fromTokensText(String text) {
    final bySymbol = <String, QuranUnit>{};
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final i = t.lastIndexOf(' ');
      if (i <= 0) continue;
      final symbol = t.substring(0, i);
      final id = int.tryParse(t.substring(i + 1));
      if (id == null || symbol == '<blank>') continue;
      bySymbol[symbol] = QuranUnit.parse(symbol, id);
    }
    final sorted = bySymbol.values.toList()
      ..sort((a, b) => b.symbol.length.compareTo(a.symbol.length));
    return QuranUnitLexicon._(bySymbol, sorted);
  }

  /// يقطّع سلسلة فونيمات (مسافات الكلمات تُتخطى) إلى وحدات بأطول مطابقة.
  ///
  /// يُعيد `[]` إن تعذّر التقطيع الكامل (رمز غير معروف).
  List<QuranUnit> segment(String phonemeString) {
    final s = phonemeString.replaceAll(' ', '');
    final out = <QuranUnit>[];
    var i = 0;
    while (i < s.length) {
      QuranUnit? hit;
      for (final u in _sorted) {
        if (u.symbol.length <= s.length - i && s.startsWith(u.symbol, i)) {
          hit = u;
          break;
        }
      }
      if (hit == null) return const [];
      out.add(hit);
      i += hit.symbol.length;
    }
    return out;
  }

  /// هل تُقطَّع السلسلة كاملة؟ (فحص سريع)
  bool segmentsFully(String s) => segment(s).isNotEmpty;
}
