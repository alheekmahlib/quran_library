part of '/quran.dart';

class QuranCtrl extends GetxController {
  static QuranCtrl get instance => GetInstance().putOrFind(() => QuranCtrl());

  QuranCtrl({QuranRepository? quranRepository})
      : _quranRepository = quranRepository ?? QuranRepository(),
        super();

  final QuranRepository _quranRepository;

  RxList<QuranPageModel> staticPages = <QuranPageModel>[].obs;
  RxList<int> quranStops = <int>[].obs;
  RxList<int> surahsStart = <int>[].obs;
  RxList<SurahModel> surahs = <SurahModel>[].obs;
  final RxList<AyahModel> ayahs = <AyahModel>[].obs;
  int lastPage = 1;
  int? initialPage;
  RxList<AyahModel> ayahsList = <AyahModel>[].obs;
  RxList<SurahModel> surahList = <SurahModel>[].obs;

  /// List of selected ayahs by their unique number
  final selectedAyahsByUnequeNumber = <int>[].obs;
  bool isAyahSelected = false;
  RxDouble scaleFactor = 1.0.obs;
  RxDouble baseScaleFactor = 1.0.obs;
  final isLoading = true.obs;
  RxList<SurahNamesModel> surahsList = <SurahNamesModel>[].obs;
  // late QuranSearch quranSearch;

  // شرح: تحسين PageController للحصول على أداء أفضل
  // Explanation: Optimized PageController for better performance
  PageController _pageController = PageController(
    keepPage: true,
    viewportFraction: 1.0,
  );

  QuranState state = QuranState();

  // @override
  // void onInit() {
  //   _initSearch();
  //   super.onInit();
  // }

  @override
  void onClose() {
    staticPages.close();
    quranStops.close();
    surahsStart.close();
    selectedAyahsByUnequeNumber.close();
    surahs.close();
    ayahs.close();
    ayahsList.close();
    scaleFactor.close();
    baseScaleFactor.close();
    isLoading.close();
    surahsList.close();
    state.dispose();
    _pageController.dispose();
    super.onClose();
  }

  /// -------- [Methods] ----------

  // Future<void> _initSearch() async {
  //   quranSearch = QuranSearch(ayahs); // تأكد من أن `ayahs` محملة مسبقًا
  //   await quranSearch.loadModel(); // تحميل نموذج BERT
  // }

  Future<void> loadFontsQuran() async {
    lastPage = _quranRepository.getLastPage() ?? 1;
    if (lastPage != 0) {
      jumpToPage(lastPage - 1);
    }
    if (state.surahs.isEmpty) {
      List<dynamic> surahsJson = await _quranRepository.getFontsQuran();
      state.surahs =
          surahsJson.map((s) => SurahModel.fromDownloadedFontsJson(s)).toList();

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

  List<AyahModel> getAyahsByPage(int page) {
    // تصفية القائمة بناءً على رقم الصفحة
    final filteredAyahs = ayahs.where((ayah) => ayah.page == page).toList();

    // فرز القائمة حسب رقم الآية
    filteredAyahs.sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));

    return filteredAyahs;
  }

  Future<void> loadQuran({quranPages = QuranRepository.hafsPagesNumber}) async {
    // حفظ آخر صفحة
    lastPage = _quranRepository.getLastPage() ?? 1;
    if (lastPage != 0) {
      jumpToPage(lastPage - 1);
    }
    // إذا كانت الصفحات لم تُملأ أو العدد غير متطابق
    if (staticPages.isEmpty || quranPages != staticPages.length) {
      // إنشاء صفحات فارغة
      staticPages.value = List.generate(
        quranPages,
        (index) => QuranPageModel(pageNumber: index + 1, ayahs: [], lines: []),
      );
      final quranJson = await _quranRepository.getQuran();
      int hizb = 1;
      int surahsIndex = 1;
      List<AyahModel> thisSurahAyahs = [];
      for (int i = 0; i < quranJson.length; i++) {
        // تحويل كل json إلى AyahModel
        final ayah = AyahModel.fromOriginalJson(quranJson[i]);
        if (ayah.surahNumber != surahsIndex) {
          surahs.last.endPage = ayahs.last.page;
          surahs.last.ayahs = thisSurahAyahs;
          surahsIndex = ayah.surahNumber!;
          thisSurahAyahs = [];
        }
        ayahs.add(ayah);
        thisSurahAyahs.add(ayah);
        staticPages[ayah.page - 1].ayahs.add(ayah);
        if (ayah.text.contains('۞')) {
          staticPages[ayah.page - 1].hizb = hizb++;
          quranStops.add(ayah.page);
        }
        if (ayah.text.contains('۩')) {
          staticPages[ayah.page - 1].hasSajda = true;
        }
        if (ayah.ayahNumber == 1) {
          ayah.text = ayah.text.replaceAll('۞', '');
          staticPages[ayah.page - 1].numberOfNewSurahs++;
          surahs.add(SurahModel(
            surahNumber: ayah.surahNumber!,
            englishName: ayah.englishName!,
            arabicName: ayah.arabicName!,
            ayahs: [],
            isDownloadedFonts: false,
          ));
          surahsStart.add(ayah.page - 1);
        }
      }
      surahs.last.endPage = ayahs.last.page;
      surahs.last.ayahs = thisSurahAyahs;
      // ملء الأسطر (lines) لكل صفحة
      for (QuranPageModel staticPage in staticPages) {
        List<AyahModel> ayas = [];
        for (AyahModel aya in staticPage.ayahs) {
          if (aya.ayahNumber == 1 && ayas.isNotEmpty) {
            ayas.clear();
          }
          if (aya.text.contains('\n')) {
            final lines = aya.text.split('\n');
            for (int i = 0; i < lines.length; i++) {
              bool centered = false;
              if ((aya.centered ?? false) && i == lines.length - 2) {
                centered = true;
              }
              final a = AyahModel.fromAya(
                ayah: aya,
                aya: lines[i],
                ayaText: lines[i],
                centered: centered,
              );
              ayas.add(a);
              if (i < lines.length - 1) {
                staticPage.lines.add(LineModel([...ayas]));
                ayas.clear();
              }
            }
          } else {
            ayas.add(aya);
          }
        }
        // إذا بقيت آيات في ayas بعد آخر سطر
        if (ayas.isNotEmpty) {
          staticPage.lines.add(LineModel([...ayas]));
        }
        ayas.clear();
      }
      update();
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

  List<AyahModel> search(String searchText) {
    if (searchText.isEmpty) {
      return [];
    } else {
      // تطبيع النصوص المدخلة
      final normalizedSearchText =
          normalizeText(searchText.toLowerCase().trim());

      final filteredAyahs = ayahs.where((aya) {
        // تطبيع نص الآية واسم السورة
        final normalizedAyahText =
            normalizeText(aya.ayaTextEmlaey.toLowerCase());
        final normalizedSurahNameAr =
            normalizeText(aya.arabicName!.toLowerCase());
        final normalizedSurahNameEn =
            normalizeText(aya.englishName!.toLowerCase());

        // التحقق من تطابق نص الآية
        final containsWord = normalizedAyahText.contains(normalizedSearchText);

        // التحقق من تطابق رقم الصفحة
        final matchesPage = aya.page.toString() ==
            normalizedSearchText
                .convertArabicNumbersToEnglish(normalizedSearchText);

        // التحقق من تطابق اسم السورة بالعربية أو الإنجليزية
        final matchesSurahName =
            normalizedSurahNameAr == normalizedSearchText ||
                normalizedSurahNameEn == normalizedSearchText;

        // التحقق من رقم الآية
        final matchesAyahNumber = aya.ayahNumber.toString() ==
            normalizedSearchText
                .convertArabicNumbersToEnglish(normalizedSearchText);

        // إذا تحقق أي شرط من الشروط أعلاه باستثناء رقم السورة
        return containsWord ||
            matchesPage ||
            matchesSurahName ||
            matchesAyahNumber;
      }).toList();

      return filteredAyahs;
    }
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

  List<SurahModel> searchSurah(String searchText) {
    if (searchText.isEmpty) {
      return [];
    } else {
      // تحويل الأرقام العربية إلى إنجليزية في النص المدخل
      // Convert Arabic numbers to English in the input text
      final convertedSearchText =
          searchText.convertArabicNumbersToEnglish(searchText);

      // إزالة التشكيل وتطبيع النص المدخل
      // Remove diacritics and normalize the input text
      final cleanedSearchText = removeDiacriticsQuran(convertedSearchText);
      final normalizedSearchText =
          normalizeText(cleanedSearchText.toLowerCase().trim());

      final filteredSurahs = surahs.where((surah) {
        // إزالة التشكيل وتطبيع أسماء السور
        // Remove diacritics and normalize surah names
        final cleanedSurahNameAr = removeDiacriticsQuran(surah.arabicName);
        final normalizedSurahNameAr =
            normalizeText(cleanedSurahNameAr.toLowerCase());
        final normalizedSurahNameEn =
            normalizeText(surah.englishName.toLowerCase());

        // استخدام contains بدلاً من == للسماح بمطابقة جزئية
        // Use contains instead of == to allow partial matching
        final matchesSurahName =
            normalizedSurahNameAr.contains(normalizedSearchText) ||
                normalizedSurahNameEn.contains(normalizedSearchText);

        // تحويل رقم السورة إلى نص مع تحويل الأرقام العربية
        // Convert surah number to text with Arabic number conversion
        final surahNumberText = surah.surahNumber.toString();
        final matchesSurahNumber = surahNumberText == normalizedSearchText;

        return matchesSurahName || matchesSurahNumber;
      }).toList();

      return filteredSurahs;
    }
  }

  void saveLastPage(int lastPage) {
    this.lastPage = lastPage;
    _quranRepository.saveLastPage(lastPage);
  }

  // شرح: تحسين التنقل للحصول على سكرول أكثر سلاسة
  // Explanation: Improved navigation for smoother scrolling
  void jumpToPage(int page) {
    if (_pageController.hasClients) {
      // استخدام animateToPage بدلاً من jumpToPage للحصول على انتقال أكثر سلاسة
      // Use animateToPage instead of jumpToPage for smoother transition
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController = PageController(
        initialPage: page,
        keepPage: true,
        viewportFraction: 1.0,
      );
    }
  }

  PageController getPageController(BuildContext context) =>
      _pageController = PageController(
        keepPage: true,
        viewportFraction:
            (Responsive.isDesktop(context) && context.isLandscape) ? 1 / 2 : 1,
      );

  /// Toggle the selection of an ayah by its unique number
  void toggleAyahSelection(int ayahUnequeNumber) {
    if (selectedAyahsByUnequeNumber.contains(ayahUnequeNumber)) {
      selectedAyahsByUnequeNumber.remove(ayahUnequeNumber);
    } else {
      selectedAyahsByUnequeNumber.clear();
      selectedAyahsByUnequeNumber.add(ayahUnequeNumber);
      selectedAyahsByUnequeNumber.refresh();
    }
    selectedAyahsByUnequeNumber.refresh();
  }

  void clearSelection() {
    selectedAyahsByUnequeNumber.clear();
  }

  Widget textScale(dynamic widget1, dynamic widget2) {
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
    } else if (newScaleFactor < 4) {
      state.scaleFactor.value = newScaleFactor;
    }

    update();
  }

  String removeDiacriticsQuran(String input) {
    final diacriticsMap = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'إٔ': 'ا',
      'إٕ': 'ا',
      'إٓ': 'ا',
      'أَ': 'ا',
      'إَ': 'ا',
      'آَ': 'ا',
      'إُ': 'ا',
      'إٌ': 'ا',
      'إً': 'ا',
      'ة': 'ه',
      'ً': '',
      'ٌ': '',
      'ٍ': '',
      'َ': '',
      'ُ': '',
      'ِ': '',
      'ّ': '',
      'ْ': '',
      'ـ': '',
      'ٰ': '',
      'ٖ': '',
      'ٗ': '',
      'ٕ': '',
      'ٓ': '',
      'ۖ': '',
      'ۗ': '',
      'ۘ': '',
      'ۙ': '',
      'ۚ': '',
      'ۛ': '',
      'ۜ': '',
      '۝': '',
      '۞': '',
      '۟': '',
      '۠': '',
      'ۡ': '',
      'ۢ': '',
    };

    StringBuffer buffer = StringBuffer();
    Map<int, int> indexMapping =
        {}; // Ensure indexMapping is declared if not already globally declared
    for (int i = 0; i < input.length; i++) {
      String char = input[i];
      String? mappedChar = diacriticsMap[char];
      if (mappedChar != null) {
        buffer.write(mappedChar);
        if (mappedChar.isNotEmpty) {
          indexMapping[buffer.length - 1] = i;
        }
      } else {
        buffer.write(char);
        indexMapping[buffer.length - 1] = i;
      }
    }
    return buffer.toString();
  }

  // List<TajweedRuleModel> getTajweedRules({required String languageCode}) {
  //   if (languageCode == "ar") {
  //     return tajweedRulesListAr;
  //   } else if (languageCode == "en") {
  //     return tajweedRulesListEn;
  //   } else if (languageCode == "bn") {
  //     return tajweedRulesListBn;
  //   } else if (languageCode == "id") {
  //     return tajweedRulesListId;
  //   } else if (languageCode == "tr") {
  //     return tajweedRulesListTr;
  //   } else if (languageCode == "ur") {
  //     return tajweedRulesListUr;
  //   }
  //   return tajweedRulesListAr;
  // }
}
