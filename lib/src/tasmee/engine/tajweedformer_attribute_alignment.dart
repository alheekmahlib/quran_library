/// Conservative shared setup for V4 per-letter attribute evidence.
library;

import 'tajweedformer_coverage.dart';
import 'tajweedformer_head.dart';
import 'tajweedformer_reference.dart';
import 'tajweedformer_timing.dart';

class TajweedFormerAlignedAttribute {
  TajweedFormerAlignedAttribute({
    required this.head,
    required this.spans,
    required this.threshold,
    required this.canonicalIndices,
  });

  final TajweedFormerProbabilityHead head;
  final List<({int start, int end})> spans;
  final double threshold;
  final Map<int, List<int>> canonicalIndices;
}

TajweedFormerAlignedAttribute? alignTajweedFormerAttribute({
  required List<TajweedFormerReferenceUnit> reference,
  required List<int> heard,
  required List<String> tokenNames,
  required int blankId,
  required Map<String, dynamic> heads,
  required Map<String, dynamic> calibration,
  required String context,
  required List<({int surah, int ayah})> verses,
  required Map<String, dynamic> timingReferences,
  required String attributeName,
  required String calibrationName,
  required int classes,
  required String preset,
  required bool allowExperimental,
}) {
  final contexts = calibration['contexts'];
  final selected = contexts is Map ? contexts[context] : null;
  final settings = selected is Map ? selected[calibrationName] : null;
  if (settings is! Map ||
      (settings['status'] != 'validated' &&
          !(allowExperimental && settings['status'] == 'experimental'))) {
    return null;
  }
  if (heard.length != reference.length) return null;
  for (var i = 0; i < heard.length; i++) {
    if (heard[i] != reference[i].tokenId) return null;
  }
  final rawTiming = heads['timing_log_probs'];
  final rawAttribute = heads[attributeName];
  if (rawTiming == null || rawAttribute == null) return null;
  if (rawTiming is! Map || rawAttribute is! Map) {
    throw const FormatException('Invalid V4 attribute heads');
  }
  final timing =
      TajweedFormerCtcHead.fromMap(Map<String, dynamic>.from(rawTiming));
  final attribute = TajweedFormerProbabilityHead.fromMap(
      Map<String, dynamic>.from(rawAttribute));
  if (timing.classes != tokenNames.length ||
      attribute.classes != classes ||
      timing.frames != attribute.frames ||
      timing.frameMs != attribute.frameMs ||
      timing.frameMs != 20) {
    throw const FormatException('V4 attribute head mismatch');
  }
  final presetTau = settings['preset_tau'];
  final rawTau =
      presetTau is Map ? presetTau[preset] ?? settings['tau'] : settings['tau'];
  if (rawTau is! num || !rawTau.isFinite || rawTau < 0 || rawTau > 1) {
    throw const FormatException('Invalid V4 attribute threshold');
  }
  final spans = alignTajweedFormerTiming(
      head: timing, reference: reference, blankId: blankId);
  if (spans == null) return null;
  final canonical = <int, List<int>>{};
  for (var verseIndex = 0; verseIndex < verses.length; verseIndex++) {
    final verse = verses[verseIndex];
    final raw = timingReferences['${verse.surah}:${verse.ayah}'];
    if (raw is! Map || raw['tokens'] is! List) continue;
    final indices = <int>[
      for (var i = 0; i < reference.length; i++)
        if (reference[i].verseIndex == verseIndex) i,
    ];
    final expected = raw['tokens'] as List;
    if (indices.length != expected.length) continue;
    var matches = true;
    for (var i = 0; i < indices.length; i++) {
      if (tokenNames[reference[indices[i]].tokenId] != expected[i]) {
        matches = false;
        break;
      }
    }
    if (matches) canonical[verseIndex] = indices;
  }
  return TajweedFormerAlignedAttribute(
      head: attribute,
      spans: spans,
      threshold: rawTau.toDouble(),
      canonicalIndices: canonical);
}

/// Why an attribute evaluator cannot run at all, or null when it can.
/// Mirrors the eligibility checks of [alignTajweedFormerAttribute] so the
/// empty result of a blocked evaluator keeps its reason instead of looking
/// like a checked-clear category.
TajweedFormerCoverageReason? reasonTajweedFormerAttributeUnavailable({
  required List<TajweedFormerReferenceUnit> reference,
  required List<int> heard,
  required Map<String, dynamic> heads,
  required Map<String, dynamic> calibration,
  required String context,
  required String attributeName,
  required String calibrationName,
  required bool allowExperimental,
}) {
  final contexts = calibration['contexts'];
  final selected = contexts is Map ? contexts[context] : null;
  final settings = selected is Map ? selected[calibrationName] : null;
  if (settings is! Map) {
    return TajweedFormerCoverageReason.missingCalibration;
  }
  final status = settings['status'];
  if (status != 'validated' &&
      !(allowExperimental && status == 'experimental')) {
    return status == 'off' || status is! String
        ? TajweedFormerCoverageReason.calibrationDisabled
        : TajweedFormerCoverageReason.calibrationExperimental;
  }
  if (heard.length != reference.length) {
    return TajweedFormerCoverageReason.pathNotEligible;
  }
  for (var i = 0; i < heard.length; i++) {
    if (heard[i] != reference[i].tokenId) {
      return TajweedFormerCoverageReason.pathNotEligible;
    }
  }
  final rawTiming = heads['timing_log_probs'];
  final rawAttribute = heads[attributeName];
  if (rawTiming == null || rawAttribute == null) {
    return TajweedFormerCoverageReason.missingHead;
  }
  return null;
}
