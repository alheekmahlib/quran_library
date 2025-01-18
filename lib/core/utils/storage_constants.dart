class StorageConstants {
  final String bookmarks = 'bookmarks';
  final String lastPage = 'last_page';
  final String isDownloadedCodeV2Fonts = 'isDownloadedCodeV2Fonts';
  final String fontsSelected = 'fontsSelected';
  final String isBold = 'IS_BOLD';

  ///Singleton factory
  static final StorageConstants _instance = StorageConstants._internal();

  factory StorageConstants() {
    return _instance;
  }

  StorageConstants._internal();
}
