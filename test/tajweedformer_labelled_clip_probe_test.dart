import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/core/services/tasmee_reference_store.dart';
import 'package:quran_library/src/tasmee/engine/models/muaalem_config.dart';
import 'package:quran_library/src/tasmee/engine/models/tasmee_tolerance.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference_store.dart';

import 'tajweedformer_sdk_sample_test.dart' show SdkSampleClient;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const directory = String.fromEnvironment('TAJWEED_LABELLED_PATH');
  const probePreset = String.fromEnvironment('TAJWEED_PROBE_PRESET');
  final probeTolerance = probePreset.isEmpty
      ? null
      : TasmeeToleranceProfile.uniform(TasmeeToleranceLevel.parse(
          probePreset, TasmeeToleranceLevel.balanced));
  test('replays labelled clips and reports aggregate candidate counts',
      () async {
    final root = Directory(directory);
    final captures =
        jsonDecode(File('${root.path}/sdk-captures.json').readAsStringSync())
            as Map;
    final cases =
        jsonDecode(File('${root.path}/cases.json').readAsStringSync()) as List;
    final items = captures['captures'] as List;
    if (cases.length != items.length) {
      throw const FormatException('Mismatched clip count');
    }
    final metadata = Map<String, dynamic>.from(captures['info'] as Map);
    final oldStore = TasmeeReferenceStore.instance;
    await oldStore.load();
    var tp = 0,
        fp = 0,
        tn = 0,
        fn = 0,
        unmatchedError = 0,
        unmatchedCorrect = 0;
    final flaggedTypes = <String, Map<String, int>>{
      'error': {},
      'correct': {},
    };
    for (var i = 0; i < items.length; i++) {
      final item = Map<String, dynamic>.from(items[i] as Map);
      final entry = cases[i] as Map;
      if (item['ayah'] != entry['ayah'] ||
          !['0', '1'].contains(entry['label'])) {
        throw const FormatException('Invalid labelled clip metadata');
      }
      final key = (entry['ayah'] as String).split(':').map(int.parse).toList();
      final client =
          SdkSampleClient({...item, 'calibration': captures['calibration']});
      final store = await TajweedFormerReferenceStore.load(
          client: client, metadata: metadata);
      final engine = TajweedFormerRecitationEngine(
          client: client, metadata: metadata, store: store);
      try {
        final range = oldStore.buildRange([(suraIdx: key[0], ayaIdx: key[1])])!;
        engine.startLive(range: range);
        engine.feedPcm(Float32List(160));
        final frame = await engine.endLive();
        final result = await engine.evaluateLive(
            config: MuaalemConfig(tajweedFormerTolerance: probeTolerance),
            range: range,
            frame: frame);
        final hasError = entry['label'] == '0';
        if (!result.hasMatch) {
          if (hasError) {
            unmatchedError++;
          } else {
            unmatchedCorrect++;
          }
          continue;
        }
        final flagged = result.errors.isNotEmpty;
        final group = flaggedTypes[hasError ? 'error' : 'correct']!;
        for (final type
            in result.errors.map((error) => error.errorType).toSet()) {
          group[type] = (group[type] ?? 0) + 1;
        }
        if (hasError && flagged) {
          tp++;
        }
        if (hasError && !flagged) {
          fn++;
        }
        if (!hasError && flagged) {
          fp++;
        }
        if (!hasError && !flagged) {
          tn++;
        }
        // ignore: avoid_print
        print('clip[$i] ${entry['ayah']} '
            'matched=${result.hasMatch} '
            'words=${result.matchedWordSpans.length} '
            'flags=${result.errors.length} '
            'types=${result.errors.map((e) => '${e.errorType}/${e.speechErrorType}').toList()} '
            'label=${entry['label']}');
        for (final error in result.errors) {
          // ignore: avoid_print
          print('   ↳ flag: expected=${error.expectedPh} '
              'predicted=${error.predictedPh} '
              'type=${error.errorType}/${error.speechErrorType} '
              'word=${error.wordIdx} uthmaniPos=${error.uthmaniPos}');
        }
      } finally {
        await engine.close();
      }
    }
    // Any flag is counted, regardless of location or rule; this is not a
    // localized correctness measure. Unmatched cases are reported separately.
    // ignore: avoid_print
    print(
        'clip-level: error_flagged=$tp correct_flagged=$fp correct_unflagged=$tn error_unflagged=$fn unmatched_error=$unmatchedError unmatched_correct=$unmatchedCorrect');
    // Counts can overlap: one clip may have flags in several categories.
    // ignore: avoid_print
    print('flagged clip categories: $flaggedTypes');
  },
      skip: directory.isEmpty
          ? 'Set TAJWEED_LABELLED_PATH to local captures'
          : false,
      timeout: const Timeout(Duration(minutes: 10)));
}
