/// Token alignment for TajweedFormer V4 reference and decoded output.
///
/// This is an alignment primitive, not a recitation verdict. Token differences
/// alone do not apply the SDK's calibrated acoustic thresholds.
library;

enum TajweedFormerAlignmentKind { match, insert, delete, replace }

class TajweedFormerAlignmentOperation {
  const TajweedFormerAlignmentOperation(
      this.kind, this.referenceIndex, this.predictedIndex);

  final TajweedFormerAlignmentKind kind;
  final int? referenceIndex;
  final int? predictedIndex;
}

/// Global edit alignment of V4 token IDs, with deterministic replacement ties.
/// Word-bar and blank tokens must be removed by the caller before alignment.
List<TajweedFormerAlignmentOperation> alignTajweedFormerTokens(
  List<int> reference,
  List<int> predicted,
) {
  final rows = reference.length + 1;
  final columns = predicted.length + 1;
  // Avoid unbounded allocation on malformed data or excessively long takes.
  if (rows * columns > 4000000) {
    throw ArgumentError('V4 alignment input exceeds the supported size');
  }
  final cost = List.generate(rows, (_) => List<int>.filled(columns, 0));
  for (var i = 0; i < rows; i++) {
    cost[i][0] = i;
  }
  for (var j = 0; j < columns; j++) {
    cost[0][j] = j;
  }
  for (var i = 1; i < rows; i++) {
    for (var j = 1; j < columns; j++) {
      final substitution =
          cost[i - 1][j - 1] + (reference[i - 1] == predicted[j - 1] ? 0 : 1);
      final deletion = cost[i - 1][j] + 1;
      final insertion = cost[i][j - 1] + 1;
      var best = substitution < deletion ? substitution : deletion;
      if (insertion < best) best = insertion;
      cost[i][j] = best;
    }
  }
  final result = <TajweedFormerAlignmentOperation>[];
  var i = reference.length;
  var j = predicted.length;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0) {
      final same = reference[i - 1] == predicted[j - 1];
      if (cost[i][j] == cost[i - 1][j - 1] + (same ? 0 : 1)) {
        result.add(TajweedFormerAlignmentOperation(
          same
              ? TajweedFormerAlignmentKind.match
              : TajweedFormerAlignmentKind.replace,
          --i,
          --j,
        ));
        continue;
      }
    }
    if (i > 0 && cost[i][j] == cost[i - 1][j] + 1) {
      result.add(TajweedFormerAlignmentOperation(
          TajweedFormerAlignmentKind.delete, --i, null));
    } else {
      result.add(TajweedFormerAlignmentOperation(
          TajweedFormerAlignmentKind.insert, null, --j));
    }
  }
  return List.unmodifiable(result.reversed);
}

/// Free-end alignment: the reference may complete at any heard position.
///
/// Recitation that continues past the reference (the next ayah joined by
/// wasl, a repeated final word) must not be forced onto the reference —
/// the forced global pass would stretch the reference over the trailing
/// speech and invent substitutions. This variant ends the reference at the
/// cheapest heard position and returns the cut: tokens heard after it stay
/// outside the take. Among equal-cost endings the latest cut wins, so
/// trailing matching tokens are kept inside the take.
({List<TajweedFormerAlignmentOperation> ops, int endCut})
    alignTajweedFormerTokensFreeEnd(
  List<int> reference,
  List<int> predicted,
) {
  final rows = reference.length + 1;
  final columns = predicted.length + 1;
  if (rows * columns > 4000000) {
    throw ArgumentError('V4 alignment input exceeds the supported size');
  }
  final cost = List.generate(rows, (_) => List<int>.filled(columns, 0));
  for (var i = 0; i < rows; i++) {
    cost[i][0] = i;
  }
  for (var j = 0; j < columns; j++) {
    cost[0][j] = j;
  }
  for (var i = 1; i < rows; i++) {
    for (var j = 1; j < columns; j++) {
      final substitution =
          cost[i - 1][j - 1] + (reference[i - 1] == predicted[j - 1] ? 0 : 1);
      final deletion = cost[i - 1][j] + 1;
      final insertion = cost[i][j - 1] + 1;
      var best = substitution < deletion ? substitution : deletion;
      if (insertion < best) best = insertion;
      cost[i][j] = best;
    }
  }
  var cut = 0;
  var bestCost = cost[reference.length][0];
  for (var j = 1; j < columns; j++) {
    if (cost[reference.length][j] <= bestCost) {
      bestCost = cost[reference.length][j];
      cut = j;
    }
  }
  final result = <TajweedFormerAlignmentOperation>[];
  var i = reference.length;
  var j = cut;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0) {
      final same = reference[i - 1] == predicted[j - 1];
      if (cost[i][j] == cost[i - 1][j - 1] + (same ? 0 : 1)) {
        result.add(TajweedFormerAlignmentOperation(
          same
              ? TajweedFormerAlignmentKind.match
              : TajweedFormerAlignmentKind.replace,
          --i,
          --j,
        ));
        continue;
      }
    }
    if (i > 0 && cost[i][j] == cost[i - 1][j] + 1) {
      result.add(TajweedFormerAlignmentOperation(
          TajweedFormerAlignmentKind.delete, --i, null));
    } else {
      result.add(TajweedFormerAlignmentOperation(
          TajweedFormerAlignmentKind.insert, null, --j));
    }
  }
  return (ops: List.unmodifiable(result.reversed), endCut: cut);
}
