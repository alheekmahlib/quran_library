part of '/quran.dart';

class QuranState {
  /// -------- [Variables] ----------
  List<SurahModel> surahs = [];
  List<List<AyahModel>> pages = [];
  List<AyahModel> allAyahs = [];

  RxInt currentPageNumber = 1.obs;
  RxBool isPlayExpanded = false.obs;
  // RxBool isSajda => false.obs;
  RxInt isBold = 0.obs;
  RxDouble scaleFactor = 1.0.obs;
  RxDouble baseScaleFactor = 1.0.obs;
  Map<int, int> pageToHizbQuarterMap = {};

  double surahItemHeight = 90.0;

  bool isQuranLoaded = false;
  RxBool isDownloadingFonts = false.obs;
  RxBool isDownloadedV2Fonts = false.obs;
  RxList<int> fontsDownloadedList = <int>[].obs;
  RxInt fontsSelected = 0.obs;
  RxDouble fontsDownloadProgress = 0.0.obs;
  RxBool isPreparingDownload = false.obs;
  OverlayEntry? overlayEntry;

  // ملاحظة: تم إزالة GlobalKey<ScaffoldState> لتجنب التعارض مع التطبيقات الأخرى
  // Note: GlobalKey<ScaffoldState> has been removed to avoid conflicts with other applications

  void dispose() {
    currentPageNumber.close();
    isPlayExpanded.close();
    isBold.close();
    scaleFactor.close();
    baseScaleFactor.close();
    isDownloadingFonts.close();
    isDownloadedV2Fonts.close();
    fontsDownloadedList.close();
    fontsSelected.close();
    fontsDownloadProgress.close();
    isPreparingDownload.close();
    overlayEntry?.remove();
  }
}
