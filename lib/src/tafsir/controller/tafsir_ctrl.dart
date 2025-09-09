part of '../tafsir.dart';

class TafsirCtrl extends GetxController {
  TafsirCtrl._privateConstructor();
  static TafsirCtrl get instance =>
      GetInstance().putOrFind(() => TafsirCtrl._privateConstructor());

  Rx<TafsirDatabase?> database = Rx<TafsirDatabase?>(null);
  RxList<TafsirTableData> tafseerList = <TafsirTableData>[].obs;

  static const _defaultDownloadedDbName = 'saadiV4.db';
  static const _defaultDownloadedTranslationLangCode = 'en';

  String? selectedDBName = _defaultDownloadedDbName;
  String translationLangCode = 'en';

  int get translationsStartIndex =>
      tafsirAndTranslationsItems.indexWhere((el) =>
          el.isTranslation == true &&
          el.bookName == _defaultDownloadedTranslationLangCode);
  // RxString selectedTableName = MufaserName.saadi.name.obs;
  RxInt radioValue = 4.obs;
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
  RxList<int> tafsirDownloadIndexList = <int>[].obs;
  int get _defaultTafsirIndex => tafsirAndTranslationsItems
      .indexWhere((el) => el.databaseName == _defaultDownloadedDbName);
  RxInt downloadIndex = 0.obs;
  // var isSelected = (-1.0).obs;
  RxBool isTafsir = true.obs;
  RxList<TranslationModel> translationList = <TranslationModel>[].obs;
  final List<TafsirNameModel> tafsirAndTranslationsItems = [];
  var isLoading = false.obs;

  late Directory _appDir;

  static const String _customTafsirsKey = 'custom_tafsirs_v3';

  List<TafsirNameModel> get tafsirWithoutTranslationItems =>
      tafsirAndTranslationsItems.where((t) => !t.isTranslation).toList();
  List<TafsirNameModel> get translationsWithoutTafsirItems =>
      tafsirAndTranslationsItems.where((t) => t.isTranslation).toList();

  List<TafsirNameModel> get customTafsirAndTranslationsItems =>
      tafsirAndTranslationsItems.where((e) => e.isCustom).toList();

  List<TafsirNameModel> get customTafsirWithoutTranslationsItems =>
      customTafsirAndTranslationsItems.where((e) => !e.isTranslation).toList();
  List<TafsirNameModel> get customTranslationsItems =>
      customTafsirAndTranslationsItems.where((e) => e.isTranslation).toList();

  Future<void> _loadPersistedCustoms() async {
    final raw = box.read(_customTafsirsKey);
    if (raw == null) return;
    try {
      final List<Map<String, dynamic>> arr = json.decode(raw) is List
          ? (json.decode(raw) as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : [];
      for (final e in arr) {
        final m = Map<String, dynamic>.from(e);
        final customTafsirEntry = CustomTafsirEntry.fromJson(m);
        // verify file exists for custom entries; if missing skip
        tafsirAndTranslationsItems.insert(
            customTafsirEntry.index, customTafsirEntry.model);
        customTafsirEntries.insert(customTafsirEntry.index, customTafsirEntry);
      }
    } catch (e) {
      if (kDebugMode) print('Failed to load custom tafsirs: $e');
    }
  }

  Future<void> removeCustomTafsir(TafsirNameModel model) async {
    if (!model.isCustom) return;
    if (model.type == TafsirFileType.sqlite && model.databaseName.isNotEmpty) {
      // try by databaseName inside app dir

      final f = File(join(_appDir.path, model.databaseName));
      if (await f.exists()) await f.delete();
    }
    customTafsirEntries.removeWhere((e) =>
        e.model.isCustom &&
        e.model.databaseName == model.databaseName &&
        e.model.name == model.name);
    tafsirAndTranslationsItems.removeWhere((e) =>
        e.isCustom &&
        e.databaseName == model.databaseName &&
        e.name == model.name);
    await _persistCustoms();
  }

  Future<void> _persistCustoms() async {
    final customOnly = customTafsirEntries.map((e) => e.toJson()).toList();
    await box.write(_customTafsirsKey, json.encode(customOnly));
  }

  bool _isTafsirInitialized = false;

  @override
  Future<void> onInit() async {
    // start from defaults
    _appDir = await getApplicationDocumentsDirectory();
    if (!_isTafsirInitialized) {
      await initTafsir();
    }
    super.onInit();
  }

  bool _isDbInitialized = false;

  /// شرح: تهيئة التفسير مع التأكد من عدم تكرار إنشاء قاعدة البيانات
  /// Explanation: Initialize tafsir and avoid redundant DB creation
  Future<void> initTafsir() async {
    if (_isTafsirInitialized) {
      log('TafsirCtrl already initialized, skipping.', name: 'TafsirCtrl');
      return;
    }
    tafsirAndTranslationsItems.assignAll(_defaultTafsirList);
    await _loadPersistedCustoms().then((_) async {
      await _initializeTafsirDownloadStatus();
      await _loadSelectedDefaultTafseer();
      await initializeDatabase();
    });
    _isTafsirInitialized = true;
    log('TafsirCtrl initialized.', name: 'TafsirCtrl');
  }

  Future<void> _loadSelectedDefaultTafseer() async {
    isTafsir.value = box.read(_StorageConstants().isTafsir) ?? true;
    radioValue.value =
        box.read(_StorageConstants().radioValue) ?? _defaultTafsirIndex;
    translationLangCode =
        box.read(_StorageConstants().translationLangCode) ?? 'en';
    TafsirCtrl.instance.fontSizeArabic.value =
        box.read(_StorageConstants().fontSize) ?? 20.0;
  }

  /// شرح: تهيئة قاعدة البيانات فقط إذا تغير الاسم
  /// Explanation: Only initialize DB if name changed
  Future<void> initializeDatabase() async {
    // guard index
    final idx = (radioValue.value >= 0 &&
            radioValue.value < tafsirAndTranslationsItems.length)
        ? radioValue.value
        : _defaultTafsirIndex;
    if (isCurrentATranslation) {
      log('Selected item is a translation, skipping DB init.',
          name: 'TafsirCtrl');
      return;
    }
    if (isCurrentNotAsqlTafsir) {
      log('Selected item is not a SQLite DB, skipping DB init.',
          name: 'TafsirCtrl');
      return;
    }
    String dbName = tafsirAndTranslationsItems[idx].databaseName;

    // تحقق مزدوج: حالة التحميل + وجود الملف فعلياً
    final file = File(join(_appDir.path, dbName));
    final fileExists = await file.exists();

    if (tafsirDownloadStatus.value[idx] != true || !fileExists) {
      log('Database $dbName not available (downloaded: ${tafsirDownloadStatus.value[idx]}, exists: $fileExists), using default.',
          name: 'TafsirCtrl');
      radioValue.value = _defaultTafsirIndex;
      dbName = _defaultDownloadedDbName;
      // تحديث حالة التحميل إذا كان الملف غير موجود
      if (!fileExists && tafsirDownloadStatus.value[idx] == true) {
        _updateDownloadStatus(idx, false);
      }
    }
    if (database.value == null || selectedDBName != dbName) {
      if (database.value?.isOpen ?? false) await database.value?.close();
      try {
        database.value = TafsirDatabase(dbName);
        selectedDBName = dbName;
        log('Database object created.', name: 'TafsirCtrl');
        _isDbInitialized = true;
      } catch (e) {
        log('Failed to initialize database $dbName: $e', name: 'TafsirCtrl');
        // العودة للتفسير الافتراضي في حالة الخطأ
        if (idx != _defaultTafsirIndex) {
          log('Falling back to default tafsir', name: 'TafsirCtrl');
          radioValue.value = _defaultTafsirIndex;
          dbName = _defaultDownloadedDbName;
          database.value = TafsirDatabase(dbName);
          selectedDBName = dbName;
          _isDbInitialized = true;
        } else {
          rethrow;
        }
      }
    }
    log('Database initialized.', name: 'TafsirCtrl');
  }

  Future<void> closeCurrentDatabase() async {
    if (database.value != null) {
      if (database.value?.isOpen ?? false) await database.value?.close();
      database.value = null; // شرح: إعادة تعيين الكائن بعد الإغلاق
      log('Closed current database!', name: 'TafsirCtrl');
    }
  }

  /// ------------[FetchingMethod]------------
  /// شرح: جلب بيانات التفسير للصفحة المطلوبة
  /// Explanation: Fetch tafsir data for the requested page
  Future<void> fetchData(int pageNum) async {
    // await initializeDatabase();

    try {
      if (isCurrentAcustomTafsir) {
        final customEntry = customTafsirEntries.firstWhereOrNull((e) =>
            e.model.databaseName ==
                tafsirAndTranslationsItems[radioValue.value].databaseName &&
            e.model.name == tafsirAndTranslationsItems[radioValue.value].name);
        if (customEntry != null) {
          final items = customEntry.items
              .where((e) => e.pageNum == pageNum)
              .toList(growable: false);
          tafseerList.assignAll(items);
          log('Fetched tafsir: [31m${items.length} entries from custom tafsir.',
              name: 'TafsirCtrl');
        } else {
          log('Custom tafsir entry not found.', name: 'TafsirCtrl');
        }
        return;
      }

      if (!_isDbInitialized) {
        await initializeDatabase();
      }
      final List<TafsirTableData> tafsirs =
          await database.value!.getTafsirByPage(pageNum);
      log('Fetched tafsir: [32m${tafsirs.length} entries', name: 'TafsirCtrl');
      if (tafsirs.isNotEmpty) {
        tafseerList.assignAll(tafsirs);
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
    if (isCurrentAcustomTafsir) {
      final customEntry = customTafsirEntries.firstWhereOrNull((e) =>
          e.model.databaseName ==
              tafsirAndTranslationsItems[radioValue.value].databaseName &&
          e.model.name == tafsirAndTranslationsItems[radioValue.value].name);
      if (customEntry != null) {
        final items = customEntry.items
            .where((e) => e.pageNum == pageNum)
            .toList(growable: false);
        log('Loaded ${items.length} entries from custom tafsir.',
            name: 'TafsirCtrl');
        return items;
      } else {
        log('Custom tafsir entry not found.', name: 'TafsirCtrl');
        return [];
      }
    }
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
    if (isCurrentAcustomTafsir) {
      final customEntry = customTafsirEntries.firstWhereOrNull((e) =>
          e.model.databaseName ==
              tafsirAndTranslationsItems[radioValue.value].databaseName &&
          e.model.name == tafsirAndTranslationsItems[radioValue.value].name);
      if (customEntry != null) {
        final items = customEntry.items
            .where((e) => customEntry.ayahUnqNum(e.ayahNum) == ayahUQNumber)
            .toList(growable: false);
        log('Loaded ${items.length} entries from custom tafsir.',
            name: 'TafsirCtrl');
        return items;
      }
    }
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
      String path = radioValue.value == translationsStartIndex
          ? 'packages/quran_library/assets/en.json'
          : join(_appDir.path, '$translationLangCode.json');
      isLoading.value = true;

      String jsonString;
      final exists = await File(path).exists();

      if (radioValue.value == translationsStartIndex || !exists) {
        jsonString = await rootBundle
            .loadString('packages/quran_library/assets/en.json');
      } else {
        jsonString = await File(path).readAsString();
      }

      final translationsModel = TranslationsModel.fromJson(jsonString);
      translationList.value = translationsModel.getTranslationsAsList();
    } catch (e) {
      log('Error loading translation file: $e', name: 'TafsirCtrl');
    } finally {
      isLoading.value = false;
    }
    update(['tafsirs_menu_list']);
  }

  /// الحصول على ترجمة آية معينة
  /// Get translation for a specific ayah
  TranslationModel? getTranslationForAyah(int surah, int ayah) {
    return translationList.firstWhereOrNull(
      (translation) =>
          translation.surahNumber == surah && translation.ayahNumber == ayah,
    );
  }

  /// الحصول على النص المترجم لآية معينة
  /// Get translated text for a specific ayah
  String getTranslationText(int surah, int ayah) {
    final translation = getTranslationForAyah(surah, ayah);
    return translation?.text ?? '';
  }

  /// الحصول على الحواشي لآية معينة
  /// Get footnotes for a specific ayah
  Map<String, String> getFootnotesForAyah(int surah, int ayah) {
    final translation = getTranslationForAyah(surah, ayah);
    return translation?.footnotes ?? {};
  }

  /// الحصول على ترجمات صفحة كاملة
  /// Get translations for an entire page
  List<TranslationModel> getTranslationsForPage(int pageNumber) {
    // يحتاج تنفيذ القران للحصول على قائمة الآيات في الصفحة
    // This needs Quran implementation to get list of ayahs in the page
    return translationList.where((translation) {
      // يمكن إضافة منطق هنا للتحقق من الصفحة حسب الحاجة
      return true; // مؤقت
    }).toList();
  }

  /// ------------[DownloadMethods]------------
  /// شرح: تحميل قاعدة بيانات التفسير أو الترجمة
  /// Explanation: Download tafsir or translation database
  Future<void> tafsirDownload(int i) async {
    String path;
    String fileUrl;
    final idx = (i >= 0 && i < tafsirAndTranslationsItems.length) ? i : 0;
    final selected = tafsirAndTranslationsItems[idx];
    if (isTafsir.value) {
      path = join(_appDir.path, selected.databaseName);
      fileUrl =
          'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/tafseer_database/${selected.databaseName}';
    } else {
      path = join(_appDir.path, '${selected.bookName}.json');
      fileUrl =
          'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/quran_database/translate/${selected.bookName}.json';
    }
    if (!onDownloading.value) {
      await downloadFile(path, fileUrl).then((_) async {
        log('Download completed for $path', name: 'TafsirCtrl');
        _onDownloadSuccess(i);
        await _saveTafsirDownloadIndex(i);
        await _loadTafsirDownloadIndices();
        await handleRadioValueChanged(i);
      });
      update(['tafsirs_menu_list']);
      log('Downloading from URL: $fileUrl', name: 'TafsirCtrl');
    }
    update(['tafsirs_menu_list']);
  }

  /// شرح: تهيئة حالة تحميل التفسير
  /// Explanation: Initialize tafsir download status
  Future<void> _initializeTafsirDownloadStatus() async {
    await _loadTafsirDownloadIndices();
    Map<int, bool> initialStatus = await _checkAllTafsirDownloaded();
    tafsirDownloadStatus.value = initialStatus;
  }

  /// شرح: تحديث حالة التحميل
  /// Explanation: Update download status
  void _updateDownloadStatus(int tafsirNumber, bool downloaded) {
    final newStatus = Map<int, bool>.from(tafsirDownloadStatus.value);
    newStatus[tafsirNumber] = downloaded;
    tafsirDownloadStatus.value = newStatus;
  }

  /// شرح: عند نجاح التحميل
  /// Explanation: On download success
  void _onDownloadSuccess(int tafsirNumber) {
    _updateDownloadStatus(tafsirNumber, true);
  }

  /// شرح: فحص جميع ملفات التفسير
  /// Explanation: Check all tafsir files
  Future<Map<int, bool>> _checkAllTafsirDownloaded() async {
    for (int i = 0; i < tafsirAndTranslationsItems.length; i++) {
      if (i == _defaultTafsirIndex ||
          i == translationsStartIndex ||
          tafsirAndTranslationsItems[i].isCustom) {
        tafsirDownloadStatus.value[i] = true;
        continue;
      }
      final dbName = tafsirAndTranslationsItems[i].databaseName;
      String filePath = '${_appDir.path}/$dbName';
      File file = File(filePath);
      final exists = await file.exists();
      if (!exists && tafsirDownloadIndexList.contains(i)) {
        tafsirDownloadIndexList.remove(i);
        await box.write('tafsirDownloadIndices', tafsirDownloadIndexList);
      }
      tafsirDownloadStatus.value[i] = exists;
    }
    return tafsirDownloadStatus.value;
  }

  /// شرح: حفظ أرقام التفسير المحملة
  /// Explanation: Save downloaded tafsir indices
  Future<void> _saveTafsirDownloadIndex(int tafsirNumber) async {
    List<dynamic> savedIndices = box.read('tafsirDownloadIndices') ??
        [_defaultTafsirIndex, translationsStartIndex];
    if (!savedIndices.contains(tafsirNumber)) {
      savedIndices.add(tafsirNumber);
      await box.write('tafsirDownloadIndices', savedIndices);
    }
  }

  /// شرح: تحميل أرقام التفسير المحملة
  /// Explanation: Load downloaded tafsir indices
  Future<void> _loadTafsirDownloadIndices() async {
    var rawList = box.read('tafsirDownloadIndices');
    List<int> savedIndices = rawList is List
        ? rawList.map((e) => e as int).toList()
        : [_defaultTafsirIndex, translationsStartIndex];
    tafsirDownloadIndexList.value = savedIndices;
  }

  List<CustomTafsirEntry> customTafsirEntries = [];

  /// Add CustomTafsirEntry objects (persist models and register entries)
  Future<bool> addCustomTafsirEntries(List<CustomTafsirEntry> entries) async {
    var added = false;
    try {
      for (final entry in entries) {
        final m = entry.model;
        final exists = tafsirAndTranslationsItems.any((e) =>
            e.isCustom && e.databaseName == m.databaseName && e.name == m.name);
        if (!exists) {
          tafsirAndTranslationsItems.insert(entry.index, m);
          added = true;
        }
      }
      // append to live observable list (avoid duplicates)
      for (final entry in entries) {
        final already = customTafsirEntries.any((e) =>
            e.model.databaseName == entry.model.databaseName &&
            e.name == entry.name);
        if (!already) customTafsirEntries.insert(entry.index, entry);
      }
      if (added) await _persistCustoms();
      await _initializeTafsirDownloadStatus();
      update(['tafsirs_menu_list']);
      return true;
    } catch (e) {
      if (kDebugMode) print('Error adding custom tafsir entries: $e');
      return false;
    }
  }
}

class CustomTafsirEntry {
  final String name;
  final TafsirNameModel model;
  final List<TafsirTableData> items;
  final int index;
  int ayahUnqNum(int ayahNum) => (QuranCtrl.instance
      .getAyahUnqNumberBySurahAndAyahNumber(items.first.surahNum, ayahNum));

  const CustomTafsirEntry({
    required this.name,
    required this.model,
    required this.items,
    this.index = 0,
  });

  factory CustomTafsirEntry.fromJson(Map<String, dynamic> j) =>
      CustomTafsirEntry(
        name: j['name'] as String,
        model: TafsirNameModel.fromJson(
            Map<String, dynamic>.from(j['model'] as Map)),
        items: (j['items'] as List)
            .map((e) => TafsirTableData.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        index: j['index'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'model': model.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
        'index': index,
      };
}
