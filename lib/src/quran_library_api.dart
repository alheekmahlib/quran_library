import 'package:get_storage/get_storage.dart';

import 'core/utils/storage_constants.dart';
import 'data/models/quran_fonts_models/ayah_model.dart';
import 'data/models/styles_models/bookmark.dart';
import 'domain/services/quran_service.dart';
import 'presentation/controllers/bookmark/bookmarks_controller.dart';
import 'presentation/controllers/quran/quran_controller.dart';

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
/// await quranLibrary.init();
/// // Use quranLibrary to access various Quran-related utilities.
/// ```
///
/// Note: Ensure that you have the necessary dependencies and configurations
/// set up in your Flutter project to use this class effectively.
class QuranLibrary {
  /// Private constructor for singleton pattern
  QuranLibrary._();

  /// Singleton instance
  static final QuranLibrary _instance = QuranLibrary._();

  /// Factory constructor to return the singleton instance
  factory QuranLibrary() => _instance;

  /// The QuranService instance for data operations
  late final QuranService _quranService;

  /// [init] تقوم بتهيئة القرآن ويجب استدعاؤها قبل البدء في استخدام الحزمة
  ///
  /// [init] initializes the FlutterQuran,
  /// and must be called before starting using the package
  Future<void> init({
    Map<int, List<dynamic>>? userBookmarks,
    bool overwriteBookmarks = false,
  }) async {
    await GetStorage.init();

    // Initialize services
    _quranService = QuranService();
    await _quranService.initialize();

    // Initialize controllers
    final quranController = QuranController.instance;
    await quranController.loadFontsQuran();
    await quranController.loadQuran();
    await quranController.fetchSurahs();

    // Initialize bookmarks
    if (userBookmarks != null) {
      Map<int, List<BookmarkModel>> convertedBookmarks = {};
      userBookmarks.forEach((key, value) {
        convertedBookmarks[key] = value
            .map((item) =>
                BookmarkModel.fromJson(item is Map ? item : item.toJson()))
            .toList();
      });
      BookmarksController.instance.initBookmarks(
        userBookmarks: convertedBookmarks,
        overwrite: overwriteBookmarks,
      );
    } else {
      BookmarksController.instance.initBookmarks(
        overwrite: overwriteBookmarks,
      );
    }

    // Load saved preferences
    final storage = GetStorage();
    final storageConstants = StorageConstants();

    quranController.state.isBold.value =
        storage.read(storageConstants.isBold) ?? 0;
    quranController.state.fontsSelected.value =
        storage.read(storageConstants.fontsSelected) ?? 0;
    quranController.state.isDownloadedV2Fonts.value =
        storage.read(storageConstants.isDownloadedCodeV2Fonts) ?? false;
  }

  /// A getter for the QuranController instance.
  QuranController get quranController => QuranController.instance;

  /// [currentPageNumber] تعيد رقم الصفحة التي يكون المستخدم عليها حاليًا.
  /// أرقام الصفحات تبدأ من 1، لذا فإن الصفحة الأولى من القرآن هي الصفحة رقم 1.
  ///
  /// [currentPageNumber] Returns the page number of the page that the user is currently on.
  /// Page numbers start at 1, so the first page of the Quran is page 1.
  int get currentPageNumber => quranController.lastPage;

  /// [search] يبحث في القرآن عن النص المُعطى.
  /// يعيد قائمة بجميع الآيات التي تحتوي على النص المُعطى.
  ///
  /// [search] searches the Qur'an for the given text.
  /// Returns a list of all verses that contain the given text.
  ///
  /// This method searches for Ayahs that contain the given query string in their text.
  /// It returns a list of AyahFontsModel representing the matching Ayahs.
  ///
  /// Parameters:
  ///   query (String): The string to search for in the Ayahs' text.
  ///
  /// Returns:
  ///   `List<AyahFontsModel>`: A list of AyahFontsModel representing the Ayahs
  ///   that contain the given query string in their text.
  List<AyahFontsModel> search(String query) {
    final results = quranController.state.allAyahs
        .where((ayah) => ayah.text.contains(query))
        .toList();

    // Convert to the correct AyahFontsModel type
    return results
        .map((ayah) => AyahFontsModel(
            ayahUQNumber: ayah.ayahUQNumber,
            ayahNumber: ayah.ayahNumber,
            text: ayah.text,
            ayaTextEmlaey: ayah.ayaTextEmlaey,
            codeV2: ayah.codeV2,
            juz: ayah.juz,
            page: ayah.page,
            hizb: ayah.hizb,
            sajda: ayah.sajda))
        .toList();
  }

  /// [search] يبحث في القرآن عن أسماء السور.
  /// يعيد قائمة بجميع السور التي تحتوي أسماؤها على النص المُعطى.
  ///
  /// [search] searches the Qur'an for surah names.
  /// Returns a list of all surahs whose names contain the given text.
  List<AyahFontsModel> surahSearch(String text) {
    final results = quranController.surahSearch(text);

    // Convert to the correct AyahFontsModel type
    return results
        .map((ayah) => AyahFontsModel(
            ayahUQNumber: ayah.ayahUQNumber,
            ayahNumber: ayah.ayahNumber,
            text: ayah.text,
            ayaTextEmlaey: ayah.ayaTextEmlaey,
            codeV2: ayah.codeV2,
            juz: ayah.juz,
            page: ayah.page,
            hizb: ayah.hizb,
            sajda: ayah.sajda))
        .toList();
  }

  /// [jumpToAyah] يتيح لك التنقل إلى أي آية.
  /// من الأفضل استدعاء هذه الطريقة أثناء عرض شاشة القرآن،
  /// وإذا تم استدعاؤها ولم تكن شاشة القرآن معروضة،
  /// فسيتم بدء العرض من صفحة هذه الآية عند فتح شاشة القرآن في المرة التالية.
  ///
  /// [jumpToAyah] let's you navigate to any ayah..
  /// It's better to call this method while Quran screen is displayed
  /// and if it's called and the Quran screen is not displayed, the next time you
  /// open quran screen it will start from this ayah's page
  void jumpToAyah(int pageNumber, int ayahUQNumber) {
    quranController.jumpToPage(pageNumber - 1);
    quranController.toggleAyahSelection(ayahUQNumber);
    Future.delayed(const Duration(seconds: 3))
        .then((_) => quranController.toggleAyahSelection(ayahUQNumber));
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
  void jumpToPage(int pageNumber) {
    quranController.jumpToPage(pageNumber - 1);
  }
}
