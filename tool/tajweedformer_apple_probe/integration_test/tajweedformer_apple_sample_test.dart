import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_apple.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_factory.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_head.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_range_session.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference.dart';

void main() {
  const runSample = bool.fromEnvironment('QURANLAB_RUN_SAMPLE');
  testWidgets('V4 Apple sample and streamed audio', (tester) async {
    final client = await createTajweedFormerClient();
    expect(client, isA<TajweedFormerApple>());
    final sdk = client! as TajweedFormerApple;
    try {
      expect(await TajweedFormerApple.isAvailable(), isTrue);
      final info = await sdk.initializeFromHost();
      expect(info['version'], isNotEmpty);
      final blank = info['blank'] as int;
      final wordBar = info['wordBar'] as int;
      expect(sdk.calibration()['data'], isA<Map>());
      final rawReference = await sdk.reference(1, 1);
      final verse = TajweedFormerReferenceVerse.fromWebReference(
        surah: 1,
        ayah: 1,
        reference: rawReference,
        blankId: blank,
        wordBarId: wordBar,
      );
      final sample = await sdk.sample();
      // This text is the SDK's bundled sample, never a learner recording.
      // ignore: avoid_print
      print('QuranLab sample: ${sample['text']}');
      expect(sample['isFinal'], isTrue);
      expect(sample['tokens'], isNotEmpty);
      final heads = sample['heads'] as Map;
      final head = TajweedFormerCtcHead.fromMap(
          Map<String, dynamic>.from(heads['log_probs'] as Map));
      expect(head.frames, greaterThan(0));
      final range = TajweedFormerRangeSession(
        client: sdk,
        reference: buildTajweedFormerReference(
            verses: [verse], blankId: blank, wordBarId: wordBar),
        blankId: blank,
        wordBarId: wordBar,
      );
      var progressEvents = 0;
      final progress = range.progress.listen((_) => progressEvents++);
      await range.start();
      await range.push(Float32List(16000));
      final result = await range.finish();
      await progress.cancel();
      expect(result['log_probs'], isNotNull);
      expect(progressEvents, greaterThan(0));
      final diagnosis = await sdk.diagnose();
      expect((diagnosis['model'] as Map)['verified'], isTrue);
      // ignore: avoid_print
      print('QuranLab diagnosis: sdk=${diagnosis['sdk']} '
          'key=${diagnosis['key']} config=${diagnosis['config']} '
          'verified=${(diagnosis['model'] as Map)['verified']} '
          'backend=${diagnosis['backend']} lastError=${diagnosis['lastError']}');
    } finally {
      await sdk.close();
    }
  }, skip: !runSample, timeout: const Timeout(Duration(minutes: 10)));
}
