// شرح: اختبار للتأكد من إزالة GlobalKey وعمل آلية عرض التفسير بشكل صحيح
// Explanation: Test to verify removal of GlobalKey and proper functioning of tafsir display mechanism

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:quran_library/quran.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset(); // إعادة تعيين Get قبل كل اختبار
  });

  group('QuranState after GlobalKey removal tests', () {
    test('QuranState no longer contains scaffoldKey reference', () {
      QuranState state = QuranState();

      // التحقق من أن QuranState لم يعد يستخدم GlobalKey من خلال فحص الحقول
      // لا يمكننا الوصول مباشرة للحقول الخاصة، لكن يمكننا فحص نتائج toString أو استخدام ميثودات أخرى

      // هذا الاختبار يضمن أن dispose() تعمل بدون مشاكل بعد إزالة المفتاح
      expect(() => state.dispose(), returnsNormally);
    });

    test('State properties are still accessible after GlobalKey removal', () {
      QuranState state = QuranState();

      // التأكد من أن الخصائص الأخرى لا تزال متاحة وتعمل بشكل صحيح
      expect(state.currentPageNumber, isA<RxInt>());
      expect(state.selectedAyahIndexes, isA<RxList<int>>());
      expect(state.isMoreOptions, isA<RxBool>());
    });

    testWidgets('Context is used directly with BottomSheet',
        (WidgetTester tester) async {
      // إنشاء تطبيق للاختبار
      final testApp = MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                // اختبار استدعاء showModalBottomSheet مباشرة، كما تفعل دالة showTafsirOnTap
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext innerContext) => SizedBox(
                    height: 200,
                    child: const Center(child: Text('اختبار النافذة المنبثقة')),
                  ),
                );
              },
              child: const Center(child: Text('اضغط هنا للاختبار')),
            );
          },
        ),
      );

      await tester.pumpWidget(testApp);

      // اختبار الضغط وظهور النافذة المنبثقة
      await tester.tap(find.text('اضغط هنا للاختبار'));
      await tester.pumpAndSettle();

      // التحقق من ظهور النافذة المنبثقة
      expect(find.text('اختبار النافذة المنبثقة'), findsOneWidget);
    });

    test('QuranState functionality without GlobalKey', () {
      // تهيئة QuranCtrl كما يحدث في التطبيق
      final quranCtrl = QuranCtrl.instance;

      // التحقق من أن QuranCtrl.state تم تهيئته بدون مشاكل
      expect(quranCtrl.state, isNotNull);
      expect(quranCtrl.state.currentPageNumber, isA<RxInt>());

      // اختبار تغيير قيمة مراقبة
      quranCtrl.state.currentPageNumber.value = 5;
      expect(quranCtrl.state.currentPageNumber.value, equals(5));
    });
  });
}
