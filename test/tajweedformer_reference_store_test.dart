import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference_store.dart';

import 'tajweedformer_range_session_test.dart' show FakeClient;

class ReferenceClient extends FakeClient {
  bool invalid = false;

  @override
  Future<Map<String, dynamic>> reference(int surah, int ayah) async => {
        'units': [
          3,
          32,
          13,
          25,
          32,
          1,
          24,
          34,
          27,
          32,
          1,
          11,
          31,
          7,
          25,
          34,
          26,
          32,
          1,
          11,
          31,
          7,
          35,
          invalid ? 24 : 25
        ],
        'words': [
          0,
          0,
          0,
          0,
          0,
          0,
          1,
          1,
          1,
          1,
          1,
          2,
          2,
          2,
          2,
          2,
          2,
          2,
          2,
          3,
          3,
          3,
          3,
          3
        ],
        'wordCount': 4,
      };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const metadata = {
    'blank': 0,
    'wordBar': 1,
    'tokens': [
      '<blk>',
      '|',
      'ء',
      'ب',
      'ت',
      'ث',
      'ج',
      'ح',
      'خ',
      'د',
      'ذ',
      'ر',
      'ز',
      'س',
      'ش',
      'ص',
      'ض',
      'ط',
      'ظ',
      'ع',
      'غ',
      'ف',
      'ق',
      'ك',
      'ل',
      'م',
      'ن',
      'ه',
      'و',
      'ي',
      'ں',
      'a',
      'i',
      'u',
      'aa',
      'ii',
      'uu',
      '<foreign>'
    ],
  };

  test('loads bundled references and checks the SDK before using a verse',
      () async {
    final client = ReferenceClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    final verse = await store.verse(surah: 1, ayah: 1, verseIndex: 2);
    expect(verse.lattice.length, 4);
    expect(verse.reference.first.verseIndex, 2);
    expect(verse.reference.map((u) => u.wordIndex).toSet(), {0, 1, 2, 3});
    client.invalid = true;
    await expectLater(
        store.verse(surah: 1, ayah: 1, verseIndex: 2), throwsFormatException);
    await client.close();
  });
}
