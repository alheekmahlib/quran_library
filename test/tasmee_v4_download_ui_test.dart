import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:quran_library/src/tasmee/constants/tasmee_storage_constants.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_ctrl.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_state.dart';
import 'package:quran_library/src/tasmee/core/services/tajweedformer_prefetch_service.dart';
import 'package:quran_library/src/tasmee/presentation/widgets/tasmee_settings_sheet.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class _FakePrefetch extends TajweedFormerPrefetchService {
  _FakePrefetch({this.error, this.available = true})
      : super(clientFactory: () async => null);

  final Object? error;
  final bool available;
  double? lastProgress;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> prefetch(
      {bool unmeteredOnly = false,
      void Function(double progress)? onProgress}) async {
    if (!available) return false;
    if (error != null) throw error!;
    onProgress?.call(0.4);
    return true;
  }

  @override
  Future<bool> removeModels() async => available;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('tasmee-v4-download-');
    PathProviderPlatform.instance = _Paths(dir.path);
    await GetStorage.init();
    Get.testMode = true;
  });
  tearDownAll(() async => dir.delete(recursive: true));

  Future<void> openSheet(WidgetTester tester) async {
    final ctrl = TasmeeCtrl.instance;
    ctrl.state.engineMode.value = TasmeeEngineMode.tajweedFormer;
    ctrl.state.isV4ModelReady.value = false;
    ctrl.state.isDownloadingV4Model.value = false;
    ctrl.state.lastError.value = '';
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      return Scaffold(
          body: TextButton(
        onPressed: () =>
            showTasmeeSettingsSheet(context: context, isDark: false),
        child: const Text('open'),
      ));
    })));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('not downloaded shows the V4 download row with wifi-only',
      (tester) async {
    await openSheet(tester);
    expect(find.text('تنزيل نموذج V4'), findsOneWidget);
    expect(find.text('التنزيل عبر Wi-Fi فقط'), findsOneWidget);
    final ctrl = TasmeeCtrl.instance;
    await tester.tap(find.text('التنزيل عبر Wi-Fi فقط'));
    await tester.pumpAndSettle();
    expect(ctrl.state.v4WifiOnly.value, isFalse);
    expect(GetStorage().read(TasmeeStorageConstants.v4WifiOnly), isFalse);
  });

  testWidgets('ready shows offline note with remove action', (tester) async {
    await openSheet(tester);
    final ctrl = TasmeeCtrl.instance;
    ctrl.state.isV4ModelReady.value = true;
    ctrl.update([TasmeeUpdateIds.control]);
    await tester.pumpAndSettle();
    expect(find.text('نموذج V4 جاهز — التسميع يعمل دون إنترنت'), findsOneWidget);
    expect(find.text('حذف النموذج'), findsOneWidget);
    expect(find.text('تنزيل نموذج V4'), findsNothing);
  });

  testWidgets('downloading shows progress', (tester) async {
    await openSheet(tester);
    final ctrl = TasmeeCtrl.instance;
    ctrl.state.isDownloadingV4Model.value = true;
    ctrl.state.v4ModelDownloadProgress.value = 0.42;
    ctrl.update([TasmeeUpdateIds.control]);
    await tester.pumpAndSettle();
    expect(find.text('تنزيل نموذج TajweedFormer — 42%'), findsOneWidget);
  });

  test('downloadV4Model marks ready and stores progress', () async {
    final ctrl = TasmeeCtrl(v4PrefetchService: _FakePrefetch());
    final ok = await ctrl.downloadV4Model();
    expect(ok, isTrue);
    expect(ctrl.state.isV4ModelReady.value, isTrue);
    expect(ctrl.state.v4ModelDownloadProgress.value, 1);
    expect(ctrl.state.isDownloadingV4Model.value, isFalse);
  });

  test('downloadV4Model maps a missing key to the Arabic hint', () async {
    final ctrl = TasmeeCtrl(
        v4PrefetchService:
            _FakePrefetch(error: StateError('Quran Lab key is not configured')));
    final ok = await ctrl.downloadV4Model();
    expect(ok, isFalse);
    expect(ctrl.state.isV4ModelReady.value, isFalse);
    expect(ctrl.state.lastError.value,
        'مفتاح Quran Lab غير مضبوط للتطبيق (QURANLAB_KEY).');
  });

  test('downloadV4Model reports a missing bridge', () async {
    final ctrl = TasmeeCtrl(v4PrefetchService: _FakePrefetch(available: false));
    final ok = await ctrl.downloadV4Model();
    expect(ok, isFalse);
    expect(ctrl.state.lastError.value,
        'جسر TajweedFormer غير متوفر على هذا الجهاز.');
  });

  test('removeV4Model clears the ready flag', () async {
    final ctrl = TasmeeCtrl(v4PrefetchService: _FakePrefetch());
    ctrl.state.isV4ModelReady.value = true;
    await ctrl.removeV4Model();
    expect(ctrl.state.isV4ModelReady.value, isFalse);
    expect(ctrl.state.v4ModelDownloadProgress.value, 0);
  });
}
