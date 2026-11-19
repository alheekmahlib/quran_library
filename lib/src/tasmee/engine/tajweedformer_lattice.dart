import 'dart:math' as math;

import 'tajweedformer_reference.dart';

/// Boundary between adjacent reference words.
enum TajweedFormerBoundary { stop, connected }

/// One permitted pronunciation of a reference word.
class TajweedFormerLatticeForm {
  TajweedFormerLatticeForm({
    required this.left,
    required this.right,
    required Iterable<int> tokens,
    this.mode,
    this.variant,
  }) : tokens = List.unmodifiable(tokens) {
    if (this.tokens.isEmpty || this.tokens.any((token) => token < 0)) {
      throw ArgumentError('A pronunciation must contain valid token IDs');
    }
  }

  final TajweedFormerBoundary left;
  final TajweedFormerBoundary right;
  final List<int> tokens;

  /// Source stop mode and optional variant, retained for later validation.
  final String? mode;
  final String? variant;
}

/// A lattice word and its corresponding displayed word position.
class TajweedFormerLatticeWord {
  TajweedFormerLatticeWord({
    required this.verseIndex,
    required this.wordIndex,
    required Iterable<TajweedFormerLatticeForm> forms,
  }) : forms = List.unmodifiable(forms) {
    if (verseIndex < 0 || wordIndex < 0 || this.forms.isEmpty) {
      throw ArgumentError('Invalid lattice word');
    }
  }

  final int verseIndex;
  final int wordIndex;
  final List<TajweedFormerLatticeForm> forms;
}

/// A closest legal path, not a verdict about the reader's pronunciation.
class TajweedFormerLatticeMatch {
  TajweedFormerLatticeMatch._(this.distance, this.formIndices, this.units);

  final int distance;
  final List<int> formIndices;
  final List<TajweedFormerReferenceUnit> units;
}

/// Finds a legal reference path closest to [heard] by token edit distance.
///
/// Adjacent forms must agree at their boundary. The default boundaries model
/// a complete passage beginning and ending at a stop; callers handling a
/// continuous partial passage must explicitly provide the actual boundaries.
/// The supplied lattice must itself come from a verified reference and match
/// the model vocabulary. This function does not establish either condition.
TajweedFormerLatticeMatch? matchTajweedFormerLattice({
  required List<TajweedFormerLatticeWord> words,
  required List<int> heard,
  TajweedFormerBoundary start = TajweedFormerBoundary.stop,
  TajweedFormerBoundary end = TajweedFormerBoundary.stop,
}) {
  if (words.isEmpty || heard.any((token) => token < 0)) {
    throw ArgumentError(
        'A nonempty lattice and valid heard tokens are required');
  }
  final count = heard.length;
  var rows = <TajweedFormerBoundary, List<int>>{
    start: List.generate(count + 1, (index) => index),
  };
  final history = <_LatticeStep>[];
  for (final word in words) {
    final next = <TajweedFormerBoundary, List<int>>{};
    final choices = <TajweedFormerBoundary, List<int>>{};
    for (var index = 0; index < word.forms.length; index++) {
      final form = word.forms[index];
      final previous = rows[form.left];
      if (previous == null) continue;
      final candidate = _editRows(previous, form.tokens, heard).last;
      final best = next[form.right];
      if (best == null) {
        next[form.right] = candidate;
        choices[form.right] = List.filled(count + 1, index);
      } else {
        for (var j = 0; j <= count; j++) {
          if (candidate[j] < best[j]) {
            best[j] = candidate[j];
            choices[form.right]![j] = index;
          }
        }
      }
    }
    history.add(_LatticeStep(rows, choices));
    rows = next;
  }
  final finalRow = rows[end];
  if (finalRow == null) return null;
  final selected = List<int>.filled(words.length, 0);
  var boundary = end;
  var j = count;
  for (var w = words.length - 1; w >= 0; w--) {
    final step = history[w];
    final index = step.choices[boundary]![j];
    selected[w] = index;
    final form = words[w].forms[index];
    final matrix = _editRows(step.rows[form.left]!, form.tokens, heard);
    var i = form.tokens.length;
    while (i > 0) {
      if (j > 0 &&
          matrix[i][j] ==
              matrix[i - 1][j - 1] +
                  (form.tokens[i - 1] == heard[j - 1] ? 0 : 1)) {
        i--;
        j--;
      } else if (matrix[i][j] == matrix[i - 1][j] + 1) {
        i--;
      } else {
        j--;
      }
    }
    boundary = form.left;
  }
  final units = <TajweedFormerReferenceUnit>[];
  for (var w = 0; w < words.length; w++) {
    final word = words[w];
    for (final token in word.forms[selected[w]].tokens) {
      units.add(TajweedFormerReferenceUnit(
        tokenId: token,
        verseIndex: word.verseIndex,
        wordIndex: word.wordIndex,
      ));
    }
  }
  return TajweedFormerLatticeMatch._(
      finalRow[count], List.unmodifiable(selected), List.unmodifiable(units));
}

class _LatticeStep {
  _LatticeStep(this.rows, this.choices);
  final Map<TajweedFormerBoundary, List<int>> rows;
  final Map<TajweedFormerBoundary, List<int>> choices;
}

List<List<int>> _editRows(
    List<int> initial, List<int> reference, List<int> heard) {
  final rows = <List<int>>[initial];
  for (final token in reference) {
    final previous = rows.last;
    final row = List<int>.filled(heard.length + 1, 0)..[0] = previous[0] + 1;
    for (var j = 1; j <= heard.length; j++) {
      row[j] = math.min(
        math.min(previous[j] + 1, row[j - 1] + 1),
        previous[j - 1] + (token == heard[j - 1] ? 0 : 1),
      );
    }
    rows.add(row);
  }
  return rows;
}
