import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_alignment.dart';

void main() {
  test('aligns matching, missing, extra, and substituted sounds', () {
    final ops = alignTajweedFormerTokens([2, 3, 4, 5], [2, 7, 4, 6, 5]);
    expect(ops.map((o) => o.kind), [
      TajweedFormerAlignmentKind.match,
      TajweedFormerAlignmentKind.replace,
      TajweedFormerAlignmentKind.match,
      TajweedFormerAlignmentKind.insert,
      TajweedFormerAlignmentKind.match,
    ]);
    expect(ops[3].referenceIndex, isNull);
    expect(ops[3].predictedIndex, 3);
    final deletion = alignTajweedFormerTokens([2, 3, 4], [2, 4])[1];
    expect(deletion.kind, TajweedFormerAlignmentKind.delete);
    expect(deletion.referenceIndex, 1);
    expect(deletion.predictedIndex, isNull);
  });

  test('free-end alignment cuts continued speech after the reference', () {
    // المرجع يكتمل عند 2,3,4 وما بعده (5,9,7) آية موصولة — لا تُمَدّ فوقه.
    final result = alignTajweedFormerTokensFreeEnd(
        [2, 3, 4], [2, 3, 4, 5, 9, 7]);
    expect(result.endCut, 3);
    expect(result.ops.map((o) => o.kind), everyElement(
        anyOf(equals(TajweedFormerAlignmentKind.match),
            equals(TajweedFormerAlignmentKind.delete),
            equals(TajweedFormerAlignmentKind.replace),
            equals(TajweedFormerAlignmentKind.insert))));
    expect(result.ops.where((o) => o.kind == TajweedFormerAlignmentKind.match),
        hasLength(3));
    // الطوابع بعد القص لا تدخل العمليات إطلاقًا.
    expect(
        result.ops
            .where((o) => o.predictedIndex != null)
            .map((o) => o.predictedIndex!),
        everyElement(lessThan(3)));
  });

  test('free-end alignment keeps a fully matching take uncropped', () {
    final result = alignTajweedFormerTokensFreeEnd([2, 3, 4], [2, 3, 4]);
    expect(result.endCut, 3);
    expect(
        result.ops.map((o) => o.kind),
        everyElement(equals(TajweedFormerAlignmentKind.match)));
    expect(result.ops, hasLength(3));
  });

  test('free-end alignment crops a repeated final token', () {
    // تكرار الحرف الأخير (تردد/همسة) يُقصّ كذيل موصول — لا يبقى داخل
    // النافذة ليولّد مرشح استبدال عند الحافة.
    final result = alignTajweedFormerTokensFreeEnd([2, 3], [2, 3, 3]);
    expect(result.endCut, 2);
    expect(
        result.ops.map((o) => o.kind),
        everyElement(equals(TajweedFormerAlignmentKind.match)));
  });

  test('handles empty input and limits memory usage', () {
    expect(alignTajweedFormerTokens([], []), isEmpty);
    expect(alignTajweedFormerTokens([], [2]).single.kind,
        TajweedFormerAlignmentKind.insert);
    expect(alignTajweedFormerTokens([2], []).single.kind,
        TajweedFormerAlignmentKind.delete);
    expect(
        () => alignTajweedFormerTokens(
            List.filled(2000, 1), List.filled(2000, 1)),
        throwsArgumentError);
  });
}
