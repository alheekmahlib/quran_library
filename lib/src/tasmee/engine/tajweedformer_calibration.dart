/// Validated site settings from the V4 model's own calibration data.
library;

class TajweedFormerSiteCalibration {
  const TajweedFormerSiteCalibration({
    required this.status,
    required this.threshold,
    required this.fusionWeight,
    required this.clipMin,
    required this.clipMax,
  });

  final String status;
  final double threshold;
  final double fusionWeight;
  final double clipMin;
  final double clipMax;
  bool get isValidated => status == 'validated';
}

/// يتحقق من البنية المشتركة التي تعتمد عليها كل الأصناف (format
/// وcontexts والسياق وfusion وsites) — أي تشوّه هنا يرمي قبل أي إجابة،
/// غيابًا كان أو قراءة.
void _validateSharedCalibrationStructure({
  required Map<String, dynamic> calibration,
  required String context,
}) {
  Never invalid() =>
      throw const FormatException('Invalid or unsupported V4 calibration');
  if (calibration['format'] != 'quranlab.tajweed-calibration/1') invalid();
  final contexts = calibration['contexts'];
  if (contexts is! Map || contexts[context] is! Map) invalid();
  final selected = contexts[context] as Map;
  final fusion = selected['fusion'];
  final sites = selected['sites'];
  if (fusion is! Map || sites is! Map) invalid();
  final heads = fusion['heads'];
  final weights = fusion['a'];
  final clip = fusion['clip'];
  final prep = fusion['inter1_prep'];
  if (heads is! List ||
      heads.length != 2 ||
      heads[0] != 'log_probs' ||
      heads[1] != 'inter1_log_probs' ||
      weights is! Map ||
      clip is! List ||
      clip.length != 2 ||
      clip[0] is! num ||
      clip[1] is! num ||
      prep is! String ||
      !prep.contains('merged into blank')) {
    invalid();
  }
  // قيم clip المشتركة بين كل الأصناف: النوع والانتهاء والترتيب تُفحص هنا
  // حتى لا يمرّ فسادُها كأنه غياب صنف.
  final clipLow = (clip[0] as num).toDouble();
  final clipHigh = (clip[1] as num).toDouble();
  if (!clipLow.isFinite || !clipHigh.isFinite || clipLow > clipHigh) {
    invalid();
  }
}

/// Read settings for a model/context/preset. Missing or unsupported data must
/// not be replaced with Zipformer values or guessed defaults.
TajweedFormerSiteCalibration readTajweedFormerSiteCalibration({
  required Map<String, dynamic> calibration,
  required String context,
  required String preset,
  required String siteClass,
}) {
  Never invalid() =>
      throw const FormatException('Invalid or unsupported V4 calibration');
  _validateSharedCalibrationStructure(
      calibration: calibration, context: context);
  final selected = (calibration['contexts'] as Map)[context] as Map;
  final sites = selected['sites'] as Map;
  final fusion = selected['fusion'] as Map;
  final weights = fusion['a'] as Map;
  final clip = fusion['clip'] as List;
  final site = sites[siteClass];
  if (site is! Map) invalid();
  final status = site['status'];
  final thresholds = site['thresholds'];
  if (status is! String ||
      !{'validated', 'experimental', 'off'}.contains(status) ||
      thresholds is! Map) {
    invalid();
  }
  final threshold = thresholds[preset];
  final weight = weights[siteClass] ?? weights['default'];
  if (threshold is! num || weight is! num) invalid();
  final t = threshold.toDouble();
  final w = weight.toDouble();
  // قيم clip ضمن شرط الفحص المشترك (نوع/انتهاء/ترتيب) — هنا قراءة فقط.
  final low = (clip[0] as num).toDouble();
  final high = (clip[1] as num).toDouble();
  if (!t.isFinite ||
      !w.isFinite ||
      w < 0 ||
      w > 1) {
    invalid();
  }
  return TajweedFormerSiteCalibration(
    status: status,
    threshold: t,
    fusionWeight: w,
    clipMin: low,
    clipMax: high,
  );
}

/// Same read, but returns null when this model's calibration carries no
/// section for the site class at all — a recordable coverage reason, not an
/// evaluation failure. The shared structure (including `fusion`) is
/// validated first: anything malformed still throws, exactly like
/// [readTajweedFormerSiteCalibration]. Only a genuinely absent class key
/// returns null.
TajweedFormerSiteCalibration? tryReadTajweedFormerSiteCalibration({
  required Map<String, dynamic> calibration,
  required String context,
  required String preset,
  required String siteClass,
}) {
  _validateSharedCalibrationStructure(
      calibration: calibration, context: context);
  final sites =
      ((calibration['contexts'] as Map)[context] as Map)['sites'] as Map;
  if (!sites.containsKey(siteClass)) return null;
  // المفتاح موجود: أي نوع خاطئ أو قيم مشوّهة ترميها القراءة الصارمة.
  return readTajweedFormerSiteCalibration(
    calibration: calibration,
    context: context,
    preset: preset,
    siteClass: siteClass,
  );
}
