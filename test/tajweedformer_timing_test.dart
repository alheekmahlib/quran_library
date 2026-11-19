import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_head.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_timing.dart';

void main() {
  test('aligns repeated sounds and a pause at the word boundary', () {
    const sequence = [0, 1, 1, 0, 1, 2, 0];
    final head = TajweedFormerCtcHead.fromMap({
      'frames': sequence.length,
      'classes': 3,
      'frameMs': 20,
      'values': [
        for (final id in sequence)
          for (var c = 0; c < 3; c++) c == id ? 0.0 : -30.0
      ],
    });
    const units = [
      TajweedFormerReferenceUnit(tokenId: 1, verseIndex: 0, wordIndex: 0),
      TajweedFormerReferenceUnit(tokenId: 1, verseIndex: 0, wordIndex: 1),
      TajweedFormerReferenceUnit(tokenId: 2, verseIndex: 0, wordIndex: 1),
    ];
    expect(alignTajweedFormerTiming(head: head, reference: units, blankId: 0),
        [(start: 1, end: 3), (start: 4, end: 5), (start: 5, end: 6)]);
  });

  test('returns no alignment when the head is too short', () {
    final head = TajweedFormerCtcHead.fromMap({
      'frames': 1,
      'classes': 3,
      'frameMs': 20,
      'values': [-1.0, -1.0, -1.0],
    });
    const units = [
      TajweedFormerReferenceUnit(tokenId: 1, verseIndex: 0, wordIndex: 0),
      TajweedFormerReferenceUnit(tokenId: 2, verseIndex: 0, wordIndex: 0),
    ];
    expect(alignTajweedFormerTiming(head: head, reference: units, blankId: 0),
        isNull);
  });
}
