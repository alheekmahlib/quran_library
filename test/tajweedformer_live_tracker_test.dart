import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_live_tracker.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference.dart';

void main() {
  TajweedFormerLiveTracker tracker(List<int> ids) => TajweedFormerLiveTracker(
        reference: [
          for (var i = 0; i < ids.length; i++)
            TajweedFormerReferenceUnit(
                tokenId: ids[i], verseIndex: 0, wordIndex: i ~/ 2),
        ],
        wordBarId: 1,
        blankId: 0,
      );

  test('only settled tokens advance and word bars are not counted', () {
    final t = tracker([2, 3, 4, 5, 6]);
    expect(t.update([2, 3, 4], 2).matchedUnitIndices, isEmpty);
    final p = t.update([2, 3, 4, 1, 5], 4);
    expect(p.matchedUnitIndices, {0, 1, 2});
    expect(p.currentUnitIndex, 2);
    expect(t.update([2, 3, 4, 1, 5], 5).currentUnitIndex, 3);
  });

  test('waits when repeated phrases make the anchor ambiguous', () {
    final t = tracker([2, 3, 4, 5, 2, 3, 4, 6]);
    expect(t.update([2, 3, 4], 3).matchedUnitIndices, isEmpty);
    expect(t.update([2, 3, 4, 6], 4).matchedUnitIndices, {4, 5, 6, 7});
  });

  test('anchors a two-unit reference only after both settled units match', () {
    final t = tracker([2, 3]);
    expect(t.update([2, 3], 1).matchedUnitIndices, isEmpty);
    expect(t.update([2, 4], 2).matchedUnitIndices, isEmpty);
    expect(t.update([2, 3], 2).matchedUnitIndices, {0, 1});
  });

  test('a single-unit reference does not anchor from one token', () {
    expect(tracker([2]).update([2], 1).matchedUnitIndices, isEmpty);
  });

  test('reanchors after a skipped sound without marking it as matched', () {
    final t = tracker([2, 3, 4, 5, 6, 7, 8, 9]);
    t.update([2, 3, 4], 3);
    final p = t.update([2, 3, 4, 6, 7, 8], 6);
    expect(p.matchedUnitIndices, {0, 1, 2, 4, 5, 6});
    expect(p.currentUnitIndex, 6);
  });

  test('rebuilds progress if the SDK revises a settled prefix', () {
    final t = tracker([2, 3, 4, 5, 6, 7]);
    t.update([2, 3, 4, 5], 4);
    final p = t.update([4, 5, 6], 3);
    expect(p.revised, isTrue);
    expect(p.matchedUnitIndices, {2, 3, 4});
  });

  test('rejects invalid settled prefixes', () {
    final t = tracker([2, 3, 4]);
    expect(() => t.update([2], 2), throwsArgumentError);
    expect(() => t.update([0], 1), throwsArgumentError);
  });

  test('reads decoded SDK chunks and rejects malformed token objects', () {
    final t = tracker([2, 3, 4, 5]);
    final p = t.updateDecodedChunk({
      'tokens': [
        {'id': 2},
        {'id': 3},
        {'id': 4},
        {'id': 5},
      ],
      'settled': 3,
    });
    expect(p.matchedUnitIndices, {0, 1, 2});
    expect(
        () => t.updateDecodedChunk({
              'tokens': [{}],
              'settled': 1
            }),
        throwsFormatException);
  });
}
