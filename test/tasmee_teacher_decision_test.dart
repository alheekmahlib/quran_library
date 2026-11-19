import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_state.dart';
import 'package:quran_library/src/tasmee/engine/models/recitation_result.dart';

void main() {
  RecitationResult result({required bool complete}) => RecitationResult(
        uthmaniText: 'نص',
        assessmentComplete: complete,
        matchedWordSpans: const [(verseIdx: 0, wordIdx: 0)],
      );

  test('ending capture is never a mastery verdict on its own', () {
    final decision = tasmeeTeacherDecisionAfterEvaluation(
      result: result(complete: false),
      ayahIndex: 1,
      ayahTotal: 5,
      verdictAccepted: true,
    );
    expect(decision.phase, TasmeeTeacherPhase.awaitingDecision);
    expect(decision.nextAyahIndex, 1,
        reason: 'a partial assessment keeps the learner on the same ayah');
  });

  test('no result or no match awaits an explicit learner decision', () {
    for (final res in [
      null,
      const RecitationResult(noMatchMessage: 'تعذّر مطابقة التلاوة.'),
    ]) {
      final decision = tasmeeTeacherDecisionAfterEvaluation(
        result: res,
        ayahIndex: 2,
        ayahTotal: 5,
      );
      expect(decision.phase, TasmeeTeacherPhase.awaitingDecision);
      expect(decision.nextAyahIndex, 2);
    }
  });

  test('a complete assessment without an accepted verdict stays manual', () {
    final decision = tasmeeTeacherDecisionAfterEvaluation(
      result: result(complete: true),
      ayahIndex: 2,
      ayahTotal: 5,
    );
    expect(decision.phase, TasmeeTeacherPhase.awaitingDecision,
        reason: 'word coverage is not mastery; the host hook decides');
    expect(decision.nextAyahIndex, 2);
  });

  test('an accepted verdict advances to the next ayah', () {
    final decision = tasmeeTeacherDecisionAfterEvaluation(
      result: result(complete: true),
      ayahIndex: 2,
      ayahTotal: 5,
      verdictAccepted: true,
    );
    expect(decision.phase, TasmeeTeacherPhase.idle);
    expect(decision.nextAyahIndex, 3);
  });

  test('an accepted verdict on the last ayah completes the page', () {
    final decision = tasmeeTeacherDecisionAfterEvaluation(
      result: result(complete: true),
      ayahIndex: 4,
      ayahTotal: 5,
      verdictAccepted: true,
    );
    expect(decision.phase, TasmeeTeacherPhase.pageDone);
    expect(decision.nextAyahIndex, 4);
  });

  test('an unaccepted verdict on the last ayah still awaits the learner', () {
    final decision = tasmeeTeacherDecisionAfterEvaluation(
      result: result(complete: true),
      ayahIndex: 4,
      ayahTotal: 5,
    );
    expect(decision.phase, TasmeeTeacherPhase.awaitingDecision,
        reason: 'pageDone claims mastery and needs a proven verdict');
  });
}
