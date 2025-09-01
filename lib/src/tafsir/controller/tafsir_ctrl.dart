part of '../tafsir.dart';

class TafsirCtrl extends GetxController {
  TafsirCtrl._privateConstructor();
  static TafsirCtrl get instance =>
      GetInstance().putOrFind(() => TafsirCtrl._privateConstructor());

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

  late Directory _dir;

  /// شرح: متغير لحفظ اسم قاعدة البيانات الحالية
  /// Explanation: Variable to store the current database name
  String? currentDbFileName;

  static const String _customTafsirsKey = 'custom_tafsirs_v1';
  final List<TafsirNameModel> _items = [];

  List<TafsirNameModel> get items => List.unmodifiable(_items);
  List<TafsirNameModel> get customItems =>
      List.unmodifiable(_items.where((e) => e.isCustom));

  /// Add multiple custom tafsir models (they should already point to valid filePath)
  Future<void> addCustomList(List<TafsirNameModel> models) async {
    var added = false;
    for (final m in models) {
      final exists = _items.any((e) =>
          e.isCustom && e.databaseName == m.databaseName && e.name == m.name);
      if (!exists) {
        _items.add(m);
        added = true;
      }
    }
    if (added) await _persistCustoms();
  }

  Future<void> _loadPersistedCustoms() async {
    final raw = box.read(_customTafsirsKey);
    if (raw == null) return;
    try {
      final List<dynamic> arr = json.decode(raw) as List<dynamic>;
      for (final e in arr) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(e);
        final model = TafsirNameModel.fromJson(m);
        // verify file exists for custom entries; if missing skip
        if (model.isCustom) {
          if (model.filePath == null) continue;
          if (await File(model.filePath!).exists()) {
            _items.add(model);
          } else {
            // optionally try to resolve by databaseName in app dir
            final appDir = await getApplicationSupportDirectory();
            final f = File(join(appDir.path, model.databaseName));
            if (await f.exists()) {
              final fixed = TafsirNameModel(
                name: model.name,
                bookName: model.bookName,
                databaseName: model.databaseName,
                isCustom: true,
                type: model.type,
                filePath: f.path,
              );
              _items.add(fixed);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Failed to load custom tafsirs: $e');
    }
  }

  Future<TafsirNameModel> addCustomFromFile({
    required File sourceFile,
    required String displayName,
    required String bookName,
    required TafsirFileType type,
  }) async {
    final appDir = await getApplicationSupportDirectory();
    await appDir.create(recursive: true);
    final ext = type == TafsirFileType.sqlite ? '.db' : '.json';
    final filename = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final dest = File(join(appDir.path, filename));
    await sourceFile.copy(dest.path);

    final model = TafsirNameModel(
      name: displayName,
      bookName: bookName,
      databaseName: filename,
      isCustom: true,
      type: type,
      filePath: dest.path,
    );

    _items.add(model);
    await _persistCustoms();
    return model;
  }

  Future<TafsirNameModel> addCustomFromBytes({
    required List<int> bytes,
    required String displayName,
    required String bookName,
    required TafsirFileType type,
    String? filenameHint,
  }) async {
    final appDir = await getApplicationSupportDirectory();
    await appDir.create(recursive: true);
    final ext = type == TafsirFileType.sqlite ? '.db' : '.json';
    final filename = filenameHint != null
        ? '${DateTime.now().millisecondsSinceEpoch}_$filenameHint$ext'
        : '${DateTime.now().millisecondsSinceEpoch}$ext';
    final dest = File(join(appDir.path, filename));
    await dest.writeAsBytes(bytes);

    final model = TafsirNameModel(
      name: displayName,
      bookName: bookName,
      databaseName: filename,
      isCustom: true,
      type: type,
      filePath: dest.path,
    );

    _items.add(model);
    await _persistCustoms();
    return model;
  }

  Future<void> removeCustom(TafsirNameModel model) async {
    if (!model.isCustom) return;
    // remove file if exists
    if (model.filePath != null) {
      try {
        final f = File(model.filePath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    } else {
      // try by databaseName inside app dir
      final appDir = await getApplicationSupportDirectory();
      final f = File(join(appDir.path, model.databaseName));
      if (await f.exists()) await f.delete();
    }
    _items.removeWhere((e) =>
        e.isCustom &&
        e.databaseName == model.databaseName &&
        e.name == model.name);
    await _persistCustoms();
  }

  Future<void> _persistCustoms() async {
    final customOnly =
        _items.where((e) => e.isCustom).map((e) => e.toJson()).toList();
    await box.write(_customTafsirsKey, json.encode(customOnly));
  }

  bool _isTafsirInitialized = false;

  @override
  Future<void> onInit() async {
    // start from defaults
    _dir = await getApplicationDocumentsDirectory();
    _items.clear();
    _items.addAll(defaultTafsirList);
    if (!_isTafsirInitialized) {
      await initTafsir();
    }
    await _loadPersistedCustoms();
    super.onInit();
  }

  /// شرح: تهيئة التفسير مع التأكد من عدم تكرار إنشاء قاعدة البيانات
  /// Explanation: Initialize tafsir and avoid redundant DB creation
  Future<void> initTafsir() async {
    initializeTafsirDownloadStatus();
    await loadTafseer();
    await initializeDatabase();
    _isTafsirInitialized = true;
    log('TafsirCtrl initialized.', name: 'TafsirCtrl');
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
    // guard index
    final idx = (radioValue.value >= 0 && radioValue.value < items.length)
        ? radioValue.value
        : 0;
    String dbName = items[idx].databaseName;
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
      String path = radioValue.value == 5
          ? 'packages/quran_library/assets/en.json'
          : join(_dir.path, '${translationLangCode.value}.json');
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
    String path;
    String fileUrl;
    final idx = (i >= 0 && i < items.length) ? i : 0;
    final selected = items[idx];
    if (isTafsir.value) {
      path = join(_dir.path, selected.databaseName);
      fileUrl =
          'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/tafseer_database/${selected.databaseName}';
    } else {
      path = join(_dir.path, '${selected.bookName}.json');
      fileUrl =
          'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/quran_database/translate/${selected.bookName}.json';
    }
    if (!onDownloading.value) {
      update(['change_tafsir']);
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
      });
      log('Downloading from URL: $fileUrl', name: 'TafsirCtrl');
    }
    update(['change_tafsir']);
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
    for (int i = 0; i < items.length; i++) {
      final dbName = items[i].databaseName;
      String filePath = '${_dir.path}/$dbName';
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

  RxList<CustomTafsirEntry> customTafsirEntries = <CustomTafsirEntry>[].obs;

  Future<void> buildCustomTafsirEntries({int previewPage = 1}) async {
    customTafsirEntries.clear();
    final appDir = await getApplicationSupportDirectory();
    for (final model in customItems) {
      try {
        List<TafsirTableData> loadedItems = [];
        if (model.type == TafsirFileType.sqlite) {
          // Try filePath first, then app dir + databaseName
          final dbPath =
              model.filePath ?? join(appDir.path, model.databaseName);
          // create a temporary db instance to read preview (TafsirDatabase must accept path/name)
          final tmpDb = TafsirDatabase(dbPath);
          try {
            loadedItems = await tmpDb.getTafsirByPage(previewPage);
            // If you want to tag each TafsirTableData with the source name, do so here
            // (depends on TafsirTableData fields — if it has a `source` or `tafsirName` field set it)
          } finally {
            await tmpDb.close();
          }
        } else if (model.type == TafsirFileType.json) {
          // JSON: read file and convert to TafsirTableData - requires mapping details
          final jsonPath =
              model.filePath ?? join(appDir.path, model.databaseName);
          final f = File(jsonPath);
          if (await f.exists()) {
            final content = await f.readAsString();
            final decoded = json.decode(content);
            // TODO: map `decoded` to List<TafsirTableData>
            // loadedItems = mapJsonToTafsirTableData(decoded);
          }
        }
        customTafsirEntries.add(CustomTafsirEntry(
          name: model.name,
          model: model,
          items: loadedItems,
        ));
      } catch (e) {
        if (kDebugMode) print('Failed to load preview for ${model.name}: $e');
        customTafsirEntries
            .add(CustomTafsirEntry(name: model.name, model: model, items: []));
      }
    }
    update(['change_tafsir']);
  }

  /// Add CustomTafsirEntry objects (persist models and register entries)
  Future<void> addCustomEntries(List<CustomTafsirEntry> entries) async {
    var added = false;
    for (final entry in entries) {
      final m = entry.model;
      final exists = _items.any((e) =>
          e.isCustom && e.databaseName == m.databaseName && e.name == m.name);
      if (!exists) {
        _items.add(m);
        added = true;
      }
    }
    if (added) await _persistCustoms();
    // append to live observable list (avoid duplicates)
    for (final entry in entries) {
      final already = customTafsirEntries.any((e) =>
          e.model.databaseName == entry.model.databaseName &&
          e.name == entry.name);
      if (!already) customTafsirEntries.add(entry);
    }
    update(['change_tafsir']);
  }
}

class CustomTafsirEntry {
  final String name;
  final TafsirNameModel model;
  final List<TafsirTableData> items;

  CustomTafsirEntry({
    required this.name,
    required this.model,
    required this.items,
  });
}
