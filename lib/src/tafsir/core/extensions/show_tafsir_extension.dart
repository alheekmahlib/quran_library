part of '../../tafsir.dart';

/// GlobalKey للوصول إلى سياق التطبيق الرئيسي كحل طوارئ
/// GlobalKey to access main app context as emergency solution
final GlobalKey<NavigatorState> tafsirNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'tafsirNavigatorKey');

extension ShowTafsirExtension on void {
  /// دالة مساعدة للحصول على سياق صالح
  /// Helper function to get valid context
  BuildContext? _getValidContext(BuildContext originalContext) {
    // التحقق من السياق الأصلي أولاً
    // Check original context first
    if (originalContext.mounted) {
      log('استخدام السياق الأصلي', name: 'TafsirUi');
      return originalContext;
    }

    // محاولة استخدام Get.context
    // Try using Get.context
    if (Get.context != null && Get.context!.mounted) {
      log('استخدام Get.context كبديل', name: 'TafsirUi');
      return Get.context!;
    }

    // محاولة استخدام GlobalKey كحل أخير
    // Try using GlobalKey as last resort
    if (tafsirNavigatorKey.currentContext != null &&
        tafsirNavigatorKey.currentContext!.mounted) {
      log('استخدام tafsirNavigatorKey.currentContext كحل أخير',
          name: 'TafsirUi');
      return tafsirNavigatorKey.currentContext!;
    }

    log('لا يوجد سياق صالح متاح', name: 'TafsirUi');
    return null;
  }

  /// دالة مساعدة لتهيئة بيانات التفسير
  /// Helper function to initialize tafsir data
  Future<void> _initializeTafsirData({
    required int ayahUQNum,
    required int pageIndex,
  }) async {
    try {
      log('بدء تهيئة بيانات التفسير', name: 'TafsirUi');

      TafsirCtrl tafsirCtrl = TafsirCtrl.instance;
      // QuranCtrl.instance.state.currentPageNumber.value = pageIndex + 1;

      // تحقق من أن التفسير أو الترجمة جاهزة
      // Check if tafsir or translation is ready
      if (tafsirCtrl.isTafsir.value) {
        // tafsirCtrl.closeAndReinitializeDatabase();
        await tafsirCtrl.fetchData(pageIndex + 1);
      } else {
        await tafsirCtrl.fetchTranslate();
      }

      log('تم تحميل بيانات التفسير بنجاح', name: 'TafsirUi');
    } catch (e) {
      log('خطأ في تهيئة التفسير: $e', name: 'TafsirUi');
      rethrow; // إعادة طرح الخطأ ليتم التعامل معه في واجهة المستخدم
    }
  }

  /// -------- [onTap] --------
  /// عرض تفسير الآية عند النقر عليها
  /// Shows Tafsir when an ayah is tapped
  Future<void> showTafsirOnTap({
    required BuildContext context,
    required int ayahNum,
    required int pageIndex,
    required int ayahUQNum,
    required int ayahNumber,
    bool? isDark,
    TafsirStyle? tafsirStyle,
    bool? islocalFont,
    String? fontsName,
  }) async {
    // شرح: هذا السطر لطباعة رسالة عند استدعاء الدالة للتأكد من تنفيذها
    // Explanation: This line logs when the function is called for debugging
    log('showTafsirOnTap called', name: 'TafsirUi');

    // تحديد قيمة isDark مبدئيًا إذا لم يتم تمريرها
    // Set default value for isDark if not passed
    final bool isDarkMode = isDark ?? false;

    // التحقق من صحة السياق
    // Check context validity
    BuildContext? validContext = _getValidContext(context);
    if (validContext == null) {
      log('لا يوجد سياق صالح لعرض التفسير، يُرجى التأكد من تمرير سياق من شاشة نشطة',
          name: 'TafsirUi');
      return;
    }

    log('تم العثور على سياق صالح، بدء عملية التفسير', name: 'TafsirUi');

    // عرض النافذة المنبثقة فوراً مع تحميل البيانات داخلها
    // Show bottom sheet immediately with data loading inside
    try {
      log('عرض نافذة التفسير مع تحميل البيانات بالتوازي', name: 'TafsirUi');

      await showModalBottomSheet(
        context: validContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext modalContext) {
          // تهيئة بيانات التفسير داخل النافذة المنبثقة
          // Initialize tafsir data inside the bottom sheet

          // عرض واجهة التفسير بعد تحميل البيانات
          // Show tafsir interface after data loading
          return ShowTafseer(
            context: modalContext,
            ayahUQNumber: ayahUQNum,
            ayahNumber: ayahNumber,
            pageIndex: pageIndex,
            isDark: isDarkMode,
            islocalFont: islocalFont,
            fontsName: fontsName,
            tafsirStyle: tafsirStyle ??
                TafsirStyle(
                  backgroundColor: isDarkMode
                      ? const Color(0xff1E1E1E)
                      : const Color(0xfffaf7f3),
                  tafsirNameWidget: Text(
                    'التفسير',
                    style: QuranLibrary().naskhStyle.copyWith(
                          fontSize: 24,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                  ),
                  fontSizeWidget: Icon(
                    Icons.text_format_outlined,
                    size: 34,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
          );
        },
      );

      log('تم عرض نافذة التفسير بنجاح', name: 'TafsirUi');
    } catch (e) {
      log('خطأ في عرض نافذة التفسير المنبثقة: $e', name: 'TafsirUi');
    }
  }
}
