part of '../../../quran.dart';

extension ShowTafsirExtension on void {
  /// -------- [onTap] --------
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

    TafsirCtrl.instance.tafseerAyah = ayahText;
    TafsirCtrl.instance.surahNumber.value = surahNum;
    TafsirCtrl.instance.ayahTextNormal.value = ayahTextN;
    TafsirCtrl.instance.ayahUQNumber.value = ayahUQNum;
    QuranCtrl.instance.state.currentPageNumber.value = pageIndex + 1;
    if (TafsirCtrl.instance.isTafsir.value) {
      TafsirCtrl.instance.closeAndInitializeDatabase(pageNumber: pageIndex + 1);
      await TafsirCtrl.instance.fetchData(pageIndex + 1);
    } else {
      await TafsirCtrl.instance.fetchTranslate();
    }

    // تحديد السياق الصحيح لعرض الشاشة المنبثقة
    // Determine the correct context for showing the bottom sheet
    BuildContext validContext = context;

    // إذا كان السياق المُرسل غير صالح، نستخدم سياق المكتبة نفسها
    // If the provided context is not valid, use the library's own context
    if (!context.mounted || MediaQuery.maybeOf(context) == null) {
      // تحقق من صلاحية سياق مفتاح السكافولد
      // Check if scaffold key context is valid
      final scaffoldContext =
          QuranCtrl.instance.state.scaffoldKey.currentContext;
      if (scaffoldContext != null && scaffoldContext.mounted) {
        validContext = scaffoldContext;
        log('استخدام سياق مفتاح السكافولد من المكتبة', name: 'TafsirUi');
        // Using scaffold key context from library
      } else if (Get.context != null) {
        validContext = Get.context!;
        log('استخدام Get.context كخيار احتياطي', name: 'TafsirUi');
        // Using Get.context as fallback
      } else {
        log('جميع السياقات غير صالحة، لا يمكن عرض التفسير', name: 'TafsirUi');
        // All contexts are invalid, cannot show tafsir
        return;
      }
    }

    // نستخدم الآن السياق الصحيح لعرض الشاشة المنبثقة
    // Now use the valid context to show the bottom sheet
    if (validContext.mounted) {
      await showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: validContext,
        builder: (context) => ShowTafseer(
          context: validContext,
          ayahUQNumber: ayahUQNum,
          ayahNumber: ayahNumber,
          pageIndex: pageIndex,
          isDark:
              isDark ?? Theme.of(validContext).brightness == Brightness.dark,
          tafsirStyle: TafsirStyle(
            backgroundColor:
                isDark ?? Theme.of(validContext).brightness == Brightness.dark
                    ? const Color(0xff1E1E1E)
                    : const Color(0xfffaf7f3),
            tafsirNameWidget: Text(
              'التفسير',
              style: QuranLibrary().naskhStyle.copyWith(
                    fontSize: 24,
                    color: isDark ??
                            Theme.of(validContext).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
            ),
            fontSizeWidget: Icon(Icons.text_format_outlined,
                size: 34,
                color: isDark ??
                        Theme.of(validContext).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black),
          ),
        ),
        isScrollControlled: true,
      );
    } else {
      // شرح: إذا لم يوجد أي context صالح، نطبع رسالة فقط ولا نرمي Exception حتى لا يكسر التطبيق
      // Explanation: If no valid context, just log error and do not throw Exception to avoid crash
      log('لا يمكن عرض التفسير لأن جميع السياقات غير صالحة', name: 'TafsirUi');
    }
  }
}
