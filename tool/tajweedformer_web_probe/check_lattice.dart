// Compares the Dart path selector with the official benchmark scorer.
// Input is made by check_lattice.py from the public benchmark; no audio is read.
import 'dart:convert';
import 'dart:io';

import 'package:quran_library/src/tasmee/engine/tajweedformer_lattice.dart';

void main(List<String> args) {
  if (args.length != 1) throw ArgumentError('Expected a fixture JSON path');
  final cases = jsonDecode(File(args.single).readAsStringSync()) as List;
  for (final item in cases) {
    final words = (item['words'] as List).map((word) {
      return TajweedFormerLatticeWord(
        verseIndex: 0,
        wordIndex: word['index'] as int,
        forms: (word['forms'] as List).map((form) => TajweedFormerLatticeForm(
              left: form['left'] == 'stop'
                  ? TajweedFormerBoundary.stop
                  : TajweedFormerBoundary.connected,
              right: form['right'] == 'stop'
                  ? TajweedFormerBoundary.stop
                  : TajweedFormerBoundary.connected,
              tokens: (form['tokens'] as List).cast<int>(),
            )),
      );
    }).toList();
    final match = matchTajweedFormerLattice(
      words: words,
      heard: (item['heard'] as List).cast<int>(),
    );
    if (match == null || match.distance != item['distance']) {
      throw StateError('Lattice scorer mismatch for ${item['id']}');
    }
    stdout
        .writeln('${item['id']}: ${match.distance} edits, legal path verified');
  }
}
