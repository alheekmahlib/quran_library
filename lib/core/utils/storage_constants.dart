part of '../../quran.dart';

class _StorageConstants {
  final String bookmarks = 'bookmarks';
  final String lastPage = 'last_page';
  final String isDownloadedCodeV2Fonts = 'isDownloadedCodeV2Fonts';
  final String fontsSelected = 'fontsSelected2';
  final String isTajweed = 'isTajweed';
  final String fontsDownloadedList = 'fontsDownloadedList';
  final String isBold = 'IS_BOLD';

  ///Singleton factory
  static final _StorageConstants _instance = _StorageConstants._internal();

  factory _StorageConstants() {
    return _instance;
  }

  _StorageConstants._internal();
}
