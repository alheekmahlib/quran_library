part of '../../../quran.dart';

extension TafsirUi on TafsirCtrl {
  /// -------- [onTap] --------

  /// شرح: نسخ نص التفسير مع الآية
  /// Explanation: Copy tafsir text with ayah
  Future<void> copyOnTap(int ayahUQNumber) async {
    await Clipboard.setData(ClipboardData(
            text:
                '﴿${ayahTextNormal.value}﴾\n\n${tafseerList[ayahUQNumber].tafsirText.customTextSpans()}'))
        .then(
            (value) => _ToastUtils().showToast(Get.context!, 'copyTafseer'.tr));
  }

  /// شرح: تغيير التفسير أو الترجمة عند تغيير الاختيار
  /// Explanation: Change tafsir/translation when selection changes
  Future<void> handleRadioValueChanged(int val, {int? pageNumber}) async {
    log('start changing Tafsir', name: 'TafsirUi');
    radioValue.value = val;
    box.write(_StorageConstants().radioValue, val);
    if (val <= 4) {
      isTafsir.value = true;
      box.write(_StorageConstants().isTafsir, true);
      await closeAndInitializeDatabase(
        pageNumber:
            pageNumber ?? QuranCtrl.instance.state.currentPageNumber.value,
      );
    } else {
      isTafsir.value = false;
      String langCode = _getLangCodeForRadio(val);
      translationLangCode.value = langCode;
      box.write(_StorageConstants().translationLangCode, langCode);
      box.write(_StorageConstants().isTafsir, false);
      tafseerList.clear(); // شرح: مسح قائمة التفسير عند اختيار الترجمة
      await fetchTranslate();
    }
    update(['change_tafsir']);
  }

  /// شرح: إرجاع كود اللغة المناسب حسب قيمة الراديو
  /// Explanation: Get language code for radio value
  String _getLangCodeForRadio(int val) {
    switch (val) {
      case 5:
        return 'en';
      case 6:
        return 'es';
      case 7:
        return 'be';
      case 8:
        return 'urdu';
      case 9:
        return 'so';
      case 10:
        return 'in';
      case 11:
        return 'ku';
      case 12:
        return 'tr';
      default:
        return 'en';
    }
  }

  /// شرح: إغلاق القاعدة وتهيئتها من جديد عند تغيير التفسير
  /// Explanation: Close and reinitialize DB when tafsir changes
  Future<void> closeAndInitializeDatabase({int? pageNumber}) async {
    tafseerList.clear();
    await closeCurrentDatabase();
    await initializeDatabase();
    await fetchData(
        pageNumber ?? QuranCtrl.instance.state.currentPageNumber.value);
    log('Database initialized for: ${tafsirAndTranslateNames[radioValue.value].databaseName}',
        name: 'TafsirUi');
  }
}
