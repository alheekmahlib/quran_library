/// Madd observations from V4's timing head and its published calibration.
/// The canonical metadata is only used when the whole verse path matches.
/// [coverage] records why madd stayed unassessed whenever no error is
/// returned: an empty list alone never means the madd sites were checked.
library;

import 'models/recitation_result.dart';
import 'tajweedformer_coverage.dart';
import 'tajweedformer_head.dart';
import 'tajweedformer_reference.dart';
import 'tajweedformer_timing.dart';

({List<RecitationError> errors, TajweedFormerCategoryCoverage coverage})
    evaluateTajweedFormerMadd({
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
  // Forced timing alignment always attempts the entire reference, including
  // sounds the decoder did not hear. Do not measure those artificial spans.
  if (heard.length != reference.length ||
      [
        for (var i = 0; i < heard.length; i++)
          if (heard[i] != reference[i].tokenId) i,
      ].isNotEmpty) {
    return (
      errors: const [],
      coverage: const TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.notEvaluated,
        reason: TajweedFormerCoverageReason.pathNotEligible,
      ),
    );
  }
  final rawHead = heads['timing_log_probs'];
  final contexts = calibration['contexts'];
  final selected = contexts is Map ? contexts[context] : null;
  final settings = selected is Map ? selected['madd'] : null;
  final status = settings is Map ? settings['status'] : null;
  if (rawHead is! Map) {
    return (
      errors: const [],
      coverage: const TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.notEvaluated,
        reason: TajweedFormerCoverageReason.missingHead,
      ),
    );
  }
  if (settings is! Map) {
    return (
      errors: const [],
      coverage: const TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.notEvaluated,
        reason: TajweedFormerCoverageReason.missingCalibration,
      ),
    );
  }
  if (status != 'validated') {
    return (
      errors: const [],
      coverage: TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.notEvaluated,
        reason: status == 'off'
            ? TajweedFormerCoverageReason.calibrationDisabled
            : TajweedFormerCoverageReason.calibrationExperimental,
      ),
    );
  }
  final head = TajweedFormerCtcHead.fromMap(Map<String, dynamic>.from(rawHead));
  if (head.classes != tokenNames.length) {
    throw const FormatException('Timing vocabulary mismatch');
  }
  final spans = alignTajweedFormerTiming(
      head: head, reference: reference, blankId: blankId);
  if (spans == null) {
    return (
      errors: const [],
      coverage: const TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.notEvaluated,
        reason: TajweedFormerCoverageReason.pathNotEligible,
      ),
    );
  }
  final shorts = <int>[];
  for (var i = 0; i < reference.length; i++) {
    if (const {'a', 'i', 'u'}.contains(tokenNames[reference[i].tokenId]) &&
        spans[i].start >= 0) {
      shorts.add(spans[i].end - spans[i].start);
    }
  }
  final minimum = settings['min_short_vowels'];
  if (minimum is! int || minimum < 1 || shorts.length < minimum) {
    return (
      errors: const [],
      coverage: const TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.notEvaluated,
        reason: TajweedFormerCoverageReason.tooFewSites,
      ),
    );
  }
  shorts.sort();
  final m = shorts.length ~/ 2;
  final unit = shorts.length.isOdd
      ? shorts[m].toDouble()
      : (shorts[m - 1] + shorts[m]) / 2;
  if (unit <= 0) {
    return (
      errors: const [],
      coverage: const TajweedFormerCategoryCoverage(
        state: TajweedFormerCoverageState.notEvaluated,
        reason: TajweedFormerCoverageReason.tooFewSites,
      ),
    );
  }
  final presets = settings['preset_cuts'];
  final presetCuts = presets is Map ? presets[preset] : null;
  final defaultCuts = settings['cuts'];
  final errors = <RecitationError>[];
  var canonicalVerses = 0;
  var checkedSites = 0;
  var disabledSites = 0;
  var unalignedSites = 0;
  for (var verseIndex = 0; verseIndex < verses.length; verseIndex++) {
    final verse = verses[verseIndex];
    final raw = timingReferences['${verse.surah}:${verse.ayah}'];
    if (raw is! Map || raw['tokens'] is! List || raw['madd'] is! List) continue;
    final indices = <int>[
      for (var i = 0; i < reference.length; i++)
        if (reference[i].verseIndex == verseIndex) i,
    ];
    final tokens = raw['tokens'] as List;
    if (indices.length != tokens.length) continue;
    var matches = true;
    for (var i = 0; i < indices.length; i++) {
      if (tokenNames[reference[indices[i]].tokenId] != tokens[i]) {
        matches = false;
        break;
      }
    }
    if (!matches) continue;
    canonicalVerses++;
    for (final item in raw['madd'] as List) {
      if (item is! Map ||
          item['unit'] is! int ||
          item['class'] is! String ||
          item['allowed'] is! List ||
          item['name_ar'] is! String ||
          item['name_en'] is! String) {
        throw const FormatException('Invalid V4 madd reference');
      }
      final pos = item['unit'] as int;
      if (pos < 0 || pos >= indices.length) {
        throw const FormatException('Invalid V4 madd position');
      }
      final cls = item['class'] as String;
      final fallback = defaultCuts is Map ? defaultCuts[cls] : null;
      final cuts = presetCuts is Map ? presetCuts[cls] ?? fallback : fallback;
      if (cuts is! Map ||
          cuts['status'] == 'off' ||
          cuts['2|4'] is! num ||
          cuts['4|6'] is! num) {
        disabledSites++;
        continue;
      }
      final cut24 = (cuts['2|4'] as num).toDouble();
      final cut46 = (cuts['4|6'] as num).toDouble();
      if (!cut24.isFinite || !cut46.isFinite || cut24 < 0 || cut46 < cut24) {
        throw const FormatException('Invalid V4 madd cuts');
      }
      final i = indices[pos], span = spans[i];
      if (span.start < 0) {
        // الموقع موجود في المرجع لكن المحاذاة الزمنية لم تغطّه — غير مقيم.
        unalignedSites++;
        continue;
      }
      checkedSites++;
      final ratio = (span.end - span.start) / unit;
      final count = ratio < cut24
          ? 2
          : ratio < cut46
              ? 4
              : 6;
      final allowed = (item['allowed'] as List).whereType<int>().toList();
      if (allowed.isEmpty) {
        throw const FormatException('Missing V4 madd lengths');
      }
      if (allowed.contains(count)) continue;
      errors.add(RecitationError(
        errorType: 'tajweed',
        speechErrorType: 'replace',
        expectedLen: allowed.length == 1 ? allowed.first : null,
        predictedLen: count,
        expectedPh: tokenNames[reference[i].tokenId],
        suraIdx: verse.surah,
        ayaIdx: verse.ayah,
        wordIdx: reference[i].wordIndex,
        refTajweedRules: [
          TajweedRule(
              nameAr: item['name_ar'] as String,
              nameEn: item['name_en'] as String,
              correctnessType: 'count')
        ],
      ));
    }
  }
  return (
    errors: List.unmodifiable(errors),
    coverage: _maddCoverage(
      errors: errors,
      verses: verses.length,
      canonicalVerses: canonicalVerses,
      checkedSites: checkedSites,
      disabledSites: disabledSites,
      unalignedSites: unalignedSites,
    ),
  );
}

TajweedFormerCategoryCoverage _maddCoverage({
  required List<RecitationError> errors,
  required int verses,
  required int canonicalVerses,
  required int checkedSites,
  required int disabledSites,
  required int unalignedSites,
}) {
  // وحدات تعذّر تقييمها: مواضع داخل آيات مقارَنة (معايرة أو محاذاة)،
  // وآيات كاملة لم يمكن مقارنتها بالمرجع القانوني.
  final unassessedSites = disabledSites + unalignedSites;
  final unassessedVerses = verses - canonicalVerses;
  final unassessed = unassessedSites + unassessedVerses;
  // سبب التعذّر الدقيق: آيات غير مقارَنة تسبق مواضع معطلة داخل آية مقارَنة.
  final TajweedFormerCoverageReason? reason;
  if (unassessedVerses > 0) {
    reason = TajweedFormerCoverageReason.missingReference;
  } else if (disabledSites > 0) {
    reason = TajweedFormerCoverageReason.calibrationDisabled;
  } else if (unalignedSites > 0) {
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
  if (canonicalVerses == verses &&
      checkedSites == 0 &&
      disabledSites + unalignedSites > 0) {
    return TajweedFormerCategoryCoverage(
      state: TajweedFormerCoverageState.notEvaluated,
      reason: disabledSites > 0
          ? TajweedFormerCoverageReason.calibrationDisabled
          : TajweedFormerCoverageReason.pathNotEligible,
      unassessed: unassessed,
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
    // قيست مواضع وبقيت أخرى معطّلة أو بلا محاذاة أو في آيات غير مقارَنة:
    // الفئة غير حاسمة لا «مُقيَّمة صافية»، والسبب الدقيق محفوظ.
    return TajweedFormerCategoryCoverage(
      state: TajweedFormerCoverageState.inconclusive,
      reason: reason,
      sites: checkedSites,
      unassessed: unassessed,
    );
  }
  return TajweedFormerCategoryCoverage(
    state: TajweedFormerCoverageState.evaluatedNoCandidate,
    sites: checkedSites,
  );
}
