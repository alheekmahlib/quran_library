/// المرجع الصوتي لِكلّ القرآن (6236 آية) بأبجدية Quran-Lab ‏(250 وحدة + blank).
///
/// المصدر: ordered_quran_phonemes.json.gz — لكل آية: aya_text، aya_phoneme،
/// aya_phonemes_list (الوحدات مقسومة كلمة كلمة).
library;

import 'dart:convert';
import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:archive/archive.dart' show GZipDecoder;

import 'asset_loader.dart';
import 'platform_io.dart';

import 'quran_units.dart';

// إسناد الوحدات إلى الكلمات العثمانية — منطق نقي في ملف مستقل ليُستخدم
// أيضًا من سكربت التوليد المسبق خارج Flutter (tool/generate_unit_word_map).
export 'quran_word_mapping.dart';
import 'quran_word_mapping.dart';

/// بيانات مرجعية لِآية واحدة، مُقطَّعة إلى وحدات جاهزة لِلمحاذاة.
class QuranReferenceVerse {
  const QuranReferenceVerse({
    required this.verseKey,
    required this.uthmani,
    required this.phonemeString,
    required this.phonemeWords,
    required this.uthmaniWords,
    required this.units,
    required this.unitWordIdx,
  });

  final String verseKey;

  /// النص العثماني للآية.
  final String uthmani;

  /// سلسلة الوحدات كاملة (بمسافات الكلمات).
  final String phonemeString;

  /// كلمات الفونيمات (aya_phonemes_list).
  final List<String> phonemeWords;

  /// كلمات النص العثماني.
  final List<String> uthmaniWords;

  /// وحدات الآية كاملة (بالترتيب).
  final List<QuranUnit> units;

  /// فهرس كلمة كل وحدة (نفس طول units).
  final List<int> unitWordIdx;

  /// الكلمة العثمانية لِلوحدة رقم i (أو null إن غابت).
  String? wordAt(int unitIdx) {
    if (unitIdx < 0 || unitIdx >= unitWordIdx.length) return null;
    final w = unitWordIdx[unitIdx];
    if (w < 0 || w >= uthmaniWords.length) return null;
    return uthmaniWords[w];
  }

  /// حدود الكلمة التي تضم وحدة ما داخل الآية (بفهارس وحدات الآية) —
  /// لِلكشف عن إعادة كلمة كاملة في كاشف الأخطاء.
  QuranRangeWordSpan? spanOfUnit(int unitIdx) {
    if (unitIdx < 0 || unitIdx >= units.length) return null;
    final w = unitWordIdx[unitIdx];
    if (w < 0) return null;
    var first = unitIdx;
    while (first > 0 && unitWordIdx[first - 1] == w) {
      first--;
    }
    var last = unitIdx;
    while (last < units.length - 1 && unitWordIdx[last + 1] == w) {
      last++;
    }
    return QuranRangeWordSpan(
      verseIdx: 0,
      wordIdx: w,
      startUnit: first,
      endUnit: last,
    );
  }
}

/// حدود كلمة واحدة داخل [QuranReferenceRange] (بوحدات النطاق المفلطحة).
class QuranRangeWordSpan {
  const QuranRangeWordSpan({
    required this.verseIdx,
    required this.wordIdx,
    required this.startUnit,
    required this.endUnit,
  });

  /// فهرس الآية داخل النطاق (0-based).
  final int verseIdx;

  /// فهرس الكلمة داخل آيتها (0-based).
  final int wordIdx;

  /// فهرس أول وحدة للكلمة في الوحدات المتراكمة (شامل).
  final int startUnit;

  /// فهرس آخر وحدة للكلمة في الوحدات المتراكمة (شامل).
  final int endUnit;
}

/// نطاق مرجعي متعدد الآيات (صفحة كاملة مثلاً) — وحدات متراكبة بترتيب التلاوة.
///
/// يُبنى عبر [QuranPhonemeReference.getRange] ويُستخدم لمحاذاة تلاوة تمتد
/// على عدة آيات (وضع الصفحة في التسميع).
class QuranReferenceRange {
  const QuranReferenceRange._({
    required this.verses,
    required this.units,
    required this.unitVerseIdx,
    required this.unitWordIdx,
    required this.wordSpans,
    required List<int> unitSpanIdx,
  }) : _unitSpanIdx = unitSpanIdx;

  /// الآيات المرتبة بترتيب التلاوة.
  final List<QuranReferenceVerse> verses;

  /// الوحدات المتراكبة (آية بعد آية).
  final List<QuranUnit> units;

  /// فهرس آية كل وحدة (0-based داخل [verses]).
  final List<int> unitVerseIdx;

  /// فهرس كلمة كل وحدة داخل آيتها (0-based).
  final List<int> unitWordIdx;

  /// حدود الكلمات مفلطحة بترتيب التلاوة (الكلمات بلا وحدات تُستثنى).
  final List<QuranRangeWordSpan> wordSpans;

  /// فهرس الكلمة (داخل wordSpans) لكل وحدة — بحث O(1).
  final List<int> _unitSpanIdx;

  /// إجمالي الكلمات المتتبَّعة في النطاق.
  int get wordCount => wordSpans.length;

  /// النص العثماني الكامل للنطاق (آيات مفصولة بفراغ).
  String get uthmani => verses.map((v) => v.uthmani).join(' ');

  /// سلسلة الفونيمات المرجعية الكاملة.
  String get phonemeString => verses.map((v) => v.phonemeString).join(' ');

  /// الكلمة العثمانية لوحدة ما (بفهرسها العالمي في النطاق)، أو null.
  String? wordAt(int unitIdx) {
    if (unitIdx < 0 || unitIdx >= units.length) return null;
    final verse = verses[unitVerseIdx[unitIdx]];
    final w = unitWordIdx[unitIdx];
    if (w < 0 || w >= verse.uthmaniWords.length) return null;
    return verse.uthmaniWords[w];
  }

  /// فهرس الكلمة (داخل wordSpans) لوحدة ما (0-based)، أو -1 — O(1)
  /// لقياس مسافة الكلمات بين موضعين.
  int spanIndexAt(int unitIdx) {
    if (unitIdx < 0 || unitIdx >= units.length) return -1;
    return _unitSpanIdx[unitIdx];
  }

  /// حدود الكلمة التي تضم وحدة ما (بفهرسها العالمي)، أو null.
  QuranRangeWordSpan? spanOfUnit(int unitIdx) {
    if (unitIdx < 0 || unitIdx >= units.length) return null;
    final s = _unitSpanIdx[unitIdx];
    if (s < 0 || s >= wordSpans.length) return null;
    return wordSpans[s];
  }

  /// عدد وحدات كلمة داخل النطاق، أو 0 إن لم تكن لها وحدات — لِلقبول
  /// النسبي لإعادة النطق بالسياق (الحكم على وحدات المستهدفة وحدها).
  int wordUnitCount(int wordIdx) {
    for (final s in wordSpans) {
      if (s.wordIdx == wordIdx) return s.endUnit - s.startUnit + 1;
    }
    return 0;
  }

  /// مفتاح آية (سورة/آية 1-based) من فهرسها داخل النطاق.
  ({int suraIdx, int ayaIdx}) keyOfVerse(int verseIdx) {
    final parts = verses[verseIdx].verseKey.split(':');
    return (
      suraIdx: int.tryParse(parts.first) ?? 1,
      ayaIdx: parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1,
    );
  }

  /// يبني نطاقًا من وحدات كلمة واحدة داخل آيتها — لِلتحقق المصغّر من
  /// نطق كلمة (نمط المصحح). يعيد null إن لم تكن للكلمة وحدات في المرجع.
  ///
  /// [units] هنا وحدات الكلمة وحدها (لا الآية كلها) فتُحاذى التلاوة
  /// عليها منفردة.
  static QuranReferenceRange? fromSingleWord(
    QuranReferenceVerse verse,
    int wordIdx,
  ) {
    final units = <QuranUnit>[];
    for (var u = 0; u < verse.units.length; u++) {
      if (verse.unitWordIdx[u] == wordIdx) units.add(verse.units[u]);
    }
    if (units.isEmpty) return null;
    return QuranReferenceRange._(
      verses: [verse],
      units: units,
      unitVerseIdx: List<int>.filled(units.length, 0),
      unitWordIdx: List<int>.filled(units.length, wordIdx),
      wordSpans: [
        QuranRangeWordSpan(
          verseIdx: 0,
          wordIdx: wordIdx,
          startUnit: 0,
          endUnit: units.length - 1,
        ),
      ],
      unitSpanIdx: List<int>.filled(units.length, 0),
    );
  }

  /// يبني نطاق تحقّق إعادة نطق كلمة **بسياقها**: وحدات الكلمة السابقة
  /// والمستهدفة معًا — إعادة النطق المنفردة تقف على الكلمة (تُسقط نون
  /// التنوين، وتُقرأ همزة الوصل، ولا يُدغم) بينما المرجع متصل الوصل،
  /// فتخفق المحاذاة الصارمة مهما أُعيدت. قراءة السابقة مع المستهدفة
  /// تعيد الوصل والإدغام والتنوين إلى حالها كما في التلاوة الحقيقية،
  /// والحكم يبقى على وحدات الكلمة المستهدفة وحدها (انظر
  /// [targetWordUnitCount]).
  ///
  /// يعيد null إن لم تكن للمستهدفة وحدات في المرجع.
  static QuranReferenceRange? fromWordWithContext(
    QuranReferenceVerse verse,
    int wordIdx,
  ) {
    final firstWord = wordIdx > 0 ? wordIdx - 1 : wordIdx;
    final units = <QuranUnit>[];
    final unitWordIdx = <int>[];
    final spans = <QuranRangeWordSpan>[];
    var targetHasUnits = false;
    for (var w = firstWord; w <= wordIdx; w++) {
      var first = -1;
      var last = -1;
      for (var u = 0; u < verse.units.length; u++) {
        if (verse.unitWordIdx[u] != w) continue;
        if (first < 0) first = units.length;
        last = units.length;
        units.add(verse.units[u]);
        unitWordIdx.add(w);
      }
      if (first < 0) continue; // كلمة بلا وحدات (مدموجة كليًا).
      if (w == wordIdx) targetHasUnits = true;
      spans.add(QuranRangeWordSpan(
        verseIdx: 0,
        wordIdx: w,
        startUnit: first,
        endUnit: last,
      ));
    }
    if (!targetHasUnits) return null;
    final unitSpanIdx = List<int>.filled(units.length, -1);
    for (var s = 0; s < spans.length; s++) {
      for (var u = spans[s].startUnit; u <= spans[s].endUnit; u++) {
        unitSpanIdx[u] = s;
      }
    }
    return QuranReferenceRange._(
      verses: [verse],
      units: units,
      unitVerseIdx: List<int>.filled(units.length, 0),
      unitWordIdx: unitWordIdx,
      wordSpans: spans,
      unitSpanIdx: unitSpanIdx,
    );
  }

  /// يبني النطاق من آيات مرتبة (تراكب الوحدات + خرائط الكلمات).
  ///
  /// الكلمة التي لا وحدات لها في المرجع تُستثنى من التتبّع الحيّ.
  static QuranReferenceRange? fromVerses(List<QuranReferenceVerse> verses) {
    if (verses.isEmpty) return null;
    final units = <QuranUnit>[];
    final unitVerseIdx = <int>[];
    final unitWordIdx = <int>[];
    final verseUnitStart = List<int>.filled(verses.length, 0);
    for (var v = 0; v < verses.length; v++) {
      verseUnitStart[v] = units.length;
      final verse = verses[v];
      for (var u = 0; u < verse.units.length; u++) {
        units.add(verse.units[u]);
        unitVerseIdx.add(v);
        unitWordIdx.add(verse.unitWordIdx[u]);
      }
    }

    final spans = <QuranRangeWordSpan>[];
    final unitSpanIdx = List<int>.filled(units.length, -1);
    for (var v = 0; v < verses.length; v++) {
      final verse = verses[v];
      final start = verseUnitStart[v];
      for (var w = 0; w < verse.uthmaniWords.length; w++) {
        var first = -1;
        var last = -1;
        for (var u = 0; u < verse.units.length; u++) {
          if (verse.unitWordIdx[u] != w) continue;
          if (first < 0) first = start + u;
          last = start + u;
        }
        if (first < 0) continue; // كلمة بلا وحدات.
        final spanIdx = spans.length;
        for (var u = first; u <= last; u++) {
          unitSpanIdx[u] = spanIdx;
        }
        spans.add(QuranRangeWordSpan(
          verseIdx: v,
          wordIdx: w,
          startUnit: first,
          endUnit: last,
        ));
      }
    }
    return QuranReferenceRange._(
      verses: verses,
      units: units,
      unitVerseIdx: unitVerseIdx,
      unitWordIdx: unitWordIdx,
      wordSpans: spans,
      unitSpanIdx: unitSpanIdx,
    );
  }
}

/// محمّل المرجع من asset أو ملف خارجي (gzip JSON) — تجزئة مؤجّلة لكل آية.
class QuranPhonemeReference {
  QuranPhonemeReference({required QuranUnitLexicon lexicon})
      : _lexicon = lexicon;

  static const defaultAssetPath =
      'assets/quran_lab/ordered_quran_phonemes.json.gz';

  /// أصل إسناد الوحدات إلى الكلمات العثمانية المولَّد مسبقًا — يُنتج بـ
  /// `dart run tool/generate_unit_word_map.dart` (نفس منطق
  /// [mapUnitsToUthmaniWords]) فيوفّر حساب المحاذاة وقت التشغيل ويثبّت
  /// النتيجة للمراجعة. اختياري: غيابه يُسقط للمسارات الحية.
  static const defaultUnitWordMapAssetPath =
      'assets/quran_lab/unit_word_map.json.gz';

  final QuranUnitLexicon _lexicon;
  final Map<String, QuranReferenceVerse> _cache = {};
  final Map<String, List<int>> _unitWordMap = {};
  Map<String, dynamic> _raw = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  int get verseCount => _raw.length;

  /// حمّل المرجع (gzip JSON) من ملف أو asset.
  ///
  /// خريطة الإسناد المولدة اختيارية: تُقرأ من [unitWordMapFilePath] إن
  /// أعطي، وإلا من الأصل الافتراضي إن وُجد — وأي غياب يُتجاهل (المسارات
  /// الحية في [mapUnitsToUthmaniWords] تكفي).
  Future<void> load({
    String? assetPath,
    String? filePath,
    String? unitWordMapFilePath,
  }) async {
    if (_loaded) return;
    final Uint8List gzBytes;
    if (filePath != null && await PlatformIo.fileExists(filePath)) {
      gzBytes = await PlatformIo.readFile(filePath);
    } else {
      gzBytes = await loadPackageAssetBytes(assetPath ?? defaultAssetPath);
    }
    // فك gzip بِـ archive (صافي Dart — يعمل على الويب أيضاً).
    _raw = jsonDecode(utf8.decode(const GZipDecoder().decodeBytes(gzBytes)))
        as Map<String, dynamic>;
    _loaded = true;
    log('QuranPhonemeReference: loaded ${_raw.length} verses',
        name: 'QuranReference');
    await _tryLoadUnitWordMap(unitWordMapFilePath);
  }

  Future<void> _tryLoadUnitWordMap(String? filePath) async {
    try {
      final Uint8List mapBytes;
      if (filePath != null && await PlatformIo.fileExists(filePath)) {
        mapBytes = await PlatformIo.readFile(filePath);
      } else {
        mapBytes = await loadPackageAssetBytes(defaultUnitWordMapAssetPath);
      }
      final decoded = jsonDecode(utf8.decode(
        const GZipDecoder().decodeBytes(mapBytes),
      )) as Map<String, dynamic>;
      _unitWordMap
        ..clear()
        ..addAll(decoded.map((k, v) => MapEntry(k, (v as List).cast<int>())));
      log(
          'QuranPhonemeReference: unit word map loaded (${_unitWordMap.length}'
          ' verses)',
          name: 'QuranReference');
    } catch (_) {
      // الأصل اختياري — المسارات الحية تكفي عند غيابه.
      log('QuranPhonemeReference: unit word map absent — computing live',
          name: 'QuranReference');
    }
  }

  /// ابحث عن آية (sura/aya 1-based) — تُقطَّع الوحدات مرّة واحدة وتُخزَّن.
  QuranReferenceVerse? getReference(
      {required int suraIdx, required int ayaIdx}) {
    final key = '$suraIdx:$ayaIdx';
    final cached = _cache[key];
    if (cached != null) return cached;
    final raw = _raw[key];
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final phonemeWords = (m['aya_phonemes_list'] as List).cast<String>();
    final uthmaniWords =
        ((m['aya_text'] as String).trim()).split(RegExp(r'\s+'));
    final units = <QuranUnit>[];
    final phonemeIdx = <int>[];
    for (var w = 0; w < phonemeWords.length; w++) {
      final wordUnits = _lexicon.segment(phonemeWords[w]);
      if (wordUnits.isEmpty) {
        log('QuranPhonemeReference: segment failed for $key word $w',
            name: 'QuranReference', level: 900);
        return null;
      }
      units.addAll(wordUnits);
      phonemeIdx.addAll(List<int>.filled(wordUnits.length, w));
    }
    // الخريطة المولدة مسبقًا تُقدَّم إن طابقت طول الوحدات — وإلا المسارات
    // الحية (تطابق عدد/مشي أوزان/محاذاة DP).
    final preset = _unitWordMap[key];
    final unitWordIdx = preset != null && preset.length == units.length
        ? preset
        : mapUnitsToUthmaniWords(
            units: units,
            phonemeIdx: phonemeIdx,
            uthmaniWords: uthmaniWords,
          );
    final verse = QuranReferenceVerse(
      verseKey: key,
      uthmani: m['aya_text'] as String,
      phonemeString: m['aya_phoneme'] as String,
      phonemeWords: phonemeWords,
      uthmaniWords: uthmaniWords,
      units: units,
      unitWordIdx: unitWordIdx,
    );
    _cache[key] = verse;
    return verse;
  }

  /// يبني نطاقاً مرجعياً متعدد الآيات (صفحة كاملة) بترتيب المفاتيح المعطاة.
  ///
  /// يُعيد null إن لم يُحمَّل المرجع أو غابت أي آية منه أو فشل التقطيع.
  QuranReferenceRange? getRange(List<({int suraIdx, int ayaIdx})> verseKeys) {
    if (!_loaded || verseKeys.isEmpty) return null;
    final verses = <QuranReferenceVerse>[];
    for (final k in verseKeys) {
      final v = getReference(suraIdx: k.suraIdx, ayaIdx: k.ayaIdx);
      if (v == null) return null;
      verses.add(v);
    }
    return QuranReferenceRange.fromVerses(verses);
  }

  /// حرّر الذاكرة.
  void dispose() {
    _raw = {};
    _cache.clear();
    _loaded = false;
  }
}
