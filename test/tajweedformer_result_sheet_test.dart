import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_ctrl.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_mode.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_state.dart';
import 'package:quran_library/src/tasmee/engine/models/recitation_result.dart';
import 'package:quran_library/src/tasmee/presentation/widgets/tasmee_result_sheet.dart';
import 'package:quran_library/quran.dart' as q;

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
  const diagnostics = bool.fromEnvironment('TAJWEEDFORMER_SHOW_DIAGNOSTICS');
  late Directory temp;
  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('tasmee-result-test-');
    PathProviderPlatform.instance = _Paths(temp.path);
    await GetStorage.init();
    Get.testMode = true;
  });
  tearDownAll(() async {
    await temp.delete(recursive: true);
  });

  testWidgets('partial V4 results hide unverified error details',
      (tester) async {
    final ctrl = TasmeeCtrl.instance;
    ctrl.state.engineMode.value = TasmeeEngineMode.tajweedFormer;
    const error = RecitationError(
        errorType: 'normal',
        speechErrorType: 'replace',
        expectedPh: 'ب',
        predictedPh: 'ت',
        suraIdx: 1,
        ayaIdx: 1,
        wordIdx: 2);
    ctrl.state.lastResult.value = const RecitationResult(
      uthmaniText: 'test',
      errors: [error],
      assessmentComplete: false,
    );
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () =>
                        showTasmeeResultSheet(context: context, isDark: false),
                    child: const Text('open'))))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'تم تتبّع التلاوة. لا تُعرض ملاحظات التصحيح حتى يكتمل التحقق من دقتها.'),
        findsOneWidget);
    expect(find.text(error.description), findsNothing);
    expect(
        find.textContaining(
            'Automatic tajweed feedback can be wrong. It does not replace a qualified teacher.'),
        findsOneWidget);
  }, skip: diagnostics);

  testWidgets('teacher offers manual navigation without claiming mastery',
      (tester) async {
    final ctrl = TasmeeCtrl.instance;
    ctrl.state.engineMode.value = TasmeeEngineMode.tajweedFormer;
    ctrl.state.mode.value = TasmeeMode.teacher;
    ctrl.state.teacherAyahIndex.value = 0;
    ctrl.state.teacherAyahTotal.value = 2;
    ctrl.state.lastResult.value = const RecitationResult(
      uthmaniText: 'test',
      assessmentComplete: false,
    );
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () =>
                        showTasmeeResultSheet(context: context, isDark: false),
                    child: const Text('open'))))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('إعادة الآية'), findsOneWidget);
    expect(find.text('الآية التالية'), findsOneWidget);
    expect(find.textContaining('تم تتبّع التلاوة'), findsOneWidget);
    expect(ctrl.state.lastResult.value!.isFullyCorrect, isFalse);
    ctrl.state.mode.value = TasmeeMode.tasmee;
  }, skip: diagnostics);

  testWidgets('debug diagnostics use the standard summary and word card',
      (tester) async {
    await tester.runAsync(() => q.QpcHafsWordByWordAssetsLoader.load());
    final ctrl = TasmeeCtrl.instance;
    ctrl.state.engineMode.value = TasmeeEngineMode.tajweedFormer;
    const error = RecitationError(
        errorType: 'normal',
        speechErrorType: 'replace',
        expectedPh: 'ب',
        predictedPh: 'ت',
        suraIdx: 1,
        ayaIdx: 1,
        wordIdx: 2);
    ctrl.state.lastResult.value = const RecitationResult(
      uthmaniText: 'test',
      errors: [error],
      assessmentComplete: false,
    );
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () =>
                        showTasmeeResultSheet(context: context, isDark: false),
                    child: const Text('open'))))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining(
            'ملاحظات اختبار غير مؤكدة؛ قد تكون خاطئة ولا تُعدّ حكمًا على التلاوة.'),
        findsOneWidget);
    expect(find.text(error.description), findsOneWidget);
    expect(find.text('1 / 1 / 3'), findsNothing);
    expect(find.text('ٱلرَّحۡمَٰنِ'), findsOneWidget);
    expect(find.textContaining('إجمالي'), findsOneWidget);
  }, skip: !diagnostics);
}
