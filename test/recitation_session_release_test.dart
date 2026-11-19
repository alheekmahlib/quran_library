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

/// محرّك دفعي خامل — أي محاولة تقييم عبره خطأ: التحرير لا يقيّم أبدًا.
class IdleEngine implements RecitationEngine {
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
    throw StateError('release must not evaluate');
  }

  @override
  Future<bool> isHealthy() async => true;

  @override
  String? getVerseText({required int suraIdx, required int ayaIdx}) => null;

  @override
  void dispose() {}
}

/// مسجّل دفعي ببوابة إيقاف — يثبت أن التحرير ينتظر اكتمال الإيقاف.
class GatedBatchRecorder implements AudioRecorder {
  bool started = false;
  bool stopped = false;
  int startCalls = 0;
  final Completer<void> stopGate = Completer<void>();

  @override
  Future<bool> hasPermission({bool request = true}) async => true;

  @override
  Future<void> start(RecordConfig config, {required String path}) async {
    startCalls++;
    started = true;
  }

  @override
  Future<String?> stop() async {
    await stopGate.future;
    stopped = true;
    return null;
  }

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// مسجّل يعلّق طلب الإذن — يحرّر المحاولة قبل أن يبدأ الالتقاط فعلًا.
/// إيقافه فوري: لم يبدأ التسجيل أصلًا فلا بوابة إيقاف هنا.
class DelayedPermissionBatchRecorder extends GatedBatchRecorder {
  final permission = Completer<bool>();
  @override
  Future<bool> hasPermission({bool request = true}) => permission.future;
  @override
  Future<String?> stop() async {
    stopped = true;
    return null;
  }
}

/// مسجّل يعلّق بدء الالتقاط نفسه — التحرير ينتظر اكتمال البدء قبل
/// إيقاف المسجّل فلا يعود قبل استقرار القناة. إيقافه فوري (بلا بوابة
/// إيقاف) كي لا يعلّق التفكيك بعد اكتمال البدء.
class GatedStartBatchRecorder extends GatedBatchRecorder {
  final startGate = Completer<void>();
  @override
  Future<void> start(RecordConfig config, {required String path}) async {
    await startGate.future;
    started = true;
  }

  @override
  Future<String?> stop() async {
    stopped = true;
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('session-release-test-');
    PathProviderPlatform.instance = _Paths(temp.path);
  });
  tearDownAll(() async {
    await temp.delete(recursive: true);
  });

  test('releasing a recording batch retry awaits recorder teardown',
      () async {
    final recorder = GatedBatchRecorder();
    final session = RecitationSession(
        config: const MuaalemConfig(), engine: IdleEngine(), recorder: recorder);
    await session.start();
    expect(session.state.value, RecitationState.recording);

    final releasing = session.release();
    var released = false;
    unawaited(releasing.then((_) => released = true));
    await Future<void>.delayed(Duration.zero);
    // ما يزال ينتظر اكتمال إيقاف المسجّل — لا يُستأنف الميكروفون قبله.
    expect(released, isFalse);

    recorder.stopGate.complete();
    await releasing;
    expect(released, isTrue);
    expect(recorder.stopped, isTrue);
    // بلا تقييم: محرّك خامل يرمي لو استُدعي، والحالة عادت خمولًا.
    expect(session.state.value, RecitationState.idle);
  });

  test('releasing during microphone setup prevents capture entirely',
      () async {
    final recorder = DelayedPermissionBatchRecorder();
    final session = RecitationSession(
        config: const MuaalemConfig(), engine: IdleEngine(), recorder: recorder);
    final starting = session.start();
    final releasing = session.release();
    recorder.permission.complete(true);
    await starting;
    await releasing;
    // حُرّرت قبل بدء الالتقاط — لم يسجّل شيئًا وبقيت الحالة خمولًا.
    expect(recorder.started, isFalse);
    expect(session.state.value, RecitationState.idle);
  });

  test('a second start while one is pending reuses the same start',
      () async {
    final recorder = DelayedPermissionBatchRecorder();
    final session = RecitationSession(
        config: const MuaalemConfig(), engine: IdleEngine(), recorder: recorder);
    final first = session.start();
    final second = session.start();
    recorder.permission.complete(true);
    await Future.wait([first, second]);
    // طلبان متقاربان أثناء انتظار الإذن — عملية بدء واحدة على المسجّل.
    expect(recorder.startCalls, 1);
    expect(recorder.started, isTrue);
    expect(session.state.value, RecitationState.recording);
    await session.release();
    expect(session.state.value, RecitationState.idle);
  });

  test('release waits for an in-flight recorder start before teardown',
      () async {
    final recorder = GatedStartBatchRecorder();
    final session = RecitationSession(
        config: const MuaalemConfig(), engine: IdleEngine(), recorder: recorder);
    final starting = session.start();
    await Future<void>.delayed(Duration.zero);
    expect(recorder.started, isFalse); // البدء معلّق عند البوابة

    final releasing = session.release();
    var released = false;
    unawaited(releasing.then((_) => released = true));
    // البوابة مغلقة: التحرير لا يعود قبل اكتمال البدء — لو تجاهله لاستُؤنف
    // المسجّل الرئيسي فوق عملية بدء لم تستقر بعد.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(released, isFalse);

    recorder.startGate.complete();
    await starting;
    await releasing;
    expect(released, isTrue);
    // البدء اكتمل ثم فُكَّك — لم يبق التقاط ولا تقييم.
    expect(recorder.started, isTrue);
    expect(recorder.stopped, isTrue);
    expect(session.state.value, RecitationState.idle);
  });
}
