import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_take_window.dart';

void main() {
  final head = {
    'frames': 10,
    'classes': 8,
    'frameMs': 40,
    'values': List<double>.filled(80, -2)
  };
  test('crops unmatched speech at both ends using token timing', () {
    final result = windowTajweedFormerTake(
      reference: [2, 3],
      blankId: 0,
      wordBarId: 1,
      decodedTokens: [
        {'id': 5, 'firstMs': 0, 'lastMs': 0},
        {'id': 2, 'firstMs': 80, 'lastMs': 80},
        {'id': 3, 'firstMs': 120, 'lastMs': 120},
        {'id': 6, 'firstMs': 240, 'lastMs': 240},
      ],
      heads: {
        'log_probs': head,
        'inter1_log_probs': head,
        'timing_log_probs': {
          'frames': 20,
          'classes': 8,
          'frameMs': 20,
          'values': List<double>.filled(160, -2),
        },
        'attr_qalqalah': {
          'frames': 20,
          'classes': 3,
          'frameMs': 20,
          'values': [
            for (var i = 0; i < 20; i++) ...[0.5, 0.3, 0.2]
          ],
        },
        'gem': {
          'frames': 20,
          'classes': 2,
          'frameMs': 20,
          'values': [
            for (var i = 0; i < 20; i++) ...[0.6, 0.4]
          ],
        },
      },
    );
    expect(result.heard, [2, 3]);
    expect(result.croppedStart, isTrue);
    expect(result.croppedEnd, isTrue);
    expect((result.heads['log_probs'] as Map)['frames'], 4);
    expect((result.heads['timing_log_probs'] as Map)['frames'], 5);
    expect((result.heads['attr_qalqalah'] as Map)['frames'], 5);
    expect((result.heads['gem'] as Map)['frames'], 5);
  });
  test('rejects a cropped take when timestamps are missing', () {
    expect(
        () => windowTajweedFormerTake(
              reference: [2, 3],
              blankId: 0,
              wordBarId: 1,
              decodedTokens: [
                {'id': 5},
                {'id': 2},
                {'id': 3}
              ],
              heads: {'log_probs': head, 'inter1_log_probs': head},
            ),
        throwsFormatException);
  });

  test('crops trailing speech that shares tokens with the reference', () {
    // تلاوة موصولة: بعد اكتمال المرجع (2,3,4) تليها رموز تحتاد مشابهة (3)
    // فتمنع المحاذاة القسرية من رؤية ذيل «إدراجات نقية» — النهاية الحرة
    // تجد أرخص إكمال عند 3 وتقصّ ما بعده.
    final result = windowTajweedFormerTake(
      reference: [2, 3, 4],
      blankId: 0,
      wordBarId: 1,
      decodedTokens: [
        {'id': 2, 'firstMs': 100, 'lastMs': 140},
        {'id': 3, 'firstMs': 140, 'lastMs': 180},
        {'id': 4, 'firstMs': 180, 'lastMs': 220},
        {'id': 7, 'firstMs': 260, 'lastMs': 300},
        {'id': 3, 'firstMs': 300, 'lastMs': 340},
        {'id': 9, 'firstMs': 340, 'lastMs': 380},
      ],
      heads: {
        'log_probs': head,
        'inter1_log_probs': head,
      },
    );
    expect(result.heard, [2, 3, 4]);
    expect(result.croppedStart, isFalse);
    expect(result.croppedEnd, isTrue);
    expect((result.heads['log_probs'] as Map)['frames'], greaterThan(0));
  });
}
