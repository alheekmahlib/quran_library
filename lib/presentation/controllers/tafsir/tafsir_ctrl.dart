part of '../../../quran.dart';

class TafsirCtrl extends GetxController {
  static TafsirCtrl get instance => Get.isRegistered<TafsirCtrl>()
      ? Get.find<TafsirCtrl>()
      : Get.put<TafsirCtrl>(TafsirCtrl());

  var tafseerList = <TafsirTableData>[].obs;
  String? selectedDBName = 'saadiV3.db';
  Rx<TafsirDatabase?> database = Rx<TafsirDatabase?>(null);
  RxString selectedTableName = MufaserName.saadi.name.obs;
  var radioValue = 3.obs;
  final box = GetStorage();
  RxString ayahTextNormal = ''.obs;
  RxInt ayahUQNumber = (-1).obs;
  RxInt surahNumber = 1.obs;
  String tafseerAyah = '';
  RxInt ayahNumber = (-1).obs;
  RxBool isDownloading = false.obs;
  RxBool onDownloading = false.obs;
  RxString progressString = "0".obs;
  RxDouble progress = 0.0.obs;
  RxDouble fontSizeArabic = 20.0.obs;
  late var cancelToken = CancelToken();
  final Rx<Map<String, bool>> tafsirDownloadStatus = Rx<Map<String, bool>>({});
  RxList<String> tafsirDownloadName = <String>['tafSaadiN'].obs;
  RxInt downloadIndex = 0.obs;
  // var isSelected = (-1.0).obs;
  RxBool isTafsir = true.obs;
  var data = [].obs;
  var isLoading = false.obs;
  var trans = 'en'.obs;
  RxInt transValue = 0.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    initializeTafsirDownloadStatus();
    // await loadTafseer().then((_) async {
    //   database.value?.close();
    //   database =
    //       Rx<TafsirDatabase?>(TafsirDatabase(tafsirDBName[radioValue.value]));
    //   await initializeDatabase();
    // });
  }

  Future<void> loadTafseer() async {
    radioValue.value = box.read(_StorageConstants().tafsirValue) ?? 3;
    selectedTableName.value = box.read(_StorageConstants().tafsirTableValue) ??
        MufaserName.saadi.name;

    transValue.value = box.read(_StorageConstants().translationValue) ?? 0;
    // shareTransValue.value = box.read(SHARE_TRANSLATE_VALUE) ?? 0;
    trans.value = box.read(_StorageConstants().translationLangCode) ?? 'en';
  }

  Future<void> initializeDatabase() async {
    log('Initializing database...');
    TafsirDatabase(tafsirDBName[radioValue.value]);
    log('Database object created.');
    log('Database initialized.');
  }

  Future<void> closeCurrentDatabase() async {
    if (database.value != null) {
      await database.value!.close(); // إغلاق قاعدة البيانات الحالية
      log('Closed current database!');
    }
  }

  Future<void> fetchData(int pageNum) async {
    final db = TafsirDatabase(tafsirDBName[radioValue.value]);

    try {
      final List<TafsirTableData> tafsir = await db.getTafsirByPage(pageNum);
      log('Fetched tafsir: ${tafsir.length} entries');

      if (tafsir.isNotEmpty) {
        tafseerList.assignAll(tafsir); // تحديث القائمة في الواجهة
      } else {
        log('No data found for this page.');
        tafseerList.clear(); // مسح القائمة إذا لم يكن هناك تفسير
      }
    } catch (e) {
      log('Error fetching data: $e');
    }
  }

  // استخدام getTafsirByPage لجلب التفسير حسب رقم الصفحة
  Future<List<TafsirTableData>> fetchTafsirPage(int pageNum) async {
    if (database.value == null) {
      throw Exception('Database not initialized');
    }
    List<TafsirTableData> tafsir =
        await database.value!.getTafsirByPage(pageNum);
    return tafsir;
  }

  Future<List<TafsirTableData>> fetchTafsirAyah(
      int ayahUQNumber, int surahNumber) async {
    if (database.value == null) {
      throw Exception('Database not initialized');
    }
    List<TafsirTableData> tafsir =
        await database.value!.getTafsirByAyah(ayahUQNumber);
    return tafsir;
  }

  Future<void> fetchTranslate() async {
    try {
      Directory databasePath = await getApplicationDocumentsDirectory();
      String path = join(databasePath.path, '${trans.value}.json');
      isLoading.value = true;

      if (await File(path).exists()) {
        String jsonString = await File(path).readAsString();
        Map<String, dynamic> showData = json.decode(jsonString);
        data.value = showData['translations'];
      } else {
        log('Error: Translation file not found at $path');
      }
    } catch (e) {
      log('Error loading translation file: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleRadioValueChanged(int val) async {
    log('start changing Tafsir');
    String? dbFileName;
    radioValue.value = val;

    switch (val) {
      case 0:
        selectedTableName.value = MufaserName.ibnkatheer.name;
        dbFileName = 'ibnkatheerV2.sqlite';
        break;
      case 1:
        selectedTableName.value = MufaserName.baghawy.name;
        dbFileName = 'baghawyV2.db';
        break;
      case 2:
        selectedTableName.value = MufaserName.qurtubi.name;
        dbFileName = 'qurtubiV2.db';
        break;
      case 3:
        selectedTableName.value = MufaserName.saadi.name;
        dbFileName = 'saadiV3.db';
        break;
      case 4:
        selectedTableName.value = MufaserName.tabari.name;
        dbFileName = 'tabariV2.db';
        break;
      case 5:
        isTafsir.value = false;
        trans.value = 'en';
        box.write(_StorageConstants().translationLangCode, 'en');
        break;
      case 6:
        isTafsir.value = false;
        trans.value = 'es';
        box.write(_StorageConstants().translationLangCode, 'es');
        break;
      case 7:
        isTafsir.value = false;
        trans.value = 'be';
        box.write(_StorageConstants().translationLangCode, 'be');
        break;
      case 8:
        isTafsir.value = false;
        trans.value = 'urdu';
        box.write(_StorageConstants().translationLangCode, 'urdu');
        break;
      case 9:
        isTafsir.value = false;
        trans.value = 'so';
        box.write(_StorageConstants().translationLangCode, 'so');
        break;
      case 10:
        isTafsir.value = false;
        trans.value = 'in';
        box.write(_StorageConstants().translationLangCode, 'in');
        break;
      case 11:
        isTafsir.value = false;
        trans.value = 'ku';
        box.write(_StorageConstants().translationLangCode, 'ku');
        break;
      case 12:
        isTafsir.value = false;
        trans.value = 'tr';
        box.write(_StorageConstants().translationLangCode, 'tr');
        break;
      case 13:
        isTafsir.value = true;
        box.write(_StorageConstants().isTafsir, true);
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
      fetchTranslate();
    }
    update(['change_tafsir']);
  }

  // ------------[OnTapMethod]------------

  Future<void> showTafsirOnTap2({
    required BuildContext context,
    required int surahNum,
    required int ayahNum,
    required String ayahText,
    required int pageIndex,
    required String ayahTextN,
    required int ayahUQNum,
    required int index,
  }) async {
    tafseerAyah = ayahText;
    surahNumber.value = surahNum;
    ayahTextNormal.value = ayahTextN;
    ayahUQNumber.value = ayahUQNum;
    QuranCtrl.instance.state.currentPageNumber.value = pageIndex + 1;
    await fetchData(pageIndex + 1);

    // if (context.mounted) {
    showModalBottomSheet<void>(
      context: Get.context!,
      builder: (BuildContext context) => ShowTafseer(
        ayahUQNumber: ayahUQNum,
        index: index,
        pageIndex: pageIndex,
        tafsirStyle: TafsirStyle(
          iconCloseWidget: IconButton(
              icon: Icon(Icons.close, size: 30, color: Colors.black),
              onPressed: () => Navigator.pop(context)),
          tafsirNameWidget: Text(
            'التفسير',
            style: QuranLibrary().naskhStyle,
          ),
          fontSizeWidget: Icon(Icons.close, size: 30, color: Colors.black),
        ),
      ),
      // ),
    );
    // }
  }

  Future<void> copyOnTap(int ayahUQNumber) async {
    await Clipboard.setData(ClipboardData(
            text:
                '﴿${ayahTextNormal.value}﴾\n\n${tafseerList[ayahUQNumber].tafsirText.customTextSpans()}'))
        .then(
            (value) => _ToastUtils().showToast(Get.context!, 'copyTafseer'.tr));
  }

  Future<void> tafsirDownload(int i) async {
    Directory databasePath = await getApplicationDocumentsDirectory();
    String path;
    String fileUrl;

    if (isTafsir.value) {
      path = join(databasePath.path, tafsirDBName[i]);
      fileUrl =
          'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/tafseer_database/${tafsirDBName[i]}';
    } else {
      path = join(databasePath.path, '${tafsirName[i]['bookName']}.json');
      fileUrl =
          'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/quran_database/translate/${tafsirName[i]['bookName']}.json';
    }

    if (!onDownloading.value) {
      await downloadFile(path, fileUrl).then((_) async {
        onDownloadSuccess(tafsirName[i]['name']);
        saveTafsirDownloadIndex(tafsirName[i]['name']);
        loadTafsirDownloadIndices();
        if (isTafsir.value) {
          await fetchData(QuranCtrl.instance.state.currentPageNumber.value + 1);
        } else {
          await handleRadioValueChanged(i);
          await fetchTranslate();
        }
      });
      log("Downloading from URL: $fileUrl");
    }
  }

  void initializeTafsirDownloadStatus() async {
    Map<String, bool> initialStatus = await checkAllTafsirDownloaded();
    tafsirDownloadStatus.value = initialStatus;
    loadTafsirDownloadIndices();
  }

  void updateDownloadStatus(String tafsirName, bool downloaded) {
    final newStatus = Map<String, bool>.from(tafsirDownloadStatus.value);
    newStatus[tafsirName] = downloaded;
    tafsirDownloadStatus.value = newStatus;
  }

  void onDownloadSuccess(String tafsirName) {
    updateDownloadStatus(tafsirName, true);
  }

  Future<Map<String, bool>> checkAllTafsirDownloaded() async {
    Directory? directory = await getApplicationDocumentsDirectory();

    for (int i = 0; i <= 4; i++) {
      String filePath = '${directory.path}/${tafsirName[i]['name']}';
      File file = File(filePath);
      tafsirDownloadStatus.value[tafsirName[i]['name']] = await file.exists();
    }
    return tafsirDownloadStatus.value;
  }

  Future<void> saveTafsirDownloadIndex(String tafsirName) async {
    List<dynamic> savedIndices =
        box.read('tafsirDownloadIndices') ?? ['tafSaadiN'];
    if (!savedIndices.contains(tafsirName)) {
      savedIndices.add(tafsirName);
      await box.write('tafsirDownloadIndices', savedIndices);
    }
  }

  Future<void> loadTafsirDownloadIndices() async {
    var rawList = box.read('tafsirDownloadIndices');

    List<String> savedIndices = rawList is List
        ? rawList.map((e) => e.toString()).toList()
        : ['tafSaadiN'];

    tafsirDownloadName.value = savedIndices;
  }
}
