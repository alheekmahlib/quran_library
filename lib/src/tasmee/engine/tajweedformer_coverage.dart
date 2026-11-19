/// Serializable assessment coverage for a TajweedFormer V4 take.
///
/// Coverage records what each evaluation category went through on one take.
/// It is deliberately separate from three other notions:
/// - correctness: no state here means "recited correctly";
/// - live match progress: matched words are neutral progress, not coverage;
/// - completeness: a covered category still does not make the whole result
///   complete ([RecitationResult.assessmentComplete] stays false for V4).
///
/// Category names are a stable serialization contract for hosts that save
/// results. They name evaluation classes, not rulings.
library;

/// What happened to one category on one take.
enum TajweedFormerCoverageState {
  /// The category was not assessed for this take; [reason] says why.
  notEvaluated,

  /// Calibrated evidence was checked and raised no candidate.
  evaluatedNoCandidate,

  /// A calibrated candidate exceeded its threshold. It awaits review and is
  /// not a validated learner verdict.
  candidateNeedsReview,

  /// The category was attempted but this take cannot decide it: partial,
  /// unmatched or otherwise undecidable evidence.
  inconclusive,
}

/// Why a category stayed unassessed or undecidable.
enum TajweedFormerCoverageReason {
  /// The user chose to skip this diagnostic category.
  skippedByUser,

  /// The take matched no legal reference path.
  noMatchedPath,

  /// The model exposed no head for this category.
  missingHead,

  /// No canonical reference metadata covers the assessed range.
  missingReference,

  /// The model's calibration has no section for this category.
  missingCalibration,

  /// The calibration explicitly disables the category (`off`).
  calibrationDisabled,

  /// The calibration marks the category experimental and explicit
  /// diagnostics were not enabled.
  calibrationExperimental,

  /// The category requires an exactly matched path; this take's path
  /// differed (partial recitation, alternate form or unmatched units).
  pathNotEligible,

  /// The decoded audio differs in a way no calibrated candidate class
  /// covers; the take stays incomplete for this category.
  unsupportedDifference,

  /// Too few eligible sites to normalize the category on this take.
  tooFewSites,

  /// The take's reference path contains no site this category could
  /// evaluate, so no candidate was generated for it at all.
  noEligibleSites,

  /// The take carried no audio signal at all (literal silence): nothing
  /// reached the model, so no category was attempted.
  noUsableSignal,

  /// No usable model signal is exposed for this category today; see the
  /// ghunna/ikhfa note before promising a verdict.
  signalUnsupported,

  /// A signal and calibration exist but this library implements no judge
  /// for them yet.
  evaluatorNotImplemented,
}

/// Coverage of a single evaluation category.
class TajweedFormerCategoryCoverage {
  const TajweedFormerCategoryCoverage({
    required this.state,
    this.reason,
    this.sites,
    this.unassessed,
  });

  final TajweedFormerCoverageState state;

  /// سبب عدم التقييم/التعذّر لحالتي `notEvaluated` و`inconclusive`. قد
  /// يرافق أيضًا حالة مقيمة (`candidateNeedsReview`/`evaluatedNoCandidate`)
  /// ليشرح وحداتها المتعذرة في [unassessed] عند وجودها.
  ///
  /// Required for `notEvaluated` and `inconclusive`; may also accompany an
  /// assessed state to explain its [unassessed] units when there are any.
  final TajweedFormerCoverageReason? reason;

  /// Number of eligible sites this category assessed, when it was assessed.
  final int? sites;

  /// عدد وحدات التقييم (مواضع، أو مقاطع/آيات كاملة عند تعذّر عدّ
  /// المواضع) التي تعذّر تقييمها ضمن هذه الفئة رغم محاولة ذلك.
  ///
  /// Assessment units (sites, or whole segments/verses when sites cannot
  /// be counted) that could not be assessed even though the category ran.
  /// Non-zero with an assessed state marks partial coverage: something was
  /// checked, something else was not, and its reason belongs in [reason]
  /// when the state allows one.
  final int? unassessed;

  Map<String, dynamic> toJson() => {
        'state': state.name,
        if (reason != null) 'reason': reason!.name,
        if (sites != null) 'sites': sites,
        if (unassessed != null) 'unassessed': unassessed,
      };

  static TajweedFormerCategoryCoverage fromJson(Map<String, dynamic> json) {
    final state = TajweedFormerCoverageState.values
        .where((v) => v.name == json['state'])
        .firstOrNull;
    if (state == null) {
      throw const FormatException('Invalid V4 coverage state');
    }
    final reasonName = json['reason'];
    final reason = reasonName == null
        ? null
        : TajweedFormerCoverageReason.values
            .where((v) => v.name == reasonName)
            .firstOrNull;
    if (reasonName != null && reason == null) {
      throw const FormatException('Invalid V4 coverage reason');
    }
    final sites = json['sites'];
    if (sites != null && sites is! int) {
      throw const FormatException('Invalid V4 coverage site count');
    }
    final unassessed = json['unassessed'];
    if (unassessed != null && unassessed is! int) {
      throw const FormatException('Invalid V4 unassessed count');
    }
    if ((state == TajweedFormerCoverageState.notEvaluated ||
            state == TajweedFormerCoverageState.inconclusive) &&
        reason == null) {
      throw const FormatException('V4 coverage state requires a reason');
    }
    return TajweedFormerCategoryCoverage(
      state: state,
      reason: reason,
      sites: sites is int ? sites : null,
      unassessed: unassessed is int ? unassessed : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TajweedFormerCategoryCoverage &&
      other.state == state &&
      other.reason == reason &&
      other.sites == sites &&
      other.unassessed == unassessed;

  @override
  int get hashCode => Object.hash(state, reason, sites, unassessed);
}

/// Whole-take coverage: one entry per evaluation category.
class TajweedFormerTakeCoverage {
  const TajweedFormerTakeCoverage({required this.categories});

  final Map<String, TajweedFormerCategoryCoverage> categories;

  Map<String, dynamic> toJson() => {
        for (final entry in categories.entries) entry.key: entry.value.toJson(),
      };

  static TajweedFormerTakeCoverage fromJson(Map<String, dynamic> json) {
    return TajweedFormerTakeCoverage(categories: {
      for (final entry in json.entries)
        if (entry.value is Map)
          entry.key: TajweedFormerCategoryCoverage.fromJson(
              Map<String, dynamic>.from(entry.value as Map)),
    });
  }

  @override
  bool operator ==(Object other) {
    if (other is! TajweedFormerTakeCoverage) return false;
    if (other.categories.length != categories.length) return false;
    for (final entry in categories.entries) {
      if (!other.categories.containsKey(entry.key)) return false;
      if (other.categories[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered([
        for (final entry in categories.entries)
          Object.hash(entry.key, entry.value)
      ]);
}

/// Every standard category, unassessed for one reason.
///
/// Used when a take produced no usable evidence at all (no matched path, no
/// heads): an empty error list alone must never imply the rules were checked.
TajweedFormerTakeCoverage unassessedTajweedFormerCoverage(
    TajweedFormerCoverageReason reason) {
  return TajweedFormerTakeCoverage(categories: {
    for (final key in tajweedFormerCoverageCategoryKeys)
      key: const TajweedFormerCategoryCoverage(
              state: TajweedFormerCoverageState.notEvaluated)
          .withReason(reason),
  });
}

/// Category keys this library reports for a V4 take. CTC site classes keep
/// the model calibration's own names; the rest name rule families.
const tajweedFormerCoverageCategoryKeys = [
  'cons_sub',
  'vowel_sub',
  'short_to_long',
  'long_to_short',
  'cons_del',
  'vowel_del',
  'vowel_ins',
  'unsupported_differences',
  'madd',
  'qalqalah',
  'gemination',
  'ghunna',
  'ikhfa',
];

extension TajweedFormerCategoryCoverageReasonOn
    on TajweedFormerCategoryCoverage {
  TajweedFormerCategoryCoverage withReason(
          TajweedFormerCoverageReason reason) =>
      TajweedFormerCategoryCoverage(state: state, reason: reason, sites: sites);
}

/// Merges the coverage of consecutive segments without turning partial
/// coverage into a complete assessment, and without hiding that a segment
/// failed to assess a category another segment did assess.
///
/// Per category:
/// - a flagged candidate anywhere wins the state, but the unassessed units
///   of the other segments are still counted;
/// - a category assessed clear in **every** segment that mentions it is
///   `evaluatedNoCandidate`;
/// - a category assessed in some segments and blocked in others becomes
///   `inconclusive` carrying the first blocking reason — the failure is
///   never absorbed into "checked clear";
/// - a category no segment could assess keeps the strongest blocked state
///   and its reason.
/// Site counts of assessed segments add up.
TajweedFormerTakeCoverage mergeTajweedFormerCoverage(
    List<TajweedFormerTakeCoverage> segments) {
  final keys = <String>{
    for (final segment in segments) ...segment.categories.keys,
  };
  return TajweedFormerTakeCoverage(categories: {
    for (final key in keys)
      key: _mergeCategory([
        for (final segment in segments) segment.categories[key]
      ].whereType<TajweedFormerCategoryCoverage>().toList()),
  });
}

bool _isAssessed(TajweedFormerCoverageState state) =>
    state == TajweedFormerCoverageState.evaluatedNoCandidate ||
    state == TajweedFormerCoverageState.candidateNeedsReview;

TajweedFormerCategoryCoverage _mergeCategory(
    List<TajweedFormerCategoryCoverage> entries) {
  final flagged = entries
      .any((e) => e.state == TajweedFormerCoverageState.candidateNeedsReview);
  final assessed = entries.where((e) => _isAssessed(e.state)).toList();
  final blocked = entries.where((e) => !_isAssessed(e.state)).toList();
  // العدادات تُجمع من كل السجلات التي تحملها مهما كانت حالتها: مقطع
  // «غير حاسم» يحمل مواضع مقيسة لا يفقدها الدمج، ومقطع «مرشّح» يحمل
  // وحدات متعذرة كذلك — حتى عند دمج سجل واحد.
  var sites = 0;
  var anySites = false;
  var unassessed = 0;
  var anyUnassessed = false;
  for (final entry in entries) {
    if (entry.sites != null) {
      sites += entry.sites!;
      anySites = true;
    }
    if (entry.unassessed != null) {
      unassessed += entry.unassessed!;
      anyUnassessed = true;
    }
  }
  for (final entry in blocked) {
    // مقطع تعذّرت فيه الفئة بلا عدّاد صريح = وحدة تقييم كاملة تعذّرت.
    if (entry.unassessed == null) {
      unassessed += 1;
      anyUnassessed = true;
    }
  }
  // السبب المفضّل: من مقطع تعذّر أولًا، وإلا سبب جزئي مرافق لحالة مقيمة.
  TajweedFormerCoverageReason? reason;
  for (final entry in blocked) {
    if (entry.reason != null) {
      reason = entry.reason;
      break;
    }
  }
  if (reason == null) {
    for (final entry in assessed) {
      if (entry.reason != null) {
        reason = entry.reason;
        break;
      }
    }
  }
  if (flagged) {
    return TajweedFormerCategoryCoverage(
      state: TajweedFormerCoverageState.candidateNeedsReview,
      reason: reason,
      sites: anySites ? sites : null,
      unassessed: anyUnassessed ? unassessed : null,
    );
  }
  if (blocked.isEmpty) {
    return TajweedFormerCategoryCoverage(
      state: TajweedFormerCoverageState.evaluatedNoCandidate,
      sites: anySites ? sites : null,
      unassessed: anyUnassessed ? unassessed : null,
    );
  }
  if (assessed.isNotEmpty) {
    // مقطع قيّم هذه الفئة وآخر تعذّر عليه: الحالة الكلية غير حاسمة
    // والسبب البادئ من المقطع المتعذّر محفوظ لا ممحو.
    return TajweedFormerCategoryCoverage(
      state: TajweedFormerCoverageState.inconclusive,
      reason: reason,
      sites: anySites ? sites : null,
      unassessed: anyUnassessed ? unassessed : null,
    );
  }
  // Nothing assessed anywhere: keep the strongest blocked state as-is.
  TajweedFormerCategoryCoverage? best;
  int rank(TajweedFormerCategoryCoverage entry) => switch (entry.state) {
        TajweedFormerCoverageState.inconclusive => 1,
        TajweedFormerCoverageState.notEvaluated => 0,
        _ => throw StateError('unreachable'),
      };
  for (final entry in blocked) {
    if (best == null || rank(entry) > rank(best)) best = entry;
  }
  return TajweedFormerCategoryCoverage(
    state: best!.state,
    reason: best.reason ?? reason,
    sites: anySites ? sites : null,
    unassessed: anyUnassessed ? unassessed : null,
  );
}
