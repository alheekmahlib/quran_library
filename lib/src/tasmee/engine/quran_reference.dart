/// المرجع الصوتي لِكلّ القرآن (6236 آية) بأبجدية Quran-Lab ‏(250 وحدة + blank).
///
/// المصدر: ordered_quran_phonemes.json.gz — لكل آية: aya_text، aya_phoneme،
/// aya_phonemes_list (الوحدات مقسومة كلمة كلمة).
library;

import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io';
import 'dart:typed_data';

import 'asset_loader.dart';

import 'quran_units.dart';

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
}

/// محمّل المرجع من asset أو ملف خارجي (gzip JSON) — تجزئة مؤجّلة لكل آية.
class QuranPhonemeReference {
  QuranPhonemeReference({required QuranUnitLexicon lexicon})
      : _lexicon = lexicon;

  static const defaultAssetPath =
      'assets/quran_lab/ordered_quran_phonemes.json.gz';

  final QuranUnitLexicon _lexicon;
  final Map<String, QuranReferenceVerse> _cache = {};
  Map<String, dynamic> _raw = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  int get verseCount => _raw.length;

  /// حمّل المرجع (gzip JSON) من ملف أو asset.
  Future<void> load({String? assetPath, String? filePath}) async {
    if (_loaded) return;
    final Uint8List gzBytes;
    if (filePath != null && File(filePath).existsSync()) {
      gzBytes = await File(filePath).readAsBytes();
    } else {
      gzBytes = await loadPackageAssetBytes(assetPath ?? defaultAssetPath);
    }
    _raw =
        jsonDecode(utf8.decode(gzip.decode(gzBytes))) as Map<String, dynamic>;
    _loaded = true;
    log('QuranPhonemeReference: loaded ${_raw.length} verses',
        name: 'QuranReference');
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
    final units = <QuranUnit>[];
    final unitWordIdx = <int>[];
    for (var w = 0; w < phonemeWords.length; w++) {
      final wordUnits = _lexicon.segment(phonemeWords[w]);
      if (wordUnits.isEmpty) {
        log('QuranPhonemeReference: segment failed for $key word $w',
            name: 'QuranReference', level: 900);
        return null;
      }
      units.addAll(wordUnits);
      unitWordIdx.addAll(List<int>.filled(wordUnits.length, w));
    }
    final verse = QuranReferenceVerse(
      verseKey: key,
      uthmani: m['aya_text'] as String,
      phonemeString: m['aya_phoneme'] as String,
      phonemeWords: phonemeWords,
      uthmaniWords: (m['aya_text'] as String).split(RegExp(r'\s+')),
      units: units,
      unitWordIdx: unitWordIdx,
    );
    _cache[key] = verse;
    return verse;
  }

  /// حرّر الذاكرة.
  void dispose() {
    _raw = {};
    _cache.clear();
    _loaded = false;
  }
}
