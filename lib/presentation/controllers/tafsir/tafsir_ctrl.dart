part of '../../../quran.dart';

class TafsirCtrl extends GetxController {
  static TafsirCtrl get instance => GetInstance().putOrFind(() => TafsirCtrl());

  RxList<TafsirTableData> tafseerList = <TafsirTableData>[].obs;
  String? selectedDBName = 'saadiV3.db';
  Rx<TafsirDatabase?> database = Rx<TafsirDatabase?>(null);
  // RxString selectedTableName = MufaserName.saadi.name.obs;
  RxInt radioValue = 3.obs;
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
  final Rx<Map<int, bool>> tafsirDownloadStatus = Rx<Map<int, bool>>({});
  RxList<int> tafsirDownloadIndexList = <int>[3, 5].obs;
  RxInt downloadIndex = 0.obs;
  // var isSelected = (-1.0).obs;
  RxBool isTafsir = true.obs;
  RxList<TranslationModel> translationList = <TranslationModel>[].obs;
  var isLoading = false.obs;
  var translationLangCode = 'en'.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await initTafsir();
  }

  Future<void> initTafsir() async {
    initializeTafsirDownloadStatus();
    await loadTafseer().then((_) async {
      database.value?.close();
      database = Rx<TafsirDatabase?>(TafsirDatabase(
          tafsirAndTranslateNames[radioValue.value].databaseName));
      await initializeDatabase();
    });
  }

  Future<void> loadTafseer() async {
    isTafsir.value = box.read(_StorageConstants().isTafsir) ?? true;
    radioValue.value = box.read(_StorageConstants().radioValue) ?? 3;
    // selectedTableName.value = box.read(_StorageConstants().tafsirTableValue) ??
    //     MufaserName.saadi.name;

    translationLangCode.value =
        box.read(_StorageConstants().translationLangCode) ?? 'en';
  }

  Future<void> initializeDatabase() async {
    log('Initializing database...');
    database.value =
        TafsirDatabase(tafsirAndTranslateNames[radioValue.value].databaseName);
    log('Database object created.');
    log('Database initialized.');
  }

  Future<void> closeCurrentDatabase() async {
    if (database.value != null) {
      await database.value!.close(); // إغلاق قاعدة البيانات الحالية
      log('Closed current database!');
    }
  }

  /// ------------[FetchingMethod]------------
  Future<void> fetchData(int pageNum) async {
    final db =
        TafsirDatabase(tafsirAndTranslateNames[radioValue.value].databaseName);

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
  Future<List<TafsirTableData>> fetchTafsirPage(int pageNum,
      {String? databaseName}) async {
    if (database.value == null) {
      throw Exception('Database not initialized');
    }
    initializeDatabase();
    List<TafsirTableData> tafsir = await database.value!
        .getTafsirByPage(pageNum, databaseName: databaseName!);
    return tafsir;
  }

  Future<List<TafsirTableData>> fetchTafsirAyah(int ayahUQNumber,
      {String? databaseName}) async {
    if (database.value == null) {
      throw Exception('Database not initialized');
    }
    initializeDatabase();
    // fetchData(pageIndex + 1);
    List<TafsirTableData> tafsir = await database.value!
        .getTafsirByAyah(ayahUQNumber, databaseName: databaseName!);
    return tafsir;
  }

  Future<void> fetchTranslate() async {
    try {
      Directory databasePath = await getApplicationDocumentsDirectory();
      String path = radioValue.value == 5
          ? 'packages/quran_library/assets/en.json'
          : join(databasePath.path, '${translationLangCode.value}.json');
      isLoading.value = true;

      String jsonString;

      if (radioValue.value == 5) {
        // استخدم rootBundle للوصول إلى الملف المضمن
        jsonString = await rootBundle
            .loadString('packages/quran_library/assets/en.json');
      } else {
        if (await File(path).exists()) {
          jsonString = await File(path).readAsString();
        } else {
          throw Exception('File not found');
        }
      }

      Map<String, dynamic> showData = json.decode(jsonString);
      translationList.value = (showData['translations'] as List)
          .map((item) => TranslationModel.fromJson(item))
          .toList();
    } catch (e) {
      log('Error loading translation file: $e');
    } finally {
      isLoading.value = false;
    }
    update(['change_tafsir']);
  }

  /// ------------[DownloadMethods]------------
  Future<void> tafsirDownload(int i) async {
    Directory databasePath = await getApplicationDocumentsDirectory();
    String path;
    String fileUrl;

    if (isTafsir.value) {
      path = join(databasePath.path, tafsirAndTranslateNames[i].databaseName);
      fileUrl =
          'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/tafseer_database/${tafsirAndTranslateNames[i].databaseName}';
    } else {
      path = join(
          databasePath.path, '${tafsirAndTranslateNames[i].bookName}.json');
      fileUrl =
          'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/quran_database/translate/${tafsirAndTranslateNames[i].bookName}.json';
    }

    if (!onDownloading.value) {
      await downloadFile(path, fileUrl).then((_) async {
        onDownloadSuccess(i);
        saveTafsirDownloadIndex(i);
        loadTafsirDownloadIndices();
        if (isTafsir.value) {
          await handleRadioValueChanged(i);
          await fetchData(QuranCtrl.instance.state.currentPageNumber.value + 1);
          update(['change_tafsir']);
        } else {
          await handleRadioValueChanged(i);
          await fetchTranslate();
          update(['change_tafsir']);
        }
      });
      log("Downloading from URL: $fileUrl");
    }
  }

  void initializeTafsirDownloadStatus() async {
    Map<int, bool> initialStatus = await checkAllTafsirDownloaded();

    tafsirDownloadStatus.value = initialStatus;
    loadTafsirDownloadIndices();
  }

  void updateDownloadStatus(int tafsirNumber, bool downloaded) {
    final newStatus = Map<int, bool>.from(tafsirDownloadStatus.value);
    newStatus[tafsirNumber] = downloaded;
    tafsirDownloadStatus.value = newStatus;
  }

  void onDownloadSuccess(int tafsirNumber) {
    updateDownloadStatus(tafsirNumber, true);
  }

  Future<Map<int, bool>> checkAllTafsirDownloaded() async {
    Directory? directory = await getApplicationDocumentsDirectory();

    for (int i = 0; i <= 4; i++) {
      String filePath = '${directory.path}/${tafsirAndTranslateNames[i].name}';
      File file = File(filePath);
      tafsirDownloadStatus.value[i] = await file.exists();
    }
    return tafsirDownloadStatus.value;
  }

  Future<void> saveTafsirDownloadIndex(int tafsirNumber) async {
    List<dynamic> savedIndices = box.read('tafsirDownloadIndices') ?? [3, 5];
    if (!savedIndices.contains(tafsirNumber)) {
      savedIndices.add(tafsirNumber);
      await box.write('tafsirDownloadIndices', savedIndices);
    }
  }

  Future<void> loadTafsirDownloadIndices() async {
    var rawList = box.read('tafsirDownloadIndices');

    List<int> savedIndices =
        rawList is List ? rawList.map((e) => e as int).toList() : [3, 5];

    tafsirDownloadIndexList.value = savedIndices;
  }
}
