part of '../../../quran.dart';

class BookmarksCtrl extends GetxController {
  static BookmarksCtrl get instance =>
      GetInstance().putOrFind(() => BookmarksCtrl());

  BookmarksCtrl({QuranRepository? quranRepository})
      : _quranRepository = quranRepository ?? QuranRepository(),
        super();

  final QuranRepository _quranRepository;

  final Map<int, List<BookmarkModel>> bookmarks = {};

  get bookmarksAyahs => bookmarks.values
      .expand((list) => list)
      .map((bookmark) => bookmark.ayahId)
      .toList();

  final BookmarkModel searchBookmark =
      BookmarkModel(id: 3, colorCode: 0xFFF7EFE0, name: 'search Bookmark');

  // final List<BookmarkModel> _defaultBookmarks = [
  //   BookmarkModel(id: 0, colorCode: 0xAAFFD354, name: 'العلامة الصفراء'),
  //   BookmarkModel(id: 1, colorCode: 0xAAF36077, name: 'العلامة الحمراء'),
  //   BookmarkModel(id: 2, colorCode: 0xAA00CD00, name: 'العلامة الخضراء'),
  // ];

  void initBookmarks(
      {Map<int, List<BookmarkModel>>? userBookmarks, bool overwrite = false}) {
    if (overwrite) {
      bookmarks.clear();
      if (userBookmarks != null) {
        bookmarks.addAll(userBookmarks);
      }
    } else {
      final savedBookmarks = _quranRepository.getBookmarks();
      if (savedBookmarks.isEmpty) {
        // إذا لم توجد إشارات محفوظة، يمكن تحميل افتراضية
        bookmarks[0xAAFFD354] = []; // اللون الأصفر
        bookmarks[0xAAF36077] = []; // اللون الأحمر
        bookmarks[0xAA00CD00] = []; // اللون الأخضر
      } else {
        // قم بتجميع الإشارات المرجعية حسب colorCode
        for (var bookmark in savedBookmarks) {
          bookmarks.update(
            bookmark.colorCode,
            (existingList) => [...existingList, bookmark],
            ifAbsent: () => [bookmark],
          );
        }
      }
    }
    _quranRepository.saveBookmarks(_flattenBookmarks());
    update();
  }

  void saveBookmark({
    required String surahName,
    required int ayahId,
    required int ayahNumber,
    required int page,
    required int colorCode,
  }) {
    final bookmark = BookmarkModel(
      id: DateTime.now().millisecondsSinceEpoch,
      // إنشاء ID فريد
      colorCode: colorCode,
      name: surahName,
      ayahNumber: ayahNumber,
      ayahId: ayahId,
      page: page,
    );

    // إضافة العلامة الجديدة إلى القائمة الموجودة
    bookmarks.update(
      colorCode,
      (existingList) => [...existingList, bookmark],
      ifAbsent: () => [bookmark], // إذا لم تكن هناك قائمة، أنشئ واحدة جديدة
    );

    _quranRepository.saveBookmarks(_flattenBookmarks());
    QuranCtrl.instance.update();
  }

  void removeBookmark(int bookmarkId) {
    // البحث في جميع القوائم لإيجاد الشارة المراد حذفها
    bookmarks.forEach((colorCode, list) {
      bookmarks.update(
        colorCode,
        (existingList) => existingList
            .where((bookmark) => bookmark.id != bookmarkId)
            .toList(),
      );
    });

    _quranRepository.saveBookmarks(_flattenBookmarks());
    QuranCtrl.instance.update();
  }

  // تحويل العلامات إلى قائمة مسطحة لحفظها في التخزين
  List<BookmarkModel> _flattenBookmarks() {
    return bookmarks.values.expand((list) => list).toList();
  }

  RxBool hasBookmark(int surahNum, int ayahUQNum, List? bookmarkList) =>
      (bookmarkList!.firstWhereOrNull(((element) =>
                  element.surahNumber == surahNum &&
                  element.ayahUQNumber == ayahUQNum)) !=
              null)
          ? true.obs
          : false.obs;
}
