part of '../../../quran.dart';

extension QuranGetters on QuranCtrl {
  /// -------- [Getter] ----------

  List<int> get startSurahsNumbers => [
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

  List<int> get downThePageIndex => [
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

  List<int> get topOfThePageIndex => [
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

  List<List<AyahFontsModel>> getCurrentPageAyahsSeparatedForBasmalah(
          int pageIndex) =>
      state.pages[pageIndex]
          .splitBetween((f, s) => f.ayahNumber > s.ayahNumber)
          .toList();

  List<AyahFontsModel> getPageAyahsByIndex(int pageIndex) =>
      state.pages[pageIndex];

  /// will return the surah number of the first ayahs..
  /// even if the page contains another surah..
  /// if you wanna get the last's ayah's surah information
  /// you can use [ayahs.last].
  int getSurahNumberFromPage(int pageNumber) => state.surahs
      .firstWhere(
          (s) => s.ayahs.firstWhereOrNull((a) => a.page == pageNumber) != null)
      .surahNumber;

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

  SurahFontsModel getCurrentSurahByPage(int pageNumber) =>
      state.surahs.firstWhere(
          (s) => s.ayahs.contains(getPageAyahsByIndex(pageNumber).first));

  SurahFontsModel getSurahDataByAyah(AyahFontsModel ayah) =>
      state.surahs.firstWhere((s) => s.ayahs.contains(ayah));

  SurahFontsModel getSurahDataByAyahUQ(int ayah) => state.surahs
      .firstWhere((s) => s.ayahs.any((a) => a.ayahUQNumber == ayah));

  AyahFontsModel getJuzByPage(int page) {
    return state.allAyahs.firstWhere(
      (a) => a.page == page + 1,
      orElse: () => AyahFontsModel.empty(),
    );
  }

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

  List<AyahFontsModel> get currentPageAyahs =>
      state.pages[state.currentPageNumber.value - 1];

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

  RxBool getCurrentSurahNumber(int surahNum) =>
      getCurrentSurahByPage(state.currentPageNumber.value).surahNumber - 1 ==
              surahNum
          ? true.obs
          : false.obs;

  RxBool getCurrentJuzNumber(int juzNum) =>
      getJuzByPage(state.currentPageNumber.value).juz - 1 == juzNum
          ? true.obs
          : false.obs;

  RxBool get isDownloadFonts =>
      (state.fontsSelected2.value == 1) ? true.obs : false.obs;

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
