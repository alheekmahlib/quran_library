import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/models/recitation_result.dart';
import 'package:quran_library/src/tasmee/engine/tasmee_error_kind.dart';

void main() {
  group('retryFeedbackFromErrors — خطأ أحدث محاولة إعادة نطق', () {
    test('لا أخطاء → null (المحاولة صحيحة)', () {
      expect(retryFeedbackFromErrors(const []), isNull);
    });

    test('المزيج يُنتقي خطأ الحروف الرادع ويتجاهل التشكيل والتجويد', () {
      final feedback = retryFeedbackFromErrors(const [
        RecitationError(errorType: 'tashkeel', speechErrorType: 'replace'),
        RecitationError(
            errorType: 'normal',
            speechErrorType: 'delete',
            expectedPh: 'سْ',
            predictedPh: ''),
        RecitationError(
            errorType: 'tajweed',
            speechErrorType: 'replace',
            expectedPh: 'ررَ',
            predictedPh: 'رَ'),
      ]);
      expect(feedback!.kind, TasmeeErrorKind.normal,
          reason: 'الحروف وحدها رادعة — التجويد ملاحظة');
      expect(feedback.expectedSymbol, 'سْ');
    });

    test('نطق فوق تشكيل عند غياب التجويد', () {
      final feedback = retryFeedbackFromErrors(const [
        RecitationError(errorType: 'tashkeel', speechErrorType: 'insert'),
        RecitationError(
            errorType: 'normal',
            speechErrorType: 'replace',
            expectedPh: 'س',
            predictedPh: 'ص'),
      ]);
      expect(feedback!.kind, TasmeeErrorKind.normal);
      expect(feedback.errorType, 'replace');
    });

    test('تجويد فقط (شدة) بلا خطأ حروف → لا ملقّط رادع', () {
      final feedback = retryFeedbackFromErrors(const [
        RecitationError(
          errorType: 'tajweed',
          speechErrorType: 'replace',
          expectedPh: 'ررَ',
          predictedPh: 'رَ',
          refTajweedRules: [
            TajweedRule(nameAr: 'الشدة', nameEn: 'Shaddah'),
          ],
        ),
      ]);
      expect(feedback, isNull,
          reason: 'التجويد ملاحظة غير رادعة في إعادة النطق');
    });

    test('إدراج (زيادة): متوقع فارغ والمنطوق موجود', () {
      final feedback = retryFeedbackFromErrors(const [
        RecitationError(
            errorType: 'normal',
            speechErrorType: 'insert',
            expectedPh: '',
            predictedPh: 'ق ل ق'),
      ]);
      expect(feedback!.kind, TasmeeErrorKind.normal);
      expect(feedback.errorType, 'insert');
      expect(feedback.expectedSymbol, isEmpty);
      expect(feedback.predictedSymbol, 'ق ل ق');
      expect(feedback.ruleName, isNull);
    });

    test('تشكيل فقط (غير رادع) → لا ملقّط', () {
      final feedback = retryFeedbackFromErrors(const [
        RecitationError(
            errorType: 'tashkeel',
            speechErrorType: 'delete',
            expectedPh: 'بُ',
            predictedPh: 'ب'),
      ]);
      expect(feedback, isNull,
          reason: 'التشكيل مُغتفَر في إعادة النطق فلا يُعرض خطأً رادعًا');
    });

    test('مدّ طولي (مُغتفَر) مع خطأ نطق (رادع) → يُنتقى الرادع', () {
      final feedback = retryFeedbackFromErrors(const [
        RecitationError(
          errorType: 'tajweed',
          speechErrorType: 'replace',
          expectedPh: 'اا',
          predictedPh: 'اااا',
          refTajweedRules: [
            TajweedRule(
                nameAr: 'المدّ',
                nameEn: 'Madd',
                goldenLen: 2,
                correctnessType: 'count'),
          ],
        ),
        RecitationError(
            errorType: 'normal',
            speechErrorType: 'replace',
            expectedPh: 'س',
            predictedPh: 'ص'),
      ]);
      expect(feedback, isNotNull);
      expect(feedback!.kind, TasmeeErrorKind.normal,
          reason: 'الشارة تعرض الخطأ الرادع لا المدّ المُغتفَر');
      expect(feedback.predictedSymbol, 'ص');
    });
  });

  group('isWordRetryAcceptable — قبول إعادة النطق (صرامة مخففة موجَّهًا)', () {
    test('بلا أخطاء → مقبولة', () {
      const result = RecitationResult(uthmaniText: 'كلمة', errors: []);
      expect(isWordRetryAcceptable(result), isTrue);
    });

    test('تشكيل فقط → مقبولة (ارتعاج حركة في نطق معزول ليس خطأ)', () {
      const result = RecitationResult(
        uthmaniText: 'كلمة',
        errors: [
          RecitationError(errorType: 'tashkeel', speechErrorType: 'replace'),
          RecitationError(errorType: 'tashkeel', speechErrorType: 'delete'),
        ],
      );
      expect(isWordRetryAcceptable(result), isTrue);
    });

    test('مدّ طولي فقط (قاعدة count) → مقبولة', () {
      const result = RecitationResult(
        uthmaniText: 'كلمة',
        errors: [
          RecitationError(
            errorType: 'tajweed',
            speechErrorType: 'replace',
            refTajweedRules: [
              TajweedRule(
                  nameAr: 'المدّ',
                  nameEn: 'Madd',
                  goldenLen: 2,
                  correctnessType: 'count'),
            ],
          ),
        ],
      );
      expect(isWordRetryAcceptable(result), isTrue);
    });

    test('تجويد رمزي (شدة — بلا قاعدة count) → مقبولة (ملاحظة لا رادع)', () {
      // إعادة نطق كلمة معزولة: النموذج لا يفرّق الشدة/الغنة/القلقلة
      // بثبات — الحروف وحدها رادعة، وإلا استحال الاجتياز (سجل فعلي:
      // مطابقة 100% مع خطأّي رمزٍ تجويديين رُفضا مرارًا).
      const result = RecitationResult(
        uthmaniText: 'كلمة',
        errors: [
          RecitationError(
            errorType: 'tajweed',
            speechErrorType: 'replace',
            refTajweedRules: [
              TajweedRule(nameAr: 'الشدة', nameEn: 'Shaddah'),
            ],
          ),
        ],
      );
      expect(isWordRetryAcceptable(result), isTrue);
    });

    test('خطأ نطق (استبدال حرف) → مرفوضة', () {
      const result = RecitationResult(
        uthmaniText: 'كلمة',
        errors: [
          RecitationError(
              errorType: 'normal',
              speechErrorType: 'replace',
              expectedPh: 'س',
              predictedPh: 'ص'),
        ],
      );
      expect(isWordRetryAcceptable(result), isFalse);
    });

    test('حرف زائد (normal/insert) → مرفوضة', () {
      const result = RecitationResult(
        uthmaniText: 'كلمة',
        errors: [
          RecitationError(
              errorType: 'normal', speechErrorType: 'insert', predictedPh: 'ق'),
        ],
      );
      expect(isWordRetryAcceptable(result), isFalse);
    });

    test('بلا تطابق → مرفوضة مهما كانت الأخطاء', () {
      const result = RecitationResult(noMatchMessage: 'لم يُعثر على تطابق');
      expect(isWordRetryAcceptable(result), isFalse);
    });
  });

  group('isRecitationAcceptable — إتقان الآية/الصفحة (حلقة المعلم)', () {
    test('تشكيل ومدّ فقط → مقبولة (لا تُعيد الآية إلى ما لا نهاية)', () {
      const result = RecitationResult(
        uthmaniText: 'آية',
        errors: [
          RecitationError(errorType: 'tashkeel', speechErrorType: 'replace'),
          RecitationError(
            errorType: 'tajweed',
            speechErrorType: 'replace',
            refTajweedRules: [
              TajweedRule(
                  nameAr: 'المدّ',
                  nameEn: 'Madd',
                  goldenLen: 2,
                  correctnessType: 'count'),
            ],
          ),
        ],
      );
      expect(isRecitationAcceptable(result), isTrue);
    });

    test('خطأ حروف رادع → غير مقبولة (الإعادة مبرَّرة)', () {
      const result = RecitationResult(
        uthmaniText: 'آية',
        errors: [
          RecitationError(
              errorType: 'normal',
              speechErrorType: 'replace',
              expectedPh: 'س',
              predictedPh: 'ص'),
        ],
      );
      expect(isRecitationAcceptable(result), isFalse);
    });
  });
}
