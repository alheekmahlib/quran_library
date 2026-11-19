/// V4 single-edit candidates, following Quran Lab's published scorer.
///
/// Algorithm reference: Quran-Lab/tajweedformer-engine, commit
/// e7abb569a860ebf4455cb05940194889a4c45a5e, tajweed/src/score.c.
/// The referenced scorer is distributed under Quran-Lab NPL-1.2; see the
/// third-party license included with this package. This code makes no verdict.
library;

import 'tajweedformer_reference.dart';

enum TajweedFormerEditKind { substitute, delete, insertAfter }

class TajweedFormerSiteEdit {
  const TajweedFormerSiteEdit({
    required this.kind,
    required this.siteClass,
    required this.position,
    required this.expected,
    required this.alternative,
  });

  final TajweedFormerEditKind kind;
  final String siteClass;

  /// Index in the reference's sound-only path (word bars removed).
  final int position;
  final int expected;
  final int? alternative;

  /// Construct the complete CTC path for this candidate.
  List<int> apply(List<int> path) {
    if (position < 0 || position >= path.length || path[position] != expected) {
      throw ArgumentError('Edit does not belong to this V4 reference path');
    }
    final result = List<int>.of(path);
    switch (kind) {
      case TajweedFormerEditKind.substitute:
        result[position] = alternative!;
      case TajweedFormerEditKind.delete:
        result.removeAt(position);
      case TajweedFormerEditKind.insertAfter:
        result.insert(position + 1, alternative!);
    }
    return result;
  }
}

class TajweedFormerSiteWindow {
  const TajweedFormerSiteWindow({
    required this.referenceIndex,
    required this.wordIndex,
    required this.edits,
  });

  final int referenceIndex;
  final int wordIndex;
  final List<TajweedFormerSiteEdit> edits;
}

/// Generates the scorer's consonant/vowel windows for a selected path.
///
/// [reference] must be the legally valid reading selected for the take, not
/// blindly the canonical path when stops or alternate readings are possible.
/// The caller must first verify that its word mapping matches the Mushaf.
List<TajweedFormerSiteWindow> tajweedFormerSiteWindows({
  required List<TajweedFormerReferenceUnit> reference,
  required List<String> tokenNames,
}) {
  const expectedNames = [
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
  if (tokenNames.length != expectedNames.length) {
    throw const FormatException('Unsupported V4 token vocabulary');
  }
  for (var i = 0; i < expectedNames.length; i++) {
    if (tokenNames[i] != expectedNames[i]) {
      throw const FormatException('Unsupported V4 token vocabulary');
    }
  }
  if (reference.isEmpty) return const [];
  if (reference.any((u) =>
      u.verseIndex < 0 || u.wordIndex < 0 || u.tokenId < 2 || u.tokenId > 36)) {
    throw ArgumentError('Expected a validated V4 path');
  }
  final path = reference.map((u) => u.tokenId).toList(growable: false);
  bool isVowel(int id) => id >= 31 && id <= 36;
  final windows = <TajweedFormerSiteWindow>[];
  for (var start = 0; start < path.length; start++) {
    final token = path[start];
    // 2..29 are the 28 consonants; nasal id 30 is not a window start.
    if (token < 2 || token > 29) continue;
    final hasVowel = start + 1 < path.length && isVowel(path[start + 1]);
    final edits = <TajweedFormerSiteEdit>[];
    final end = start + (hasVowel ? 2 : 1);
    for (var pos = start; pos < end; pos++) {
      final expected = path[pos];
      final vowel = isVowel(expected);
      final low = vowel ? 31 : 2;
      final high = vowel ? 36 : 30;
      for (var candidate = low; candidate <= high; candidate++) {
        if (candidate == expected) continue;
        final String cls;
        if (!vowel) {
          cls = 'cons_sub';
        } else if ((candidate - 31) % 3 == (expected - 31) % 3) {
          cls = expected < 34 ? 'short_to_long' : 'long_to_short';
        } else {
          cls = 'vowel_sub';
        }
        edits.add(TajweedFormerSiteEdit(
            kind: TajweedFormerEditKind.substitute,
            siteClass: cls,
            position: pos,
            expected: expected,
            alternative: candidate));
      }
      edits.add(TajweedFormerSiteEdit(
          kind: TajweedFormerEditKind.delete,
          siteClass: vowel ? 'vowel_del' : 'cons_del',
          position: pos,
          expected: expected,
          alternative: null));
      if (!vowel && !hasVowel) {
        for (var candidate = 31; candidate <= 36; candidate++) {
          edits.add(TajweedFormerSiteEdit(
              kind: TajweedFormerEditKind.insertAfter,
              siteClass: 'vowel_ins',
              position: pos,
              expected: expected,
              alternative: candidate));
        }
      }
    }
    windows.add(TajweedFormerSiteWindow(
        referenceIndex: start,
        wordIndex: reference[start].wordIndex,
        edits: List.unmodifiable(edits)));
  }
  return List.unmodifiable(windows);
}
