/// Evaluates V4 site candidates against verified calibration and raw heads.
///
/// The caller must supply the legally valid reference path for the actual
/// recitation. Results are experimental app-side evidence, not a verdict from
/// Quran Lab's inference SDK. Run away from the UI isolate for longer audio.
library;

import 'tajweedformer_calibration.dart';
import 'tajweedformer_site_candidates.dart';
import 'tajweedformer_site_evidence.dart';

class TajweedFormerWindowEvidence {
  const TajweedFormerWindowEvidence({
    required this.siteClass,
    required this.edit,
    required this.evidence,
  });

  final String siteClass;
  final TajweedFormerSiteEdit edit;
  final TajweedFormerSiteEvidence evidence;
}

/// Scores the alternatives of a single site window. Only classes explicitly
/// marked `validated` by this model are returned. Disabled and experimental
/// classes are never promoted to learner-facing feedback by this helper.
List<TajweedFormerWindowEvidence> evaluateTajweedFormerWindow({
  required TajweedFormerSiteWindow window,
  required List<int> referencePath,
  required List<List<double>> logProbs,
  required List<List<double>> inter1LogProbs,
  required int blankId,
  required int wordBarId,
  required Map<String, dynamic> calibration,
  required String context,
  required String preset,
}) {
  final byClass = <String, List<TajweedFormerSiteEdit>>{};
  for (final edit in window.edits) {
    (byClass[edit.siteClass] ??= []).add(edit);
  }
  final result = <TajweedFormerWindowEvidence>[];
  for (final entry in byClass.entries) {
    final settings = readTajweedFormerSiteCalibration(
      calibration: calibration,
      context: context,
      preset: preset,
      siteClass: entry.key,
    );
    if (!settings.isValidated) continue;
    final paths = entry.value.map((edit) => edit.apply(referencePath)).toList();
    final evidence = evaluateCalibratedTajweedFormerSite(
      logProbs: logProbs,
      inter1LogProbs: inter1LogProbs,
      expected: referencePath,
      alternatives: paths,
      blankId: blankId,
      wordBarId: wordBarId,
      calibration: settings,
    );
    final best = evidence?.alternativeIndex;
    if (evidence != null && best != null) {
      result.add(TajweedFormerWindowEvidence(
        siteClass: entry.key,
        edit: entry.value[best],
        evidence: evidence,
      ));
    }
  }
  return List.unmodifiable(result);
}
