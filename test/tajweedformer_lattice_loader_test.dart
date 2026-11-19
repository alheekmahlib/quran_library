import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_lattice.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_lattice_loader.dart';

void main() {
  Map<String, dynamic> data() => {
        'format': 'quran-library.tajweedformer-lattice.v1',
        'source_revision': '233568a621d853da7969ed174ddff625ef9ace5e',
        'verses': {
          '1:1': [
            {
              'canonical': 0,
              'forms': [
                {
                  'left': 'ibtida',
                  'right': 'wasl',
                  'mode': 'plain',
                  'variant': null,
                  'tokens': ['b', 'a'],
                },
              ],
            },
            {
              'canonical': 0,
              'forms': [
                {
                  'left': 'wasl',
                  'right': 'waqf',
                  'mode': 'sukun',
                  'variant': null,
                  'tokens': ['c'],
                },
                {
                  'left': 'wasl',
                  'right': 'waqf',
                  'mode': 'rawm',
                  'variant': 'alternate',
                  'tokens': ['c', 'a'],
                },
              ],
            },
          ],
        },
      };

  const sdk = {
    'units': [2, 3, 1, 4],
    'words': [0, 0, 0, 1],
    'wordCount': 2,
  };
  List<TajweedFormerLatticeWord> load(
    Map<String, dynamic> lattice, {
    Map<String, dynamic> reference = sdk,
    List<int> map = const [0, 1],
    int count = 2,
    List<String> names = const ['blank', '|', 'b', 'a', 'c'],
  }) =>
      loadTajweedFormerLatticeVerse(
        data: lattice,
        surah: 1,
        ayah: 1,
        verseIndex: 0,
        tokenNames: names,
        blankId: 0,
        wordBarId: 1,
        sdkReference: reference,
        displayWordMap: map,
        displayWordCount: count,
      );

  test('checks the canonical SDK path and retains form metadata', () {
    final words = load(data(), map: [0, 0], count: 1);
    expect(words.map((w) => w.wordIndex), [0, 0]);
    expect(words[1].forms[1].mode, 'rawm');
    expect(words[1].forms[1].variant, 'alternate');
    expect(
        matchTajweedFormerLattice(words: words, heard: [2, 3, 4])!.distance, 0);
  });

  test('rejects a different SDK reference or vocabulary', () {
    expect(
        () => load(data(), reference: {
              'units': [2, 4, 1, 4],
              'words': [0, 0, 0, 1],
              'wordCount': 2,
            }),
        throwsFormatException);
    expect(() => load(data(), names: ['blank', '|', 'b', 'a', 'x']),
        throwsFormatException);
  });

  test('rejects unmapped words and malformed canonical forms', () {
    expect(() => load(data(), map: [0, 2], count: 3), throwsFormatException);
    final lattice = data();
    final words = (lattice['verses'] as Map)['1:1'] as List;
    words[0]['forms'][0]['right'] = 'waqf';
    expect(() => load(lattice), throwsFormatException);
  });

  test('rejects invalid alternate forms even when the canonical path matches',
      () {
    final lattice = data();
    final words = (lattice['verses'] as Map)['1:1'] as List;
    words[1]['forms'][1]['mode'] = 'plain';
    expect(() => load(lattice), throwsFormatException);
  });
}
