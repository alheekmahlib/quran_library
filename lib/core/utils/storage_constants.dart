part of '../../quran.dart';

class StorageConstants {
  final String bookmarks = 'bookmarks';
  final String lastPage = 'last_page';
  final String isDownloadedCodeV2Fonts = 'isDownloadedCodeV2Fonts';
  final String fontsSelected = 'fontsSelected2';
  final String isTajweed = 'isTajweed';
  final String fontsDownloadedList = 'fontsDownloadedList';
  final String isBold = 'IS_BOLD';

  ///Singleton factory
  static final StorageConstants _instance = StorageConstants._internal();

  factory StorageConstants() {
    return _instance;
  }

  StorageConstants._internal();
}
