import 'dart:math' as math;

import 'package:get/get.dart';

import '../../../core/extensions/split_between_extension.dart';
import '../../../data/models/quran_fonts_models/ayah_model.dart';
import '../../../data/models/quran_fonts_models/surahs_model.dart';
import 'quran_controller.dart';

/// Extensions on [QuranController] that provides getters
/// for [QuranController]'s properties.
extension QuranGetters on QuranController {
  /// -------- [Getter] ----------

  // List<int> get _startSurahsNumbers => [
  //       1,
  //       2,
  //       3,
  //       4,
  //       6,
  //       7,
  //       8,
  //       9,
  //       10,
  //       13,
  //       15,
  //       17,
  //       19,
  //       21,
  //       22,
  //       23,
  //       24,
  //       26,
  //       27,
  //       31,
  //       32,
  //       33,
  //       34,
  //       37,
  //       38,
  //       41,
  //       42,
  //       44,
  //       45,
  //       47,
  //       48,
  //       50,
  //       53,
  //       58,
  //       60,
  //       62,
  //       64,
  //       65,
  //       66,
  //       67,
  //       72,
  //       73,
  //       78,
  //       80,
  //       82,
  //       86,
  //       103,
  //       106,
  //       109,
  //       112,
  //     ];

  // List<int> get _downThePageIndex => [
  //       75,
  //       206,
  //       330,
  //       340,
  //       348,
  //       365,
  //       375,
  //       413,
  //       416,
  //       444,
  //       451,
  //       497,
  //       505,
  //       524,
  //       547,
  //       554,
  //       556,
  //       583
  //     ];

  // List<int> get _topOfThePageIndex => [
  //       76,
  //       207,
  //       331,
  //       341,
  //       349,
  //       366,
  //       376,
  //       414,
  //       417,
  //       435,
  //       445,
  //       452,
  //       498,
  //       506,
  //       525,
  //       548,
  //       554,
  //       555,
  //       557,
  //       583,
  //       584
  //     ];

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
      int pageIndex) {
    final pageAyahs = List<AyahFontsModel>.from(state.pages[pageIndex]);
    return pageAyahs
        .splitBetween((f, s) => f.ayahNumber > s.ayahNumber)
        .map((list) => List<AyahFontsModel>.from(list))
        .toList();
  }

  /// Retrieves a list of AyahFontsModel for a specific page index.
  ///
  /// Parameters:
  ///   pageIndex (int): The index of the page for which to retrieve the Ayahs.
  ///
  /// Returns:
  ///   `List<AyahFontsModel>`: A list of AyahFontsModel representing the Ayahs
  ///   on the specified page.
  List<AyahFontsModel> getPageAyahsByIndex(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= state.pages.length) {
      return [];
    }
    return List<AyahFontsModel>.from(state.pages[pageIndex]);
  }

  /// Retrieves the Ayah data for a given unique Ayah number.
  ///
  /// This method returns the AyahFontsModel representing the Ayah with the
  /// specified unique number.
  ///
  /// Parameters:
  ///   ayahUQNumber (int): The unique number of the Ayah to retrieve.
  ///
  /// Returns:
  ///   `AyahFontsModel`: The AyahFontsModel representing the Ayah with the
  ///   given unique number. If no Ayah is found, an empty AyahFontsModel is returned.
  AyahFontsModel getAyahDataByAyahUQNumber(int ayahUQNumber) {
    final ayah =
        state.allAyahs.firstWhereOrNull((a) => a.ayahUQNumber == ayahUQNumber);
    if (ayah == null) return AyahFontsModel.empty();

    return AyahFontsModel(
        ayahUQNumber: ayah.ayahUQNumber,
        ayahNumber: ayah.ayahNumber,
        text: ayah.text,
        ayaTextEmlaey: ayah.ayaTextEmlaey,
        codeV2: ayah.codeV2,
        juz: ayah.juz,
        page: ayah.page,
        hizb: ayah.hizb,
        sajda: ayah.sajda);
  }

  /// will return the surah number of the first ayahs..
  /// even if the page contains another surah.
  int getSurahNumberFromPage(int pageNumber) {
    final pageAyahs = getPageAyahsByIndex(pageNumber);
    if (pageAyahs.isEmpty) return 1;

    final firstAyah = pageAyahs.first;
    final surah = getSurahDataByAyah(firstAyah);
    return surah.surahNumber;
  }

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
      final originalSurah = state.surahs.firstWhere(
          (s) => s.ayahs.any((a) => a.ayahUQNumber == ayah.ayahUQNumber),
          orElse: () => state.surahs.first);

      // Create a new SurahFontsModel to avoid type conflicts
      SurahFontsModel surah = SurahFontsModel(
          surahNumber: originalSurah.surahNumber,
          arabicName: originalSurah.arabicName,
          englishName: originalSurah.englishName,
          revelationType: originalSurah.revelationType,
          ayahs: []);

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
  SurahFontsModel getCurrentSurahByPage(int pageNumber) {
    final firstAyah = getPageAyahsByIndex(pageNumber).first;
    final originalSurah = state.surahs.firstWhere(
        (s) => s.ayahs.any((a) => a.ayahUQNumber == firstAyah.ayahUQNumber));

    return SurahFontsModel(
        surahNumber: originalSurah.surahNumber,
        arabicName: originalSurah.arabicName,
        englishName: originalSurah.englishName,
        revelationType: originalSurah.revelationType,
        ayahs: []);
  }

  /// Retrieves the Surah data for a given Ayah.
  ///
  /// This method returns the SurahFontsModel of the Surah that contains the given Ayah.
  ///
  /// Parameters:
  ///   ayah (AyahFontsModel): The Ayah for which to retrieve the Surah data.
  ///
  /// Returns:
  ///   `SurahFontsModel`: The SurahFontsModel representing the Surah of the given Ayah.
  SurahFontsModel getSurahDataByAyah(AyahFontsModel ayah) {
    final originalSurah = state.surahs.firstWhere(
        (s) => s.ayahs.any((a) => a.ayahUQNumber == ayah.ayahUQNumber));

    return SurahFontsModel(
        surahNumber: originalSurah.surahNumber,
        arabicName: originalSurah.arabicName,
        englishName: originalSurah.englishName,
        revelationType: originalSurah.revelationType,
        ayahs: []);
  }

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
  SurahFontsModel getSurahDataByAyahUQ(int ayah) {
    final originalSurah = state.surahs
        .firstWhere((s) => s.ayahs.any((a) => a.ayahUQNumber == ayah));

    return SurahFontsModel(
        surahNumber: originalSurah.surahNumber,
        arabicName: originalSurah.arabicName,
        englishName: originalSurah.englishName,
        revelationType: originalSurah.revelationType,
        ayahs: []);
  }

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
    final pageAyahs = getPageAyahsByIndex(page - 1);
    if (pageAyahs.isEmpty) return AyahFontsModel.empty();

    final firstAyah = pageAyahs.first;
    return AyahFontsModel(
        ayahUQNumber: firstAyah.ayahUQNumber,
        ayahNumber: firstAyah.ayahNumber,
        text: firstAyah.text,
        ayaTextEmlaey: firstAyah.ayaTextEmlaey,
        codeV2: firstAyah.codeV2,
        juz: firstAyah.juz,
        page: firstAyah.page,
        hizb: firstAyah.hizb,
        sajda: firstAyah.sajda);
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
    final pageAyahs = getPageAyahsByIndex(pageNumber - 1);
    if (pageAyahs.isEmpty) return "";

    // Find the highest Hizb quarter on the current page
    int? currentMaxHizbQuarter =
        pageAyahs.map((ayah) => ayah.hizb).reduce(math.max);

    // Store/update the highest Hizb quarter for this page
    state.pageToHizbQuarterMap[pageNumber] = currentMaxHizbQuarter;

    // Check if this is a new Hizb quarter compared to the previous page
    bool isNewHizbQuarter = true;
    if (pageNumber > 1) {
      int? previousPageHizbQuarter = state.pageToHizbQuarterMap[pageNumber - 1];
      isNewHizbQuarter = previousPageHizbQuarter != currentMaxHizbQuarter;
    }

    // Format the display string
    if (isNewHizbQuarter) {
      int hizbNumber = ((currentMaxHizbQuarter - 1) ~/ 4) + 1;
      int quarterNumber = ((currentMaxHizbQuarter - 1) % 4) + 1;
      return "حزب $hizbNumber - $quarterNumber/4";
    } else {
      return "";
    }
  }
}
