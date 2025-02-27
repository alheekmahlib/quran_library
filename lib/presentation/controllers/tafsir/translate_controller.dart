part of '../../../quran.dart';

class TranslateDataController extends GetxController {
  static TranslateDataController get instance =>
      Get.isRegistered<TranslateDataController>()
          ? Get.find<TranslateDataController>()
          : Get.put<TranslateDataController>(TranslateDataController());
  var data = [].obs;
  var isLoading = false.obs;
  var trans = 'en'.obs;
  RxInt transValue = 0.obs;
  RxInt shareTransValue = 0.obs;
  var expandedMap = <int, bool>{}.obs;
  final box = GetStorage();

  Future<void> fetchTranslate() async {
    isLoading.value = true;
    String jsonString = await rootBundle
        .loadString("assets/json/translate/${trans.value}.json");
    Map<String, dynamic> showData = json.decode(jsonString);
    // List<dynamic> sura = showData[surahNumber];
    data.value = showData['translations'];
    isLoading.value = false; // Set isLoading to false and update the data
    log('trans.value ${trans.value}');
  }

  translateHandleRadioValueChanged(int translateVal) async {
    transValue.value = translateVal;
    switch (transValue.value) {
      case 1:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'en';
        box.write(_StorageConstants().translationLangCode, 'en');
      case 2:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'es';
        box.write(_StorageConstants().translationLangCode, 'es');
      case 3:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'be';
        box.write(_StorageConstants().translationLangCode, 'be');
      case 4:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'urdu';
        box.write(_StorageConstants().translationLangCode, 'urdu');
      case 5:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'so';
        box.write(_StorageConstants().translationLangCode, 'so');
      case 6:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'in';
        box.write(_StorageConstants().translationLangCode, 'in');
      case 7:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'ku';
        box.write(_StorageConstants().translationLangCode, 'ku');
      case 8:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'tr';
        box.write(_StorageConstants().translationLangCode, 'tr');
      case 9:
        // sl<ShareController>().isTafseer.value = true;
        box.write(_StorageConstants().isTafsir, true);
      default:
        trans.value = 'en';
    }
  }

  shareTranslateHandleRadioValue(int translateVal) async {
    shareTransValue.value = translateVal;
    switch (shareTransValue.value) {
      case 0:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'en';
        box.write(_StorageConstants().translationLangCode, 'en');
      case 1:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'es';
        box.write(_StorageConstants().translationLangCode, 'es');
      case 2:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'be';
        box.write(_StorageConstants().translationLangCode, 'be');
      case 3:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'urdu';
        box.write(_StorageConstants().translationLangCode, 'urdu');
      case 4:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'so';
        box.write(_StorageConstants().translationLangCode, 'so');
      case 5:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'in';
        box.write(_StorageConstants().translationLangCode, 'in');
      case 6:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'ku';
        box.write(_StorageConstants().translationLangCode, 'ku');
      case 7:
        // sl<ShareController>().isTafseer.value = false;
        trans.value = 'tr';
        box.write(_StorageConstants().translationLangCode, 'tr');
      // case 8:
      //   sl<ShareController>().isTafseer.value = true;
      //   sl<AyatController>().dBName =
      //       sl<AyatController>().saadiClient?.database;
      //   sl<AyatController>().selectedDBName = MufaserName.saadi.name;
      //   box.write(IS_TAFSEER, true);
      default:
        trans.value = 'en';
    }
  }

  void loadTranslateValue() {
    transValue.value = box.read(_StorageConstants().translationValue) ?? 0;
    // shareTransValue.value = box.read(SHARE_TRANSLATE_VALUE) ?? 0;
    trans.value = box.read(_StorageConstants().translationLangCode) ?? 'en';
    // ShareController.instance.currentTranslate.value =
    //     box.read(CURRENT_TRANSLATE) ?? 'English';
    // sl<ShareController>().isTafseer.value = (box.read(IS_TAFSEER)) ?? false;
    log('trans.value ${trans.value}');
    log('translateـvalue $transValue');
  }

  @override
  void onInit() {
    fetchTranslate();
    super.onInit();
  }

  void changeTranslateOnTap(int index) {
    transValue.value == index;
    box.write(_StorageConstants().translationValue, index);
    translateHandleRadioValueChanged(index);
    fetchTranslate();
    Get.back();
  }
}
