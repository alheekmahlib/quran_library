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

    // if (context.mounted) {
    // شرح: إذا دخلنا هنا فهذا يعني أن context متصل بالشجرة
    // Explanation: If we reach here, context is mounted and valid
    log('context is mounted, showing bottom sheet', name: 'TafsirUi');
    // شرح: يجب تمرير context صحيح من شاشة Flutter تحتوي على MaterialApp و Scaffold
    // Explanation: You must pass a valid context from a Flutter screen with MaterialApp and Scaffold
    // شرح: نحاول استخدام context المرسل، وإذا لم يكن صالحًا نستخدم Get.context كخيار احتياطي
    // Explanation: Try the passed context, if not valid use Get.context as fallback
    // BuildContext? validContext;
    // if (context.mounted &&
    //     MediaQuery.maybeOf(context) != null &&
    //     Scaffold.maybeOf(context) != null) {
    //   validContext = context;
    // } else if (Get.context != null &&
    //     MediaQuery.maybeOf(Get.context!) != null &&
    //     Scaffold.maybeOf(Get.context!) != null) {
    //   validContext = Get.context!;
    //   log('تم استخدام Get.context كخيار احتياطي', name: 'TafsirUi');
    //   // Used Get.context as fallback
    // }

    if (QuranCtrl.instance.state.scaffoldKey.currentContext!.mounted) {
      await showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: QuranCtrl.instance.state.scaffoldKey.currentContext!,
        builder: (context) => ShowTafseer(
          context: QuranCtrl.instance.state.scaffoldKey.currentContext!,
          ayahUQNumber: ayahUQNum,
          ayahNumber: ayahNumber,
          pageIndex: pageIndex,
          isDark: isDark!,
          tafsirStyle: TafsirStyle(
            backgroundColor:
                isDark ? const Color(0xff1E1E1E) : const Color(0xfffaf7f3),
            tafsirNameWidget: Text(
              'التفسير',
              style: QuranLibrary().naskhStyle.copyWith(
                    fontSize: 24,
                    color: isDark ? Colors.white : Colors.black,
                  ),
            ),
            fontSizeWidget: Icon(Icons.text_format_outlined,
                size: 34, color: isDark ? Colors.white : Colors.black),
          ),
        ),
        isScrollControlled: true,
      );
    } else {
      // شرح: إذا لم يوجد أي context صالح، نطبع رسالة فقط ولا نرمي Exception حتى لا يكسر التطبيق
      // Explanation: If no valid context, just log error and do not throw Exception to avoid crash
      log('لا يمكن عرض التفسير لأن الـ context غير صحيح (يجب أن يكون ضمن MaterialApp/Scaffold)',
          name: 'TafsirUi');
      // يمكنك هنا إظهار Toast أو تجاهل التنفيذ حسب الحاجة
      // You can show a Toast or just ignore as needed
    }
    // } else {
    //   // شرح: إذا لم يكن context متصل بالشجرة نطبع رسالة خطأ
    //   // Explanation: If context is not mounted, log an error
    //   log('context is NOT mounted!', name: 'TafsirUi');
    // }
  }
}
