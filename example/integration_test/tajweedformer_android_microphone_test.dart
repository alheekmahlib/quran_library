import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_android.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_audio_session.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_range_session.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference.dart';

void main() {
  const key = String.fromEnvironment('QURANLAB_ANDROID_KEY');
  testWidgets('V4 Android microphone smoke test', (tester) async {
    final client = TajweedFormerAndroid();
    TajweedFormerAudioSession? audio;
    try {
      final info = await client.initialize(key);
      final blank = info['blank'] as int;
      final wordBar = info['wordBar'] as int;
      final raw = await client.reference(1, 1);
      final verse = TajweedFormerReferenceVerse.fromWebReference(
        surah: 1,
        ayah: 1,
        reference: raw,
        blankId: blank,
        wordBarId: wordBar,
      );
      final range = TajweedFormerRangeSession(
        client: client,
        reference: buildTajweedFormerReference(
            verses: [verse], blankId: blank, wordBarId: wordBar),
        blankId: blank,
        wordBarId: wordBar,
      );
      var chunks = 0;
      var tokens = 0;
      final sub = client.chunks.listen((chunk) {
        chunks++;
        tokens = (chunk['tokens'] as List).length;
      });
      audio = TajweedFormerAudioSession.microphone(range);
      await audio.start();
      // Do not print the learner's audio or decoded words.
      // ignore: avoid_print
      print('QURANLAB_MIC_READY: recording for 25 seconds');
      await Future<void>.delayed(const Duration(seconds: 25));
      final heads = await audio.finish();
      await sub.cancel();
      expect(heads['log_probs'], isNotNull);
      expect(chunks, greaterThan(0));
      // ignore: avoid_print
      print('QURANLAB_MIC_RESULT: chunks=$chunks tokens=$tokens');
    } finally {
      await audio?.cancel();
      await client.close();
    }
  }, skip: key.isEmpty, timeout: const Timeout(Duration(minutes: 10)));
}
