import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/core/services/tasmee_reference_store.dart';
import 'package:quran_library/src/tasmee/engine/live_recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/models/muaalem_config.dart';
import 'package:quran_library/src/tasmee/engine/models/recitation_result.dart';
import 'package:quran_library/src/tasmee/engine/recitation_session.dart';
import 'package:quran_library/src/tasmee/engine/recitation_state.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_coverage.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference_store.dart';

import 'tajweedformer_recitation_engine_test.dart'
    show StreamingClient, metadata;
import 'tajweedformer_session_handoff_test.dart' show FakeRecorder;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  RecitationResult roundTrip(RecitationResult result) =>
      RecitationResult.fromJson(
          jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>);

  test('a non-Hafs request stays an unassessed incomplete result', () async {
    final client = StreamingClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    await TasmeeReferenceStore.instance.load();
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);

    final live = await engine.evaluateLive(
      config: const MuaalemConfig(rewaya: 'warsh'),
      frame: const LiveRecognitionFrame(units: [], timestamps: []),
    );
    expect(live.assessmentComplete, isFalse);
    expect(live.hasMatch, isFalse);
    expect(
      live.coverage!.categories.values,
      everyElement(
        allOf(
          isA<TajweedFormerCategoryCoverage>()
              .having((c) => c.state, 'state',
                  TajweedFormerCoverageState.notEvaluated)
              .having((c) => c.reason, 'reason',
                  TajweedFormerCoverageReason.missingReference),
        ),
      ),
    );

    final batch = await engine.correctRecitation(
      wavBytes: Uint8List(0),
      config: const MuaalemConfig(rewaya: 'warsh'),
    );
    expect(batch.assessmentComplete, isFalse);
    expect(batch.coverage, isNotNull);
    await engine.close();
  });

  test('an undecodable WAV is incomplete with its coverage reason', () async {
    final client = StreamingClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    await TasmeeReferenceStore.instance.load();
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);

    final result = await engine.correctRecitation(
        wavBytes: Uint8List.fromList([1, 2, 3, 4]));
    expect(result.assessmentComplete, isFalse);
    expect(result.hasMatch, isFalse);
    expect(
      result.coverage!.categories.values.first.reason,
      TajweedFormerCoverageReason.noMatchedPath,
    );

    // الحفظ والاستعادة لا يرقّيان نتيجة فاشلة إلى مكتملة ولا يفقدان سببها.
    final restored = roundTrip(result);
    expect(restored.assessmentComplete, isFalse);
    expect(restored.coverage, result.coverage);
    await engine.close();
  });

  test('an evaluation without a reference range is incomplete, not clean',
      () async {
    final client = StreamingClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    await TasmeeReferenceStore.instance.load();
    final range =
        TasmeeReferenceStore.instance.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    engine.startLive(range: range);
    await engine.waitUntilReady();
    final frame = await engine.endLive();
    // النطاق غاب عند التقييم (لا مرجع يُحاذا عليه) — لا نجاح زائف.
    final result = await engine.evaluateLive(
        config: const MuaalemConfig(), frame: frame);
    expect(result.assessmentComplete, isFalse);
    expect(result.hasMatch, isFalse);
    expect(
      result.coverage!.categories.values.first.reason,
      TajweedFormerCoverageReason.noMatchedPath,
    );

    final restored = roundTrip(result);
    expect(restored.assessmentComplete, isFalse);
    expect(restored.coverage, result.coverage);
    await engine.close();
  });

  test('a silent live capture reports no usable signal and never completes',
      () async {
    final client = StreamingClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    await TasmeeReferenceStore.instance.load();
    final range =
        TasmeeReferenceStore.instance.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    final session = RecitationSession(
        config: const MuaalemConfig(),
        engine: engine,
        recorder: FakeRecorder(),
        range: range);
    await session.startLive();
    expect(session.state.value, RecitationState.recording);
    // لا كلام إطلاقًا — ذروة الصوت صفر: النتيجة صمت تام لا تقييم فيه.
    await session.stopLive();

    final result = session.result.value!;
    expect(result.assessmentComplete, isFalse);
    expect(result.hasMatch, isFalse);
    expect(result.noMatchMessage, contains('الميكروفون'));
    expect(
      result.coverage!.categories.values,
      everyElement(
        isA<TajweedFormerCategoryCoverage>()
            .having((c) => c.state, 'state',
                TajweedFormerCoverageState.notEvaluated)
            .having((c) => c.reason, 'reason',
                TajweedFormerCoverageReason.noUsableSignal),
      ),
    );

    // حفظها واستعادتها يبقي العلامة والسبب — لا تُقرأ إتقانًا لاحقًا.
    final restored = roundTrip(result);
    expect(restored.assessmentComplete, isFalse);
    expect(restored.coverage, result.coverage);
    await engine.close();
  });
}
