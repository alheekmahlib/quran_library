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

  /// شرح: متغير لحفظ اسم قاعدة البيانات الحالية
  /// Explanation: Variable to store the current database name
  String? currentDbFileName;

  @override
  Future<void> onInit() async {
    super.onInit();
    await initTafsir();
  }

  /// شرح: تهيئة التفسير مع التأكد من عدم تكرار إنشاء قاعدة البيانات
  /// Explanation: Initialize tafsir and avoid redundant DB creation
  Future<void> initTafsir() async {
    initializeTafsirDownloadStatus();
    await loadTafseer();
    await initializeDatabase();
  }

  Future<void> loadTafseer() async {
    isTafsir.value = box.read(_StorageConstants().isTafsir) ?? true;
    radioValue.value = box.read(_StorageConstants().radioValue) ?? 3;
    translationLangCode.value =
        box.read(_StorageConstants().translationLangCode) ?? 'en';
    TafsirCtrl.instance.fontSizeArabic.value =
        box.read(_StorageConstants().fontSize) ?? 20.0;
  }

  /// شرح: تهيئة قاعدة البيانات فقط إذا تغير الاسم
  /// Explanation: Only initialize DB if name changed
  Future<void> initializeDatabase() async {
    String dbName = tafsirAndTranslateNames[radioValue.value].databaseName;
    if (database.value == null || currentDbFileName != dbName) {
      await database.value?.close();
      database.value = TafsirDatabase(dbName);
      currentDbFileName = dbName;
      log('Database object created.', name: 'TafsirCtrl');
    }
    log('Database initialized.', name: 'TafsirCtrl');
  }

  Future<void> closeCurrentDatabase() async {
    if (database.value != null) {
      await database.value!.close();
      database.value = null; // شرح: إعادة تعيين الكائن بعد الإغلاق
      log('Closed current database!', name: 'TafsirCtrl');
    }
  }

  /// ------------[FetchingMethod]------------
  /// شرح: جلب بيانات التفسير للصفحة المطلوبة
  /// Explanation: Fetch tafsir data for the requested page
  Future<void> fetchData(int pageNum) async {
    await initializeDatabase();
    try {
      final List<TafsirTableData> tafsir =
          await database.value!.getTafsirByPage(pageNum);
      log('Fetched tafsir: [32m${tafsir.length} entries', name: 'TafsirCtrl');
      if (tafsir.isNotEmpty) {
        tafseerList.assignAll(tafsir);
      } else {
        log('No data found for this page.', name: 'TafsirCtrl');
        tafseerList.clear();
      }
    } catch (e) {
      log('Error fetching data: $e', name: 'TafsirCtrl');
    }
  }

  /// شرح: جلب التفسير حسب رقم الصفحة
  /// Explanation: Fetch tafsir by page number
  Future<List<TafsirTableData>> fetchTafsirPage(int pageNum,
      {String? databaseName}) async {
    await initializeDatabase();
    if (database.value == null) {
      throw Exception('Database not initialized');
    }
    return await database.value!
        .getTafsirByPage(pageNum, databaseName: databaseName);
  }

  /// شرح: جلب التفسير حسب رقم الآية
  /// Explanation: Fetch tafsir by ayah number
  Future<List<TafsirTableData>> fetchTafsirAyah(int ayahUQNumber,
      {String? databaseName}) async {
    await initializeDatabase();
    if (database.value == null) {
      throw Exception('Database not initialized');
    }
    return await database.value!
        .getTafsirByAyah(ayahUQNumber, databaseName: databaseName);
  }

  /// شرح: جلب الترجمة
  /// Explanation: Fetch translation
  Future<void> fetchTranslate() async {
    try {
      Directory databasePath = await getApplicationDocumentsDirectory();
      String path = radioValue.value == 5
          ? 'packages/quran_library/assets/en.json'
          : join(databasePath.path, '${translationLangCode.value}.json');
      isLoading.value = true;
      String jsonString;
      if (radioValue.value == 5) {
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
      log('Error loading translation file: $e', name: 'TafsirCtrl');
    } finally {
      isLoading.value = false;
    }
    update(['change_tafsir']);
  }

  /// ------------[DownloadMethods]------------
  /// شرح: تحميل قاعدة بيانات التفسير أو الترجمة
  /// Explanation: Download tafsir or translation database
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
        await saveTafsirDownloadIndex(i);
        await loadTafsirDownloadIndices();
        if (isTafsir.value) {
          await handleRadioValueChanged(i);
          await fetchData(QuranCtrl.instance.state.currentPageNumber.value + 1);
        } else {
          await handleRadioValueChanged(i);
          await fetchTranslate();
        }
        update(['change_tafsir']);
      });
      log('Downloading from URL: $fileUrl', name: 'TafsirCtrl');
    }
  }

  /// شرح: تهيئة حالة تحميل التفسير
  /// Explanation: Initialize tafsir download status
  void initializeTafsirDownloadStatus() async {
    Map<int, bool> initialStatus = await checkAllTafsirDownloaded();
    tafsirDownloadStatus.value = initialStatus;
    await loadTafsirDownloadIndices();
  }

  /// شرح: تحديث حالة التحميل
  /// Explanation: Update download status
  void updateDownloadStatus(int tafsirNumber, bool downloaded) {
    final newStatus = Map<int, bool>.from(tafsirDownloadStatus.value);
    newStatus[tafsirNumber] = downloaded;
    tafsirDownloadStatus.value = newStatus;
  }

  /// شرح: عند نجاح التحميل
  /// Explanation: On download success
  void onDownloadSuccess(int tafsirNumber) {
    updateDownloadStatus(tafsirNumber, true);
  }

  /// شرح: فحص جميع ملفات التفسير
  /// Explanation: Check all tafsir files
  Future<Map<int, bool>> checkAllTafsirDownloaded() async {
    Directory? directory = await getApplicationDocumentsDirectory();
    for (int i = 0; i <= 4; i++) {
      String filePath = '${directory.path}/${tafsirAndTranslateNames[i].name}';
      File file = File(filePath);
      tafsirDownloadStatus.value[i] = await file.exists();
    }
    return tafsirDownloadStatus.value;
  }

  /// شرح: حفظ أرقام التفسير المحملة
  /// Explanation: Save downloaded tafsir indices
  Future<void> saveTafsirDownloadIndex(int tafsirNumber) async {
    List<dynamic> savedIndices = box.read('tafsirDownloadIndices') ?? [3, 5];
    if (!savedIndices.contains(tafsirNumber)) {
      savedIndices.add(tafsirNumber);
      await box.write('tafsirDownloadIndices', savedIndices);
    }
  }

  /// شرح: تحميل أرقام التفسير المحملة
  /// Explanation: Load downloaded tafsir indices
  Future<void> loadTafsirDownloadIndices() async {
    var rawList = box.read('tafsirDownloadIndices');
    List<int> savedIndices =
        rawList is List ? rawList.map((e) => e as int).toList() : [3, 5];
    tafsirDownloadIndexList.value = savedIndices;
  }
}
