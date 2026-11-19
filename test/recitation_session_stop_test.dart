import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:quran_library/src/tasmee/engine/models/muaalem_config.dart';
import 'package:quran_library/src/tasmee/engine/models/recitation_result.dart';
import 'package:quran_library/src/tasmee/engine/quran_reference.dart';
import 'package:quran_library/src/tasmee/engine/recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/recitation_session.dart';
import 'package:quran_library/src/tasmee/engine/recitation_state.dart';
import 'package:record/record.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

/// محرّك يعدّ استدعاءات التقييم — الإيقاف المكرر يجب ألا يقيّم مرتين.
class CountingEngine implements RecitationEngine {
  int evaluations = 0;

  @override
  Future<RecitationResult> correctRecitation({
    required Uint8List wavBytes,
    MuaalemConfig config = const MuaalemConfig(),
    double errorRatio = 0.1,
    int? suraIdx,
    int? ayaIdx,
    QuranReferenceRange? range,
    String? referenceText,
  }) async {
    evaluations++;
    return const RecitationResult();
  }

  @override
  Future<bool> isHealthy() async => true;

  @override
  String? getVerseText({required int suraIdx, required int ayaIdx}) => null;

  @override
  void dispose() {}
}

/// مسجّل دفعي يكتب ملفًا فعلًا عند البدء — إيقافه قابل للتعليق ببوابة
/// لإثبات سلوك الطلبات المتداخلة أثناء الإيقاف الجاري.
class GatedFileBatchRecorder implements AudioRecorder {
  String? path;
  int stopCalls = 0;
  final Completer<void> stopGate = Completer<void>();

  @override
  Future<bool> hasPermission({bool request = true}) async => true;

  @override
  Future<void> start(RecordConfig config, {required String path}) async {
    this.path = path;
    File(path).writeAsBytesSync([1, 2, 3, 4]);
  }

  @override
  Future<String?> stop() async {
    stopCalls++;
    await stopGate.future;
    return path;
  }

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('session-stop-test-');
    PathProviderPlatform.instance = _Paths(temp.path);
  });
  tearDownAll(() async {
    await temp.delete(recursive: true);
  });

  test('two overlapping stop calls evaluate the recording once', () async {
    final recorder = GatedFileBatchRecorder();
    final engine = CountingEngine();
    final session = RecitationSession(
        config: const MuaalemConfig(), engine: engine, recorder: recorder);
    await session.start();
    expect(session.state.value, RecitationState.recording);

    // طلبا إيقاف متداخلان (مؤقّت سكون + زر إيقاف مثلًا) والأول معلّق
    // داخل إيقاف المسجّل — الثاني لا يفتح تقييمًا ثانيًا فوق الأول.
    final first = session.stop();
    final second = session.stop();
    await Future<void>.delayed(Duration.zero);
    recorder.stopGate.complete();
    await Future.wait([first, second]);

    expect(engine.evaluations, 1);
    expect(recorder.stopCalls, 1);
    expect(session.state.value, RecitationState.finished);
  });

  test('stopping again after completion keeps the finished result', () async {
    final recorder = GatedFileBatchRecorder();
    final engine = CountingEngine();
    final session = RecitationSession(
        config: const MuaalemConfig(), engine: engine, recorder: recorder);
    await session.start();
    recorder.stopGate.complete();
    await session.stop();
    expect(session.state.value, RecitationState.finished);
    expect(engine.evaluations, 1);

    // إيقاف بعد الاكتمال — يعيد نتيجة الأول نفسها؛ لا يقرأ ملفًا محذوفًا
    // فيقلب الجلسة المنتهية إلى خطأ.
    await session.stop();
    expect(engine.evaluations, 1);
    expect(session.state.value, RecitationState.finished);
    expect(session.lastError.value, isEmpty);
  });

  test('release during an in-flight stop waits for its evaluation',
      () async {
    final recorder = GatedFileBatchRecorder();
    final engine = CountingEngine();
    final session = RecitationSession(
        config: const MuaalemConfig(), engine: engine, recorder: recorder);
    await session.start();

    final stopping = session.stop();
    final releasing = session.release();
    var released = false;
    unawaited(releasing.then((_) => released = true));
    await Future<void>.delayed(Duration.zero);
    // الإيقاف معلّق عند بوابة المسجّل — التحرير لم يعد بعد.
    expect(released, isFalse);

    recorder.stopGate.complete();
    await Future.wait([stopping, releasing]);
    // التحرير انتظر اكتمال التقييم: تقييم واحد، وإيقاف مسجّل واحد (لم
    // يفكك التحرير المسجّل تحت قراءة الإيقاف).
    expect(engine.evaluations, 1);
    expect(recorder.stopCalls, 1);
    expect(released, isTrue);
  });
}
