part of '../../../quran.dart';

/// Extensions on [QuranCtrl] that provides getters
/// for [QuranCtrl]'s properties.
extension QuranGetters on QuranCtrl {
  /// -------- [Getter] ----------

  List<int> get _startSurahsNumbers => [
        1,
        2,
        3,
        4,
        6,
        7,
        8,
        9,
        10,
        13,
        15,
        17,
        19,
        21,
        22,
        23,
        24,
        26,
        27,
        31,
        32,
        33,
        34,
        37,
        38,
        41,
        42,
        44,
        45,
        47,
        48,
        50,
        53,
        58,
        60,
        62,
        64,
        65,
        66,
        67,
        72,
        73,
        78,
        80,
        82,
        86,
        103,
        106,
        109,
        112,
      ];

  List<int> get _downThePageIndex => [
        75,
        206,
        330,
        340,
        348,
        365,
        375,
        413,
        416,
        444,
        451,
        497,
        505,
        524,
        547,
        554,
        556,
        583
      ];

  List<int> get _topOfThePageIndex => [
        76,
        207,
        331,
        341,
        349,
        366,
        376,
        414,
        417,
        435,
        445,
        452,
        498,
        506,
        525,
        548,
        554,
        555,
        557,
        583,
        584
      ];

  /// Returns a list of lists of AyahFontsModel, where each sublist contains Ayahs
  /// that are separated by a Basmalah, for the given page index.
  ///
  /// Parameters:
  ///   pageIndex (int): The index of the page for which to retrieve the Ayahs.
  ///
  /// Returns:
  ///   `List<List<AyahFontsModel>>`: A list of lists of AyahFontsModel, where each
  ///   sublist contains Ayahs separated by a Basmalah.
  List<List<AyahFontsModel>> getCurrentPageAyahsSeparatedForBasmalah(
          int pageIndex) =>
      state.pages[pageIndex]
          .splitBetween((f, s) => f.ayahNumber > s.ayahNumber)
          .toList();

  /// Retrieves a list of AyahFontsModel for a specific page index.
  ///
  /// Parameters:
  ///   pageIndex (int): The index of the page for which to retrieve the Ayahs.
  ///
  /// Returns:
  ///   `List<AyahFontsModel>`: A list of AyahFontsModel representing the Ayahs on the specified page.
  List<AyahFontsModel> getPageAyahsByIndex(int pageIndex) =>
      state.pages[pageIndex];

  /// will return the surah number of the first ayahs..
  /// even if the page contains another surah.
  int getSurahNumberFromPage(int pageNumber) => state.surahs
      .firstWhere(
          (s) => s.ayahs.firstWhereOrNull((a) => a.page == pageNumber) != null)
      .surahNumber;

  /// Retrieves a list of Surahs present on a specific page.
  ///
  /// Parameters:
  ///   pageNumber (int): The index of the page for which to retrieve the Surahs.
  ///
  /// Returns:
  ///   `List<SurahFontsModel>`: A list of SurahFontsModel representing the Surahs on the specified page.
  List<SurahFontsModel> getSurahsByPage(int pageNumber) {
    List<AyahFontsModel> pageAyahs = getPageAyahsByIndex(pageNumber);
    List<SurahFontsModel> surahsOnPage = [];
    for (AyahFontsModel ayah in pageAyahs) {
      SurahFontsModel surah = state.surahs.firstWhere(
          (s) => s.ayahs.contains(ayah),
          orElse: () => SurahFontsModel(
              surahNumber: 1,
              arabicName: 'Unknown',
              englishName: 'Unknown',
              revelationType: 'Unknown',
              ayahs: []));
      if (!surahsOnPage.any((s) => s.surahNumber == surah.surahNumber) &&
          surah.surahNumber != -1) {
        surahsOnPage.add(surah);
      }
    }
    return surahsOnPage;
  }

  /// Retrieves the current Surah data for a given page number.
  ///
  /// This method returns the SurahFontsModel of the first Ayah on the specified page.
  /// It uses the Ayah data on the page to determine which Surah the page belongs to.
  ///
  /// Parameters:
  ///   pageNumber (int): The number of the page for which to retrieve the Surah.
  ///
  /// Returns:
  ///   `SurahFontsModel`: The SurahFontsModel representing the Surah of the first Ayah on the specified page.
  SurahFontsModel getCurrentSurahByPage(int pageNumber) =>
      state.surahs.firstWhere(
          (s) => s.ayahs.contains(getPageAyahsByIndex(pageNumber).first));

  /// Retrieves the Surah data for a given Ayah.
  ///
  /// This method returns the SurahFontsModel of the Surah that contains the given Ayah.
  ///
  /// Parameters:
  ///   ayah (AyahFontsModel): The Ayah for which to retrieve the Surah data.
  ///
  /// Returns:
  ///   `SurahFontsModel`: The SurahFontsModel representing the Surah of the given Ayah.
  SurahFontsModel getSurahDataByAyah(AyahFontsModel ayah) =>
      state.surahs.firstWhere((s) => s.ayahs.contains(ayah));

  /// Retrieves the Surah data for a given unique Ayah number.
  ///
  /// This method returns the SurahFontsModel of the Surah that contains
  /// the Ayah with the specified unique number.
  ///
  /// Parameters:
  ///   ayah (int): The unique number of the Ayah for which to retrieve
  ///   the Surah data.
  ///
  /// Returns:
  ///   `SurahFontsModel`: The SurahFontsModel representing the Surah containing
  ///   the Ayah with the given unique number.
  SurahFontsModel getSurahDataByAyahUQ(int ayah) => state.surahs
      .firstWhere((s) => s.ayahs.any((a) => a.ayahUQNumber == ayah));

  /// Retrieves the Juz data for a given page number.
  ///
  /// This method returns the AyahFontsModel of the Juz that contains the
  /// first Ayah on the specified page.
  ///
  /// Parameters:
  ///   page (int): The page number for which to retrieve the Juz data.
  ///
  /// Returns:
  ///   `AyahFontsModel`: The AyahFontsModel representing the Juz of the first
  ///   Ayah on the specified page. If no Ayah is found, an empty AyahFontsModel
  ///   is returned.
  AyahFontsModel getJuzByPage(int page) {
    return state.allAyahs.firstWhere(
      (a) => a.page == page + 1,
      orElse: () => AyahFontsModel._empty(),
    );
  }

  /// Retrieves the display string for the Hizb quarter of the given page number.
  ///
  /// This method returns a string indicating the Hizb quarter of the given page number.
  /// It takes into account whether the Hizb quarter is new or the same as the previous page's Hizb quarter,
  /// and formats the string accordingly.
  ///
  /// Parameters:
  ///    pageNumber (int): The page number for which to retrieve the Hizb quarter display string.
  ///
  /// Returns:
  ///   `String`: A string indicating the Hizb quarter of the given page number.
  String getHizbQuarterDisplayByPage(int pageNumber) {
    final List<AyahFontsModel> currentPageAyahs =
        state.allAyahs.where((ayah) => ayah.page == pageNumber).toList();
    if (currentPageAyahs.isEmpty) return "";

    // Find the highest Hizb quarter on the current page
    int? currentMaxHizbQuarter =
        currentPageAyahs.map((ayah) => ayah.hizb).reduce(math.max);

    // Store/update the highest Hizb quarter for this page
    state.pageToHizbQuarterMap[pageNumber] = currentMaxHizbQuarter;

    // For displaying the Hizb quarter, check if this is a new Hizb quarter different from the previous page's Hizb quarter
    // For the first page, there is no "previous page" to compare, so display its Hizb quarter
    if (pageNumber == 1 ||
        state.pageToHizbQuarterMap[pageNumber - 1] != currentMaxHizbQuarter) {
      int hizbNumber = ((currentMaxHizbQuarter - 1) ~/ 4) + 1;
      int quarterPosition = (currentMaxHizbQuarter - 1) % 4;

      switch (quarterPosition) {
        case 0:
          return "الحزب ${'$hizbNumber'.convertNumbersAccordingToLang()}";
        case 1:
          return "١/٤ الحزب ${'$hizbNumber'.convertNumbersAccordingToLang()}";
        case 2:
          return "١/٢ الحزب ${'$hizbNumber'.convertNumbersAccordingToLang()}";
        case 3:
          return "٣/٤ الحزب ${'$hizbNumber'.convertNumbersAccordingToLang()}";
        default:
          return "";
      }
    }

    // If the page's Hizb quarter is the same as the previous page, do not display it again
    return "";
  }

  /// Determines if there is a Sajda (prostration) on the given page of Ayahs.
  ///
  /// This function iterates through a list of AyahFontsModel representing Ayahs on a page,
  /// checking if any Ayah contains a Sajda. If a Sajda is found, and it is either recommended or obligatory,
  /// the function updates the application state to indicate the presence of a Sajda on the page.
  ///
  /// Parameters:
  ///   pageAyahs (`List<AyahFontsModel>`): The list of Ayahs to check for Sajda.
  ///
  /// Returns:
  ///   `bool`: A boolean value indicating whether a Sajda is present on the page.
  bool getSajdaInfoForPage(List<AyahFontsModel> pageAyahs) {
    for (var ayah in pageAyahs) {
      if (ayah.sajda != false && ayah.sajda is Map) {
        var sajdaDetails = ayah.sajda;
        if (sajdaDetails['recommended'] == true ||
            sajdaDetails['obligatory'] == true) {
          return state.isSajda.value = true;
        }
      }
    }
    // No sajda found on this page
    return state.isSajda.value = false;
  }

  /// Retrieves the list of Ayahs on the current page.
  ///
  /// This method returns the list of Ayahs on the page currently being viewed.
  ///
  /// Returns:
  ///   `List<AyahFontsModel>`: The list of Ayahs on the current page.
  List<AyahFontsModel> get currentPageAyahs =>
      state.pages[state.currentPageNumber.value - 1];

  /// Retrieves the Ayah with a Sajda (prostration) on the given page.
  ///
  /// This method returns the AyahFontsModel of the first Ayah on the given page
  /// that contains a Sajda. If no Sajda is found on the page, the method returns null.
  ///
  /// Parameters:
  ///   pageIndex (int): The index of the page for which to retrieve the Ayah with a Sajda.
  ///
  /// Returns:
  ///   `AyahFontsModel?`: The AyahFontsModel of the first Ayah on the given page that contains a Sajda, or null if no Sajda is found.
  AyahFontsModel? getAyahWithSajdaInPage(int pageIndex) =>
      state.pages[pageIndex].firstWhereOrNull((ayah) {
        if (ayah.sajda != false) {
          if (ayah.sajda is Map) {
            var sajdaDetails = ayah.sajda;
            if (sajdaDetails['recommended'] == true ||
                sajdaDetails['obligatory'] == true) {
              return state.isSajda.value = true;
            }
          } else {
            return ayah.sajda == true;
          }
        }
        return state.isSajda.value = false;
      });

  /// Checks if the current Surah number matches the specified Surah number.
  ///
  /// This method compares the Surah number of the current page with the given Surah number.
  ///
  /// Parameters:
  ///   surahNum (int): The number of the Surah to compare with the current Surah.
  ///
  /// Returns:
  ///   `bool`: true if the current Surah number matches the specified Surah number, false otherwise.
  bool getCurrentSurahNumber(int surahNum) =>
      getCurrentSurahByPage(state.currentPageNumber.value).surahNumber - 1 ==
      surahNum;

  /// Checks if the current Juz number matches the specified Juz number.
  ///
  /// This method compares the Juz number of the current page with the given Juz number.
  ///
  /// Parameters:
  ///   juzNum (int): The number of the Juz to compare with the current Juz.
  ///
  /// Returns:
  ///   `bool`: true if the current Juz number matches the specified Juz number, false otherwise.
  bool getCurrentJuzNumber(int juzNum) =>
      getJuzByPage(state.currentPageNumber.value).juz - 1 == juzNum;

  /// Checks if the fonts are downloaded locally.
  ///
  /// This method returns a boolean indicating whether the fonts are downloaded locally.
  ///
  /// Returns:
  ///   `bool`: true if the fonts are downloaded, false otherwise.
  bool get isDownloadFonts => (state.fontsSelected2.value == 1);

// PageController get pageController {
//   return state.quranPageController = PageController(
//       viewportFraction: Responsive.isDesktop(Get.context!) ? 1 / 2 : 1,
//       initialPage: state.currentPageNumber.value - 1,
//       keepPage: true);
// }
//
// ScrollController get surahController {
//   final suraNumber =
//       getCurrentSurahByPage(state.currentPageNumber.value - 1).surahNumber -
//           1;
//   if (state.surahController == null) {
//     state.surahController = ScrollController(
//       initialScrollOffset: state.surahItemHeight * suraNumber,
//     );
//   }
//   return state.surahController!;
// }
//
// ScrollController get juzController {
//   if (state.juzListController == null) {
//     state.juzListController = ScrollController(
//       initialScrollOffset: state.surahItemHeight *
//           getJuzByPage(state.currentPageNumber.value).juz,
//     );
//   }
//   return state.juzListController!;
// }

// Color get backgroundColor => state.backgroundPickerColor.value == 0xfffaf7f3
//     ? Get.theme.colorScheme.surfaceContainer
//     : ThemeController.instance.isDarkMode
//         ? Get.theme.colorScheme.surfaceContainer
//         : Color(state.backgroundPickerColor.value);

// String get surahBannerPath {
//   if (themeCtrl.isBlueMode) {
//     return SvgPath.svgSurahBanner1;
//   } else if (themeCtrl.isBrownMode) {
//     return SvgPath.svgSurahBanner2;
//   } else if (themeCtrl.isOldMode) {
//     return SvgPath.svgSurahBanner4;
//   } else {
//     return SvgPath.svgSurahBanner3;
//   }
// }
}

extension SplitBetweenExtension<T> on List<T> {
  List<List<T>> splitBetween(bool Function(T first, T second) condition) {
    if (isEmpty) return []; // إذا كانت القائمة فارغة، إرجاع قائمة فارغة.

    List<List<T>> result = []; // قائمة النتيجة التي ستحتوي على القوائم الفرعية.
    List<T> currentGroup = [first]; // المجموعة الحالية تبدأ بالعنصر الأول.

    for (int i = 1; i < length; i++) {
      if (condition(this[i - 1], this[i])) {
        // إذا تحقق الشرط، أضف المجموعة الحالية إلى النتيجة.
        result.add(currentGroup);
        currentGroup = []; // ابدأ مجموعة جديدة.
      }
      currentGroup.add(this[i]); // أضف العنصر الحالي إلى المجموعة.
    }

    if (currentGroup.isNotEmpty) {
      result.add(currentGroup); // أضف المجموعة الأخيرة.
    }

    return result;
  }
}
