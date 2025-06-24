import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../data/models/quran_fonts_models/ayah_model.dart';
import '../../../data/models/quran_fonts_models/surahs_model.dart';

/// Class that holds the state for the Quran controller.
///
/// This class is responsible for maintaining the state of the Quran,
/// including the current page, selected Ayahs, and various UI settings.
class QuranState {
  /// List of Surahs
  List<SurahFontsModel> surahs = [];
  
  /// List of pages, each containing a list of Ayahs
  List<List<AyahFontsModel>> pages = [];
  
  /// List of all Ayahs
  List<AyahFontsModel> allAyahs = [];

  /// Page controller for Quran pages
  final PageController quranPageController = PageController();

  /// Current page number
  final RxInt currentPageNumber = 1.obs;
  
  /// Last read Surah number
  final RxInt lastReadSurahNumber = 1.obs;
  
  /// Selected Ayah indexes
  final RxList<int> selectedAyahIndexes = <int>[].obs;
  
  /// Flag for selection state
  bool isSelected = false;
  
  /// Scroll controller for the indicator
  final ScrollController scrollIndicatorController = ScrollController();
  
  /// Scroll controller for Ayahs
  final ScrollController ayahsScrollController = ScrollController();
  
  /// Selected indicator index
  final RxInt selectedIndicatorIndex = 0.obs;
  
  /// Text widget position
  final RxDouble textWidgetPosition = (-240.0).obs;
  
  /// Flag for play expanded state
  final RxBool isPlayExpanded = false.obs;
  
  /// Flag for Sajda state
  final RxBool isSajda = false.obs;
  
  /// Pages mode
  final RxInt isPages = 0.obs;
  
  /// Bold text mode
  final RxInt isBold = 0.obs;
  
  /// Flag for more options state
  final RxBool isMoreOptions = false.obs;
  
  /// Map for more options
  final RxMap<String, bool> moreOptionsMap = <String, bool>{}.obs;
  
  /// Selected Mushaf settings page
  final RxInt selectMushafSettingsPage = 0.obs;
  
  /// Ayahs widget height
  final RxDouble ayahsWidgetHeight = 0.0.obs;
  
  /// Current list page
  final RxInt currentListPage = 1.obs;
  
  /// Scale factor for text
  final RxDouble scaleFactor = 1.0.obs;
  
  /// Base scale factor for text
  final RxDouble baseScaleFactor = 1.0.obs;
  
  /// GetStorage instance
  final box = GetStorage();
  
  /// Last displayed Hizb quarter
  int? lastDisplayedHizbQuarter;
  
  /// Map from page to Hizb quarter
  final Map<int, int> pageToHizbQuarterMap = {};

  /// Height of Surah item
  double surahItemHeight = 90.0;
  
  /// Scroll controller for Surah list
  ScrollController? surahController;
  
  /// Scroll controller for Juz list
  ScrollController? juzListController;
  
  /// Flag for page mode
  final RxBool isPageMode = false.obs;

  /// Flag for scrolling state
  final RxBool isScrolling = false.obs;
  
  /// Flag for Quran loaded state
  bool isQuranLoaded = false;
  
  /// Flag for downloading fonts state
  final RxBool isDownloadingFonts = false.obs;
  
  /// Flag for downloaded V2 fonts state
  final RxBool isDownloadedV2Fonts = false.obs;
  
  /// List of downloaded fonts
  final RxList<int> fontsDownloadedList = <int>[].obs;
  
  /// Selected font
  final RxInt fontsSelected = 0.obs;
  
  /// Fonts download progress
  final RxDouble fontsDownloadProgress = 0.0.obs;
  
  /// Selected Ayah number
  final RxInt selectedAyahNumber = 0.obs;
  
  /// Selected Surah number
  final RxInt selectedSurahNumber = 0.obs;
  
  /// Overlay entry
  OverlayEntry? overlayEntry;

  /// Disposes all controllers and closes all reactive variables
  void dispose() {
    quranPageController.dispose();
    scrollIndicatorController.dispose();
    ayahsScrollController.dispose();
    surahController?.dispose();
    juzListController?.dispose();
    
    currentPageNumber.close();
    lastReadSurahNumber.close();
    selectedAyahIndexes.close();
    selectedIndicatorIndex.close();
    textWidgetPosition.close();
    isPlayExpanded.close();
    isSajda.close();
    isPages.close();
    isBold.close();
    isMoreOptions.close();
    moreOptionsMap.close();
    selectMushafSettingsPage.close();
    ayahsWidgetHeight.close();
    currentListPage.close();
    scaleFactor.close();
    baseScaleFactor.close();
    isPageMode.close();
    isScrolling.close();
    isDownloadingFonts.close();
    isDownloadedV2Fonts.close();
    fontsDownloadedList.close();
    fontsSelected.close();
    fontsDownloadProgress.close();
    selectedAyahNumber.close();
    selectedSurahNumber.close();
    
    overlayEntry?.remove();
  }
}