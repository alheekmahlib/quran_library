import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_android.dart';

void main() {
  testWidgets('optional V4 bridge checks the Android version', (tester) async {
    const available = bool.fromEnvironment('TAJWEEDFORMER_EXPECT_AVAILABLE');
    expect(await TajweedFormerAndroid.isAvailable(), available);
    final client = TajweedFormerAndroid();
    await expectLater(
      client.initialize('invalid-test-key'),
      throwsA(isA<PlatformException>().having(
        (error) => error.code,
        'code',
        available ? 'invalid_argument' : 'runtime_unsupported',
      )),
    );
    await client.close();
  });
}
