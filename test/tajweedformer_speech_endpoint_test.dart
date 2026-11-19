import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_speech_endpoint.dart';

void main() {
  testWidgets('endpoint requires speech followed by sustained silence',
      (tester) async {
    var count = 0;
    final detector = TajweedFormerSpeechEndpoint(() => count++);
    detector.update(false);
    await tester.pump(const Duration(seconds: 2));
    expect(count, 0);
    detector.update(true);
    detector.update(false);
    await tester.pump(const Duration(milliseconds: 800));
    detector.update(true);
    await tester.pump(const Duration(seconds: 2));
    expect(count, 0);
    detector.update(false);
    await tester.pump(const Duration(milliseconds: 1200));
    detector.update(false);
    await tester.pump(const Duration(seconds: 2));
    expect(count, 1);
    detector.update(true);
    detector.update(false);
    detector.dispose();
    await tester.pump(const Duration(seconds: 2));
    expect(count, 1);
  });
}
