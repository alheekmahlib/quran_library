@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_web.dart';

void main() {
  test('native platforms fail explicitly instead of reporting V4 ready',
      () async {
    final sdk = TajweedFormerWeb();
    expect(TajweedFormerWeb.isSupported, isFalse);
    await expectLater(sdk.start(), throwsUnsupportedError);
    await expectLater(sdk.push(Float32List(1)), throwsUnsupportedError);
    await expectLater(sdk.initialize('test'), throwsUnsupportedError);
    await sdk.close();
  });
}
