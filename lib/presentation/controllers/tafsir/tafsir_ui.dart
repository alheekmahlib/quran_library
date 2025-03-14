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

  Future<void> handleRadioValueChanged(int val) async {
    log('start changing Tafsir');
    String? dbFileName;
    radioValue.value = val;

    switch (val) {
      case 0:
        isTafsir.value = true;
        selectedTableName.value = MufaserName.ibnkatheer.name;
        dbFileName = 'ibnkatheerV2.sqlite';
        box.write(_StorageConstants().isTafsir, true);
        break;
      case 1:
        isTafsir.value = true;
        selectedTableName.value = MufaserName.baghawy.name;
        dbFileName = 'baghawyV2.db';
        box.write(_StorageConstants().isTafsir, true);
        break;
      case 2:
        isTafsir.value = true;
        selectedTableName.value = MufaserName.qurtubi.name;
        dbFileName = 'qurtubiV2.db';
        box.write(_StorageConstants().isTafsir, true);
        break;
      case 3:
        isTafsir.value = true;
        selectedTableName.value = MufaserName.saadi.name;
        dbFileName = 'saadiV3.db';
        box.write(_StorageConstants().isTafsir, true);
        break;
      case 4:
        isTafsir.value = true;
        selectedTableName.value = MufaserName.tabari.name;
        dbFileName = 'tabariV2.db';
        box.write(_StorageConstants().isTafsir, true);
        selectedTableName.value = MufaserName.ibnkatheer.name;
        dbFileName = 'ibnkatheerV2.sqlite';
        break;
      case 5:
        isTafsir.value = false;
        trans.value = 'en';
        box.write(_StorageConstants().translationLangCode, 'en');
        box.write(_StorageConstants().isTafsir, false);
        break;
      case 6:
        isTafsir.value = false;
        trans.value = 'es';
        box.write(_StorageConstants().translationLangCode, 'es');
        box.write(_StorageConstants().isTafsir, false);
        break;
      case 7:
        isTafsir.value = false;
        trans.value = 'be';
        box.write(_StorageConstants().translationLangCode, 'be');
        box.write(_StorageConstants().isTafsir, false);
        break;
      case 8:
        isTafsir.value = false;
        trans.value = 'urdu';
        box.write(_StorageConstants().translationLangCode, 'urdu');
        box.write(_StorageConstants().isTafsir, false);
        break;
      case 9:
        isTafsir.value = false;
        trans.value = 'so';
        box.write(_StorageConstants().translationLangCode, 'so');
        box.write(_StorageConstants().isTafsir, false);
        break;
      case 10:
        isTafsir.value = false;
        trans.value = 'in';
        box.write(_StorageConstants().translationLangCode, 'in');
        box.write(_StorageConstants().isTafsir, false);
        break;
      case 11:
        isTafsir.value = false;
        trans.value = 'ku';
        box.write(_StorageConstants().translationLangCode, 'ku');
        box.write(_StorageConstants().isTafsir, false);
        break;
      case 12:
        isTafsir.value = false;
        trans.value = 'tr';
        box.write(_StorageConstants().translationLangCode, 'tr');
        box.write(_StorageConstants().isTafsir, false);
        break;
      default:
        selectedTableName.value = MufaserName.saadi.name;
        dbFileName = 'saadiV3.db';
    }
    if (isTafsir.value) {
      tafseerList.clear();
      await closeCurrentDatabase();
      box.write(_StorageConstants().tafsirTableValue, selectedTableName.value);
      database.value = TafsirDatabase(dbFileName!);
      initializeDatabase();
      await fetchData(QuranCtrl.instance.state.currentPageNumber.value);
      log('Database initialized for: $dbFileName');
    } else {
      // transValue.value == val;
      box.write(_StorageConstants().translationValue, val);
      await fetchTranslate();
    }
    update(['change_tafsir']);
  }
}
