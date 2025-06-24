/// A class that contains constants for asset paths.
///
/// This class provides a centralized place to define and access
/// asset paths used throughout the application. By using this class,
/// we can avoid hardcoding asset paths in multiple places, making
/// the code more maintainable and less prone to errors.
class AssetsPath {
  /// Singleton instance
  static final AssetsPath _instance = AssetsPath._();

  /// Private constructor
  AssetsPath._();

  /// Factory constructor to return the singleton instance
  factory AssetsPath() => _instance;

  /// Base path for all assets
  final String _basePath = 'packages/quran_library/assets';

  /// Base path for JSON files
  String get jsonPath => '$_basePath/jsons';

  /// Path for Quran Hafs JSON file
  String get quranHafsJson => '$jsonPath/quran_hafs.json';

  /// Path for Surahs name JSON file
  String get surahsNameJson => '$jsonPath/surahs_name.json';

  /// Path for Quran V2 JSON file
  String get quranV2Json => '$jsonPath/quranV2.json';

  /// Base path for fonts
  String get fontsPath => '$_basePath/fonts';

  /// Base path for images
  String get imagesPath => '$_basePath/images';

  /// Base path for database files
  String get databasePath => '$_basePath/db';
}