import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_lattice.dart';

void main() {
  const stop = TajweedFormerBoundary.stop;
  const connected = TajweedFormerBoundary.connected;

  TajweedFormerLatticeForm form(TajweedFormerBoundary left,
          TajweedFormerBoundary right, List<int> t) =>
      TajweedFormerLatticeForm(left: left, right: right, tokens: t);

  test('selects a legal stop and preserves displayed word positions', () {
    final words = [
      TajweedFormerLatticeWord(verseIndex: 0, wordIndex: 0, forms: [
        form(stop, connected, [1, 2]),
        form(stop, stop, [1, 3]),
      ]),
      TajweedFormerLatticeWord(verseIndex: 0, wordIndex: 1, forms: [
        form(connected, stop, [4]),
        form(stop, stop, [5]),
      ]),
    ];
    final match = matchTajweedFormerLattice(words: words, heard: [1, 3, 5])!;
    expect(match.distance, 0);
    expect(match.formIndices, [1, 1]);
    expect(match.units.map((u) => u.tokenId), [1, 3, 5]);
    expect(match.units.map((u) => u.wordIndex), [0, 0, 1]);
    // The individually closest forms are incompatible at the boundary.
    expect(
        matchTajweedFormerLattice(words: words, heard: [1, 3, 4])!.distance, 1);
    expect(matchTajweedFormerLattice(words: words, heard: [], end: connected),
        isNull);
  });

  test('dynamic program agrees with exhaustive legal-path search', () {
    final rng = Random(706);
    for (var trial = 0; trial < 200; trial++) {
      final words = List.generate(
          4,
          (w) => TajweedFormerLatticeWord(
                verseIndex: 0,
                wordIndex: w,
                forms: List.generate(
                    4,
                    (i) => form(
                          i < 2 ? stop : connected,
                          i.isEven ? stop : connected,
                          List.generate(
                              1 + rng.nextInt(3), (_) => rng.nextInt(4)),
                        )),
              ));
      final heard = List.generate(rng.nextInt(9), (_) => rng.nextInt(4));
      int? minimum;
      void visit(int index, TajweedFormerBoundary boundary, List<int> tokens) {
        if (index == words.length) {
          if (boundary == stop) {
            final distance = editDistance(tokens, heard);
            minimum = minimum == null ? distance : min(minimum!, distance);
          }
          return;
        }
        for (final candidate in words[index].forms) {
          if (candidate.left == boundary) {
            visit(index + 1, candidate.right, [...tokens, ...candidate.tokens]);
          }
        }
      }

      visit(0, stop, []);
      final match = matchTajweedFormerLattice(words: words, heard: heard)!;
      expect(match.distance, minimum);
      expect(editDistance(match.units.map((u) => u.tokenId).toList(), heard),
          minimum);
      var boundary = stop;
      for (var i = 0; i < words.length; i++) {
        final chosen = words[i].forms[match.formIndices[i]];
        expect(chosen.left, boundary);
        boundary = chosen.right;
      }
      expect(boundary, stop);
    }
  });
}

int editDistance(List<int> reference, List<int> heard) {
  var row = List.generate(heard.length + 1, (i) => i);
  for (final token in reference) {
    final next = <int>[row.first + 1];
    for (var j = 0; j < heard.length; j++) {
      next.add(min(min(row[j + 1] + 1, next.last + 1),
          row[j] + (token == heard[j] ? 0 : 1)));
    }
    row = next;
  }
  return row.last;
}
