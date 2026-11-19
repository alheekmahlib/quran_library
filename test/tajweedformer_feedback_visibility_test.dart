import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_state.dart';
import 'package:quran_library/src/tasmee/engine/models/recitation_result.dart';
import 'package:quran_library/src/tasmee/engine/tasmee_error_kind.dart';
import 'package:quran_library/src/tasmee/engine/models/muaalem_config.dart';

void main() {
  test('learner strictness selects V4 model presets independently of V3', () {
    expect(TasmeeStrictness.strict.tajweedFormerPreset,
        TajweedFormerFeedbackPreset.sensitive);
    expect(TasmeeStrictness.balanced.tajweedFormerPreset,
        TajweedFormerFeedbackPreset.balanced);
    expect(TasmeeStrictness.lenient.tajweedFormerPreset,
        TajweedFormerFeedbackPreset.strict);
    expect(
        const MuaalemConfig().toFormFields().containsKey('tajweedFormerPreset'),
        isFalse);
  });
  test('a partial assessment never colors a word correct or incorrect', () {
    for (final candidate in [true, false]) {
      expect(
          finalTasmeeWordStatus(assessmentComplete: false, correct: candidate),
          TasmeeWordStatus.heard);
    }
  });

  test('complete assessments preserve existing word verdict colors', () {
    expect(finalTasmeeWordStatus(assessmentComplete: true, correct: true),
        TasmeeWordStatus.correct);
    expect(finalTasmeeWordStatus(assessmentComplete: true, correct: false),
        TasmeeWordStatus.incorrect);
  });

  test(
      'explicit diagnostics color flagged words without marking others correct',
      () {
    expect(
      finalTasmeeWordStatus(
          assessmentComplete: false,
          correct: false,
          showUnverifiedErrors: true),
      TasmeeWordStatus.incorrect,
    );
    expect(
      finalTasmeeWordStatus(
          assessmentComplete: false, correct: true, showUnverifiedErrors: true),
      TasmeeWordStatus.heard,
    );
  });

  test('restored partial results cannot be treated as mastery', () {
    final partial = RecitationResult.fromJson({
      'uthmani_text': 'test',
      'assessment_complete': false,
    });
    expect(partial.hasMatch, isTrue);
    expect(partial.isFullyCorrect, isFalse);
    expect(isRecitationAcceptable(partial), isFalse);
    final legacy = RecitationResult.fromJson({'uthmani_text': 'test'});
    expect(legacy.isFullyCorrect, isTrue);
  });

  test('saved partial result retains its status, positions and error data', () {
    const result = RecitationResult(
      start: SurahAyahPosition(suraIdx: 2, ayaIdx: 3, uthmaniWordIdx: 4),
      end: SurahAyahPosition(suraIdx: 2, ayaIdx: 3, phonemesIdx: 9),
      uthmaniText: 'نص تجريبي',
      assessmentComplete: false,
      unitAccuracy: 0.75,
      matchedWordSpans: [(verseIdx: 0, wordIdx: 4)],
      errors: [
        RecitationError(
          errorType: 'tajweed',
          speechErrorType: 'replace',
          suraIdx: 2,
          ayaIdx: 3,
          wordIdx: 4,
          expectedLen: 2,
          predictedLen: 4,
          refTajweedRules: [TajweedRule(nameAr: 'مد', nameEn: 'madd')],
        ),
      ],
    );
    final restored = RecitationResult.fromJson(
        jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>);
    expect(restored.assessmentComplete, isFalse);
    expect(restored.isFullyCorrect, isFalse);
    expect(isRecitationAcceptable(restored), isFalse);
    expect(restored.start!.uthmaniWordIdx, 4);
    expect(restored.end!.phonemesIdx, 9);
    expect(restored.unitAccuracy, 0.75);
    expect(restored.matchedWordSpans, [(verseIdx: 0, wordIdx: 4)]);
    final error = restored.errors.single;
    expect((error.suraIdx, error.ayaIdx, error.wordIdx), (2, 3, 4));
    expect((error.expectedLen, error.predictedLen), (2, 4));
    expect(error.wordText, isNull);
    expect(error.refTajweedRules.single.nameAr, 'مد');
  });
}
