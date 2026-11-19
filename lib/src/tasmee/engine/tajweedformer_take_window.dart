import 'tajweedformer_alignment.dart';
import 'tajweedformer_head.dart';

/// Restricts audio heads to the decoded region aligned to the selected path.
/// A cropped edge means that speech continued outside the selected range.
({
  List<int> heard,
  Map<String, dynamic> heads,
  bool croppedStart,
  bool croppedEnd
}) windowTajweedFormerTake({
  required List<int> reference,
  required List<dynamic> decodedTokens,
  required int blankId,
  required int wordBarId,
  required Map<String, dynamic> heads,
}) {
  final tokens = <Map>[];
  for (final token in decodedTokens) {
    if (token is! Map || token['id'] is! int) {
      throw const FormatException('Invalid V4 decoded token');
    }
    if (token['id'] != blankId && token['id'] != wordBarId) tokens.add(token);
  }
  final heard = tokens.map((t) => t['id'] as int).toList();
  if (reference.isEmpty || heard.isEmpty) {
    throw const FormatException('Empty V4 reference or transcription');
  }
  // محاذاة بنهاية حرة: التلاوة الموصولة (الآية التالية بالوصل، أو إعادة
  // الكلمة الأخيرة) تُقصّ من النافذة بدل أن تُمَدّ فوق المرجع فتخترع
  // استبدالات كاذبة على آخر كلمة.
  final aligned = alignTajweedFormerTokensFreeEnd(reference, heard);
  final ops = aligned.ops;
  var first = 0;
  var last = aligned.endCut;
  for (final op in ops) {
    if (op.kind != TajweedFormerAlignmentKind.insert) break;
    first = op.predictedIndex! + 1;
  }
  for (final op in ops.reversed) {
    if (op.kind != TajweedFormerAlignmentKind.insert) break;
    last = op.predictedIndex!;
  }
  if (first >= last) throw const FormatException('No aligned V4 audio');
  final croppedStart = first > 0;
  final croppedEnd = last < heard.length;
  if (!croppedStart && !croppedEnd) {
    return (heard: heard, heads: heads, croppedStart: false, croppedEnd: false);
  }
  final firstMs = tokens[first]['firstMs'];
  final lastMs = tokens[last - 1]['lastMs'];
  if (firstMs is! num ||
      lastMs is! num ||
      !firstMs.isFinite ||
      !lastMs.isFinite ||
      firstMs < 0 ||
      lastMs < firstMs) {
    throw const FormatException('Missing V4 token timing for partial audio');
  }
  final result = Map<String, dynamic>.of(heads);
  for (final key in ['log_probs', 'inter1_log_probs', 'timing_log_probs']) {
    final raw = heads[key];
    if (key == 'timing_log_probs' && raw == null) continue;
    if (raw is! Map) throw const FormatException('Missing V4 CTC head');
    final head = TajweedFormerCtcHead.fromMap(Map<String, dynamic>.from(raw));
    final start =
        croppedStart ? (firstMs ~/ head.frameMs - 1).clamp(0, head.frames) : 0;
    final end = croppedEnd
        ? ((lastMs / head.frameMs).ceil() + 2).clamp(0, head.frames)
        : head.frames;
    if (start >= end) throw const FormatException('Invalid V4 audio window');
    result[key] = {
      'frames': end - start,
      'classes': head.classes,
      'frameMs': head.frameMs,
      'values': head.values.sublist(start * head.classes, end * head.classes),
    };
  }
  for (final name in ['attr_qalqalah', 'gem', 'attr_ghunna']) {
    final rawAttribute = heads[name];
    if (rawAttribute == null) continue;
    if (rawAttribute is! Map) {
      throw const FormatException('Invalid V4 attribute head');
    }
    final head = TajweedFormerProbabilityHead.fromMap(
        Map<String, dynamic>.from(rawAttribute));
    final start =
        croppedStart ? (firstMs ~/ head.frameMs - 1).clamp(0, head.frames) : 0;
    final end = croppedEnd
        ? ((lastMs / head.frameMs).ceil() + 2).clamp(0, head.frames)
        : head.frames;
    if (start >= end) throw const FormatException('Invalid V4 audio window');
    result[name] = {
      'frames': end - start,
      'classes': head.classes,
      'frameMs': head.frameMs,
      'values': head.values.sublist(start * head.classes, end * head.classes),
    };
  }
  return (
    heard: heard.sublist(first, last),
    heads: result,
    croppedStart: croppedStart,
    croppedEnd: croppedEnd
  );
}
