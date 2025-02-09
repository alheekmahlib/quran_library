part of '../../../quran.dart';

class QuranCtrl extends GetxController {
  static QuranCtrl get instance => Get.isRegistered<QuranCtrl>()
      ? Get.find<QuranCtrl>()
      : Get.put<QuranCtrl>(QuranCtrl());
  QuranCtrl({QuranRepository? quranRepository})
      : _quranRepository = quranRepository ?? QuranRepository(),
        super();

  final QuranRepository _quranRepository;

  RxList<QuranPage> staticPages = <QuranPage>[].obs;
  RxList<int> quranStops = <int>[].obs;
  RxList<int> surahsStart = <int>[].obs;
  RxList<Surah> surahs = <Surah>[].obs;
  int lastPage = 1;
  int? initialPage;
  var selectedAyahIndexes = <int>[].obs;
  bool isAyahSelected = false;
  RxDouble scaleFactor = 1.0.obs;
  RxDouble baseScaleFactor = 1.0.obs;
  var isLoading = true.obs;
  RxList<SurahNamesModel> surahsList = <SurahNamesModel>[].obs;

  PageController _pageController = PageController();

  QuranState state = QuranState();

  @override
  void onClose() {
    state.quranPageController.dispose();
    state.overlayEntry!.remove();
    super.onClose();
  }

  /// -------- [Methods] ----------

  Future<void> loadFontsQuran() async {
    lastPage = _quranRepository.getLastPage() ?? 1;
    if (lastPage != 0) {
      jumpToPage(lastPage - 1);
    }
    if (state.surahs.isEmpty) {
      List<dynamic> surahsJson = await _quranRepository.getFontsQuran();
      state.surahs =
          surahsJson.map((s) => SurahFontsModel.fromJson(s)).toList();

      for (final surah in state.surahs) {
        state.allAyahs.addAll(surah.ayahs);
        // log('Added ${surah.arabicName} ayahs');
        update();
      }
      List.generate(604, (pageIndex) {
        state.pages.add(state.allAyahs
            .where((ayah) => ayah.page == pageIndex + 1)
            .toList());
      });
      state.isQuranLoaded = true;
      // log('Pages Length: ${state.pages.length}', name: 'Quran Controller');
    }
  }

  Future<void> fetchSurahs() async {
    try {
      isLoading(true);
      final jsonResponse = await _quranRepository.getSurahs();
      final response = SurahResponseModel.fromJson(jsonResponse);
      surahsList.assignAll(response.surahs);
    } catch (e) {
      log('Error fetching data: $e');
    } finally {
      isLoading(false);
    }
    update();
  }

// دالة تطبيع النصوص لتحويل الأحرف
  String normalizeText(String text) {
    return text
        .replaceAll('ة', 'ه')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ئ', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll(RegExp(r'\s+'), ' '); // إزالة الفراغات الزائدة
  }

  void saveLastPage(int lastPage) {
    this.lastPage = lastPage;
    _quranRepository.saveLastPage(lastPage);
  }

  void jumpToPage(int page) {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(page);
    } else {
      _pageController = PageController(initialPage: page);
    }
  }

  PageController get pageController => _pageController;

  void toggleAyahSelection(int index) {
    if (selectedAyahIndexes.contains(index)) {
      selectedAyahIndexes.remove(index);
    } else {
      selectedAyahIndexes.clear();
      selectedAyahIndexes.add(index);
      selectedAyahIndexes.refresh();
    }
    selectedAyahIndexes.refresh();
  }

  void clearSelection() {
    selectedAyahIndexes.clear();
  }

  dynamic textScale(dynamic widget1, dynamic widget2) {
    if (state.scaleFactor.value <= 1.3) {
      return widget1;
    } else {
      return widget2;
    }
  }

  void updateTextScale(ScaleUpdateDetails details) {
    double newScaleFactor = state.baseScaleFactor.value * details.scale;
    if (newScaleFactor < 1.0) {
      newScaleFactor = 1.0;
    }
    state.scaleFactor.value = newScaleFactor;
    update();
  }

  List<TajweedRuleModel> getTajweedRules({required String languageCode}) {
    if (languageCode == "ar") {
      return tajweedRulesListAr;
    } else if (languageCode == "en") {
      return tajweedRulesListEn;
    } else if (languageCode == "bn") {
      return tajweedRulesListBn;
    } else if (languageCode == "id") {
      return tajweedRulesListId;
    } else if (languageCode == "tr") {
      return tajweedRulesListTr;
    } else if (languageCode == "ur") {
      return tajweedRulesListUr;
    }
    return tajweedRulesListAr;
  }
}
