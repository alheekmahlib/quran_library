part of '/quran.dart';

/// A repository class for managing Quran-related data.
///
/// This class provides methods to fetch, store, and manipulate
/// data related to the Quran. It acts as an intermediary between
/// the data sources (such as APIs or local databases) and the
/// application logic, ensuring that the data is properly handled
/// and formatted before being used in the app.
class QuranRepository {
  ///Quran pages number
  static const hafsPagesNumber = 604;

  /// Fetches the Quran data.
  ///
  /// This method retrieves a list of Quran data asynchronously.
  ///
  /// Returns a [Future] that completes with a [List] of dynamic objects
  /// representing the Quran data.
  ///
  /// Throws an [Exception] if the data retrieval fails.
  Future<List<dynamic>> getQuran() async {
    String content = await rootBundle
        .loadString('packages/quran_library/assets/jsons/quran_hafs.json');
    return jsonDecode(content);
  }

  /// Fetches the Quran info.
  ///
  /// This method retrieves a list of Quran data asynchronously.
  ///
  /// Returns a [Future] that completes with a [List] of dynamic objects
  /// representing the Quran info.
  ///
  /// Throws an [Exception] if the data retrieval fails.
  Future<List<dynamic>> getQuranInfo() async {
    final String infoRaw = await rootBundle
        .loadString('packages/quran_library/assets/jsons/quran_info.json');
    return jsonDecode(infoRaw);
  }

  /// Fetches the Quran data in Warsh narration from remote URL.
  ///
  /// This method retrieves Warsh Quran data from the remote repository.
  /// Data is cached locally for offline access.
  ///
  /// Returns a [Future] that completes with a [List] of dynamic objects
  /// representing the Quran data in Warsh narration.
  ///
  /// Throws an [Exception] if the data retrieval fails.
  Future<List<dynamic>> getQuranWarsh() async {
    const url =
        'https://raw.githubusercontent.com/alheekmahlib/data/main/packages/quran_library/content/warshData_v2-1.json';
    return await getQuranFromUrl(url, cacheKey: 'warshData');
  }

  /// Fetches Quran data from a remote URL with caching support.
  ///
  /// This method attempts to load data from the given [url]. If successful,
  /// the data is cached locally using GetStorage for offline access.
  /// If the network request fails, it attempts to load from cache.
  ///
  /// [url] - The remote URL to fetch data from
  /// [cacheKey] - Key used to store/retrieve cached data
  ///
  /// Returns a [Future] that completes with a [List] of dynamic objects
  /// representing the Quran data.
  ///
  /// Throws an [Exception] if both network and cache fail.
  Future<List<dynamic>> getQuranFromUrl(String url,
      {required String cacheKey}) async {
    try {
      // Try to load from network
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 15);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      final response = await dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        List<dynamic> data;
        try {
          if (raw is List) {
            data = raw;
          } else if (raw is String) {
            final decoded = jsonDecode(raw);
            if (decoded is List) {
              data = decoded;
            } else if (decoded is Map && decoded['data'] is List) {
              data = decoded['data'] as List<dynamic>;
            } else {
              throw Exception('Unexpected JSON format (String decoded)');
            }
          } else if (raw is Map) {
            if (raw['data'] is List) {
              data = raw['data'] as List<dynamic>;
            } else {
              throw Exception('Unexpected JSON format (Map)');
            }
          } else {
            throw Exception('Unsupported response type: ${raw.runtimeType}');
          }
        } catch (e) {
          throw Exception('Failed to parse remote JSON: $e');
        }
        await _cacheRemoteData(cacheKey, data);
        log('Loaded Quran data from URL: $url', name: 'QuranRepository');
        return data;
      }
      throw Exception('Failed to load from $url: ${response.statusCode}');
    } catch (e) {
      log('Failed to load from URL, trying cache: $e', name: 'QuranRepository');
      // Try to load from cache if network fails
      try {
        return await _loadFromCache(cacheKey);
      } catch (cacheError) {
        // Fallback to bundled asset if available (e.g. Warsh local file)
        try {
          final localContent = await rootBundle.loadString(
              'packages/quran_library/assets/jsons/${cacheKey == 'warshData' ? 'warshData_v2-1' : 'quran_hafs'}.json');
          final decoded = jsonDecode(localContent);
          if (decoded is List) {
            log('Loaded local bundled fallback for key: $cacheKey',
                name: 'QuranRepository');
            return decoded;
          }
        } catch (_) {}
        throw Exception('Failed to load from cache: $cacheError');
      }
    }
  }

  /// Caches remote Quran data locally
  Future<void> _cacheRemoteData(String key, List<dynamic> data) async {
    try {
      GetStorage().write('cached_$key', jsonEncode(data));
      GetStorage()
          .write('cached_${key}_timestamp', DateTime.now().toIso8601String());
      log('Cached data for key: $key', name: 'QuranRepository');
    } catch (e) {
      log('Failed to cache data: $e', name: 'QuranRepository');
    }
  }

  /// Loads Quran data from local cache
  Future<List<dynamic>> _loadFromCache(String key) async {
    try {
      final cachedData = GetStorage().read<String>('cached_$key');
      if (cachedData != null) {
        log('Loaded data from cache: $key', name: 'QuranRepository');
        final decoded = jsonDecode(cachedData);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['data'] is List) {
          return decoded['data'] as List<dynamic>;
        }
        throw Exception('Cached JSON has unexpected format');
      }
      throw Exception('No cached data found for key: $key');
    } catch (e) {
      throw Exception('Failed to load from cache: $e');
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
    String content = await rootBundle
        .loadString('packages/quran_library/assets/jsons/surahs_name.json');
    return jsonDecode(content);
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
  Future<List<dynamic>> getQuranDataV3() async {
    String jsonString = await rootBundle
        .loadString('packages/quran_library/assets/jsons/quranV3.json');
    Map<String, dynamic> jsonResponse = jsonDecode(jsonString);
    List<dynamic> surahsJson = jsonResponse['data']['surahs'];
    return surahsJson;
  }

  /// Saves the last page number.
  ///
  /// This method takes an integer [lastPage] which represents the last page
  /// number read by the user and saves it for future reference.
  ///
  /// [lastPage]: The page number to be saved.
  void saveLastPage(int lastPage) =>
      GetStorage().write(_StorageConstants().lastPage, lastPage);

  /// Retrieves the last page number from the storage.
  ///
  /// This method reads the last page number stored in the local storage
  /// using the `GetStorage` package and returns it as an integer. If the
  /// value is not found, it returns `null`.
  ///
  /// Returns:
  ///   - `int?`: The last page number if it exists in the storage, otherwise `null`.
  int? getLastPage() => GetStorage().read(_StorageConstants().lastPage);

  /// Saves the list of bookmarks to persistent storage.
  ///
  /// This method uses the `GetStorage` package to write the provided list of
  /// [BookmarkModel] instances to storage. The bookmarks can be retrieved later
  /// using the appropriate read method from `GetStorage`.
  ///
  /// [bookmarks] - A list of [BookmarkModel] instances to be saved.
  void saveBookmarks(List<BookmarkModel> bookmarks) => GetStorage().write(
        _StorageConstants().bookmarks,
        bookmarks.map((bookmark) => jsonEncode(bookmark._toJson())).toList(),
      );

  /// Retrieves a list of bookmarks.
  ///
  /// This method fetches all the bookmarks stored in the repository.
  ///
  /// Returns:
  ///   A list of [BookmarkModel] objects representing the bookmarks.
  List<BookmarkModel> getBookmarks() {
    final savedBookmarks = GetStorage().read(_StorageConstants().bookmarks);

    if (savedBookmarks == null || savedBookmarks is! List) {
      return []; // Return an empty list if data is null or not a list
    }

    try {
      return savedBookmarks.map((bookmark) {
        if (bookmark is Map<dynamic, dynamic>) {
          // Cast to Map<String, dynamic> before passing to fromJson
          return BookmarkModel._fromJson(Map<String, dynamic>.from(bookmark));
        } else if (bookmark is String) {
          // Decode JSON string and cast to Map<String, dynamic>
          return BookmarkModel._fromJson(
            Map<String, dynamic>.from(jsonDecode(bookmark)),
          );
        } else {
          throw Exception("Unexpected bookmark type: ${bookmark.runtimeType}");
        }
      }).toList();
    } catch (e) {
      // Log the error and return an empty list in case of issues
      log("Error parsing bookmarks: $e");
      return [];
    }
  }
}
