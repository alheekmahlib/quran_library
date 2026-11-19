import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/core/services/tasmee_reference_store.dart';
import 'package:quran_library/src/tasmee/engine/models/muaalem_config.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference_store.dart';

import 'tajweedformer_range_session_test.dart' show FakeClient;

class SdkSampleClient extends FakeClient {
  SdkSampleClient(this.data);
  final Map<String, dynamic> data;
  @override
  Future<Map<String, dynamic>> reference(int surah, int ayah) async =>
      Map<String, dynamic>.from(data['reference'] as Map);
  @override
  Map<String, dynamic> calibration() =>
      Map<String, dynamic>.from(data['calibration'] as Map);
  @override
  Future<void> push(Float32List samples) async {
    final tokens = (data['sample'] as Map)['tokens'] as List;
    stream.add({'tokens': tokens, 'settled': tokens.length, 'isFinal': false});
  }

  @override
  Future<Map<String, dynamic>> finish() async {
    final sample = data['sample'] as Map;
    final tokens = sample['tokens'] as List;
    stream.add({'tokens': tokens, 'settled': tokens.length, 'isFinal': true});
    return Map<String, dynamic>.from(sample['heads'] as Map);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const path = String.fromEnvironment('TAJWEED_SAMPLE_PATH');
  test('evaluates the SDK sample without a microphone', () async {
    final data =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final metadata = Map<String, dynamic>.from(data['info'] as Map);
    final client = SdkSampleClient(data);
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    await TasmeeReferenceStore.instance.load();
    final range =
        TasmeeReferenceStore.instance.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    engine.startLive(range: range);
    engine.feedPcm(Float32List(160));
    final frame = await engine.endLive();
    final result = await engine.evaluateLive(
        config: const MuaalemConfig(), range: range, frame: frame);
    expect(result.hasMatch, isTrue, reason: result.noMatchMessage);
    expect(result.matchedWordSpans, isNotEmpty);
    expect(result.errors, isEmpty);
    expect(result.isFullyCorrect, isFalse);
    await engine.close();
  },
      skip: path.isEmpty
          ? 'Set TAJWEED_SAMPLE_PATH to an SDK sample capture'
          : false);
}
