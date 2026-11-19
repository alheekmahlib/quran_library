import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/core/services/tasmee_reference_store.dart';
import 'package:quran_library/src/tasmee/engine/models/muaalem_config.dart';
import 'package:quran_library/src/tasmee/engine/recitation_session.dart';
import 'package:quran_library/src/tasmee/engine/recitation_state.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference_store.dart';
import 'package:record/record.dart';

import 'tajweedformer_recitation_engine_test.dart'
    show StreamingClient, metadata;

class ExclusiveClient extends StreamingClient {
  bool open = false;
  int starts = 0;
  @override
  Future<void> start() async {
    if (open) throw StateError('overlapping takes');
    open = true;
    starts++;
    await super.start();
  }

  @override
  Future<Map<String, dynamic>> finish() async {
    try {
      return await super.finish();
    } finally {
      open = false;
    }
  }

  @override
  Future<void> cancel() async {
    open = false;
    await super.cancel();
  }
}

class FakeRecorder implements AudioRecorder {
  StreamController<Uint8List>? input;
  @override
  Future<bool> hasPermission({bool request = true}) async => true;
  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async {
    input = StreamController<Uint8List>(sync: true);
    return input!.stream;
  }

  void speak() => input!.add(Uint8List.fromList([0, 64, 0, 64]));

  @override
  Future<String?> stop() async {
    await input?.close();
    input = null;
    return null;
  }

  @override
  Future<void> dispose() async => stop();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class DelayedPermissionRecorder extends FakeRecorder {
  final permission = Completer<bool>();
  @override
  Future<bool> hasPermission({bool request = true}) => permission.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paused V4 take releases model for retry before resuming', () async {
    final client = ExclusiveClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    await TasmeeReferenceStore.instance.load();
    final range =
        TasmeeReferenceStore.instance.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    final mainRecorder = FakeRecorder();
    final main = RecitationSession(
        config: const MuaalemConfig(),
        engine: engine,
        recorder: mainRecorder,
        range: range);
    await main.startLive();
    mainRecorder.speak();
    await main.pauseLive();
    expect(main.state.value, RecitationState.paused);
    expect(client.open, isFalse);

    final cancelled = RecitationSession(
        config: const MuaalemConfig(),
        engine: engine,
        recorder: FakeRecorder(),
        range: range);
    await cancelled.startLive();
    await cancelled.cancelV4Live();
    expect(client.open, isFalse);

    final retryRecorder = FakeRecorder();
    final retry = RecitationSession(
        config: const MuaalemConfig(),
        engine: engine,
        recorder: retryRecorder,
        range: range);
    await retry.startLive();
    retryRecorder.speak();
    await retry.stopLive();
    expect(retry.state.value, RecitationState.finished);
    expect(retry.result.value!.assessmentComplete, isTrue);
    expect(client.open, isFalse);

    await main.resumeLive();
    mainRecorder.speak();
    await main.stopLive();
    expect(main.state.value, RecitationState.finished);
    // لقطة الاستئناف بعد إعادة كلمة ما زالت غير مكتملة: مسار إعادة الكلمة
    // خارج نطاق التحقق الميداني (2026-11-16 غطى لقطات الآية الكاملة فقط).
    expect(main.result.value!.assessmentComplete, isFalse);
    expect(main.result.value!.matchedWordSpans.length, 4);
    expect(client.starts, 4);
    await engine.close();
  });

  test('cancelling a retry waits for pending microphone setup', () async {
    final client = ExclusiveClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    await TasmeeReferenceStore.instance.load();
    final range = TasmeeReferenceStore.instance
        .buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    final recorder = DelayedPermissionRecorder();
    final session = RecitationSession(
        config: const MuaalemConfig(),
        engine: engine,
        recorder: recorder,
        range: range);
    final starting = session.startLive();
    final cancelling = session.cancelV4Live();
    recorder.permission.complete(true);
    await starting;
    await cancelling;
    expect(client.open, isFalse);
    expect(client.starts, 0);
    expect(session.isLive.value, isFalse);
    await engine.close();
  });

  test('a rejected second session keeps the active take alive', () async {
    final client = ExclusiveClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    await TasmeeReferenceStore.instance.load();
    final range =
        TasmeeReferenceStore.instance.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    final mainRecorder = FakeRecorder();
    final main = RecitationSession(
        config: const MuaalemConfig(),
        engine: engine,
        recorder: mainRecorder,
        range: range);
    await main.startLive();
    expect(main.state.value, RecitationState.recording);
    expect(client.open, isTrue);

    // جلسة ثانية يرفضها المحرك (محاولة مشغولة) — فشلها لا يملك حق
    // إلغاء محاولة الجلسة الأولى.
    final second = RecitationSession(
        config: const MuaalemConfig(),
        engine: engine,
        recorder: FakeRecorder(),
        range: range);
    await second.startLive();
    expect(second.state.value, RecitationState.error);
    expect(client.cancelled, isFalse);
    expect(client.open, isTrue);
    expect(main.state.value, RecitationState.recording);
    expect(engine.hasActiveTake, isTrue);

    mainRecorder.speak();
    await main.stopLive();
    expect(main.state.value, RecitationState.finished);
    expect(main.result.value!.matchedWordSpans.length, 4);
    expect(client.starts, 1);
    await engine.close();
  });

  test('disposing a rejected session keeps the owner take and its updates',
      () async {
    final client = ExclusiveClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    await TasmeeReferenceStore.instance.load();
    final range =
        TasmeeReferenceStore.instance.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    final mainRecorder = FakeRecorder();
    final main = RecitationSession(
        config: const MuaalemConfig(),
        engine: engine,
        recorder: mainRecorder,
        range: range);
    var mainMatches = 0;
    var secondMatches = 0;
    main.onMatchedWords = (_, __) => mainMatches++;
    await main.startLive();

    final second = RecitationSession(
        config: const MuaalemConfig(),
        engine: engine,
        recorder: FakeRecorder(),
        range: range);
    second.onMatchedWords = (_, __) => secondMatches++;
    await second.startLive();
    expect(second.state.value, RecitationState.error);
    // التخلص من الجلسة المرفوضة لا يمسّ محاولة المالك ولا مستمعه.
    second.dispose();

    mainRecorder.speak();
    await main.stopLive();
    expect(main.state.value, RecitationState.finished);
    expect(client.cancelled, isFalse);
    // تحديثات المطابقات وصلت مالك المحاولة وحده — مستمع الجلسة
    // المرفوضة لم يُستبدل بمستمعها قبل الرفض.
    expect(mainMatches, greaterThan(0));
    expect(secondMatches, 0);
    await engine.close();
  });

  test('cancelling a rejected session releases only its own recorder',
      () async {
    final client = ExclusiveClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    await TasmeeReferenceStore.instance.load();
    final range =
        TasmeeReferenceStore.instance.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    final mainRecorder = FakeRecorder();
    final main = RecitationSession(
        config: const MuaalemConfig(),
        engine: engine,
        recorder: mainRecorder,
        range: range);
    await main.startLive();

    final second = RecitationSession(
        config: const MuaalemConfig(),
        engine: engine,
        recorder: FakeRecorder(),
        range: range);
    await second.startLive();
    expect(second.state.value, RecitationState.error);
    // إلغاء تحريري للجلسة المرفوضة — لا يلغي محاولة الجلسة الأولى.
    await second.cancelV4Live();
    expect(engine.hasActiveTake, isTrue);
    expect(main.state.value, RecitationState.recording);

    mainRecorder.speak();
    await main.stopLive();
    expect(main.state.value, RecitationState.finished);
    expect(client.starts, 1);
    await engine.close();
  });

  test('disposing an owning live session frees the engine take', () async {
    final client = ExclusiveClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    await TasmeeReferenceStore.instance.load();
    final range =
        TasmeeReferenceStore.instance.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    final firstRecorder = FakeRecorder();
    final first = RecitationSession(
        config: const MuaalemConfig(),
        engine: engine,
        recorder: firstRecorder,
        range: range);
    await first.startLive();
    expect(first.state.value, RecitationState.recording);
    expect(engine.hasActiveTake, isTrue);

    // الخروج أثناء جلسة مالكة حية — الإيقاف ينهي المحاولة (لا فرع الدمج
    // الذي يترك المحرك مشغولًا فترفض الجلسة التالية).
    first.dispose();
    while (first.state.value != RecitationState.finished &&
        first.state.value != RecitationState.error) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(engine.hasActiveTake, isFalse);

    final secondRecorder = FakeRecorder();
    final second = RecitationSession(
        config: const MuaalemConfig(),
        engine: engine,
        recorder: secondRecorder,
        range: range);
    await second.startLive();
    expect(second.state.value, RecitationState.recording);
    secondRecorder.speak();
    await second.stopLive();
    expect(second.state.value, RecitationState.finished);
    expect(client.starts, 2);
    await engine.close();
  });
}
