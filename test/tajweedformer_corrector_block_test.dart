import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_ctrl.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_mode.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_state.dart';
import 'package:quran_library/src/tasmee/engine/recitation_state.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('tasmee-corrector-test-');
    PathProviderPlatform.instance = _Paths(temp.path);
    await GetStorage.init();
    Get.testMode = true;
  });
  tearDownAll(() async {
    await temp.delete(recursive: true);
  });

  test('V4 corrector start is blocked without preparing an engine',
      () async {
    final ctrl = TasmeeCtrl.instance;
    ctrl.state.sessionState.value = RecitationState.idle;
    ctrl.state.engineMode.value = TasmeeEngineMode.tajweedFormer;
    ctrl.state.mode.value = TasmeeMode.corrector;
    ctrl.state.isTasmeeMode.value = true;
    addTearDown(() {
      ctrl.state.mode.value = TasmeeMode.tasmee;
      ctrl.state.isTasmeeMode.value = false;
      ctrl.state.lastError.value = '';
    });
    await ctrl.startRecording();
    expect(
      ctrl.state.lastError.value,
      'التصحيح الفوري للكلمات غير متاح مع TajweedFormer بعد؛ اختر نمط التسميع.',
    );
    expect(ctrl.isRecording, isFalse);
    expect(ctrl.isProcessing, isFalse);
    expect(ctrl.state.isPreparingEngine.value, isFalse);
  });

  test('a second start during launch or pause never opens another session',
      () async {
    final ctrl = TasmeeCtrl.instance;
    ctrl.state.engineMode.value = TasmeeEngineMode.offline;
    ctrl.state.mode.value = TasmeeMode.tasmee;
    ctrl.state.isTasmeeMode.value = true;
    ctrl.state.sessionState.value = RecitationState.idle;
    ctrl.state.lastError.value = '';
    addTearDown(() {
      ctrl.state.isTasmeeMode.value = false;
      ctrl.state.sessionState.value = RecitationState.idle;
      ctrl.state.lastError.value = '';
      ctrl.state.isPreparingEngine.value = false;
    });

    // نافذة البدء: الحارس التهيئي مفعّل (إذن ميكروفون/تسجيل محاولة V4) —
    // طلب ثانٍ يُرفض فورًا بلا إنشاء جلسة.
    ctrl.state.isPreparingEngine.value = true;
    await ctrl.startRecording();
    expect(ctrl.state.lastError.value, isEmpty);

    // جلسة قائمة متوقفة (تصحيح كلمة) — كذلك لا تبدأ جلسة ثانية فوقها.
    ctrl.state.isPreparingEngine.value = false;
    ctrl.state.sessionState.value = RecitationState.paused;
    await ctrl.startRecording();
    expect(ctrl.state.lastError.value, isEmpty);
    expect(ctrl.state.sessionState.value, RecitationState.paused);
  });
}
