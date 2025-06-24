import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/utils/assets_path.dart';
import '../../core/utils/storage_constants.dart';
import '../../data/models/quran_fonts_models/ayah_model.dart';
import '../../data/models/quran_fonts_models/surahs_model.dart';
import '../../data/models/styles_models/bookmark.dart';

/// A service class for managing Quran-related operations.
///
/// This class provides methods to fetch, store, and manipulate
/// data related to the Quran. It acts as an intermediary between
/// the data sources (such as APIs or local databases) and the
/// application logic, ensuring that the data is properly handled
/// and formatted before being used in the app.
class QuranService {
  /// Singleton instance
  static final QuranService _instance = QuranService._();

  /// Private constructor
  QuranService._();

  /// Factory constructor to return the singleton instance
  factory QuranService() => _instance;

  /// Assets path utility
  final _assetsPath = AssetsPath();

  /// Storage constants
  final _storageConstants = StorageConstants();

  /// GetStorage instance for local storage
  final _storage = GetStorage();

  /// Quran pages number
  static const hafsPagesNumber = 604;

  /// Initialize the service
  Future<void> initialize() async {
    // Any initialization logic can go here
  }

  /// Fetches the Quran data.
  ///
  /// This method retrieves a list of Quran data asynchronously.
  ///
  /// Returns a [Future] that completes with a [List] of dynamic objects
  /// representing the Quran data.
  ///
  /// Throws an [Exception] if the data retrieval fails.
  Future<List<dynamic>> getQuran() async {
    try {
      String content = await rootBundle.loadString(_assetsPath.quranHafsJson);
      return json.decode(content);
    } catch (e) {
      throw Exception('Failed to load Quran data: $e');
    }
  }

  /// Fetches the list of Surahs from the data source.
  ///
  /// This method returns a [Future] that completes with a [Map] containing
  /// the Surah data. The keys in the map are the Surah identifiers, and the
  /// values are the corresponding Surah details.
  ///
  /// Returns:
  ///   A [Future] that completes with a [Map<String, dynamic>] containing
  ///   the Surah data.
  ///
  /// Throws:
  ///   An exception if there is an error while fetching the Surah data.
  Future<Map<String, dynamic>> getSurahs() async {
    try {
      String content = await rootBundle.loadString(_assetsPath.surahsNameJson);
      return json.decode(content);
    } catch (e) {
      throw Exception('Failed to load Surahs data: $e');
    }
  }

  /// Fetches a list of Quran fonts.
  ///
  /// This method retrieves a list of available fonts for the Quran.
  ///
  /// Returns a [Future] that completes with a [List] of dynamic objects
  /// representing the fonts.
  ///
  /// Example usage:
  /// ```dart
  /// List<dynamic> fonts = await getFontsQuran();
  /// ```
  Future<List<dynamic>> getFontsQuran() async {
    try {
      String jsonString = await rootBundle.loadString(_assetsPath.quranV2Json);
      Map<String, dynamic> jsonResponse = json.decode(jsonString);
      List<dynamic> surahsJson = jsonResponse['data']['surahs'];
      return surahsJson;
    } catch (e) {
      throw Exception('Failed to load Quran fonts data: $e');
    }
  }

  /// Saves the last page number.
  ///
  /// This method takes an integer [lastPage] which represents the last page
  /// number read by the user and saves it for future reference.
  ///
  /// [lastPage]: The page number to be saved.
  void saveLastPage(int lastPage) {
    _storage.write(_storageConstants.lastPage, lastPage);
  }

  /// Retrieves the last page number from the storage.
  ///
  /// This method reads the last page number stored in the local storage
  /// and returns it as an integer. If the value is not found, it returns `null`.
  ///
  /// Returns:
  ///   - `int?`: The last page number if it exists in the storage, otherwise `null`.
  int? getLastPage() {
    return _storage.read<int>(_storageConstants.lastPage);
  }

  /// Saves the list of bookmarks to persistent storage.
  ///
  /// This method uses the `GetStorage` package to write the provided list of
  /// [BookmarkModel] instances to storage. The bookmarks can be retrieved later
  /// using the appropriate read method from `GetStorage`.
  ///
  /// [bookmarks] - A list of [BookmarkModel] instances to be saved.
  void saveBookmarks(List<BookmarkModel> bookmarks) {
    _storage.write(
      _storageConstants.bookmarks,
      bookmarks.map((bookmark) => json.encode(bookmark.toJson())).toList(),
    );
  }

  /// Retrieves a list of bookmarks.
  ///
  /// This method fetches all the bookmarks stored in the repository.
  ///
  /// Returns:
  ///   A [List] of [BookmarkModel] objects representing the bookmarks.
  List<BookmarkModel> getBookmarks() {
    final bookmarksJson =
        _storage.read<List<dynamic>>(_storageConstants.bookmarks);
    if (bookmarksJson == null) return [];

    return bookmarksJson
        .map(
            (bookmarkJson) => BookmarkModel.fromJson(json.decode(bookmarkJson)))
        .toList();
  }

  /// Searches for Ayahs by text.
  ///
  /// This method searches through all Ayahs in the Quran for those
  /// that contain the specified text.
  ///
  /// [text] - The text to search for.
  ///
  /// Returns a list of [AyahFontsModel] objects that match the search criteria.
  List<AyahFontsModel> searchAyahs(String text, List<AyahFontsModel> allAyahs) {
    if (text.isEmpty || allAyahs.isEmpty) return [];

    final normalizedText = text.trim().toLowerCase();
    return allAyahs.where((ayah) {
      final ayahText = ayah.text.toLowerCase();
      final ayahEmlaeyText = ayah.ayaTextEmlaey.toLowerCase();
      return ayahText.contains(normalizedText) ||
          ayahEmlaeyText.contains(normalizedText);
    }).toList();
  }

  /// Searches for Surahs by text.
  ///
  /// This method searches through all Surahs in the Quran for those
  /// that match the specified text in their name or number.
  ///
  /// [text] - The text to search for.
  /// [surahs] - The list of Surahs to search through.
  ///
  /// Returns a list of [AyahFontsModel] objects from matching Surahs.
  List<AyahFontsModel> searchSurahs(String text, List<SurahFontsModel> surahs,
      List<AyahFontsModel> allAyahs) {
    if (text.isEmpty || surahs.isEmpty || allAyahs.isEmpty) return [];

    final normalizedText = text.trim().toLowerCase();
    final matchingSurahs = surahs.where((surah) {
      final arabicNameLower = surah.arabicName.toLowerCase();
      final englishNameLower = surah.englishName.toLowerCase();
      final surahNumberStr = surah.surahNumber.toString();

      return arabicNameLower.contains(normalizedText) ||
          englishNameLower.contains(normalizedText) ||
          surahNumberStr == normalizedText;
    }).toList();

    if (matchingSurahs.isEmpty) return [];

    return allAyahs.where((ayah) {
      return matchingSurahs.any((surah) =>
          surah.ayahs.isNotEmpty &&
          ayah.ayahUQNumber >= surah.ayahs.first.ayahUQNumber &&
          ayah.ayahUQNumber <= surah.ayahs.last.ayahUQNumber);
    }).toList();
  }
}
