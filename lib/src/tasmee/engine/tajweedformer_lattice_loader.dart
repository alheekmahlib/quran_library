import 'tajweedformer_lattice.dart';
import 'tajweedformer_reference.dart';

/// Loads one experimental quran-p2g lattice only after comparing its canonical
/// token and word sequence to the active SDK reference for the same verse.
///
/// [displayWordMap] must be independently verified against the displayed
/// Mushaf. Matching the canonical path does not validate alternate forms,
/// variant dependencies, correction accuracy, or the source's provenance.
List<TajweedFormerLatticeWord> loadTajweedFormerLatticeVerse({
  required Map<String, dynamic> data,
  required int surah,
  required int ayah,
  required int verseIndex,
  required List<String> tokenNames,
  required int blankId,
  required int wordBarId,
  required Map<String, dynamic> sdkReference,
  required List<int> displayWordMap,
  required int displayWordCount,
}) {
  if (data['format'] != 'quran-library.tajweedformer-lattice.v1' ||
      data['source_revision'] != '233568a621d853da7969ed174ddff625ef9ace5e' ||
      verseIndex < 0 ||
      blankId < 0 ||
      wordBarId < 0 ||
      blankId >= tokenNames.length ||
      wordBarId >= tokenNames.length ||
      blankId == wordBarId ||
      tokenNames.toSet().length != tokenNames.length) {
    throw const FormatException('Unsupported V4 lattice or vocabulary');
  }
  final rawVerses = data['verses'];
  final rawWords = rawVerses is Map ? rawVerses['$surah:$ayah'] : null;
  if (rawWords is! List ||
      rawWords.isEmpty ||
      displayWordMap.length != rawWords.length ||
      displayWordCount < 1 ||
      displayWordMap.first != 0 ||
      displayWordMap.last != displayWordCount - 1) {
    throw const FormatException('Invalid V4 lattice word map');
  }
  for (var i = 1; i < displayWordMap.length; i++) {
    if (displayWordMap[i] < displayWordMap[i - 1] ||
        displayWordMap[i] > displayWordMap[i - 1] + 1) {
      throw const FormatException('Invalid V4 lattice word map');
    }
  }
  final sdk = TajweedFormerReferenceVerse.fromWebReference(
    surah: surah,
    ayah: ayah,
    reference: sdkReference,
    wordBarId: wordBarId,
    blankId: blankId,
    expectedWordCount: rawWords.length,
  );
  final canonical = <int>[];
  final words = <TajweedFormerLatticeWord>[];
  for (var i = 0; i < rawWords.length; i++) {
    final raw = rawWords[i];
    if (raw is! Map || raw['forms'] is! List || raw['canonical'] is! int) {
      throw const FormatException('Invalid V4 lattice word');
    }
    final rawForms = raw['forms'] as List;
    final canonicalIndex = raw['canonical'] as int;
    if (canonicalIndex < 0 || canonicalIndex >= rawForms.length) {
      throw const FormatException('Invalid canonical form');
    }
    final forms = <TajweedFormerLatticeForm>[];
    for (final form in rawForms) {
      if (form is! Map ||
          form['tokens'] is! List ||
          !['ibtida', 'wasl'].contains(form['left']) ||
          !['waqf', 'wasl'].contains(form['right']) ||
          !['plain', 'sukun', 'rawm', 'ishmam'].contains(form['mode']) ||
          (form['right'] == 'wasl') != (form['mode'] == 'plain') ||
          (form['variant'] != null && form['variant'] is! String)) {
        throw const FormatException('Invalid V4 lattice form');
      }
      final ids = <int>[];
      for (final token in form['tokens'] as List) {
        final id = token is String ? tokenNames.indexOf(token) : -1;
        if (id < 0 || id == blankId || id == wordBarId) {
          throw const FormatException('Unknown V4 lattice token');
        }
        ids.add(id);
      }
      if (ids.isEmpty) throw const FormatException('Empty V4 lattice form');
      forms.add(TajweedFormerLatticeForm(
        left: form['left'] == 'ibtida'
            ? TajweedFormerBoundary.stop
            : TajweedFormerBoundary.connected,
        right: form['right'] == 'waqf'
            ? TajweedFormerBoundary.stop
            : TajweedFormerBoundary.connected,
        tokens: ids,
        mode: form['mode'] as String,
        variant: form['variant'] as String?,
      ));
    }
    final selected = forms[canonicalIndex];
    if (selected.left !=
            (i == 0
                ? TajweedFormerBoundary.stop
                : TajweedFormerBoundary.connected) ||
        selected.right !=
            (i == rawWords.length - 1
                ? TajweedFormerBoundary.stop
                : TajweedFormerBoundary.connected) ||
        selected.mode != (i == rawWords.length - 1 ? 'sukun' : 'plain') ||
        selected.variant != null) {
      throw const FormatException('Invalid canonical boundary');
    }
    if (i > 0) canonical.add(wordBarId);
    canonical.addAll(selected.tokens);
    words.add(TajweedFormerLatticeWord(
      verseIndex: verseIndex,
      wordIndex: displayWordMap[i],
      forms: forms,
    ));
  }
  if (canonical.length != sdk.tokenIds.length) {
    throw const FormatException('Lattice does not match SDK reference');
  }
  for (var i = 0; i < canonical.length; i++) {
    if (canonical[i] != sdk.tokenIds[i]) {
      throw const FormatException('Lattice does not match SDK reference');
    }
  }
  return List.unmodifiable(words);
}
