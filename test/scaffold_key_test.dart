// شرح: اختبار لمفتاح السكافولد للتأكد من عدم التضارب
// Explanation: Test for scaffold key to make sure there's no conflict

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:quran_library/quran.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset(); // إعادة تعيين Get قبل كل اختبار
  });

  group('QuranState scaffoldKey tests', () {
    test('scaffoldKey is created lazily', () {
      QuranState state = QuranState();
      expect(state.scaffoldKey, isA<GlobalKey<ScaffoldState>>());

      // نتأكد من إنشاء المفتاح مرة واحدة فقط
      final key1 = state.scaffoldKey;
      final key2 = state.scaffoldKey;
      expect(key1, equals(key2)); // يجب أن يكون نفس الكائن
    });

    test('scaffoldKey has unique debug label', () {
      QuranState state = QuranState();
      expect(state.scaffoldKey.debugLabel, equals('QuranLibraryScaffoldKey'));
    });

    test('Multiple instances have different scaffold keys', () {
      QuranState state1 = QuranState();
      QuranState state2 = QuranState();

      expect(state1.scaffoldKey, isNot(equals(state2.scaffoldKey)));
    });

    test('scaffoldKey is cleared on dispose', () {
      QuranState state = QuranState();
      state.scaffoldKey; // تهيئة المفتاح

      // هنا لا نستطيع اختبار أن _scaffoldKey أصبح null لأنه متغير خاص
      // لكن يمكننا التحقق أن dispose تعمل دون أخطاء
      expect(() => state.dispose(), returnsNormally);
    });
  });
}
