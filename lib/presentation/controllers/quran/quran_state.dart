part of '../../../quran.dart';

class QuranState {
  /// -------- [Variables] ----------
  List<SurahFontsModel> surahs = [];
  List<List<AyahFontsModel>> pages = [];
  List<AyahFontsModel> allAyahs = [];

  /// Page Controller
  PageController quranPageController = PageController();

  RxInt currentPageNumber = 1.obs;
  RxInt lastReadSurahNumber = 1.obs;
  var selectedAyahIndexes = <int>[].obs;
  // bool isSelected = false;
  final ScrollController scrollIndicatorController = ScrollController();
  final ScrollController ayahsScrollController = ScrollController();
  RxInt selectedIndicatorIndex = 0.obs;
  // PreferDirection preferDirection = PreferDirection.topCenter;
  RxDouble textWidgetPosition = (-240.0).obs;
  RxBool isPlayExpanded = false.obs;
  RxBool isSajda = false.obs;
  RxInt isPages = 0.obs;
  RxInt isBold = 0.obs;
  RxBool isMoreOptions = false.obs;
  var moreOptionsMap = <String, bool>{}.obs;
  RxInt selectMushafSettingsPage = 0.obs;
  RxDouble ayahsWidgetHeight = 0.0.obs;
  RxInt currentListPage = 1.obs;
  RxDouble scaleFactor = 1.0.obs;
  RxDouble baseScaleFactor = 1.0.obs;
  final box = GetStorage();
  int? lastDisplayedHizbQuarter;
  Map<int, int> pageToHizbQuarterMap = {};

  double surahItemHeight = 90.0;
  ScrollController? surahController;
  ScrollController? juzListController;
  RxBool isPageMode = false.obs;

  RxBool isScrolling = false.obs;
  bool isQuranLoaded = false;
  // RxBool isFontsDownloaded = false.obs;
  RxBool isDownloadingFonts = false.obs;
  RxBool isDownloadedV2Fonts = false.obs;
  RxList<int> fontsDownloadedList = <int>[].obs;
  // RxInt fontsSelected = 0.obs;
  RxInt fontsSelected2 = 0.obs;
  RxDouble fontsDownloadProgress = 0.0.obs;
  RxInt selectedAyahNumber = 0.obs;
  RxInt selectedSurahNumber = 0.obs;
  OverlayEntry? overlayEntry;

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
    fontsSelected2.close();
    fontsDownloadProgress.close();
    selectedAyahNumber.close();
    selectedSurahNumber.close();
    overlayEntry?.remove();
  }
}
