/// مخزن المرجع الصوتي المشترك لِوحدة التسميع (web-safe).
///
/// يحمل المعجم (tokens) والمرجع الصوتي الكامل (858KB gz) مرة واحدة
/// ويشاركهما بين [TasmeeCtrl] (لبناء النطاقات) ومحرّك Zipformer
/// (لِلمحاذاة) — بدل تحميل نسختين في الذاكرة.
library;

import '../../engine/asset_loader.dart';
import '../../engine/platform_io.dart';
import '../../engine/quran_reference.dart';
import '../../engine/quran_units.dart';

/// مسار أصل المعجم داخل الحزمة.
const String kTasmeeTokensAssetPath = 'assets/quran_lab/tokens.txt';

class TasmeeReferenceStore {
  TasmeeReferenceStore._();

  static final TasmeeReferenceStore instance = TasmeeReferenceStore._();

  QuranUnitLexicon? _lexicon;
  QuranPhonemeReference? _reference;
  Future<void>? _loading;

  /// المعجم (أو null قبل [load]).
  QuranUnitLexicon? get lexicon => _lexicon;

  /// المرجع الصوتي (أو null قبل [load]).
  QuranPhonemeReference? get reference => _reference;

  bool get isLoaded => _reference?.isLoaded ?? false;

  /// حمّل المعجم والمرجع مرة واحدة (النداءات المتزامنة تتشارك التحميل).
  ///
  /// [tokensPath]/[filePath] مسارات ملفات خارجية بديلة (وإلا الأصول).
  Future<void> load({String? tokensPath, String? filePath}) {
    return _loading ??= _doLoad(tokensPath: tokensPath, filePath: filePath);
  }

  Future<void> _doLoad({String? tokensPath, String? filePath}) async {
    String tokensText;
    if (tokensPath != null && await PlatformIo.fileExists(tokensPath)) {
      tokensText = String.fromCharCodes(await PlatformIo.readFile(tokensPath));
    } else {
      tokensText = await loadPackageAssetString(kTasmeeTokensAssetPath);
    }
    final lex = QuranUnitLexicon.fromTokensText(tokensText);
    final ref = QuranPhonemeReference(lexicon: lex);
    await ref.load(filePath: filePath);
    _lexicon = lex;
    _reference = ref;
  }

  /// يبني نطاقاً مرجعياً متعدد الآيات (أو null إن لم يُحمَّل المرجع).
  QuranReferenceRange? buildRange(List<({int suraIdx, int ayaIdx})> verseKeys) {
    return _reference?.getRange(verseKeys);
  }
}
