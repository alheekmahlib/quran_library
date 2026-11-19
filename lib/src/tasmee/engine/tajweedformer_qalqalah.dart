/// Experimental qalqalah evidence from V4's timing and attribute heads.
///
/// The window and score follow Quran Lab's public scorer, tajweed/src/score.c
/// at e7abb569a860ebf4455cb05940194889a4c45a5e (NPL-1.2; see NOTICE).
/// An experimental calibration is never a validated recitation verdict.
/// [coverage] keeps the reason the category stayed unassessed whenever no
/// error is returned.
library;

import 'models/recitation_result.dart';
import 'tajweedformer_attribute_alignment.dart';
import 'tajweedformer_coverage.dart';
import 'tajweedformer_reference.dart';

({List<RecitationError> errors, TajweedFormerCategoryCoverage coverage})
    evaluateTajweedFormerQalqalah({
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
  bool allowExperimental = false,
}) {
  final blocked = reasonTajweedFormerAttributeUnavailable(
    reference: reference,
    heard: heard,
    heads: heads,
    calibration: calibration,
    context: context,
    attributeName: 'attr_qalqalah',
    calibrationName: 'qalqalah',
    allowExperimental: allowExperimental,
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
    attributeName: 'attr_qalqalah',
    calibrationName: 'qalqalah',
    classes: 3,
    preset: preset,
    allowExperimental: allowExperimental,
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
  final attribute = aligned.head;
  const letters = {'ب', 'ج', 'د', 'ط', 'ق'};
  const vowels = {'a', 'i', 'u', 'aa', 'ii', 'uu'};
  final errors = <RecitationError>[];
  var checkedSites = 0;
  var unalignedSites = 0;
  var outOfRangeSites = 0;
  for (final entry in aligned.canonicalIndices.entries) {
    final verseIndex = entry.key;
    final verse = verses[verseIndex];
    for (final i in entry.value) {
      if (!letters.contains(tokenNames[reference[i].tokenId])) continue;
      if (i + 1 < reference.length &&
          vowels.contains(tokenNames[reference[i + 1].tokenId])) {
        continue;
      }
      final span = aligned.spans[i];
      if (span.start < 0) {
        // مرجع قانوني لكن المحاذاة الزمنية لم تغطّ الحرف — تعذّر موضعي.
        unalignedSites++;
        continue;
      }
      final start = span.end + 2;
      final end = (span.end + 14).clamp(0, attribute.frames);
      if (start >= end) {
        // نافذة الدليل خارج رؤوس النموذج — تعذّر موضعي لا غياب مرجع.
        outOfRangeSites++;
        continue;
      }
      checkedSites++;
      var probability = 0.0;
      for (var frame = start; frame < end; frame++) {
        probability +=
            attribute.values[frame * 3 + 1] + attribute.values[frame * 3 + 2];
      }
      if (probability / (end - start) >= aligned.threshold) continue;
      errors.add(RecitationError(
        errorType: 'tajweed',
        speechErrorType: 'delete',
        expectedPh: tokenNames[reference[i].tokenId],
        suraIdx: verse.surah,
        ayaIdx: verse.ayah,
        wordIdx: reference[i].wordIndex,
        refTajweedRules: const [
          TajweedRule(nameAr: 'القلقلة', nameEn: 'Qalqalah')
        ],
      ));
    }
  }
  return (
    errors: List.unmodifiable(errors),
    coverage: _attributeCoverage(
      errors: errors,
      verses: verses.length,
      canonicalVerses: aligned.canonicalIndices.length,
      checkedSites: checkedSites,
      unalignedSites: unalignedSites,
      outOfRangeSites: outOfRangeSites,
    ),
  );
}

TajweedFormerCategoryCoverage _attributeCoverage({
  required List<RecitationError> errors,
  required int verses,
  required int canonicalVerses,
  required int checkedSites,
  required int unalignedSites,
  required int outOfRangeSites,
}) {
  final unassessedVerses = verses - canonicalVerses;
  final unassessedSites = unalignedSites + outOfRangeSites;
  final unassessed = unassessedSites + unassessedVerses;
  // سبب التعذّر الدقيق: غياب مرجع آية يسبق تعذّر مواضع داخل آية مقارَنة.
  final TajweedFormerCoverageReason? reason;
  if (unassessedVerses > 0) {
    reason = TajweedFormerCoverageReason.missingReference;
  } else if (unassessedSites > 0) {
    reason = TajweedFormerCoverageReason.pathNotEligible;
  } else {
    reason = null;
  }
  if (errors.isNotEmpty) {
    return TajweedFormerCategoryCoverage(
      state: TajweedFormerCoverageState.candidateNeedsReview,
      reason: reason,
      sites: checkedSites > 0 ? checkedSites : null,
      unassessed: unassessed > 0 ? unassessed : null,
    );
  }
  if (canonicalVerses == 0) {
    return TajweedFormerCategoryCoverage(
      state: TajweedFormerCoverageState.notEvaluated,
      reason: TajweedFormerCoverageReason.missingReference,
      unassessed: unassessed,
    );
  }
  if (unassessed > 0) {
    // مواضع/آيات لم تُقيَّم: الفئة غير حاسمة لا صافية، والسبب الدقيق محفوظ.
    return TajweedFormerCategoryCoverage(
      state: TajweedFormerCoverageState.inconclusive,
      reason: reason,
      sites: checkedSites > 0 ? checkedSites : null,
      unassessed: unassessed,
    );
  }
  return TajweedFormerCategoryCoverage(
    state: TajweedFormerCoverageState.evaluatedNoCandidate,
    sites: checkedSites,
  );
}
