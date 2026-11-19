/// Gemination evidence from V4, enabled only by validated model calibration.
/// The held-probability mean follows Quran Lab's public scorer, score.c at
/// e7abb569a860ebf4455cb05940194889a4c45a5e (NPL-1.2; see NOTICE).
/// The model's current calibration marks gemination `off`; [coverage] keeps
/// that state visible instead of an empty error list.
library;

import 'models/recitation_result.dart';
import 'tajweedformer_attribute_alignment.dart';
import 'tajweedformer_coverage.dart';
import 'tajweedformer_reference.dart';

({List<RecitationError> errors, TajweedFormerCategoryCoverage coverage})
    evaluateTajweedFormerGemination({
  required List<TajweedFormerReferenceUnit> reference,
  required List<int> heard,
  required List<String> tokenNames,
  required int blankId,
  required Map<String, dynamic> heads,
  required Map<String, dynamic> calibration,
  required String context,
  required List<({int surah, int ayah})> verses,
  required Map<String, dynamic> timingReferences,
  String preset = 'balanced',
}) {
  final blocked = reasonTajweedFormerAttributeUnavailable(
    reference: reference,
    heard: heard,
    heads: heads,
    calibration: calibration,
    context: context,
    attributeName: 'gem',
    calibrationName: 'gemination',
    allowExperimental: false,
  );
  if (blocked != null) {
    return (
      errors: const [],
      coverage: TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.notEvaluated, reason: blocked),
    );
  }
  final aligned = alignTajweedFormerAttribute(
    reference: reference,
    heard: heard,
    tokenNames: tokenNames,
    blankId: blankId,
    heads: heads,
    calibration: calibration,
    context: context,
    verses: verses,
    timingReferences: timingReferences,
    attributeName: 'gem',
    calibrationName: 'gemination',
    classes: 2,
    preset: preset,
    allowExperimental: false,
  );
  if (aligned == null) {
    return (
      errors: const [],
      coverage: const TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.notEvaluated,
        reason: TajweedFormerCoverageReason.pathNotEligible,
      ),
    );
  }
  final errors = <RecitationError>[];
  var checkedSites = 0;
  var unalignedSites = 0;
  var outOfRangeSites = 0;
  var versesWithoutPositions = 0;
  for (final entry in aligned.canonicalIndices.entries) {
    final verse = verses[entry.key];
    final raw = timingReferences['${verse.surah}:${verse.ayah}'] as Map;
    final positions = raw['geminated'];
    if (positions is! List) {
      // آية قانونية بلا قائمة مواضع شدة — تعذّر مرجعي على مستوى الآية.
      versesWithoutPositions++;
      continue;
    }
    for (final position in positions) {
      if (position is! int || position < 0 || position >= entry.value.length) {
        throw const FormatException('Invalid V4 gemination position');
      }
      final i = entry.value[position];
      final span = aligned.spans[i];
      if (span.start < 0) {
        unalignedSites++;
        continue;
      }
      final end = span.end > span.start + 1 ? span.end : span.start + 1;
      if (end > aligned.head.frames) {
        outOfRangeSites++;
        continue;
      }
      checkedSites++;
      var held = 0.0;
      for (var frame = span.start; frame < end; frame++) {
        held += aligned.head.values[frame * 2 + 1];
      }
      if (held / (end - span.start) >= aligned.threshold) continue;
      errors.add(RecitationError(
        errorType: 'tajweed',
        speechErrorType: 'delete',
        expectedPh: tokenNames[reference[i].tokenId],
        suraIdx: verse.surah,
        ayaIdx: verse.ayah,
        wordIdx: reference[i].wordIndex,
        refTajweedRules: const [
          TajweedRule(nameAr: 'الشدة', nameEn: 'Gemination')
        ],
      ));
    }
  }
  final unassessedVerses =
      (verses.length - aligned.canonicalIndices.length) +
          versesWithoutPositions;
  final unassessedSites = unalignedSites + outOfRangeSites;
  final unassessed = unassessedSites + unassessedVerses;
  final TajweedFormerCoverageReason? reason;
  if (unassessedVerses > 0) {
    reason = TajweedFormerCoverageReason.missingReference;
  } else if (unassessedSites > 0) {
    reason = TajweedFormerCoverageReason.pathNotEligible;
  } else {
    reason = null;
  }
  return (
    errors: List.unmodifiable(errors),
    coverage: TajweedFormerCategoryCoverage(
      state: errors.isNotEmpty
          ? TajweedFormerCoverageState.candidateNeedsReview
          : aligned.canonicalIndices.isEmpty
              ? TajweedFormerCoverageState.notEvaluated
              : unassessed > 0
                  ? TajweedFormerCoverageState.inconclusive
                  : TajweedFormerCoverageState.evaluatedNoCandidate,
      reason: errors.isNotEmpty
          ? reason
          : aligned.canonicalIndices.isEmpty
              ? TajweedFormerCoverageReason.missingReference
              : reason,
      sites: checkedSites > 0 ? checkedSites : null,
      unassessed: unassessed > 0 ? unassessed : null,
    ),
  );
}
