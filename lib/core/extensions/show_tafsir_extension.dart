part of '../../../quran.dart';

extension ShowTafsirExtension on void {
  /// -------- [onTap] --------
  /// عرض تفسير الآية عند النقر عليها
  /// Shows Tafsir when an ayah is tapped
  Future<void> showTafsirOnTap({
    required BuildContext context,
    required int surahNum,
    required int ayahNum,
    required String ayahText,
    required int pageIndex,
    required String ayahTextN,
    required int ayahUQNum,
    required int ayahNumber,
    bool? isDark,
  }) async {
    // شرح: هذا السطر لطباعة رسالة عند استدعاء الدالة للتأكد من تنفيذها
    // Explanation: This line logs when the function is called for debugging
    log('showTafsirOnTap called', name: 'TafsirUi');

    try {
      // تهيئة بيانات التفسير
      // Initialize tafsir data
      TafsirCtrl.instance.tafseerAyah = ayahText;
      TafsirCtrl.instance.surahNumber.value = surahNum;
      TafsirCtrl.instance.ayahTextNormal.value = ayahTextN;
      TafsirCtrl.instance.ayahUQNumber.value = ayahUQNum;
      QuranCtrl.instance.state.currentPageNumber.value = pageIndex + 1;

      // جلب بيانات التفسير أو الترجمة
      // Fetch tafsir or translation data
      if (TafsirCtrl.instance.isTafsir.value) {
        TafsirCtrl.instance
            .closeAndInitializeDatabase(pageNumber: pageIndex + 1);
        await TafsirCtrl.instance.fetchData(pageIndex + 1);
      } else {
        await TafsirCtrl.instance.fetchTranslate();
      }
    } catch (e) {
      log('خطأ في تهيئة التفسير: $e', name: 'TafsirUi');
      // استمرار في التنفيذ رغم الخطأ للمحاولة في عرض البيانات المتوفرة
      // Continue execution to try showing available data
    }

    // محاولة الحصول على سياق صالح لعرض النافذة المنبثقة
    // Try to get a valid context for showing bottom sheet
    BuildContext? validContext;

    // التحقق من أن السياق المرسل صالح
    // Check if passed context is valid
    try {
      if (context.mounted && context.findRenderObject() != null) {
        validContext = context;
        log('السياق المرسل صالح', name: 'TafsirUi');
      } else {
        log('السياق المرسل غير صالح، محاولة استخدام بديل', name: 'TafsirUi');
      }
    } catch (e) {
      log('خطأ في التحقق من السياق المرسل: $e', name: 'TafsirUi');
    }

    // إذا كان السياق المرسل غير صالح، نحاول استخدام Get.context
    // If passed context is invalid, try using Get.context
    if (validContext == null) {
      try {
        if (Get.context != null) {
          log('استخدام Get.context كخيار احتياطي', name: 'TafsirUi');
          validContext = Get.context;
        }
      } catch (e) {
        log('خطأ في استخدام Get.context: $e', name: 'TafsirUi');
      }
    }

    // إذا لم نتمكن من الحصول على سياق صالح
    // If we couldn't get a valid context
    if (validContext == null) {
      log('لا يوجد سياق صالح لعرض التفسير، يُرجى التأكد من تمرير سياق من شاشة نشطة',
          name: 'TafsirUi');
      // إظهار رسالة عن طريق GetX في حالة عدم توفر سياق صالح
      // Show message via GetX if no valid context is available
      try {
        // Get.snackbar(
        //   'خطأ',
        //   'لا يمكن عرض التفسير، يرجى المحاولة مرة أخرى',
        //   snackPosition: SnackPosition.BOTTOM,
        //   backgroundColor: Colors.white,
        //   colorText: Colors.white,
        // );
      } catch (_) {
        // تجاهل الأخطاء هنا لأننا في وضع معالجة الخطأ بالفعل
        // Ignore errors here as we're already handling errors
      }
      return;
    }

    // استخدام showModalBottomSheet المباشر مع السياق الصالح
    // Use direct showModalBottomSheet with valid context
    try {
      log('محاولة عرض نافذة التفسير المنبثقة', name: 'TafsirUi');
      await showModalBottomSheet(
        context: validContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        // تحسين شكل الشاشة المنبثقة
        // Improve bottom sheet appearance
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        builder: (BuildContext modalContext) {
          // استخدام Scaffold مستقل داخل BottomSheet لتجنب أخطاء "No Scaffold Found"
          // Use independent Scaffold inside BottomSheet to avoid "No Scaffold Found" errors
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(modalContext).size.height * 0.9,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Column(
                  children: [
                    ShowTafseer(
                      context: modalContext,
                      ayahUQNumber: ayahUQNum,
                      ayahNumber: ayahNumber,
                      pageIndex: pageIndex,
                      isDark: isDark!,
                      tafsirStyle: TafsirStyle(
                        backgroundColor: isDark
                            ? const Color(0xff1E1E1E)
                            : const Color(0xfffaf7f3),
                        tafsirNameWidget: Text(
                          'التفسير',
                          style: QuranLibrary().naskhStyle.copyWith(
                                fontSize: 24,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                        ),
                        fontSizeWidget: Icon(Icons.text_format_outlined,
                            size: 34,
                            color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      log('خطأ في عرض نافذة التفسير المنبثقة: $e', name: 'TafsirUi');
      // محاولة إظهار رسالة للمستخدم
      try {
        // Get.snackbar(
        //   'خطأ',
        //   'حدث خطأ أثناء عرض التفسير، يرجى المحاولة مرة أخرى',
        //   snackPosition: SnackPosition.BOTTOM,
        //   backgroundColor: Colors.red.withValues(alpha: 0.7),
        //   colorText: Colors.white,
        // );
      } catch (_) {
        // تجاهل الأخطاء في وضع معالجة الخطأ
        // Ignore errors in error handling mode
      }
    }
  }
}
