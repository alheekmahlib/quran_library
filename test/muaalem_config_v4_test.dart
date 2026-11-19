import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/models/muaalem_config.dart';

void main() {
  test('the Hafs defaults carry nothing V4 must reject', () {
    expect(const MuaalemConfig().unsupportedTajweedFormerSettings(), isEmpty);
    expect(
      const MuaalemConfig(rewaya: 'hafs', takbeer: 'takbeer')
          .unsupportedTajweedFormerSettings(),
      ['takbeer'],
      reason: 'rewaya itself is rejected separately as Hafs-only',
    );
  });

  test('every non-default recitation setting is named, never silently ignored',
      () {
    expect(
      const MuaalemConfig(recitationSpeed: 'mujawwad')
          .unsupportedTajweedFormerSettings(),
      ['recitationSpeed'],
    );
    expect(
      const MuaalemConfig(maddMonfaselLen: 5)
          .unsupportedTajweedFormerSettings(),
      ['maddMonfaselLen'],
    );
    expect(
      const MuaalemConfig(qalqla: 'qalqla_sughra')
          .unsupportedTajweedFormerSettings(),
      ['qalqla'],
    );
    expect(
      const MuaalemConfig(ghonna: 'ghonna', itbaq: 'itbaq')
          .unsupportedTajweedFormerSettings(),
      containsAll(['ghonna', 'itbaq']),
    );
    expect(
      const MuaalemConfig(
        rewaya: 'warsh',
        tafkheemLetters: 'tafqeem',
      ).unsupportedTajweedFormerSettings(),
      ['tafkheemLetters'],
      reason: 'a non-Hafs riwaya is reported by its own explicit check',
    );
  });

  test('the V4 evidence preset is a supported setting, not a rejection', () {
    expect(
      const MuaalemConfig(
              tajweedFormerPreset: TajweedFormerFeedbackPreset.sensitive)
          .unsupportedTajweedFormerSettings(),
      isEmpty,
    );
  });
}
