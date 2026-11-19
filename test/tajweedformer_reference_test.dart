import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference.dart';

void main() {
  TajweedFormerReferenceVerse verse(int surah, int ayah, List<int> tokens) =>
      TajweedFormerReferenceVerse(surah: surah, ayah: ayah, tokenIds: tokens);

  test('retains verse and word positions across a range', () {
    final result = buildTajweedFormerReference(
      verses: [
        verse(1, 1, [2, 3, 1, 4]),
        verse(1, 2, [5, 1, 6, 7])
      ],
      wordBarId: 1,
      blankId: 0,
    );
    expect(result.map((u) => (u.tokenId, u.verseIndex, u.wordIndex)), [
      (2, 0, 0),
      (3, 0, 0),
      (4, 0, 1),
      (5, 1, 0),
      (6, 1, 1),
      (7, 1, 1),
    ]);
  });

  test('rejects malformed reference instead of shifting word positions', () {
    for (final tokens in <List<int>>[
      [],
      [1, 2],
      [2, 1],
      [2, 1, 1, 3],
      [2, 0, 3],
      [2, -1]
    ]) {
      expect(
        () => buildTajweedFormerReference(
          verses: [verse(1, 1, tokens)],
          wordBarId: 1,
          blankId: 0,
        ),
        throwsFormatException,
      );
    }
  });

  test('copies and protects the input tokens', () {
    final tokens = [2, 1, 3];
    final input = verse(1, 1, tokens);
    tokens.clear();
    expect(input.tokenIds, [2, 1, 3]);
    expect(() => input.tokenIds.clear(), throwsUnsupportedError);
  });

  test('rejects invalid special IDs and verse keys', () {
    expect(() => verse(0, 1, [2]), throwsArgumentError);
    expect(() => verse(1, 0, [2]), throwsArgumentError);
    expect(
      () => buildTajweedFormerReference(verses: [], wordBarId: 0, blankId: 0),
      throwsArgumentError,
    );
  });

  test('checks word counts against the displayed verses when provided', () {
    final verses = [
      verse(1, 1, [2, 1, 3])
    ];
    expect(
      () => buildTajweedFormerReference(
        verses: verses,
        wordBarId: 1,
        blankId: 0,
        expectedWordCounts: [1],
      ),
      throwsFormatException,
    );
    expect(
      () => buildTajweedFormerReference(
        verses: verses,
        wordBarId: 1,
        blankId: 0,
        expectedWordCounts: [],
      ),
      throwsArgumentError,
    );
    expect(
      buildTajweedFormerReference(
        verses: verses,
        wordBarId: 1,
        blankId: 0,
        expectedWordCounts: [2],
      ),
      hasLength(2),
    );
  });

  test('accepts the web SDK word map and rejects shifted positions', () {
    final raw = <String, dynamic>{
      'units': [3, 4, 1, 5],
      'words': [0, 0, 0, 1],
      'wordCount': 2,
    };
    final parsed = TajweedFormerReferenceVerse.fromWebReference(
      surah: 1,
      ayah: 1,
      reference: raw,
      blankId: 0,
      wordBarId: 1,
      expectedWordCount: 2,
    );
    expect(parsed.tokenIds, [3, 4, 1, 5]);
    raw['words'] = [0, 0, 1, 1];
    expect(
      () => TajweedFormerReferenceVerse.fromWebReference(
        surah: 1,
        ayah: 1,
        reference: raw,
        blankId: 0,
        wordBarId: 1,
      ),
      throwsFormatException,
    );
  });

  test('merges adjacent reference words only with a verified display map', () {
    final verses = [
      verse(2, 1, [2, 1, 3, 1, 4])
    ];
    final units = buildTajweedFormerReference(
      verses: verses,
      wordBarId: 1,
      blankId: 0,
      expectedWordCounts: [1],
      displayWordMaps: [
        [0, 0, 0]
      ],
    );
    expect(units.map((u) => u.wordIndex), [0, 0, 0]);
    for (final map in <List<int>>[
      [],
      [0, 0],
      [1, 1, 1],
      [0, 2, 2],
      [0, 1, 0],
    ]) {
      expect(
        () => buildTajweedFormerReference(
          verses: verses,
          wordBarId: 1,
          blankId: 0,
          displayWordMaps: [map],
        ),
        throwsFormatException,
      );
    }
    expect(
      () => buildTajweedFormerReference(
        verses: verses,
        wordBarId: 1,
        blankId: 0,
        displayWordMaps: [],
      ),
      throwsArgumentError,
    );
  });
}
