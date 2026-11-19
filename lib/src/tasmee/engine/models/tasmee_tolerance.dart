import 'muaalem_config.dart';

/// Learner-facing sensitivity. V4's preset names describe the opposite:
/// its `strict` preset is conservative about raising candidate flags.
enum TasmeeToleranceLevel {
  skip,
  lenient,
  balanced,
  strict;

  TajweedFormerFeedbackPreset get v4Preset => switch (this) {
        TasmeeToleranceLevel.strict => TajweedFormerFeedbackPreset.sensitive,
        TasmeeToleranceLevel.lenient => TajweedFormerFeedbackPreset.strict,
        _ => TajweedFormerFeedbackPreset.balanced,
      };

  static TasmeeToleranceLevel parse(
          Object? value, TasmeeToleranceLevel fallback) =>
      TasmeeToleranceLevel.values.where((v) => v.name == value).firstOrNull ??
      fallback;
}

/// Independent V4 diagnostic settings. They do not establish correctness.
class TasmeeToleranceProfile {
  const TasmeeToleranceProfile({
    this.letters = TasmeeToleranceLevel.balanced,
    this.tashkeel = TasmeeToleranceLevel.balanced,
    this.madd = TasmeeToleranceLevel.balanced,
  }) : assert(letters != TasmeeToleranceLevel.skip);

  const TasmeeToleranceProfile.uniform(TasmeeToleranceLevel level)
      : assert(level != TasmeeToleranceLevel.skip),
        letters = level,
        tashkeel = level,
        madd = level;

  final TasmeeToleranceLevel letters;
  final TasmeeToleranceLevel tashkeel;
  final TasmeeToleranceLevel madd;

  TasmeeToleranceProfile copyWith(
          {TasmeeToleranceLevel? letters,
          TasmeeToleranceLevel? tashkeel,
          TasmeeToleranceLevel? madd}) =>
      TasmeeToleranceProfile(
          letters: letters ?? this.letters,
          tashkeel: tashkeel ?? this.tashkeel,
          madd: madd ?? this.madd);

  Map<String, String> toJson() => {
        'letters': letters.name,
        'tashkeel': tashkeel.name,
        'madd': madd.name,
      };

  factory TasmeeToleranceProfile.fromJson(Object? raw,
      {TasmeeToleranceLevel fallback = TasmeeToleranceLevel.balanced}) {
    if (fallback == TasmeeToleranceLevel.skip) {
      fallback = TasmeeToleranceLevel.balanced;
    }
    final map = raw is Map ? raw : const {};
    final letters = TasmeeToleranceLevel.parse(map['letters'], fallback);
    return TasmeeToleranceProfile(
      letters: letters == TasmeeToleranceLevel.skip ? fallback : letters,
      tashkeel: TasmeeToleranceLevel.parse(map['tashkeel'], fallback),
      madd: TasmeeToleranceLevel.parse(map['madd'], fallback),
    );
  }
}
