part of '../../../quran.dart';

/// Extensions on [QuranCtrl] that provides getters
/// for [QuranCtrl]'s properties.
extension QuranGetters on QuranCtrl {
  /// -------- [Getter] ----------

  RxBool get isDownloadedFonts =>
      QuranCtrl.instance.state.fontsSelected.value == 1 ? true.obs : false.obs;

  /// تبديل نوع الخط وتحميله إذا لم يكن محملاً من قبل
  ///
  /// Switch font type and download it if not already downloaded
  Future<void> switchFontType({required int fontIndex}) async {
    // إعادة التحقق من حالة التحميل من التخزين
    // Re-check download status from storage
    final storageValue =
        GetStorage().read<bool>(_StorageConstants().isDownloadedCodeV2Fonts);
    state.isDownloadedV2Fonts.value = storageValue ?? false;

    // التحقق مما إذا كان الخط المطلوب هو نفس الخط الحالي
    // Check if the requested font is the same as the current font
    if (state.fontsSelected.value == fontIndex &&
        (fontIndex == 0 || state.isDownloadedV2Fonts.value)) {
      log('Font is already selected', name: 'QuranGetters');
      return;
    }

    // إذا كان الخط هو الخط الافتراضي (0)، فقط قم بتعيينه
    // If the font is the default font (0), just set it
    if (fontIndex == 0) {
      state.fontsSelected.value = fontIndex;
      GetStorage().write(_StorageConstants().fontsSelected, fontIndex);
      Get.forceAppUpdate();
      log('Default font selected', name: 'QuranGetters');
      return;
    }

    // إذا كان الخط محملاً بالفعل، قم بتعيينه
    // If the font is already downloaded, just set it
    if (state.isDownloadedV2Fonts.value) {
      state.fontsSelected.value = fontIndex;
      GetStorage().write(_StorageConstants().fontsSelected, fontIndex);
      update(['fontsSelected']);
      Get.forceAppUpdate();
      log('Downloaded font selected', name: 'QuranGetters');
      return;
    }

    // إذا كان الخط غير محمل، قم بتحميله أولاً ثم تعيينه
    // If the font is not downloaded, download it first then set it
    try {
      log('Starting font download', name: 'QuranGetters');
      state.isDownloadingFonts.value = true;
      // تهيئة قيمة تقدم التحميل
      // Initialize download progress value
      state.fontsDownloadProgress.value = 0.0;
      update(['fontsDownloadingProgress']);

      await downloadAllFontsZipFile(fontIndex);

      state.fontsSelected.value = fontIndex;
      GetStorage().write(_StorageConstants().fontsSelected, fontIndex);
      update(['fontsSelected', 'fontsDownloadingProgress']);
      Get.forceAppUpdate();
      log('Font downloaded and selected', name: 'QuranGetters');
    } catch (e) {
      state.isDownloadingFonts.value = false;
      update(['fontsDownloadingProgress']);
      log('Error downloading font: $e', name: 'QuranGetters');
    }
  }

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

  /// Returns a list of lists of AyahModel, where each sublist contains Ayahs
  /// that are separated by a Basmalah, for the given page index.
  ///
  /// Parameters:
  ///   pageIndex (int): The index of the page for which to retrieve the Ayahs.
  ///
  /// Returns:
  ///   `List<List<AyahModel>>`: A list of lists of AyahModel, where each
  ///   sublist contains Ayahs separated by a Basmalah.
  List<List<AyahModel>> getCurrentPageAyahsSeparatedForBasmalah(
          int pageIndex) =>
      state.pages[pageIndex]
          .splitBetween((f, s) => f.ayahNumber > s.ayahNumber)
          .toList();

  /// Retrieves a list of AyahModel for a specific page index.
  ///
  /// Parameters:
  ///   pageIndex (int): The index of the page for which to retrieve the Ayahs.
  ///
  /// Returns:
  ///   `List<AyahModel>`: A list of AyahModel representing the Ayahs on the specified page.
  List<AyahModel> getPageAyahsByIndex(int pageIndex) => state.pages[pageIndex];

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
  ///   `List<SurahModel>`: A list of SurahModel representing the Surahs on the specified page.
  List<SurahModel> getSurahsByPage(int pageNumber) {
    if (getPageAyahsByIndex(pageNumber).isEmpty) return [];
    List<AyahModel> pageAyahs = getPageAyahsByIndex(pageNumber);
    List<SurahModel> surahsOnPage = [];
    for (AyahModel ayah in pageAyahs) {
      SurahModel surah = state.surahs.firstWhere((s) => s.ayahs.contains(ayah),
          orElse: () => SurahModel(
                surahNumber: 1,
                arabicName: 'Unknown',
                englishName: 'Unknown',
                revelationType: 'Unknown',
                ayahs: [],
                isDownloadedFonts: false,
              ));
      if (!surahsOnPage.any((s) => s.surahNumber == surah.surahNumber) &&
          surah.surahNumber != -1) {
        surahsOnPage.add(surah);
      }
    }
    return surahsOnPage;
  }

  /// Retrieves the current Surah data for a given page number.
  ///
  /// This method returns the SurahModel of the first Ayah on the specified page.
  /// It uses the Ayah data on the page to determine which Surah the page belongs to.
  ///
  /// Parameters:
  ///   pageNumber (int): The number of the page for which to retrieve the Surah.
  ///
  /// Returns:
  ///   `SurahModel`: The SurahModel representing the Surah of the first Ayah on the specified page.
  SurahModel getCurrentSurahByPage(int pageNumber) => state.surahs.firstWhere(
      (s) => s.ayahs.contains(getPageAyahsByIndex(pageNumber).first));

  /// Retrieves the Surah data for a given Ayah.
  ///
  /// This method returns the SurahModel of the Surah that contains the given Ayah.
  ///
  /// Parameters:
  ///   ayah (AyahModel): The Ayah for which to retrieve the Surah data.
  ///
  /// Returns:
  ///   `SurahModel`: The SurahModel representing the Surah of the given Ayah.
  SurahModel getSurahDataByAyah(AyahModel ayah) =>
      state.surahs.firstWhere((s) => s.ayahs.contains(ayah));

  /// Retrieves the Surah data for a given unique Ayah number.
  ///
  /// This method returns the SurahModel of the Surah that contains
  /// the Ayah with the specified unique number.
  ///
  /// Parameters:
  ///   ayah (int): The unique number of the Ayah for which to retrieve
  ///   the Surah data.
  ///
  /// Returns:
  ///   `SurahModel`: The SurahModel representing the Surah containing
  ///   the Ayah with the given unique number.
  SurahModel getSurahDataByAyahUQ(int ayah) => state.surahs
      .firstWhere((s) => s.ayahs.any((a) => a.ayahUQNumber == ayah));

  /// Retrieves the Juz data for a given page number.
  ///
  /// This method returns the AyahModel of the Juz that contains the
  /// first Ayah on the specified page.
  ///
  /// Parameters:
  ///   page (int): The page number for which to retrieve the Juz data.
  ///
  /// Returns:
  ///   `AyahModel`: The AyahModel representing the Juz of the first
  ///   Ayah on the specified page. If no Ayah is found, an empty AyahModel
  ///   is returned.
  AyahModel getJuzByPage(int page) {
    return state.allAyahs.firstWhere(
      (a) => a.page == page + 1,
      orElse: () => AyahModel.empty(),
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
    final List<AyahModel> currentPageAyahs =
        state.allAyahs.where((ayah) => ayah.page == pageNumber).toList();
    if (currentPageAyahs.isEmpty) return "";

    // Find the highest Hizb quarter on the current page
    int? currentMaxHizbQuarter =
        currentPageAyahs.map((ayah) => ayah.hizb!).reduce(math.max);

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
  /// This function iterates through a list of AyahModel representing Ayahs on a page,
  /// checking if any Ayah contains a Sajda. If a Sajda is found, and it is either recommended or obligatory,
  /// the function updates the application state to indicate the presence of a Sajda on the page.
  ///
  /// Parameters:
  ///   pageAyahs (`List<AyahModel>`): The list of Ayahs to check for Sajda.
  ///
  /// Returns:
  ///   `bool`: A boolean value indicating whether a Sajda is present on the page.
  bool getSajdaInfoForPage(List<AyahModel> pageAyahs) {
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
  ///   `List<AyahModel>`: The list of Ayahs on the current page.
  List<AyahModel> get currentPageAyahs =>
      state.pages[state.currentPageNumber.value - 1];

  /// Retrieves the Ayah with a Sajda (prostration) on the given page.
  ///
  /// This method returns the AyahModel of the first Ayah on the given page
  /// that contains a Sajda. If no Sajda is found on the page, the method returns null.
  ///
  /// Parameters:
  ///   pageIndex (int): The index of the page for which to retrieve the Ayah with a Sajda.
  ///
  /// Returns:
  ///   `AyahModel?`: The AyahModel of the first Ayah on the given page that contains a Sajda, or null if no Sajda is found.
  AyahModel? getAyahWithSajdaInPage(int pageIndex) =>
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
  bool get isDownloadFonts => (state.fontsSelected.value == 1);

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
