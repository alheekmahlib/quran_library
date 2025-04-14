part of '../../../quran.dart';

extension TafsirUi on TafsirCtrl {
  /// -------- [onTap] --------

  // Future<void> showTafsirOnTap2({
  //   required BuildContext context,
  //   required int surahNum,
  //   required int ayahNum,
  //   required String ayahText,
  //   required int pageIndex,
  //   required String ayahTextN,
  //   required int ayahUQNum,
  //   required int index,
  // }) async {
  //   tafseerAyah = ayahText;
  //   surahNumber.value = surahNum;
  //   ayahTextNormal.value = ayahTextN;
  //   ayahUQNumber.value = ayahUQNum;
  //   QuranCtrl.instance.state.currentPageNumber.value = pageIndex + 1;
  //   if (isTafsir.value) {
  //     initializeDatabase();
  //     await fetchData(pageIndex + 1);
  //   } else {
  //     await fetchTranslate();
  //   }

  //   // if (context.mounted) {
  //   showModalBottomSheet<void>(
  //     context: Get.context!,
  //     builder: (BuildContext context) => ShowTafseer(
  //       ayahUQNumber: ayahUQNum,
  //       index: index,
  //       pageIndex: pageIndex,
  //       tafsirStyle: TafsirStyle(
  //         iconCloseWidget: IconButton(
  //             icon: Icon(Icons.close, size: 30, color: Colors.black),
  //             onPressed: () => Navigator.pop(context)),
  //         tafsirNameWidget: Text(
  //           'التفسير',
  //           style: QuranLibrary().naskhStyle,
  //         ),
  //         fontSizeWidget: Icon(Icons.close, size: 30, color: Colors.black),
  //       ),
  //     ),
  //     // ),
  //   );
  //   // }
  // }

  Future<void> copyOnTap(int ayahUQNumber) async {
    await Clipboard.setData(ClipboardData(
            text:
                '﴿${ayahTextNormal.value}﴾\n\n${tafseerList[ayahUQNumber].tafsirText.customTextSpans()}'))
        .then(
            (value) => _ToastUtils().showToast(Get.context!, 'copyTafseer'.tr));
  }

  Future<void> handleRadioValueChanged(int val, {int? pageNumber}) async {
    log('start changing Tafsir');
    radioValue.value = val;
    box.write(_StorageConstants().radioValue, val);

    switch (val) {
      case 0:
        isTafsir.value = true;
        box.write(_StorageConstants().isTafsir, true);
        break;
      case 1:
        isTafsir.value = true;
        box.write(_StorageConstants().isTafsir, true);
        break;
      case 2:
        isTafsir.value = true;
        box.write(_StorageConstants().isTafsir, true);
        break;
      case 3:
        isTafsir.value = true;
        box.write(_StorageConstants().isTafsir, true);
        break;
      case 4:
        isTafsir.value = true;
        box.write(_StorageConstants().isTafsir, true);
        break;
      case 5:
        isTafsir.value = false;
        translationLangCode.value = 'en';
        box.write(_StorageConstants().translationLangCode, 'en');
        box.write(_StorageConstants().isTafsir, false);
        break;
      case 6:
        isTafsir.value = false;
        translationLangCode.value = 'es';
        box.write(_StorageConstants().translationLangCode, 'es');
        box.write(_StorageConstants().isTafsir, false);
        break;
      case 7:
        isTafsir.value = false;
        translationLangCode.value = 'be';
        box.write(_StorageConstants().translationLangCode, 'be');
        box.write(_StorageConstants().isTafsir, false);
        break;
      case 8:
        isTafsir.value = false;
        translationLangCode.value = 'urdu';
        box.write(_StorageConstants().translationLangCode, 'urdu');
        box.write(_StorageConstants().isTafsir, false);
        break;
      case 9:
        isTafsir.value = false;
        translationLangCode.value = 'so';
        box.write(_StorageConstants().translationLangCode, 'so');
        box.write(_StorageConstants().isTafsir, false);
        break;
      case 10:
        isTafsir.value = false;
        translationLangCode.value = 'in';
        box.write(_StorageConstants().translationLangCode, 'in');
        box.write(_StorageConstants().isTafsir, false);
        break;
      case 11:
        isTafsir.value = false;
        translationLangCode.value = 'ku';
        box.write(_StorageConstants().translationLangCode, 'ku');
        box.write(_StorageConstants().isTafsir, false);
        break;
      case 12:
        isTafsir.value = false;
        translationLangCode.value = 'tr';
        box.write(_StorageConstants().translationLangCode, 'tr');
        box.write(_StorageConstants().isTafsir, false);
        break;
      default:
        database.value =
            TafsirDatabase(tafsirAndTranslateNames[3].databaseName);
    }
    if (isTafsir.value) {
      await closeAndInitializeDatabase(
          pageNumber:
              pageNumber ?? QuranCtrl.instance.state.currentPageNumber.value);
    } else {
      await fetchTranslate();
    }
    update(['change_tafsir']);
  }

  Future<void> closeAndInitializeDatabase({int? pageNumber}) async {
    tafseerList.clear();
    await closeCurrentDatabase();
    database.value =
        TafsirDatabase(tafsirAndTranslateNames[radioValue.value].databaseName);
    await initializeDatabase();
    await fetchData(
        pageNumber ?? QuranCtrl.instance.state.currentPageNumber.value);
    log('Database initialized for: ${tafsirAndTranslateNames[radioValue.value].databaseName}');
  }
}
