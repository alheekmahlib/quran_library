/// Ghunna and ikhfa: a declared-unsupported category with an extension path.
///
/// What is known from the SDK's published contract (Quran Lab skill
/// reference page `ref/reference.md`, "The reference"): the model exposes
/// its tajweed attributes as heads, and `attr_ghunna` is among them; the
/// public phonetics dataset carries the ghunna kinds (`asl`, `mushaddadah`,
/// `ikhfa`, `idgham`) with their lengths per phone.
///
/// What is missing before any judgment: the calibration served with this
/// model build has no ghunna section (no status, thresholds or tau), and
/// the `attr_ghunna` head's class layout is not documented for this build,
/// so no window, threshold or meaning can be applied honestly. No ghunna
/// or ikhfa verdict may be inferred from a written reference, from the
/// nasal token `ں` alone, or from the absence of flagged candidates.
///
/// Extension path: when a model build ships a documented `attr_ghunna`
/// class layout together with a calibration section for it,
/// [describeTajweedFormerGhunnaCoverage] flips from `signalUnsupported` to
/// `evaluatorNotImplemented`, which is the signal to write the evaluator
/// against that calibration and add its coverage entries here.
library;

import 'tajweedformer_coverage.dart';

/// Coverage entry for the ghunna and ikhfa categories on a V4 take.
///
/// Checks only whether the served calibration has become ghunna-capable;
/// it never produces, simulates or promises a verdict.
TajweedFormerCategoryCoverage describeTajweedFormerGhunnaCoverage({
  required Map<String, dynamic> calibration,
  required String context,
}) {
  final contexts = calibration['contexts'];
  final selected = contexts is Map ? contexts[context] : null;
  final settings = selected is Map ? selected['ghunna'] : null;
  if (settings is! Map) {
    return const TajweedFormerCategoryCoverage(
      state: TajweedFormerCoverageState.notEvaluated,
      reason: TajweedFormerCoverageReason.signalUnsupported,
    );
  }
  // A calibration section exists. Its class layout and thresholds still
  // have no documented meaning for this library: implementing a judge here
  // without that documentation would be inventing a verdict.
  final status = settings['status'];
  if (status == 'validated' || status == 'experimental') {
    return const TajweedFormerCategoryCoverage(
      state: TajweedFormerCoverageState.notEvaluated,
      reason: TajweedFormerCoverageReason.evaluatorNotImplemented,
    );
  }
  return const TajweedFormerCategoryCoverage(
    state: TajweedFormerCoverageState.notEvaluated,
    reason: TajweedFormerCoverageReason.calibrationDisabled,
  );
}
