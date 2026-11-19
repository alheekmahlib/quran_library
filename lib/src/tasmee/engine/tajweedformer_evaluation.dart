import 'models/recitation_result.dart';
import 'models/tasmee_tolerance.dart';
import 'tajweedformer_alignment.dart';
import 'tajweedformer_calibration.dart';
import 'tajweedformer_coverage.dart';
import 'tajweedformer_head.dart';
import 'tajweedformer_reference.dart';
import 'tajweedformer_site_candidates.dart';
import 'tajweedformer_site_evidence.dart';

/// Evaluates every eligible site using the model's calibrated CTC heads.
///
/// The reference must be a selected legal path corresponding to
/// the audio. Unsupported differences are surfaced as incomplete rather than
/// silently treated as correct. [coverage] records, per calibrated class,
/// whether it was assessed, flagged for review, or left out and why; the
/// `unsupported_differences` entry preserves [incomplete] instead of
/// letting it disappear inside an empty error list.
({
  List<RecitationError> errors,
  bool incomplete,
  Map<String, TajweedFormerCategoryCoverage> coverage
}) evaluateTajweedFormerTake({
  required List<TajweedFormerReferenceUnit> reference,
  required List<int> heard,
  required List<String> tokenNames,
  required int blankId,
  required int wordBarId,
  required Map<String, dynamic> heads,
  required Map<String, dynamic> calibration,
  required String context,
  required int surah,
  required int ayah,
  List<({int surah, int ayah})>? verses,
  String preset = 'balanced',
  TasmeeToleranceProfile? tolerance,
  bool connectedStart = false,
}) {
  final mainMap = heads['log_probs'];
  final interMap = heads['inter1_log_probs'];
  if (mainMap is! Map || interMap is! Map || reference.isEmpty) {
    throw const FormatException('Missing V4 CTC heads or reference');
  }
  final main = TajweedFormerCtcHead.fromMap(Map<String, dynamic>.from(mainMap));
  final inter =
      TajweedFormerCtcHead.fromMap(Map<String, dynamic>.from(interMap));
  if (main.classes != tokenNames.length || inter.classes != tokenNames.length) {
    throw const FormatException('V4 head vocabulary mismatch');
  }
  final path = reference.map((u) => u.tokenId).toList(growable: false);
  // همزة الوصل تُحذف نطقًا عند الوصل إلى ما قبلها؛ إن بدأ المقطع موصولًا
  // (قصّ بداية) فحذف همزة الوصل في أول وحدة سلوك قرآني صحيح لا خطأ،
  // فلا يُرفع له مرشح ولا يُحسب فرقًا غير مدعوم.
  final elideStartHamza = connectedStart &&
      path.isNotEmpty &&
      tokenNames[path.first] == 'ء';
  final clean = heard.where((id) => id != blankId && id != wordBarId).toList();
  if (clean.any((id) => id < 0 || id >= tokenNames.length)) {
    throw const FormatException('Invalid V4 decoded token');
  }
  final ops = alignTajweedFormerTokens(path, clean);
  final windows =
      tajweedFormerSiteWindows(reference: reference, tokenNames: tokenNames);
  final candidates = [for (final window in windows) ...window.edits];
  final coverage = <String, TajweedFormerCategoryCoverage>{
    for (final entry in _siteClassStatuses(
      candidates: candidates,
      calibration: calibration,
      context: context,
      preset: preset,
      tolerance: tolerance,
    ).entries)
      entry.key: entry.value,
  };
  var incomplete = false;
  var previousRef = -1;
  final predictedAt = <int, int>{};
  for (final op in ops) {
    if (op.referenceIndex != null && op.predictedIndex != null) {
      predictedAt[op.referenceIndex!] = op.predictedIndex!;
    }
    if (op.kind == TajweedFormerAlignmentKind.match) {
      previousRef = op.referenceIndex!;
      continue;
    }
    final pos = op.referenceIndex ?? previousRef;
    if (pos < 0 || pos >= path.length) {
      incomplete = true;
      continue;
    }
    if (elideStartHamza &&
        pos == 0 &&
        op.kind == TajweedFormerAlignmentKind.delete) {
      // حذف همزة الوصل المتوقعة عند بداية موصولة — ليست فرقًا.
      if (op.referenceIndex != null) previousRef = op.referenceIndex!;
      continue;
    }
    final alt = op.predictedIndex == null ? null : clean[op.predictedIndex!];
    final kind = switch (op.kind) {
      TajweedFormerAlignmentKind.replace => TajweedFormerEditKind.substitute,
      TajweedFormerAlignmentKind.delete => TajweedFormerEditKind.delete,
      TajweedFormerAlignmentKind.insert => TajweedFormerEditKind.insertAfter,
      TajweedFormerAlignmentKind.match => throw StateError('Unexpected match'),
    };
    final matches = candidates.where(
        (e) => e.kind == kind && e.position == pos && e.alternative == alt);
    if (matches.isEmpty) {
      incomplete = true;
    } else {
      final siteClass = matches.first.siteClass;
      final level = _levelForClass(tolerance, siteClass);
      if (level == TasmeeToleranceLevel.skip) {
        incomplete = true;
        if (op.referenceIndex != null) previousRef = op.referenceIndex!;
        continue;
      }
      final settings = tryReadTajweedFormerSiteCalibration(
        calibration: calibration,
        context: context,
        preset: level?.v4Preset.name ?? preset,
        siteClass: siteClass,
      );
      if (settings == null || !settings.isValidated) {
        incomplete = true;
        // الفرق المنطوق يقع على صنف لا يجوز لهذا النموذج الحكم عليه:
        // الفئة غير حاسمة بسببه الدقيق، لا «مُقيَّمة صافية».
        final reason = settings == null
            ? TajweedFormerCoverageReason.missingCalibration
            : settings.status == 'off'
                ? TajweedFormerCoverageReason.calibrationDisabled
                : TajweedFormerCoverageReason.calibrationExperimental;
        final existing = coverage[siteClass];
        if (existing != null &&
            existing.state != TajweedFormerCoverageState.candidateNeedsReview &&
            existing.state != TajweedFormerCoverageState.inconclusive) {
          coverage[siteClass] = TajweedFormerCategoryCoverage(
            state: TajweedFormerCoverageState.inconclusive,
            reason: reason,
            sites: existing.sites,
          );
        }
      }
    }
    if (op.referenceIndex != null) previousRef = op.referenceIndex!;
  }
  coverage['unsupported_differences'] = TajweedFormerCategoryCoverage(
    state: incomplete
        ? TajweedFormerCoverageState.inconclusive
        : TajweedFormerCoverageState.evaluatedNoCandidate,
    reason:
        incomplete ? TajweedFormerCoverageReason.unsupportedDifference : null,
  );
  final scorer = TajweedFormerSiteScorer(
    logProbs: main.toRows(),
    inter1LogProbs: inter.toRows(),
    expected: path,
    blankId: blankId,
    wordBarId: wordBarId,
  );
  final errors = <RecitationError>[];
  final flaggedClasses = <String>{};
  for (final window in windows) {
    final byClass = <String, List<TajweedFormerSiteEdit>>{};
    for (final edit in window.edits) {
      if (elideStartHamza &&
          edit.position == 0 &&
          edit.kind == TajweedFormerEditKind.delete &&
          edit.siteClass == 'cons_del') {
        continue;
      }
      (byClass[edit.siteClass] ??= []).add(edit);
    }
    TajweedFormerSiteEdit? selected;
    var bestLlr = double.negativeInfinity;
    for (final entry in byClass.entries) {
      final level = _levelForClass(tolerance, entry.key);
      if (level == TasmeeToleranceLevel.skip) continue;
      final settings = tryReadTajweedFormerSiteCalibration(
        calibration: calibration,
        context: context,
        preset: level?.v4Preset.name ?? preset,
        siteClass: entry.key,
      );
      // صنف بلا معايرة أو غير مُعتمد يُتخطى في التقييم، وحالته مسجلة
      // أصلًا في تغطية الفئة — لا استثناء ولا حكم.
      if (settings == null || !settings.isValidated) continue;
      final evidence = scorer.evaluateEdits(
        edits: entry.value,
        calibration: settings,
      );
      if (evidence == null || !evidence.exceedsThreshold) continue;
      if (evidence.llr > bestLlr) {
        bestLlr = evidence.llr;
        selected = entry.value[evidence.alternativeIndex!];
      }
    }
    if (selected != null) {
      flaggedClasses.add(selected.siteClass);
      final edit = selected;
      final pos = edit.position;
      final unit = reference[pos];
      if (verses != null && unit.verseIndex >= verses.length) {
        throw const FormatException('V4 verse position is out of range');
      }
      final location =
          verses == null ? (surah: surah, ayah: ayah) : verses[unit.verseIndex];
      final predictedIndex = predictedAt[pos] ?? 0;
      errors.add(RecitationError(
        errorType: edit.siteClass.startsWith('cons_') ? 'normal' : 'tashkeel',
        speechErrorType: switch (edit.kind) {
          TajweedFormerEditKind.substitute => 'replace',
          TajweedFormerEditKind.delete => 'delete',
          TajweedFormerEditKind.insertAfter => 'insert',
        },
        expectedPh: edit.kind == TajweedFormerEditKind.insertAfter
            ? null
            : tokenNames[path[pos]],
        predictedPh:
            edit.alternative == null ? null : tokenNames[edit.alternative!],
        uthmaniPos: [pos, pos + 1],
        phPos: [predictedIndex, predictedIndex + 1],
        suraIdx: location.surah,
        ayaIdx: location.ayah,
        wordIdx: unit.wordIndex,
      ));
    }
  }
  for (final entry in coverage.entries.toList()) {
    if (flaggedClasses.contains(entry.key)) {
      coverage[entry.key] = TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.candidateNeedsReview,
        sites: entry.value.sites,
      );
    }
  }
  return (
    errors: List.unmodifiable(errors),
    incomplete: incomplete,
    coverage: Map.unmodifiable(coverage),
  );
}

/// Initial per-class coverage from the calibration, before scoring:
/// validated classes start assessed-clear, `off` classes disabled,
/// experimental classes blocked until diagnostics are explicitly enabled,
/// and a class with no candidate in this path is reported absent with a
/// reason instead of silently missing from the map.
const _siteCoverageClasses = [
  'cons_sub',
  'vowel_sub',
  'short_to_long',
  'long_to_short',
  'cons_del',
  'vowel_del',
  'vowel_ins',
];

Map<String, TajweedFormerCategoryCoverage> _siteClassStatuses({
  required List<TajweedFormerSiteEdit> candidates,
  required Map<String, dynamic> calibration,
  required String context,
  required String preset,
  TasmeeToleranceProfile? tolerance,
}) {
  final result = <String, TajweedFormerCategoryCoverage>{};
  // المواقع الفعلية لكل صنف: تعديلات كثيرة قد تشارك الموضع نفسه.
  final positionsPerClass = <String, Set<int>>{};
  for (final candidate in candidates) {
    (positionsPerClass[candidate.siteClass] ??= {}).add(candidate.position);
  }
  for (final key in _siteCoverageClasses) {
    final level = _levelForClass(tolerance, key);
    if (level == TasmeeToleranceLevel.skip) {
      result[key] = const TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.notEvaluated,
        reason: TajweedFormerCoverageReason.skippedByUser,
      );
      continue;
    }
    final classPreset = level?.v4Preset.name ?? preset;
    final positions = positionsPerClass[key];
    if (positions == null) {
      // لا مرشح لهذا الصنف في مسار هذه اللقطة: سجّل غيابه بسببه. إن
      // كانت المعايرة نفسها لا تعرف الصنف فذلك هو السبب الأدق.
      final calibrated = tryReadTajweedFormerSiteCalibration(
            calibration: calibration,
            context: context,
            preset: classPreset,
            siteClass: key,
          ) !=
          null;
      result[key] = TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.notEvaluated,
        reason: calibrated
            ? TajweedFormerCoverageReason.noEligibleSites
            : TajweedFormerCoverageReason.missingCalibration,
      );
      continue;
    }
    final settings = tryReadTajweedFormerSiteCalibration(
      calibration: calibration,
      context: context,
      preset: classPreset,
      siteClass: key,
    );
    if (settings == null) {
      result[key] = const TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.notEvaluated,
        reason: TajweedFormerCoverageReason.missingCalibration,
      );
      continue;
    }
    switch (settings.status) {
      case 'validated':
        result[key] = TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.evaluatedNoCandidate,
          sites: positions.length,
        );
      case 'off':
        result[key] = const TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.notEvaluated,
          reason: TajweedFormerCoverageReason.calibrationDisabled,
        );
      default:
        result[key] = const TajweedFormerCategoryCoverage(
          state: TajweedFormerCoverageState.notEvaluated,
          reason: TajweedFormerCoverageReason.calibrationExperimental,
        );
    }
  }
  return result;
}

TasmeeToleranceLevel? _levelForClass(
    TasmeeToleranceProfile? profile, String siteClass) {
  if (profile == null) return null;
  return siteClass.startsWith('cons_') ? profile.letters : profile.tashkeel;
}
