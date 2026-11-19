import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/models/muaalem_config.dart';
import 'package:quran_library/src/tasmee/engine/recitation_session.dart';
import 'package:quran_library/src/tasmee/engine/recitation_state.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference_store.dart';
import 'package:record/record.dart';

import 'tajweedformer_recitation_engine_test.dart' show metadata;
import 'tajweedformer_reference_store_test.dart' show ReferenceClient;

/// مسجّل واهم يرفض أي لمسة — يثبت أن الرفض يسبق فتح الميكروفون.
class UntouchableRecorder implements AudioRecorder {
  int touches = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    touches++;
    throw StateError('recorder must not be touched');
  }
}

/// يمنح الإذن ثم يفشل عند أول استخدام فعلي — يكفي عبور فحص الإعدادات.
class PermissionOnlyRecorder implements AudioRecorder {
  @override
  Future<bool> hasPermission({bool request = true}) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('not expected in this test');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TajweedFormerRecitationEngine> buildEngine() async {
    final client = ReferenceClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    return TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
  }

  test('a V4 batch session rejects unsupported settings before any capture',
      () async {
    final engine = await buildEngine();
    final recorder = UntouchableRecorder();
    final session = RecitationSession(
      config: const MuaalemConfig(maddMonfaselLen: 5),
      engine: engine,
      recorder: recorder,
    );
    await session.start();
    expect(session.state.value, RecitationState.error);
    expect(session.lastError.value, contains('maddMonfaselLen'));
    expect(session.lastError.value, contains('TajweedFormer'));
    expect(recorder.touches, 0,
        reason: 'the refusal must happen before the microphone is opened');
    await engine.close();
  });

  test('a V4 live session rejects unsupported settings before any capture',
      () async {
    final engine = await buildEngine();
    final recorder = UntouchableRecorder();
    final session = RecitationSession(
      config: const MuaalemConfig(ghonna: 'ghonna'),
      engine: engine,
      recorder: recorder,
    );
    await session.startLive();
    expect(session.state.value, RecitationState.error);
    expect(session.lastError.value, contains('ghonna'));
    expect(recorder.touches, 0);
    await engine.close();
  });

  test('Hafs defaults with a V4 preset pass the settings check', () async {
    final engine = await buildEngine();
    final session = RecitationSession(
      config: const MuaalemConfig(
          tajweedFormerPreset: TajweedFormerFeedbackPreset.sensitive),
      engine: engine,
      recorder: PermissionOnlyRecorder(),
    );
    await session.startLive();
    // الفحص اجتاز؛ الفشل اللاحق هنا من غياب نطاق مرجعي لا من الإعدادات.
    expect(session.state.value, RecitationState.error);
    expect(session.lastError.value.contains('لا يدعم هذه الإعدادات'), isFalse,
        reason: 'supported settings must not be rejected');
    await engine.close();
  });
}
