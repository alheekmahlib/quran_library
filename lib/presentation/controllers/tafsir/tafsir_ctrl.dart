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
  RxList<String> tafsirDownloadIndex = <String>[].obs;
  // RxInt downloadIndex = 0.obs;
  // var isSelected = (-1.0).obs;
  RxBool isTafsir = true.obs;

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
      default:
        selectedTableName.value = MufaserName.saadi.name;
        dbFileName = 'saadiV3.db';
    }
    tafseerList.clear();
    await closeCurrentDatabase();
    box.write(_StorageConstants().tafsirTableValue, selectedTableName.value);
    database.value = TafsirDatabase(dbFileName);
    // initializeDatabase();
    await fetchData(QuranCtrl.instance.state.currentPageNumber.value);
    log('Database initialized for: $dbFileName');
    update();
  }

  // ------------[OnTapMethod]------------

  Future<void> showTafsirOnTap2(
      BuildContext context,
      surahNum,
      int ayahNum,
      String ayahText,
      int pageIndex,
      String ayahTextN,
      int ayahUQNum,
      int index) async {
    tafseerAyah = ayahText;
    surahNumber.value = surahNum;
    ayahTextNormal.value = ayahTextN;
    ayahUQNumber.value = ayahUQNum;
    QuranCtrl.instance.state.currentPageNumber.value = pageIndex + 1;
    await TafsirCtrl.instance.fetchData(pageIndex + 1);

    // if (context.mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ShowTafseer(
          ayahUQNumber: ayahUQNum,
          tafsirStyle: TafsirStyle(
            iconCloseWidget: Icon(Icons.close, size: 30, color: Colors.black),
            tafsirNameWidget: Text(
              'التفسير',
              style: QuranLibrary().naskhStyle,
            ),
            fontSizeWidget: Icon(Icons.close, size: 30, color: Colors.black),
          ),
        ),
      ),
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
    var path = join(databasePath.path, tafsirDBName[i]);
    String fileUrl =
        'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/tafseer_database/${tafsirDBName[i]}';

    if (!onDownloading.value) {
      await downloadFile(path, fileUrl).then((_) async {
        onDownloadSuccess(tafsirDBName[i]);
        saveTafsirDownloadIndex(tafsirDBName[i]);
        loadTafsirDownloadIndices();
        await TafsirCtrl.instance
            .fetchData(QuranCtrl.instance.state.currentPageNumber.value + 1);
      });
      log("Downloading from URL: $fileUrl");
    }
  }

  Future<bool> downloadFile(String path, String url) async {
    Dio dio = Dio();
    log('11111111111');
    cancelToken = CancelToken();
    try {
      try {
        log('22222222222222');
        await Directory(dirname(path)).create(recursive: true);
        isDownloading.value = true;
        onDownloading.value = true;
        progressString.value = "0";
        progress.value = 0;

        await dio.download(url, path, onReceiveProgress: (rec, total) {
          progressString.value = ((rec / total) * 100).toStringAsFixed(0);
          progress.value = (rec / total).toDouble();
          log(progressString.value);
        }, cancelToken: cancelToken);
      } catch (e) {
        if (e is DioException && e.type == DioExceptionType.cancel) {
          log('Download canceled');
          // Delete the partially downloaded file
          try {
            final file = File(path);
            if (await file.exists()) {
              await file.delete();
              onDownloading.value = false;
              log('Partially downloaded file deleted');
            }
          } catch (e) {
            log('Error deleting partially downloaded file: $e');
          }
          return false;
        } else {
          log('$e');
        }
      }
      onDownloading.value = false;
      progressString.value = "100";
      log("Download completed for $path");
      return true;
    } catch (e) {
      log("Error isDownloading: $e");
    }
    return false;
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
      String filePath = '${directory.path}/${tafsirDBName[i]}';
      File file = File(filePath);
      tafsirDownloadStatus.value[tafsirDBName[i]] = await file.exists();
    }
    return tafsirDownloadStatus.value;
  }

  Future<void> saveTafsirDownloadIndex(String tafsirName) async {
    List<String> savedIndices =
        box.read('tafsirDownloadIndices') ?? ['saadiV3.db'];
    if (!savedIndices.contains(tafsirName)) {
      savedIndices.add(tafsirName);
      await box.write('tafsirDownloadIndices', savedIndices);
    }
  }

  Future<void> loadTafsirDownloadIndices() async {
    List<String> savedIndices =
        box.read('tafsirDownloadIndices') ?? ['saadiV3.db'];
    // tafsirDownload(3).then((_) => savedIndices.add(tafsirDBName[3]));
    tafsirDownloadIndex.value = savedIndices.toList();
  }
}
