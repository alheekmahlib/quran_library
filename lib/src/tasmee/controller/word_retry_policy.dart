/// سياسة قبول محاولة إعادة نطق كلمة — قابلة للتوصيل بمصدر حكم مستقبلي.
///
/// Pluggable acceptance policy for a single-word retry attempt. A policy
/// that returns [TasmeeWordRetryOutcome.correct] or
/// [TasmeeWordRetryOutcome.incorrect] must be backed by an assessment that
/// actually covers the target word; partial coverage stays
/// [TasmeeWordRetryOutcome.inconclusive]. Wiring a policy in is never by
/// itself a reason to let an engine decide.
library;

import '../engine/models/recitation_result.dart';
import '../engine/tasmee_error_kind.dart';
import 'tasmee_state.dart';

/// One completed retry attempt, as seen by the policy.
class WordRetryAttempt {
  const WordRetryAttempt({
    required this.result,
    required this.targetWordIdx,
    required this.targetUnitCount,
    required this.minAccuracy,
  });

  /// نتيجة تقييم المحاولة (null إن فشل التقييم كليًا).
  final RecitationResult? result;

  /// الكلمة المستهدفة داخل نطاق المحاولة (0-based).
  final int targetWordIdx;

  /// عدد وحداتها المرجعية (0 = نطاق بلا وحدات مستهدفة).
  final int targetUnitCount;

  /// حد القبول النسبي المطلوب (محركات التقييم الكامل فقط).
  final double minAccuracy;
}

/// يقرر نتيجة محاولة إعادة النطق.
abstract class WordRetryAcceptancePolicy {
  const WordRetryAcceptancePolicy();

  TasmeeWordRetryOutcome decide(WordRetryAttempt attempt);
}

/// سياسة Zipformer (V3): تقييم كامل + قبول نسبي على وحدات الكلمة
/// المستهدفة وحدها ([isContextWordRetryAcceptable]).
class ContextWordRatioAcceptancePolicy extends WordRetryAcceptancePolicy {
  const ContextWordRatioAcceptancePolicy();

  @override
  TasmeeWordRetryOutcome decide(WordRetryAttempt attempt) {
    final result = attempt.result;
    if (result == null) return TasmeeWordRetryOutcome.incorrect;
    return isContextWordRetryAcceptable(
      result,
      targetWordIdx: attempt.targetWordIdx,
      targetUnitCount: attempt.targetUnitCount,
      minAccuracy: attempt.minAccuracy,
    )
        ? TasmeeWordRetryOutcome.correct
        : TasmeeWordRetryOutcome.incorrect;
  }
}

/// سياسة TajweedFormer V4 الحالية: كل محاولة غير حاسمة. النتيجة الجزئية
/// ليست قبولًا ولا رفضًا؛ عندما يتوافر مصدر حكم مثبت يغطي الكلمة
/// المستهدفة تُستبدل هذه السياسة بسياسة تقرر، لا أن يُرفع الحكم من
/// مسار التوصيل وحده.
class InconclusiveWordRetryPolicy extends WordRetryAcceptancePolicy {
  const InconclusiveWordRetryPolicy();

  @override
  TasmeeWordRetryOutcome decide(WordRetryAttempt attempt) =>
      TasmeeWordRetryOutcome.inconclusive;
}
