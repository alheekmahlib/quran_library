import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_ctrl.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_mode.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_state.dart';
import 'package:quran_library/src/tasmee/engine/recitation_state.dart';
import 'package:quran_library/src/tasmee/engine/tasmee_error_kind.dart';
import 'package:quran_library/src/tasmee/presentation/widgets/tasmee_control_widget.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

TasmeeWordCorrection _correction({String key = '1:3'}) =>
    TasmeeWordCorrection(
      key: key,
      wordText: 'ٱلرَّحِيمِ',
      contextWordText: 'ٱلْحَمْدُ',
      errorKind: TasmeeErrorKind.normal,
      suraIdx: 1,
      ayaIdx: 1,
      wordNumber: 3,
      verseIdx: 0,
      wordIdx: 2,
      errorType: 'replace',
      expectedSymbol: 'ر',
      predictedSymbol: 'ل',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('tasmee-correction-test-');
    PathProviderPlatform.instance = _Paths(temp.path);
    await GetStorage.init();
    Get.testMode = true;
  });
  tearDownAll(() async {
    await temp.delete(recursive: true);
  });

  // سيناريوهان في اختبار واحد: المتحكم مفرد Getx وحالته الثابتة تعبر
  // حدود testWidgets فلا يُعزل الاختباران المتتاليان ببعضهما.
  testWidgets('the shared bar opens the correction sheet, skip and accept resume',
      (tester) async {
    final ctrl = TasmeeCtrl.instance;
    ctrl.state.engineMode.value = TasmeeEngineMode.offline;
    ctrl.state.mode.value = TasmeeMode.corrector;
    ctrl.state.sessionState.value = RecitationState.paused;
    ctrl.state.wordStatuses.clear();
    addTearDown(() {
      ctrl.state.mode.value = TasmeeMode.tasmee;
      ctrl.state.activeWordCorrection.value = null;
      ctrl.state.wordRetryOutcome.value = null;
      ctrl.state.wordRetryFeedback.value = null;
      ctrl.state.sessionState.value = RecitationState.idle;
      ctrl.state.wordStatuses.clear();
    });
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: TasmeeControlWidget(isDark: false),
        ),
      ),
    ));

    // (1) التخطي: فتح الشيت تلقائيًا ثم تخطي الكلمة يستأنف الجلسة.
    ctrl.state.activeWordCorrection.value = _correction();
    await tester.pumpAndSettle();
    expect(find.text('تصحيح الكلمة'), findsOneWidget);
    expect(find.text('تخطَّ الكلمة'), findsOneWidget);

    // أثناء الالتقاط: زر الاستماع معطّل — صوت السماعة يدخل الميكروفون.
    var listen = tester.widget<IconButton>(find
        .ancestor(
            of: find.byIcon(Icons.volume_up_rounded),
            matching: find.byType(IconButton))
        .first);
    expect(listen.onPressed, isNotNull);
    ctrl.state.isWordRetryListening.value = true;
    // بلا pumpAndSettle: مؤشر الاستماع دوراني لا يستقر.
    await tester.pump();
    listen = tester.widget<IconButton>(find
        .ancestor(
            of: find.byIcon(Icons.volume_up_rounded),
            matching: find.byType(IconButton))
        .first);
    expect(listen.onPressed, isNull);
    ctrl.state.isWordRetryListening.value = false;
    await tester.pumpAndSettle();

    await tester.tap(find.text('تخطَّ الكلمة'));
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.pump();
    expect(find.text('تصحيح الكلمة'), findsNothing);
    expect(ctrl.state.activeWordCorrection.value, isNull);

    // (2) القبول: محاولة صحيحة تعلّم الكلمة خضراء وتغلق الشيت.
    ctrl.state.activeWordCorrection.value = _correction();
    await tester.pumpAndSettle();
    expect(find.text('تصحيح الكلمة'), findsOneWidget);

    ctrl.state.wordRetryOutcome.value = TasmeeWordRetryOutcome.correct;
    await tester.pumpAndSettle();
    expect(find.text('متابعة'), findsOneWidget);

    await tester.tap(find.text('متابعة'));
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.pump();
    expect(find.text('تصحيح الكلمة'), findsNothing);
    expect(ctrl.state.activeWordCorrection.value, isNull);
    // القبول (Zipformer) يعلّم الكلمة خضراء ويحميها من التقييم النهائي.
    expect(ctrl.state.wordStatuses['1:3'], TasmeeWordStatus.correct);
  });
}
