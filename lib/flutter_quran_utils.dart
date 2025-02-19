part of '../../quran.dart';

/// A class that provides utility functions for interacting with the Quran library.
///
/// This class includes methods and properties that facilitate various operations
/// related to the Quran, such as retrieving verses, chapters, and other relevant
/// information.
///
/// Example usage:
///
/// ```dart
/// QuranLibrary quranLibrary = QuranLibrary();
/// // Use quranLibrary to access various Quran-related utilities.
/// ```
///
/// Note: Ensure that you have the necessary dependencies and configurations
/// set up in your Flutter project to use this class effectively.
class QuranLibrary {
  /// [init] تقوم بتهيئة القرآن ويجب استدعاؤها قبل البدء في استخدام الحزمة
  ///
  /// [init] initializes the FlutterQuran,
  /// and must be called before starting using the package
  Future<void> init(
      {Map<int, List<BookmarkModel>>? userBookmarks,
      bool overwriteBookmarks = false}) async {
    // Get.put(QuranController());
    await GetStorage.init();
    QuranCtrl.instance.state.isDownloadedV2Fonts.value =
        GetStorage().read(_StorageConstants().isDownloadedCodeV2Fonts) ?? false;
    QuranRepository().getLastPage();
    await QuranCtrl.instance.loadFontsQuran();
    await QuranCtrl.instance.loadQuran();
    await QuranCtrl.instance.fetchSurahs();
    BookmarksCtrl.instance.initBookmarks(
        userBookmarks: userBookmarks, overwrite: overwriteBookmarks);
    QuranCtrl.instance.state.isBold.value =
        GetStorage().read(_StorageConstants().isBold) ?? 0;
    quranCtrl.state.fontsSelected2.value =
        GetStorage().read(_StorageConstants().fontsSelected) ?? 0;
    // quranCtrl.state.isTajweed.value =
    //     GetStorage().read(StorageConstants().isTajweed) ?? 0;
    quranCtrl.state.fontsDownloadedList.value = (GetStorage()
            .read<List<dynamic>>(_StorageConstants().fontsDownloadedList)
            ?.cast<int>() ??
        []);
  }

  /// A singleton instance of the `QuranCtrl` class.
  ///
  /// This instance is used to access the functionalities provided by the
  /// `QuranCtrl` class throughout the application.
  final quranCtrl = QuranCtrl.instance;

  /// [currentPageNumber] تعيد رقم الصفحة التي يكون المستخدم عليها حاليًا.
  /// أرقام الصفحات تبدأ من 1، لذا فإن الصفحة الأولى من القرآن هي الصفحة رقم 1.
  ///
  /// [currentPageNumber] Returns the page number of the page that the user is currently on.
  /// Page numbers start at 1, so the first page of the Quran is page 1.
  int get currentPageNumber => quranCtrl.lastPage;

  /// [search] يبحث في القرآن عن الآيات من خلال الكلمة أو رقم الصفحة.
  /// يعيد قائمة بجميع الآيات التي تحتوي نصوصها على النص المُعطى.
  ///
  /// [search] searches the Qur’an for verses by word or page number.
  /// Returns a list of all verses whose texts contain the given text.
  List<AyahModel> search(String text) => quranCtrl.search(text);

  /// [search] يبحث في القرآن عن أسماء السور.
  /// يعيد قائمة بجميع السور التي يكون أسمها أو رقمها أو رفم الصفحة الخاصة بها مطابق للنص المُعطى.
  ///
  /// [search] Searches the Qur’an for the names of the surahs.
  /// Returns a list of all surahs whose name, number, or page number matches the given text.
  List<AyahModel> surahSearch(String text) => quranCtrl.searchSurah(text);

  /// [navigateToAyah] يتيح لك التنقل إلى أي آية.
  /// من الأفضل استدعاء هذه الطريقة أثناء عرض شاشة القرآن،
  /// وإذا تم استدعاؤها ولم تكن شاشة القرآن معروضة،
  /// فسيتم بدء العرض من صفحة هذه الآية عند فتح شاشة القرآن في المرة التالية.
  ///
  /// [jumpToAyah] let's you navigate to any ayah..
  /// It's better to call this method while Quran screen is displayed
  /// and if it's called and the Quran screen is not displayed, the next time you
  /// open quran screen it will start from this ayah's page
  void jumpToAyah(int pageNumber, int ayahUQNumber) {
    quranCtrl.jumpToPage(pageNumber - 1);
    quranCtrl.toggleAyahSelection(ayahUQNumber);
    Future.delayed(const Duration(seconds: 3))
        .then((_) => quranCtrl.toggleAyahSelection(ayahUQNumber));
  }

  /// [jumpToPage] يتيح لك التنقل إلى أي صفحة في القرآن باستخدام رقم الصفحة.
  /// ملاحظة: تستقبل هذه الطريقة رقم الصفحة وليس فهرس الصفحة.
  /// من الأفضل استدعاء هذه الطريقة أثناء عرض شاشة القرآن،
  /// وإذا تم استدعاؤها ولم تكن شاشة القرآن معروضة،
  /// فسيتم بدء العرض من هذه الصفحة عند فتح شاشة القرآن في المرة التالية.
  ///
  /// [jumpToPage] let's you navigate to any quran page with page number
  /// Note it receives page number not page index
  /// It's better to call this method while Quran screen is displayed
  /// and if it's called and the Quran screen is not displayed, the next time you
  /// open quran screen it will start from this page
  void jumpToPage(int page) => quranCtrl.jumpToPage(page - 1);

  /// [jumpToJoz] let's you navigate to any quran jozz with jozz number
  /// Note it receives jozz number not jozz index
  void jumpToJoz(int jozz) =>
      jumpToPage(jozz == 1 ? 0 : (quranCtrl.quranStops[(jozz - 1) * 8 - 1]));

  /// [jumpToHizb] يتيح لك التنقل إلى أي جزء في القرآن باستخدام رقم الجزء.
  /// ملاحظة: تستقبل هذه الطريقة رقم الجزء وليس فهرس الجزء.
  ///
  /// [jumpToHizb] let's you navigate to any quran hizb with hizb number
  /// Note it receives hizb number not hizb index
  void jumpToHizb(int hizb) =>
      jumpToPage(hizb == 1 ? 0 : (quranCtrl.quranStops[(hizb - 1) * 4 - 1]));

  /// [jumpToBookmark] يتيح لك التنقل إلى علامة مرجعية معينة.
  /// ملاحظة: يجب أن يكون رقم صفحة العلامة المرجعية بين 1 و604.
  ///
  /// [jumpToBookmark] let's you navigate to a certain bookmark
  /// Note that bookmark page number must be between 1 and 604
  void jumpToBookmark(BookmarkModel bookmark) {
    if (bookmark.page > 0 && bookmark.page <= 604) {
      jumpToPage(bookmark.page);
    } else {
      throw Exception("Page number must be between 1 and 604");
    }
  }

  /// [jumpToSurah] يتيح لك التنقل إلى أي سورة في القرآن باستخدام رقم السورة.
  /// ملاحظة: تستقبل هذه الطريقة رقم السورة وليس فهرس السورة.
  ///
  /// [jumpToSurah] let's you navigate to any quran surah with surah number
  /// Note it receives surah number not surah index
  void jumpToSurah(int surah) =>
      jumpToPage(quranCtrl.surahsStart[surah - 1] + 1);

  /// [allJoz] returns list of all Quran joz' names
  List<String> get allJoz => _QuranConstants.quranHizbs
      .sublist(0, 30)
      .map((jozz) => "الجزء $jozz")
      .toList();

  /// [allHizb] يعيد قائمة بأسماء جميع أجزاء القرآن.
  ///
  /// [allHizb] returns list of all Quran hizbs' names
  List<String> get allHizb =>
      _QuranConstants.quranHizbs.map((jozz) => "الحزب $jozz").toList();

  /// [getAllSurahs] يعيد قائمة بأسماء السور.
  ///
  /// [getAllSurahs] returns list of all Quran surahs' names
  List<String> getAllSurahs({bool isArabic = true}) => quranCtrl.surahs
      .map((surah) =>
          isArabic ? 'سورة ${surah.nameAr}' : 'Surah ${surah.nameEn}')
      .toList();

  /// [getAllSurahsArtPath] يعيد قائمة بمسارات المخطوطات الخاصة بإسماء السور.
  ///
  /// [getAllSurahsArtPath] returns list of all Quran surahs' name artistic manuscript path
  List<String> getAllSurahsArtPath() => List.generate(quranCtrl.surahs.length,
      (i) => 'packages/quran_library/lib/assets/svg/surah_name/00$i.svg');

  /// يعيد قائمة بجميع شارات المرجعية المحفوظة [allBookmarks].
  ///
  /// [allBookmarks] returns list of all bookmarks
  List<BookmarkModel> get allBookmarks {
    final allBookmarks =
        BookmarksCtrl.instance.bookmarks.values.expand((list) => list).toList();
    return allBookmarks.sublist(0, allBookmarks.length - 1);
  }

  /// يعيد قائمة بجميع العلامات المرجعية التي استخدمها وقام بتعيينها المستخدم في صفحات القرآن [usedBookmarks].
  ///
  /// [usedBookmarks] returns list of all bookmarks used and set by the user in quran pages
  List<BookmarkModel> get usedBookmarks =>
      BookmarksCtrl.instance.bookmarks.values
          .expand((list) => list)
          .where((bookmark) => bookmark.page != -1)
          .toList();

  /// للحصول على معلومات السورة في نافذة حوار، قم فقط باستدعاء: [getSurahInfoDialog].
  ///
  /// مطلوب تمرير رقم السورة [surahNumber].
  /// كما أن التمرير الاختياري لنمط [SurahInfoStyle] ممكن.
  ///
  /// to get the Surah information dialog just call [getSurahInfoDialog]
  ///
  /// and required to pass the Surah number [surahNumber]
  /// and style [SurahInfoStyle] is optional.
  void getSurahInfoDialog(
          {required int surahNumber,
          required BuildContext context,
          SurahInfoStyle? surahInfoStyle,
          String? languageCode,
          bool isDark = false}) =>
      surahInfoDialogWidget(context, surahNumber - 1,
          surahStyle: surahInfoStyle,
          languageCode: languageCode,
          isDark: isDark);

  /// [getSurahInfo] تتيح لك الحصول على سورة مع جميع بياناتها.
  /// ملاحظة: تستقبل هذه الطريقة رقم السورة وليس فهرس السورة.
  ///
  /// [getSurahInfo] let's you get a Surah with all its data
  /// Note it receives surah number not surah index
  SurahNamesModel getSurahInfo({required int surahNumber}) =>
      quranCtrl.surahsList[surahNumber];

  /// للحصول على نافذة حوار خاصة بتحميل الخطوط، قم فقط باستدعاء: [getFontsDownloadDialog].
  ///
  /// قم بتمرير رمز اللغة ليتم عرض الأرقام على حسب اللغة،
  /// رمز اللغة الإفتراضي هو: 'ar' [languageCode].
  /// كما أن التمرير الاختياري لنمط [DownloadFontsDialogStyle] ممكن.
  ///
  /// to get the fonts download dialog just call [getFontsDownloadDialog]
  ///
  /// and pass the language code to translate the number if you want,
  /// the default language code is 'ar' [languageCode]
  /// and style [DownloadFontsDialogStyle] is optional.
  Widget getFontsDownloadDialog(
          DownloadFontsDialogStyle? downloadFontsDialogStyle,
          String? languageCode,
          {bool isDark = false}) =>
      FontsDownloadDialog(
        downloadFontsDialogStyle: downloadFontsDialogStyle,
        languageCode: languageCode,
        isDark: isDark,
      );

  /// للحصول على الويدجت الخاصة بتنزيل الخطوط فقط قم بإستدعاء [getFontsDownloadWidget]
  ///
  /// to get the fonts download widget just call [getFontsDownloadWidget]
  Widget getFontsDownloadWidget(BuildContext context,
          {DownloadFontsDialogStyle? downloadFontsDialogStyle,
          String? languageCode,
          bool isDark = false}) =>
      quranCtrl.fontsDownloadWidget(
        context,
        downloadFontsDialogStyle: downloadFontsDialogStyle,
        languageCode: languageCode,
        isDark: isDark,
      );

  /// للحصول على طريقة تنزيل الخطوط فقط قم بإستدعاء [fontsDownloadMethod]
  ///
  /// to get the fonts download method just call [fontsDownloadMethod]
  void getFontsDownloadMethod({required int fontIndex}) =>
      quranCtrl.downloadAllFontsZipFile(fontIndex);

  /// للحصول على طريقة تنزيل الخطوط فقط قم بإستدعاء [getFontsPrepareMethod]
  /// مطلوب تمرير رقم الصفحة [pageIndex]
  ///
  /// to prepare the fonts was downloaded before just call [getFontsPrepareMethod]
  /// required to pass [pageIndex]
  void getFontsPrepareMethod({required int pageIndex}) =>
      quranCtrl.prepareFonts(pageIndex);

  /// لحذف الخطوط فقط قم بإستدعاء [deleteFontsMethod]
  ///
  /// to delete the fonts just call [deleteFontsMethod]
  void getDeleteFontsMethod() => quranCtrl.deleteFonts();

  /// للحصول على تقدم تنزيل الخطوط، ما عليك سوى إستدعاء [fontsDownloadProgress]
  ///
  /// to get fonts download progress just call [fontsDownloadProgress]
  double get fontsDownloadProgress =>
      quranCtrl.state.fontsDownloadProgress.value;

  /// لمعرفة ما إذا كانت الخطوط محملة او لا، ما عليك سوى إستدعاء [isFontsDownloaded]
  ///
  /// To find out whether fonts are downloaded or not, just call [isFontsDownloaded]
  bool get isFontsDownloaded =>
      GetStorage().read(_StorageConstants().isDownloadedCodeV2Fonts) ?? false;

  /// لمعرفة الخط الذي تم تحديده، ما عليك سوى إستدعاء [currentFontsSelected]
  ///
  /// To find out which font has been selected, just call [currentFontsSelected]
  int get currentFontsSelected => quranCtrl.state.fontsSelected2.value;

  /// يقوم بتعيين علامة مرجعية باستخدام [ayahId] و[page] و[bookmarkId] المحددة.
  ///
  /// [ayahId] هو معرّف الآية التي سيتم حفظها.
  /// [page] هو رقم الصفحة التي تحتوي على الآية.
  /// [bookmarkId] هو معرّف العلامة المرجعية التي سيتم حفظها.
  ///
  /// لا يمكن حفظ علامة مرجعية برقم صفحة خارج النطاق من 1 إلى 604.
  /// Sets a bookmark with the given [ayahId], [page] and [bookmarkId].
  ///
  /// [ayahId] is the id of the ayah to be saved.
  /// [page] is the page number of the ayah.
  /// [bookmarkId] is the id of the bookmark to be saved.
  ///
  /// You can't save a bookmark with a page number that is not between 1 and 604.
  void setBookmark(
          {required String surahName,
          required int ayahNumber,
          required int ayahId,
          required int page,
          required int bookmarkId}) =>
      BookmarksCtrl.instance.saveBookmark(
          surahName: surahName,
          ayahNumber: ayahNumber,
          ayahId: ayahId,
          page: page,
          colorCode: bookmarkId);

  /// يزيل علامة مرجعية من قائمة العلامات المرجعية المحفوظة للمستخدم.
  /// [bookmarkId] هو معرّف العلامة المرجعية التي سيتم إزالتها.
  ///
  /// Removes a bookmark from the list of user's saved bookmarks.
  /// [bookmarkId] is the id of the bookmark to be removed.
  void removeBookmark({required int bookmarkId}) =>
      BookmarksCtrl.instance.removeBookmark(bookmarkId);

  /// لمعرفة أسماء السور في اي صفحة فقط قم بإستدعاء [getAllSurahInPageByPageNumber]
  /// وفقط قم بتمرير رقم الصفحة لها.
  ///
  /// To know the names of the surahs on any page, just call [getAllSurahInPageByPageNumber]
  /// And just pass the page number to it.
  List<SurahFontsModel> getAllSurahInPageByPageNumber(
          {required int pageNumber}) =>
      quranCtrl.getSurahsByPage(pageNumber);

  /// لجلب بيانات السورة الحالية عن طريق رقم الصفحة
  /// يمكنك إستخدام [getCurrentSurahDataByPageNumber].
  ///
  /// To fetch the current Surah data by page number,
  /// you can use [getCurrentSurahDataByPageNumber].
  SurahFontsModel getCurrentSurahDataByPageNumber({required int pageNumber}) =>
      quranCtrl.getCurrentSurahByPage(pageNumber);

  /// لجلب بيانات السورة الحالية عن طريق بيانات الآية
  /// يمكنك إستخدام [getCurrentSurahDataByAyah].
  ///
  /// To fetch the current Surah data by Ayah data,
  /// you can use [getCurrentSurahDataByAyah].
  SurahFontsModel getCurrentSurahDataByAyah({required AyahFontsModel ayah}) =>
      quranCtrl.getSurahDataByAyah(ayah);

  /// لجلب بيانات السورة الحالية عن طريق رقم الآية الفريد
  /// يمكنك إستخدام [getCurrentSurahDataByAyahUniqueNumber].
  ///
  /// To fetch the current Surah data by Ayah unique number,
  /// you can use [getCurrentSurahDataByAyahUniqueNumber].
  SurahFontsModel getCurrentSurahDataByAyahUniqueNumber(
          {required int ayahUniqueNumber}) =>
      quranCtrl.getSurahDataByAyahUQ(ayahUniqueNumber);

  /// لجلب رقم الجزء الحالي عن طريق رقم الصفحة
  /// يمكنك إستخدام [getJuzByPageNumber].
  ///
  /// To fetch the current Juz number by page number,
  /// you can use [getJuzByPageNumber].
  AyahFontsModel getJuzByPageNumber({required int pageNumber}) =>
      quranCtrl.getJuzByPage(pageNumber);

  /// لجلب آيات الصفحة عن طريق رقم الصفحة
  /// يمكنك إستخدام [getPageAyahsByPageNumber].
  ///
  /// To fetch the Ayahs in the page by page number,
  /// you can use [getPageAyahsByPageNumber].
  List<AyahFontsModel> getPageAyahsByPageNumber({required int pageNumber}) =>
      quranCtrl.getPageAyahsByIndex(pageNumber);

  /// لجلب آيات الصفحة عن طريق رقم الصفحة
  /// يمكنك إستخدام [getTajweedRules].
  ///
  /// To fetch the Ayahs in the page by page number,
  /// you can use [getTajweedRules].
  // List<TajweedRuleModel> getTajweedRules({required String languageCode}) =>
  //     quranCtrl.getTajweedRules(languageCode: languageCode);

  /// [hafsStyle] هو النمط الافتراضي للقرآن، مما يضمن عرض جميع الأحرف الخاصة بشكل صحيح.
  ///
  /// [hafsStyle] is the default style for Quran so all special characters will be rendered correctly
  final hafsStyle = const TextStyle(
    color: Colors.black,
    fontSize: 23.55,
    fontFamily: "hafs",
    package: "quran_library",
  );

  /// [naskhStyle] هو النمط الافتراضي للنصوص الآخرى.
  ///
  /// [naskhStyle] is the default style for other text.
  final naskhStyle = const TextStyle(
    color: Colors.black,
    fontSize: 23.55,
    fontFamily: "naskh",
    package: "quran_library",
  );

  ///Singleton factory
  static final QuranLibrary _instance = QuranLibrary._internal();

  /// Factory constructor for creating a new instance of [QuranLibrary].
  ///
  /// This constructor is used to create an instance of the [QuranLibrary] class.
  factory QuranLibrary() {
    return _instance;
  }

  QuranLibrary._internal();
}
