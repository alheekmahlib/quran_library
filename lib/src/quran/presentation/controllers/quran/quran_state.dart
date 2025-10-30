part of '/quran.dart';

class QuranState {
  /// -------- [Variables] ----------
  List<SurahModel> surahs = [];
  List<List<AyahModel>> pages = [];
  List<AyahModel> allAyahs = [];

  RxInt currentPageNumber = 1.obs;
  RxBool isPlayExpanded = false.obs;
  // RxBool isSajda => false.obs;
  RxBool isBold = false.obs;
  RxDouble scaleFactor = 1.0.obs;
  RxDouble baseScaleFactor = 1.0.obs;
  Map<int, int> pageToHizbQuarterMap = {};

  double surahItemHeight = 90.0;

  bool isQuranLoaded = false;
  RxBool isDownloadingFonts = false.obs;
  RxBool isFontDownloaded = false.obs;
  RxList<int> fontsDownloadedList = <int>[].obs;
  RxInt fontsSelected = 0.obs;
  RxDouble fontsDownloadProgress = 0.0.obs;
  RxBool isPreparingDownload = false.obs;
  OverlayEntry? overlayEntry;

  // صفحات الخطوط التي تم تحميلها لتجنب إعادة التحميل
  // Loaded fonts pages cache to avoid reloading
  final Set<int> loadedFontPages = <int>{};

  // حارس لتحضير الخط للصفحة الأولى مرة واحدة
  // Guard to prepare initial page fonts once
  bool didPrepareInitialFonts = false;

  final FocusNode quranPageRLFocusNode = FocusNode();

  // ملاحظة: تم إزالة GlobalKey<ScaffoldState> لتجنب التعارض مع التطبيقات الأخرى
  // Note: GlobalKey<ScaffoldState> has been removed to avoid conflicts with other applications

  void dispose() {
    currentPageNumber.close();
    isPlayExpanded.close();
    isBold.close();
    scaleFactor.close();
    baseScaleFactor.close();
    isDownloadingFonts.close();
    isFontDownloaded.close();
    fontsDownloadedList.close();
    fontsSelected.close();
    fontsDownloadProgress.close();
    isPreparingDownload.close();
    overlayEntry?.remove();
  }
}
