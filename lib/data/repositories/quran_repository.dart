part of '../../../quran.dart';

class QuranRepository {
  ///Quran pages number
  static const hafsPagesNumber = 604;

  Future<List<dynamic>> getQuran() async {
    String content = await rootBundle
        .loadString('packages/quran_library/lib/assets/jsons/quran_hafs.json');
    return jsonDecode(content);
  }

  Future<Map<String, dynamic>> getSurahs() async {
    String content = await rootBundle
        .loadString('packages/quran_library/lib/assets/jsons/surahs_name.json');
    return jsonDecode(content);
  }

  Future<List<dynamic>> getFontsQuran() async {
    String jsonString = await rootBundle
        .loadString('packages/quran_library/lib/assets/jsons/quranV2.json');
    Map<String, dynamic> jsonResponse = jsonDecode(jsonString);
    List<dynamic> surahsJson = jsonResponse['data']['surahs'];
    return surahsJson;
  }

  saveLastPage(int lastPage) =>
      GetStorage().write(StorageConstants().lastPage, lastPage);

  int? getLastPage() => GetStorage().read(StorageConstants().lastPage);

  saveBookmarks(List<BookmarkModel> bookmarks) => GetStorage().write(
        StorageConstants().bookmarks,
        bookmarks.map((bookmark) => json.encode(bookmark.toJson())).toList(),
      );

  List<BookmarkModel> getBookmarks() {
    final savedBookmarks = GetStorage().read(StorageConstants().bookmarks);

    if (savedBookmarks == null || savedBookmarks is! List) {
      return []; // Return an empty list if data is null or not a list
    }

    try {
      return savedBookmarks.map((bookmark) {
        if (bookmark is Map<dynamic, dynamic>) {
          // Cast to Map<String, dynamic> before passing to fromJson
          return BookmarkModel.fromJson(Map<String, dynamic>.from(bookmark));
        } else if (bookmark is String) {
          // Decode JSON string and cast to Map<String, dynamic>
          return BookmarkModel.fromJson(
            Map<String, dynamic>.from(json.decode(bookmark)),
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
