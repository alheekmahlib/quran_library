/// Checked access to a raw TajweedFormer CTC head.
library;

import 'dart:typed_data';

class TajweedFormerCtcHead {
  TajweedFormerCtcHead._(this.frames, this.classes, this.frameMs, this.values);

  final int frames;
  final int classes;
  final int frameMs;
  final Float64List values;

  /// Accepts the serialized raw head returned by an inference client.
  factory TajweedFormerCtcHead.fromMap(Map<String, dynamic> source) {
    final frames = source['frames'];
    final classes = source['classes'];
    final frameMs = source['frameMs'];
    final raw = source['values'];
    if (frames is! int ||
        frames < 0 ||
        classes is! int ||
        classes <= 0 ||
        frameMs is! int ||
        frameMs <= 0 ||
        raw is! List ||
        raw.length != frames * classes) {
      throw const FormatException('Invalid V4 head dimensions');
    }
    final values = Float64List(raw.length);
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      final double value;
      if (item == '-Infinity') {
        value = double.negativeInfinity;
      } else if (item is num) {
        value = item.toDouble();
      } else {
        throw const FormatException('Invalid V4 CTC head value');
      }
      if (value.isNaN || value == double.infinity || value > 0) {
        throw const FormatException('Invalid V4 CTC log probability');
      }
      values[i] = value;
    }
    return TajweedFormerCtcHead._(frames, classes, frameMs, values);
  }

  /// Matrix view used by the full-sequence CTC evaluator.
  List<List<double>> toRows() => List.generate(
        frames,
        (frame) => values.sublist(frame * classes, (frame + 1) * classes),
        growable: false,
      );
}

/// An attribute head containing per-frame probabilities, not log scores.
class TajweedFormerProbabilityHead {
  TajweedFormerProbabilityHead._(
      this.frames, this.classes, this.frameMs, this.values);

  final int frames;
  final int classes;
  final int frameMs;
  final Float64List values;

  factory TajweedFormerProbabilityHead.fromMap(Map<String, dynamic> source) {
    final frames = source['frames'];
    final classes = source['classes'];
    final frameMs = source['frameMs'];
    final raw = source['values'];
    if (frames is! int ||
        frames < 0 ||
        classes is! int ||
        classes <= 0 ||
        frameMs is! int ||
        frameMs <= 0 ||
        raw is! List ||
        raw.length != frames * classes) {
      throw const FormatException('Invalid V4 attribute head dimensions');
    }
    final values = Float64List(raw.length);
    for (var i = 0; i < raw.length; i++) {
      if (raw[i] is! num) throw const FormatException('Invalid V4 probability');
      final value = (raw[i] as num).toDouble();
      if (!value.isFinite || value < 0 || value > 1) {
        throw const FormatException('Invalid V4 probability');
      }
      values[i] = value;
    }
    return TajweedFormerProbabilityHead._(frames, classes, frameMs, values);
  }
}
