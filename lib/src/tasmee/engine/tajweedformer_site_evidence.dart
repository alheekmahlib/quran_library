/// Calibrated site evidence for TajweedFormer, independent of any UI verdict.
library;

import 'tajweedformer_ctc.dart';
import 'tajweedformer_calibration.dart';
import 'tajweedformer_site_candidates.dart';

/// Evidence for one site, or null when the model marks its class as off.
/// The alternative sequences must be generated for the same edit class and
/// site. Calibration values must come from the currently loaded model/context.
class TajweedFormerSiteEvidence {
  const TajweedFormerSiteEvidence(
      {required this.llr,
      required this.exceedsThreshold,
      this.alternativeIndex});

  final double llr;
  final bool exceedsThreshold;

  /// Index in the caller's alternatives; null when none has a possible path.
  final int? alternativeIndex;
}

/// Reuses the two expected-path likelihoods across all sites in one take.
class TajweedFormerSiteScorer {
  TajweedFormerSiteScorer({
    required this.logProbs,
    required List<List<double>> inter1LogProbs,
    required List<int> expected,
    required this.blankId,
    required this.wordBarId,
  }) : _merged = tajweedFormerMergeWordBarIntoBlank(
            logProbabilities: inter1LogProbs,
            blankId: blankId,
            wordBarId: wordBarId) {
    final path = _withoutBar(expected);
    _expectedMain = _likelihood(logProbs, path);
    _expectedInter = _likelihood(_merged, path);
    if (!_expectedMain.isFinite || !_expectedInter.isFinite) {
      throw StateError('Insufficient CTC evidence for the expected sequence');
    }
    _mainScorer = TajweedFormerCtcRescorer(logProbs, path, blankId);
    _interScorer = TajweedFormerCtcRescorer(_merged, path, blankId);
  }

  final List<List<double>> logProbs;
  final List<List<double>> _merged;
  final int blankId;
  final int wordBarId;
  late final double _expectedMain;
  late final double _expectedInter;
  late final TajweedFormerCtcRescorer _mainScorer, _interScorer;

  List<int> _withoutBar(List<int> tokens) =>
      tokens.where((id) => id != wordBarId).toList(growable: false);

  double _likelihood(List<List<double>> head, List<int> tokens) =>
      tajweedFormerCtcLogLikelihood(
          logProbabilities: head, tokens: tokens, blankId: blankId);

  TajweedFormerSiteEvidence? evaluate({
    required List<List<int>> alternatives,
    required TajweedFormerSiteCalibration calibration,
  }) {
    return _evaluate(alternatives.length, calibration, (i) {
      final path = _withoutBar(alternatives[i]);
      return (_likelihood(logProbs, path), _likelihood(_merged, path));
    });
  }

  TajweedFormerSiteEvidence? evaluateEdits({
    required List<TajweedFormerSiteEdit> edits,
    required TajweedFormerSiteCalibration calibration,
  }) =>
      _evaluate(edits.length, calibration, (i) {
        final edit = edits[i];
        if (edit.position < 0 ||
            edit.position >= _mainScorer.tokens.length ||
            _mainScorer.tokens[edit.position] != edit.expected) {
          throw ArgumentError('Edit does not belong to this reference');
        }
        double score(TajweedFormerCtcRescorer scorer) => switch (edit.kind) {
              TajweedFormerEditKind.delete => scorer.delete(edit.position),
              TajweedFormerEditKind.substitute =>
                scorer.replace(edit.position, edit.alternative!),
              TajweedFormerEditKind.insertAfter =>
                scorer.insertAfter(edit.position, edit.alternative!),
            };
        return (score(_mainScorer), score(_interScorer));
      });

  TajweedFormerSiteEvidence? _evaluate(
      int count,
      TajweedFormerSiteCalibration calibration,
      (double, double) Function(int) score) {
    if (!calibration.isValidated) return null;
    if (count == 0 ||
        !calibration.fusionWeight.isFinite ||
        calibration.fusionWeight < 0 ||
        calibration.fusionWeight > 1 ||
        !calibration.threshold.isFinite ||
        !calibration.clipMin.isFinite ||
        !calibration.clipMax.isFinite ||
        calibration.clipMin > calibration.clipMax) {
      throw ArgumentError('Invalid V4 site calibration or alternatives');
    }
    var best = double.negativeInfinity;
    int? bestIndex;
    for (var i = 0; i < count; i++) {
      final (mainScore, interScore) = score(i);
      final main = mainScore - _expectedMain;
      final inter = interScore - _expectedInter;
      final weight = calibration.fusionWeight;
      final fused = weight == 1
          ? main
          : weight == 0
              ? inter
              : weight * main + (1 - weight) * inter;
      if (fused > best) {
        best = fused;
        bestIndex = i;
      }
    }
    final clipped =
        best.clamp(calibration.clipMin, calibration.clipMax).toDouble();
    return TajweedFormerSiteEvidence(
      llr: clipped,
      exceedsThreshold: bestIndex != null && clipped > calibration.threshold,
      alternativeIndex: bestIndex,
    );
  }
}

/// Applies only model-validated site settings. Experimental and disabled
/// classes return no evidence for user-facing feedback.
TajweedFormerSiteEvidence? evaluateCalibratedTajweedFormerSite({
  required List<List<double>> logProbs,
  required List<List<double>> inter1LogProbs,
  required List<int> expected,
  required List<List<int>> alternatives,
  required int blankId,
  required int wordBarId,
  required TajweedFormerSiteCalibration calibration,
}) =>
    evaluateTajweedFormerSite(
      logProbs: logProbs,
      inter1LogProbs: inter1LogProbs,
      expected: expected,
      alternatives: alternatives,
      blankId: blankId,
      wordBarId: wordBarId,
      fusionWeight: calibration.fusionWeight,
      threshold: calibration.threshold,
      clipMin: calibration.clipMin,
      clipMax: calibration.clipMax,
      enabled: calibration.isValidated,
    );

TajweedFormerSiteEvidence? evaluateTajweedFormerSite({
  required List<List<double>> logProbs,
  required List<List<double>> inter1LogProbs,
  required List<int> expected,
  required List<List<int>> alternatives,
  required int blankId,
  required int wordBarId,
  required double fusionWeight,
  required double threshold,
  required double clipMin,
  required double clipMax,
  required bool enabled,
}) {
  if (!enabled) return null;
  if (alternatives.isEmpty ||
      !fusionWeight.isFinite ||
      fusionWeight < 0 ||
      fusionWeight > 1 ||
      !threshold.isFinite ||
      !clipMin.isFinite ||
      !clipMax.isFinite ||
      clipMin > clipMax) {
    throw ArgumentError('Invalid V4 site calibration or alternatives');
  }
  final merged = tajweedFormerMergeWordBarIntoBlank(
    logProbabilities: inter1LogProbs,
    blankId: blankId,
    wordBarId: wordBarId,
  );
  List<int> withoutBar(List<int> tokens) =>
      tokens.where((id) => id != wordBarId).toList(growable: false);
  double likelihood(List<List<double>> head, List<int> tokens) =>
      tajweedFormerCtcLogLikelihood(
          logProbabilities: head, tokens: tokens, blankId: blankId);
  // Both heads score the same sound-only path. The inter1 head additionally
  // merges the word-bar probability into blank before the CTC forward pass.
  final expectedMain = likelihood(logProbs, withoutBar(expected));
  final expectedInter = likelihood(merged, withoutBar(expected));
  if (!expectedMain.isFinite || !expectedInter.isFinite) {
    throw StateError('Insufficient CTC evidence for the expected sequence');
  }
  var bestFused = double.negativeInfinity;
  int? bestAlternativeIndex;
  for (var i = 0; i < alternatives.length; i++) {
    final alternative = alternatives[i];
    final path = withoutBar(alternative);
    final main = likelihood(logProbs, path) - expectedMain;
    final inter = likelihood(merged, path) - expectedInter;
    // At exactly 0 or 1, do not multiply an impossible path by zero.
    final fused = fusionWeight == 1
        ? main
        : fusionWeight == 0
            ? inter
            : fusionWeight * main + (1 - fusionWeight) * inter;
    if (fused > bestFused) {
      bestFused = fused;
      bestAlternativeIndex = i;
    }
  }
  final clipped = bestFused.clamp(clipMin, clipMax).toDouble();
  return TajweedFormerSiteEvidence(
      llr: clipped,
      exceedsThreshold: bestAlternativeIndex != null && clipped > threshold,
      alternativeIndex: bestAlternativeIndex);
}
