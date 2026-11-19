import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_site_candidates.dart';

const tokens = [
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
  '<foreign>',
];

void main() {
  List<TajweedFormerReferenceUnit> ref(List<int> ids) => [
        for (var i = 0; i < ids.length; i++)
          TajweedFormerReferenceUnit(
              tokenId: ids[i], verseIndex: 0, wordIndex: i ~/ 2),
      ];

  test('creates reference consonant-vowel edit windows and classes', () {
    final windows = tajweedFormerSiteWindows(
        reference: ref([3, 31, 4]), tokenNames: tokens);
    expect(windows.length, 2);
    final first = windows[0].edits;
    expect(first.where((e) => e.siteClass == 'cons_sub').length, 28);
    expect(first.where((e) => e.siteClass == 'cons_del').length, 1);
    expect(first.where((e) => e.siteClass == 'vowel_sub').length, 4);
    expect(
        first.where((e) => e.siteClass == 'short_to_long').single.alternative,
        34);
    expect(first.where((e) => e.siteClass == 'vowel_del').length, 1);
    expect(first.where((e) => e.siteClass == 'vowel_ins'), isEmpty);
    expect(windows[1].edits.where((e) => e.siteClass == 'vowel_ins').length, 6);
    expect(windows[1].wordIndex, 1);
  });

  test('edits produce full paths and reject mismatched references', () {
    final edits =
        tajweedFormerSiteWindows(reference: ref([3, 31, 4]), tokenNames: tokens)
            .first
            .edits;
    final shortToLong =
        edits.singleWhere((e) => e.siteClass == 'short_to_long');
    expect(shortToLong.apply([3, 31, 4]), [3, 34, 4]);
    expect(() => shortToLong.apply([3, 32, 4]), throwsArgumentError);
    final deletion = edits.singleWhere((e) => e.siteClass == 'vowel_del');
    expect(deletion.apply([3, 31, 4]), [3, 4]);
  });

  test('rejects another vocabulary and preserves multi-verse positions', () {
    final wrongTokens = List<String>.of(tokens)..[3] = 'changed';
    expect(
        () => tajweedFormerSiteWindows(
            reference: ref([3, 31]), tokenNames: wrongTokens),
        throwsFormatException);
    final verses = [
      const TajweedFormerReferenceUnit(tokenId: 3, verseIndex: 0, wordIndex: 0),
      const TajweedFormerReferenceUnit(
          tokenId: 31, verseIndex: 1, wordIndex: 0),
    ];
    final windows =
        tajweedFormerSiteWindows(reference: verses, tokenNames: tokens);
    expect(windows.single.edits.any((edit) => edit.position == 1), isTrue);
  });
}
