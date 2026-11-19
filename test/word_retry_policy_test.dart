import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_state.dart';
import 'package:quran_library/src/tasmee/controller/word_retry_policy.dart';
import 'package:quran_library/src/tasmee/engine/models/recitation_result.dart';

void main() {
  RecitationResult fullResult({
    List<RecitationError> errors = const [],
  }) =>
      RecitationResult(
        uthmaniText: 'نص',
        assessmentComplete: true,
        matchedWordSpans: const [(verseIdx: 0, wordIdx: 0)],
        errors: errors,
      );

  test('the ratio policy keeps the Zipformer acceptance contract', () {
    const policy = ContextWordRatioAcceptancePolicy();
    WordRetryAttempt attempt({RecitationResult? result, int targetUnitCount = 10}) =>
        WordRetryAttempt(
          result: result,
          targetWordIdx: 0,
          targetUnitCount: targetUnitCount,
          minAccuracy: 0.75,
        );

    expect(policy.decide(attempt(result: null)),
        TasmeeWordRetryOutcome.incorrect,
        reason: 'a capture failure is a failed attempt for V3');
    expect(policy.decide(attempt(result: fullResult())),
        TasmeeWordRetryOutcome.correct);
    expect(
      policy.decide(attempt(
          result: fullResult(errors: const [
        RecitationError(
            errorType: 'normal', speechErrorType: 'replace', wordIdx: 0)
      ]))),
      TasmeeWordRetryOutcome.correct,
      reason: 'one unit error of ten still clears the 0.75 ratio, as in V3',
    );
    expect(
      policy.decide(attempt(
          targetUnitCount: 2,
          result: fullResult(errors: const [
        RecitationError(
            errorType: 'normal', speechErrorType: 'replace', wordIdx: 0)
      ]))),
      TasmeeWordRetryOutcome.incorrect,
      reason: 'a blocking letter error on a two-unit word fails the retry',
    );
    expect(
      policy.decide(attempt(
          result: fullResult(errors: const [
        RecitationError(
            errorType: 'tajweed', speechErrorType: 'replace', wordIdx: 0)
      ]))),
      TasmeeWordRetryOutcome.correct,
      reason: 'non-blocking tajweed notes never fail the retry',
    );
  });

  test('the V4 policy stays inconclusive whatever the result looks like', () {
    const policy = InconclusiveWordRetryPolicy();
    for (final result in [
      null,
      fullResult(),
      const RecitationResult(uthmaniText: 'نص', assessmentComplete: false),
      fullResult(errors: const [
        RecitationError(
            errorType: 'normal', speechErrorType: 'replace', wordIdx: 0)
      ]),
    ]) {
      expect(
        policy.decide(WordRetryAttempt(
          result: result,
          targetWordIdx: 0,
          targetUnitCount: 5,
          minAccuracy: 0.75,
        )),
        TasmeeWordRetryOutcome.inconclusive,
        reason: 'wiring a policy in is not a verdict source; partial V4 '
            'coverage can neither accept nor reject an attempt',
      );
    }
  });
}
