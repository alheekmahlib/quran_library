part of '../tafsir.dart';

extension TafsirUi on TafsirCtrl {
  /// -------- [onTap] --------

  /// شرح: نسخ نص التفسير مع الآية
  /// Explanation: Copy tafsir text with ayah
  Future<void> copyOnTap(int ayahUQNumber) async {
    await Clipboard.setData(ClipboardData(
            text:
                '﴿${ayahTextNormal.value}﴾\n\n${tafseerList[ayahUQNumber].tafsirText.customTextSpans()}'))
        .then(
            (value) => ToastUtils().showToast(Get.context!, 'copyTafseer'.tr));
  }

  /// شرح: تغيير التفسير أو الترجمة عند تغيير الاختيار
  /// Explanation: Change tafsir/translation when selection changes
  Future<void> handleRadioValueChanged(int val, {int? pageNumber}) async {
    if (radioValue.value == val) {
      return;
    }
    radioValue.value = val;
    log('start changing Tafsir', name: 'TafsirUi');
    box.write(_StorageConstants().radioValue, val);
    if (val < translationsStartIndex) {
      isTafsir.value = true;
      box.write(_StorageConstants().isTafsir, true);
      await closeAndReinitializeDatabase();
      await fetchData(
          pageNumber ?? QuranCtrl.instance.state.currentPageNumber.value);
    } else {
      isTafsir.value = false;
      String langCode = tafsirAndTranslationsItems[val].bookName;
      translationLangCode = langCode;
      await fetchTranslate();
      box.write(_StorageConstants().translationLangCode, langCode);
      box.write(_StorageConstants().isTafsir, false);
      tafseerList.clear(); // شرح: مسح قائمة التفسير عند اختيار الترجمة
    }
    update(['tafsirs_menu_list', 'change_font_size', 'actualTafsirContent']);
    // update(['ActualTafsirWidget']);
  }

  /// شرح: إغلاق القاعدة وتهيئتها من جديد عند تغيير التفسير
  /// Explanation: Close and reinitialize DB when tafsir changes
  Future<void> closeAndReinitializeDatabase() async {
    _isDbInitialized = false;
    tafseerList.clear();
    if (isCurrentATranslation) {
      log('Selected item is traanslation item, skipping DB init.',
          name: 'TafsirCtrl');
      return;
    }
    if (isCurrentNotAsqlTafsir) {
      log('Selected item is not a SQLite DB, skipping DB init.',
          name: 'TafsirCtrl');
      return;
    }
    if (isCurrentAcustomTafsir) {
      log('Selected item is CustomTafsir item, skipping DB init.',
          name: 'TafsirCtrl');
      return;
    }
    await closeCurrentDatabase();
    await initializeDatabase();

    log('Database initialized for: ${tafsirAndTranslationsItems[radioValue.value].databaseName}',
        name: 'TafsirUi');
  }
}
