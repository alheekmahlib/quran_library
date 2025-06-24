/// A class that contains constants for storage keys.
///
/// This class provides a centralized place to define and access
/// storage keys used throughout the application. By using this class,
/// we can avoid hardcoding storage keys in multiple places, making
/// the code more maintainable and less prone to errors.
class StorageConstants {
  /// Singleton instance
  static final StorageConstants _instance = StorageConstants._();

  /// Private constructor
  StorageConstants._();

  /// Factory constructor to return the singleton instance
  factory StorageConstants() => _instance;

  /// Key for storing the last page number
  final String lastPage = 'last_page';

  /// Key for storing bookmarks
  final String bookmarks = 'bookmarks';

  /// Key for storing whether the text is bold
  final String isBold = 'is_bold';

  /// Key for storing the selected font
  final String fontsSelected = 'fonts_selected';

  /// Key for storing whether V2 fonts are downloaded
  final String isDownloadedCodeV2Fonts = 'is_downloaded_code_v2_fonts';

  /// Key for storing the list of downloaded fonts
  final String fontsDownloadedList = 'fonts_downloaded_list';
}