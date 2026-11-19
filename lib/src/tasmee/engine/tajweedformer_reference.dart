/// Model-specific reference data for TajweedFormer V4.
///
/// V4 token IDs must only be compared with reference data from the same model
/// vocabulary. They are not compatible with the Zipformer phoneme alphabet.
library;

/// One expected sound and its position in a requested range of verses.
class TajweedFormerReferenceUnit {
  const TajweedFormerReferenceUnit({
    required this.tokenId,
    required this.verseIndex,
    required this.wordIndex,
  });

  final int tokenId;
  final int verseIndex;
  final int wordIndex;
}

/// The V4 SDK's word-separated token IDs for a single verse.
class TajweedFormerReferenceVerse {
  TajweedFormerReferenceVerse({
    required this.surah,
    required this.ayah,
    required Iterable<int> tokenIds,
  }) : tokenIds = List.unmodifiable(tokenIds) {
    if (surah < 1 || surah > 114 || ayah < 1) {
      throw ArgumentError('Invalid Quran verse: $surah:$ayah');
    }
  }

  final int surah;
  final int ayah;
  final List<int> tokenIds;

  /// Parses the web SDK's `reference.units()` result and checks its word map.
  /// The SDK assigns each word-bar token to the word before that bar.
  factory TajweedFormerReferenceVerse.fromWebReference({
    required int surah,
    required int ayah,
    required Map<String, dynamic> reference,
    required int wordBarId,
    required int blankId,
    int? expectedWordCount,
  }) {
    final rawUnits = reference['units'];
    final rawWords = reference['words'];
    final wordCount = reference['wordCount'];
    if (rawUnits is! List ||
        rawWords is! List ||
        wordCount is! int ||
        rawUnits.length != rawWords.length ||
        wordCount < 1 ||
        rawUnits.any((value) => value is! int) ||
        rawWords.any((value) => value is! int)) {
      throw const FormatException('Invalid V4 reference data');
    }
    final tokenIds = rawUnits.cast<int>();
    var wordIndex = 0;
    for (var i = 0; i < tokenIds.length; i++) {
      if (rawWords[i] != wordIndex) {
        throw const FormatException('Invalid V4 reference word mapping');
      }
      if (tokenIds[i] == wordBarId) wordIndex++;
    }
    if (wordCount != wordIndex + 1 ||
        (expectedWordCount != null && expectedWordCount != wordCount)) {
      throw const FormatException('V4 reference word count mismatch');
    }
    final verse = TajweedFormerReferenceVerse(
      surah: surah,
      ayah: ayah,
      tokenIds: tokenIds,
    );
    // Reuse the shared checks for empty words, blank IDs and special tokens.
    buildTajweedFormerReference(
      verses: [verse],
      wordBarId: wordBarId,
      blankId: blankId,
      expectedWordCounts: [wordCount],
    );
    return verse;
  }
}

/// Flattens the SDK reference while retaining its word and verse positions.
///
/// The reference and the model must have matching token vocabulary hashes;
/// verify this against the SDK's signed model metadata before calling this.
/// Empty words, including those produced by consecutive word bars, are rejected
/// rather than silently shifting the positions used by the Mushaf UI.
/// When provided, [expectedWordCounts] verifies each verse against the words
/// rendered by the host before any reference positions are used in the UI.
/// [displayWordMaps] optionally maps each SDK word to a displayed word. Some
/// references split a displayed word into several pronunciation units. Each
/// supplied map must come from a verified source for the same displayed text;
/// it may merge adjacent SDK words but cannot skip or reorder displayed words.
List<TajweedFormerReferenceUnit> buildTajweedFormerReference({
  required List<TajweedFormerReferenceVerse> verses,
  required int wordBarId,
  required int blankId,
  List<int>? expectedWordCounts,
  List<List<int>?>? displayWordMaps,
}) {
  if (wordBarId == blankId || wordBarId < 0 || blankId < 0) {
    throw ArgumentError('Invalid V4 special token IDs');
  }
  if (expectedWordCounts != null &&
      expectedWordCounts.length != verses.length) {
    throw ArgumentError('Expected word counts must match the verse count');
  }
  if (displayWordMaps != null && displayWordMaps.length != verses.length) {
    throw ArgumentError('Display word maps must match the verse count');
  }
  final units = <TajweedFormerReferenceUnit>[];
  for (var verseIndex = 0; verseIndex < verses.length; verseIndex++) {
    final tokens = verses[verseIndex].tokenIds;
    if (tokens.isEmpty ||
        tokens.first == wordBarId ||
        tokens.last == wordBarId) {
      throw FormatException('Empty word in V4 reference verse $verseIndex');
    }
    var wordIndex = 0;
    var previousWasBar = false;
    final pending = <(int, int)>[];
    for (final token in tokens) {
      if (token < 0 || token == blankId) {
        throw FormatException('Invalid token $token in V4 reference');
      }
      if (token == wordBarId) {
        if (previousWasBar) {
          throw FormatException('Empty word in V4 reference verse $verseIndex');
        }
        wordIndex++;
        previousWasBar = true;
      } else {
        pending.add((token, wordIndex));
        previousWasBar = false;
      }
    }
    final map = displayWordMaps?[verseIndex];
    if (map != null &&
        (map.length != wordIndex + 1 ||
            map.first != 0 ||
            List.generate(map.length - 1, (i) => i + 1)
                .any((i) => map[i] < map[i - 1] || map[i] > map[i - 1] + 1))) {
      throw FormatException('Invalid displayed word map for verse $verseIndex');
    }
    final displayCount = map == null ? wordIndex + 1 : map.last + 1;
    if (expectedWordCounts != null &&
        expectedWordCounts[verseIndex] != displayCount) {
      throw FormatException(
          'Word count mismatch in V4 reference verse $verseIndex');
    }
    for (final (token, referenceWord) in pending) {
      units.add(TajweedFormerReferenceUnit(
        tokenId: token,
        verseIndex: verseIndex,
        wordIndex: map == null ? referenceWord : map[referenceWord],
      ));
    }
  }
  return List.unmodifiable(units);
}
