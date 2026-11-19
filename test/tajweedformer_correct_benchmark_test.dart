import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/core/services/tasmee_reference_store.dart';
import 'package:quran_library/src/tasmee/engine/models/muaalem_config.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference_store.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_live_tracker.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_lattice.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_evaluation.dart';

import 'tajweedformer_sdk_sample_test.dart' show SdkSampleClient;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const path = String.fromEnvironment('TAJWEED_BENCHMARK_PATH');
  test('evaluates public correct recitations without microphone capture',
      () async {
    final data =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final metadata = Map<String, dynamic>.from(data['info'] as Map);
    await TasmeeReferenceStore.instance.load();
    for (final raw in data['captures'] as List) {
      final item = Map<String, dynamic>.from(raw as Map);
      final key = (item['ayah'] as String).split(':').map(int.parse).toList();
      final client =
          SdkSampleClient({...item, 'calibration': data['calibration']});
      final store = await TajweedFormerReferenceStore.load(
          client: client, metadata: metadata);
      final verse =
          await store.verse(surah: key[0], ayah: key[1], verseIndex: 0);
      final tracker = TajweedFormerLiveTracker(
          reference: verse.reference,
          blankId: metadata['blank'] as int,
          wordBarId: metadata['wordBar'] as int);
      final tokens = (item['sample'] as Map)['tokens'] as List;
      final progress = tracker
          .updateDecodedChunk({'tokens': tokens, 'settled': tokens.length});
      if (progress.matchedUnitIndices.isNotEmpty) {
        final first =
            progress.matchedUnitIndices.reduce((a, b) => a < b ? a : b);
        final last =
            progress.matchedUnitIndices.reduce((a, b) => a > b ? a : b);
        // ignore: avoid_print
        print(
            '  anchored words ${verse.reference[first].wordIndex}..${verse.reference[last].wordIndex} of ${verse.lattice.last.wordIndex}');
      }
      final ids = tokens
          .map((token) => (token as Map)['id'] as int)
          .where((id) => id != metadata['blank'] && id != metadata['wordBar'])
          .toList();
      final full = matchTajweedFormerLattice(words: verse.lattice, heard: ids)!;
      final fullScore = evaluateTajweedFormerTake(
        reference: full.units,
        heard: ids,
        tokenNames: (metadata['tokens'] as List).cast<String>(),
        blankId: metadata['blank'] as int,
        wordBarId: metadata['wordBar'] as int,
        heads:
            Map<String, dynamic>.from((item['sample'] as Map)['heads'] as Map),
        calibration: Map<String, dynamic>.from(
            (data['calibration'] as Map)['data'] as Map),
        context: metadata['defaultContext'] as String,
        surah: key[0],
        ayah: key[1],
      );
      // ignore: avoid_print
      print(
          '  full-verse flags=${fullScore.errors.length}, edits=${full.distance}');
      final range = TasmeeReferenceStore.instance
          .buildRange([(suraIdx: key[0], ayaIdx: key[1])])!;
      final engine = TajweedFormerRecitationEngine(
          client: client, metadata: metadata, store: store);
      engine.startLive(range: range);
      engine.feedPcm(Float32List(160));
      final frame = await engine.endLive();
      final stopwatch = Stopwatch()..start();
      final result = await engine.evaluateLive(
          config: const MuaalemConfig(), range: range, frame: frame);
      stopwatch.stop();
      expect(result.hasMatch, isTrue, reason: result.noMatchMessage);
      expect(result.assessmentComplete, isFalse);
      // This dataset contains correct clips, so flags estimate false alarms;
      // it cannot measure missed errors. Keep per-clip outcomes visible.
      // ignore: avoid_print
      print(
          '${item['ayah']}: match=${result.hasMatch}, flags=${result.errors.length}, evaluation_ms=${stopwatch.elapsedMilliseconds}, reason=${result.noMatchMessage ?? 'none'}');
      // Report aggregates only: model outputs and learner audio remain local.
      final timingFlags =
          result.errors.where((error) => error.errorType == 'tajweed').length;
      // ignore: avoid_print
      print('  timing_flags=$timingFlags');
      await engine.close();
    }
  },
      skip: path.isEmpty ? 'Set TAJWEED_BENCHMARK_PATH to SDK captures' : false,
      timeout: const Timeout(Duration(minutes: 10)));
}
