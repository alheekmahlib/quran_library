import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_head.dart';

void main() {
  test('checks shape and preserves negative infinity from the SDK bridge', () {
    final head = TajweedFormerCtcHead.fromMap({
      'frames': 2,
      'classes': 2,
      'frameMs': 40,
      'values': [-0.5, '-Infinity', -1.0, -0.4],
    });
    expect(head.toRows(), [
      [-0.5, double.negativeInfinity],
      [-1.0, -0.4]
    ]);
  });

  test('rejects missing, malformed and non-CTC values', () {
    for (final values in <List<dynamic>>[
      [0],
      [null, -1],
      [double.nan, -1],
      [double.infinity, -1],
      [0.1, -1],
    ]) {
      expect(
          () => TajweedFormerCtcHead.fromMap({
                'frames': 1,
                'classes': 2,
                'frameMs': 40,
                'values': values,
              }),
          throwsFormatException);
    }
  });
}
