import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_live_tracker.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_word_progress.dart';

void main() {
  const reference = [
    TajweedFormerReferenceUnit(tokenId: 2, verseIndex: 0, wordIndex: 0),
    TajweedFormerReferenceUnit(tokenId: 3, verseIndex: 0, wordIndex: 0),
    TajweedFormerReferenceUnit(tokenId: 4, verseIndex: 0, wordIndex: 1),
    TajweedFormerReferenceUnit(tokenId: 5, verseIndex: 1, wordIndex: 0),
  ];
  final mapper = TajweedFormerWordProgressMapper(reference);

  test('partially matched words are shown without a correctness verdict', () {
    final progress = mapper.project(const TajweedFormerLiveProgress(
      matchedUnitIndices: {0, 2, 3},
      currentUnitIndex: 3,
      revised: false,
    ));
    expect(progress.matchedWords, {
      (verseIndex: 0, wordIndex: 0),
      (verseIndex: 0, wordIndex: 1),
      (verseIndex: 1, wordIndex: 0),
    });
    expect(progress.currentWord, (verseIndex: 1, wordIndex: 0));
  });

  test('revisions rebuild words from the snapshot', () {
    final progress = mapper.project(const TajweedFormerLiveProgress(
      matchedUnitIndices: {0, 1},
      currentUnitIndex: 1,
      revised: true,
    ));
    expect(progress.matchedWords, {(verseIndex: 0, wordIndex: 0)});
    expect(progress.revised, isTrue);
  });

  test('rejects invalid reference and progress positions', () {
    expect(
      () => TajweedFormerWordProgressMapper(reference.reversed.toList()),
      throwsArgumentError,
    );
    expect(
      () => mapper.project(const TajweedFormerLiveProgress(
        matchedUnitIndices: {4},
        currentUnitIndex: 4,
        revised: false,
      )),
      throwsArgumentError,
    );
    expect(
      () => mapper.project(const TajweedFormerLiveProgress(
        matchedUnitIndices: {0},
        currentUnitIndex: 1,
        revised: false,
      )),
      throwsArgumentError,
    );
  });
}
