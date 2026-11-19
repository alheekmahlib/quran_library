import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_ctrl.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_state.dart';
import 'package:quran_library/src/tasmee/engine/models/tasmee_tolerance.dart';
import 'package:quran_library/src/tasmee/presentation/widgets/tasmee_settings_sheet.dart';

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
  late Directory dir;
  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('tasmee-settings-');
    PathProviderPlatform.instance = _Paths(dir.path);
    await GetStorage.init();
    Get.testMode = true;
  });
  tearDownAll(() async => dir.delete(recursive: true));

  Future<void> openSheet(WidgetTester tester) async {
    final ctrl = TasmeeCtrl.instance;
    ctrl.state.engineMode.value = TasmeeEngineMode.tajweedFormer;
    ctrl.state.tolerance.value = const TasmeeToleranceProfile();
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

  Finder axisRow(String title) => find
      .ancestor(of: find.text(title), matching: find.byType(Column))
      .first;

  testWidgets('V4 categories can be changed independently', (tester) async {
    await openSheet(tester);
    final ctrl = TasmeeCtrl.instance;
    await tester.scrollUntilVisible(find.text('المدود'), 220,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('الحروف والكلمات'), findsOneWidget);
    expect(find.text('التشكيل والحركات'), findsOneWidget);
    expect(find.text('المدود'), findsOneWidget);
    final row = axisRow('التشكيل والحركات');
    await tester.tap(find.descendant(of: row, matching: find.text('تجاهل')));
    await tester.pumpAndSettle();
    expect(ctrl.state.tolerance.value.tashkeel, TasmeeToleranceLevel.skip);
    expect(ctrl.state.tolerance.value.letters, TasmeeToleranceLevel.balanced);
    expect(ctrl.state.tolerance.value.madd, TasmeeToleranceLevel.balanced);
  });

  testWidgets('preset chip applies one level to every axis', (tester) async {
    await openSheet(tester);
    final ctrl = TasmeeCtrl.instance;
    await tester.scrollUntilVisible(find.text('مُيسّر'), 220,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('متقن'));
    await tester.pumpAndSettle();
    final profile = ctrl.state.tolerance.value;
    expect(profile.letters, TasmeeToleranceLevel.strict);
    expect(profile.tashkeel, TasmeeToleranceLevel.strict);
    expect(profile.madd, TasmeeToleranceLevel.strict);
    expect(ctrl.state.strictness.value, TasmeeStrictness.strict);
    expect(
        find.text('تدقيق عالٍ يلتقط التغيرات الدقيقة في التشكيل والمدود'),
        findsOneWidget);
    expect(find.text('مخصّص'), findsNothing);
  });

  testWidgets('a per-axis change shows the custom state and description',
      (tester) async {
    await openSheet(tester);
    final ctrl = TasmeeCtrl.instance;
    await tester.scrollUntilVisible(find.text('المدود'), 220,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('مخصّص'), findsNothing);
    final row = axisRow('الحروف والكلمات');
    await tester.tap(find.descendant(of: row, matching: find.text('متسامح')));
    await tester.pumpAndSettle();
    expect(find.text('مخصّص'), findsOneWidget);
    expect(find.text('مخصّص — مستويات مستقلة لكل محور'), findsOneWidget);
    expect(ctrl.state.tolerance.value.letters, TasmeeToleranceLevel.lenient);
    expect(ctrl.state.tolerance.value.tashkeel, TasmeeToleranceLevel.balanced);
    // الرجوع إلى مسبق عام يزيل شارة التخصيص.
    await tester.tap(find.text('متوازن').first);
    await tester.pumpAndSettle();
    expect(find.text('مخصّص'), findsNothing);
    expect(ctrl.state.tolerance.value.letters, TasmeeToleranceLevel.balanced);
  });

  testWidgets('madd skip is selectable and leaves other axes intact',
      (tester) async {
    await openSheet(tester);
    final ctrl = TasmeeCtrl.instance;
    await tester.scrollUntilVisible(find.text('المدود'), 220,
        scrollable: find.byType(Scrollable).last);
    final row = axisRow('المدود');
    await tester.tap(find.descendant(of: row, matching: find.text('تجاهل')));
    await tester.pumpAndSettle();
    expect(ctrl.state.tolerance.value.madd, TasmeeToleranceLevel.skip);
    expect(ctrl.state.tolerance.value.letters, TasmeeToleranceLevel.balanced);
    expect(ctrl.state.tolerance.value.tashkeel, TasmeeToleranceLevel.balanced);
  });
}
