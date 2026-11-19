import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_ctrl.dart';
import 'package:quran_library/src/tasmee/core/services/tasmee_reference_store.dart';
import 'package:quran_library/src/tasmee/engine/models/muaalem_config.dart';
import 'package:quran_library/src/tasmee/engine/recitation_session.dart';
import 'package:quran_library/src/tasmee/engine/recitation_state.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference_store.dart';

import 'tajweedformer_recitation_engine_test.dart'
    show StreamingClient, metadata;
import 'tajweedformer_session_handoff_test.dart' show FakeRecorder;

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

/// يعلّق إنهاء المحاولة عند بوابة — يحاكي تقييمًا لم تكتمل نتيجته بعد.
class _GatedFinishClient extends StreamingClient {
  final finishGate = Completer<void>();
  @override
  Future<Map<String, dynamic>> finish() async {
    await finishGate.future;
    return super.finish();
  }
}

Future<TajweedFormerRecitationEngine> _engine(
    {required StreamingClient client}) async {
  final store = await TajweedFormerReferenceStore.load(
      client: client, metadata: metadata);
  await TasmeeReferenceStore.instance.load();
  return TajweedFormerRecitationEngine(
      client: client, metadata: metadata, store: store);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('tasmee-stop-lifecycle-');
    PathProviderPlatform.instance = _Paths(temp.path);
    await GetStorage.init();
    Get.testMode = true;
  });
  tearDownAll(() async {
    await temp.delete(recursive: true);
  });

  test('a stop without a session does not block stopping a later session',
      () async {
    final ctrl = TasmeeCtrl.instance;
    // المتحكم مفرد دائم — صفّر بقايا اختبار سابق قبل البدء.
    ctrl.state.lastResult.value = null;
    ctrl.state.lastError.value = '';
    // لا جلسة — الإيقاف عائد فورًا ولا يترك خلفه عملية محفوظة مكتملة
    // يُعاد تقديمها لطلب إيقاف لاحق فيتجاوز الجلسة الجديدة.
    await ctrl.stopRecording();

    final engine = await _engine(client: StreamingClient());
    final range =
        TasmeeReferenceStore.instance.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final session = RecitationSession(
        config: const MuaalemConfig(),
        engine: engine,
        recorder: FakeRecorder(),
        range: range);
    ctrl.attachSessionForTesting(session);
    await session.startLive();
    expect(session.state.value, RecitationState.recording);

    // إيقاف الجلسة الجديدة يعمل فعلًا: يوقفها ويقيّمها لا يعيد طلبًا قديمًا.
    await ctrl.stopRecording();
    expect(session.state.value, RecitationState.finished);
    expect(session.result.value, isNotNull);
    expect(ctrl.state.sessionState.value, RecitationState.finished);
    await engine.close();
  });

  test('a stale stop completing cannot touch the replacement session',
      () async {
    final ctrl = TasmeeCtrl.instance;
    // صفّر بقايا الاختبار السابق — النتيجة القديمة للاختبار الأول لا
    // تُعدّ تسريبًا من الإيقاف المعلّق هنا.
    ctrl.state.lastResult.value = null;
    ctrl.state.lastError.value = '';
    final oldClient = _GatedFinishClient();
    final oldEngine = await _engine(client: oldClient);
    final range =
        TasmeeReferenceStore.instance.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final oldRecorder = FakeRecorder();
    final old = RecitationSession(
        config: const MuaalemConfig(),
        engine: oldEngine,
        recorder: oldRecorder,
        range: range);
    ctrl.attachSessionForTesting(old);
    await old.startLive();
    oldRecorder.speak();

    // إيقاف معلّق: التقييم بانتظار نتيجة المحرك القديم عند البوابة.
    final stopping = ctrl.stopRecording();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(old.state.value, RecitationState.processing);

    // خرج المستخدم ودخل وبدأ تسجيلًا جديدًا قبل اكتمال النتيجة القديمة —
    // جلسة جديدة (محرك مستقل) حلت محل القديمة وأصبحت الحالية.
    final currentEngine = await _engine(client: StreamingClient());
    final currentRecorder = FakeRecorder();
    final current = RecitationSession(
        config: const MuaalemConfig(),
        engine: currentEngine,
        recorder: currentRecorder,
        range: range);
    ctrl.attachSessionForTesting(current);
    await current.startLive();
    expect(current.state.value, RecitationState.recording);

    // اكتملت عملية الإيقاف القديمة الآن — لا تمس الجلسة الجديدة.
    oldClient.finishGate.complete();
    await stopping;
    expect(current.state.value, RecitationState.recording,
        reason: 'اكتمال إيقاف الجلسة القديمة لا يلغي التسجيل الجديد');
    expect(ctrl.state.sessionState.value, RecitationState.recording);
    expect(ctrl.state.lastResult.value, isNull,
        reason: 'نتيجة الجلسة القديمة لا تُطبَّق على الوضع الجديد');
    expect(ctrl.state.lastError.value, isEmpty);

    // والجلسة الجديدة قابلة للإيقاف الطبيعي بعد ذلك.
    await ctrl.stopRecording();
    expect(current.state.value, RecitationState.finished);
    await oldEngine.close();
    await currentEngine.close();
  });

  test('stopping the replacement session while the old stop still pending',
      () async {
    final ctrl = TasmeeCtrl.instance;
    ctrl.state.lastResult.value = null;
    ctrl.state.lastError.value = '';
    final oldClient = _GatedFinishClient();
    final oldEngine = await _engine(client: oldClient);
    final range =
        TasmeeReferenceStore.instance.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final oldRecorder = FakeRecorder();
    final old = RecitationSession(
        config: const MuaalemConfig(),
        engine: oldEngine,
        recorder: oldRecorder,
        range: range);
    ctrl.attachSessionForTesting(old);
    await old.startLive();
    oldRecorder.speak();
    // إيقاف قديم معلّق عند بوابة التقييم — لم يكتمل بعد.
    final stoppingOld = ctrl.stopRecording();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(old.state.value, RecitationState.processing);

    // جلسة بديلة (محرك مستقل) بدأت التسجيل قبل اكتمال الإيقاف القديم.
    final currentEngine = await _engine(client: StreamingClient());
    final currentRecorder = FakeRecorder();
    final current = RecitationSession(
        config: const MuaalemConfig(),
        engine: currentEngine,
        recorder: currentRecorder,
        range: range);
    ctrl.attachSessionForTesting(current);
    await current.startLive();
    expect(current.state.value, RecitationState.recording);

    // طلب إيقاف الجديدة والقديمة ما تزال معلّقة — لا يُعاد إليه طلب
    // القديمة فيبتلع إيقافها وتستمر بالتسجيل.
    final stoppingCurrent = ctrl.stopRecording();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(current.state.value, RecitationState.finished,
        reason: 'إيقاف الجلسة الحالية يسلك مساره الخاص لا طلب الجلسة القديمة');
    expect(current.result.value, isNotNull);
    // القديمة ما تزال منتظرة عند البوابة — لم يفتحها أحد بعد.
    expect(old.state.value, RecitationState.processing);

    // الآن يكتمل الإيقاف القديم — لا يمسّ نتيجة الجديدة ولا حالتها.
    final currentResult = ctrl.state.lastResult.value;
    expect(currentResult, current.result.value);
    oldClient.finishGate.complete();
    await stoppingOld;
    await stoppingCurrent;
    expect(current.state.value, RecitationState.finished);
    expect(ctrl.state.sessionState.value, RecitationState.finished);
    expect(ctrl.state.lastResult.value, currentResult,
        reason: 'اكتمال الإيقاف القديم لا يستبدل نتيجة الجلسة الجديدة');
    await oldEngine.close();
    await currentEngine.close();
  });
}
