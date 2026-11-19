import 'tajweedformer_live_tracker.dart';
import 'tajweedformer_reference.dart';

/// A displayed word position in the caller's verified Mushaf mapping.
typedef TajweedFormerWordPosition = ({int verseIndex, int wordIndex});

/// Exact settled-token matches, not a recitation or correctness verdict.
class TajweedFormerWordProgress {
  const TajweedFormerWordProgress({
    required this.matchedWords,
    required this.currentWord,
    required this.revised,
  });

  /// Words with at least one matched reference unit; this is not a verdict.
  final Set<TajweedFormerWordPosition> matchedWords;
  final TajweedFormerWordPosition? currentWord;
  final bool revised;
}

/// Projects a tracker snapshot onto the caller's verified displayed words.
///
/// Construct this with the exact reference passed to the tracker. A matched
/// word only means that at least one reference unit was observed; no error, verdict,
/// range completion or saved result can be inferred from it.
class TajweedFormerWordProgressMapper {
  TajweedFormerWordProgressMapper(List<TajweedFormerReferenceUnit> reference)
      : _reference = List.unmodifiable(reference) {
    for (var i = 0; i < _reference.length; i++) {
      final unit = _reference[i];
      if (unit.verseIndex < 0 || unit.wordIndex < 0) {
        throw ArgumentError('Invalid displayed word position');
      }
      final position = (verseIndex: unit.verseIndex, wordIndex: unit.wordIndex);
      if (i > 0) {
        final previous = _reference[i - 1];
        if (unit.verseIndex < previous.verseIndex ||
            (unit.verseIndex == previous.verseIndex &&
                unit.wordIndex < previous.wordIndex)) {
          throw ArgumentError('Reference positions must be ordered');
        }
      }
      (_wordUnits[position] ??= <int>{}).add(i);
    }
  }

  final List<TajweedFormerReferenceUnit> _reference;
  final Map<TajweedFormerWordPosition, Set<int>> _wordUnits = {};

  TajweedFormerWordProgress project(TajweedFormerLiveProgress progress) {
    if (progress.matchedUnitIndices
            .any((index) => index < 0 || index >= _reference.length) ||
        (progress.currentUnitIndex != null &&
            !progress.matchedUnitIndices.contains(progress.currentUnitIndex))) {
      throw ArgumentError('Progress does not belong to this reference');
    }
    final matched = <TajweedFormerWordPosition>{};
    for (final entry in _wordUnits.entries) {
      if (entry.value.any(progress.matchedUnitIndices.contains)) {
        matched.add(entry.key);
      }
    }
    final current = progress.currentUnitIndex;
    final unit = current == null ? null : _reference[current];
    return TajweedFormerWordProgress(
      matchedWords: Set.unmodifiable(matched),
      currentWord: unit == null
          ? null
          : (verseIndex: unit.verseIndex, wordIndex: unit.wordIndex),
      revised: progress.revised,
    );
  }
}
