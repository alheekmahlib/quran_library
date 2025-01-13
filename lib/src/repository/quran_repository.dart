import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/bookmark.dart';
import '../utils/preferences/preferences.dart';
import '../utils/preferences/preferences_utils.dart';

class QuranRepository {
  ///Quran pages number
  static const hafsPagesNumber = 604;

  Future<List<dynamic>> getQuran() async {
    String content = await rootBundle
        .loadString('packages/quran_library/lib/assets/jsons/quran_hafs.json');
    return jsonDecode(content);
  }

  Future<bool> saveLastPage(int lastPage) async =>
      PreferencesUtils().setInt(Preferences().lastPage, lastPage);

  int? getLastPage() => PreferencesUtils().getInt(Preferences().lastPage);

  Future<bool> saveBookmarks(List<BookmarkModel> bookmarks) =>
      PreferencesUtils().setStringList(
        Preferences().bookmarks,
        bookmarks.map((bookmark) => json.encode(bookmark.toJson())).toList(),
      );

  List<BookmarkModel> getBookmarks() {
    final savedBookmarks =
        PreferencesUtils().getStringList(Preferences().bookmarks);
    if (savedBookmarks == null) return [];

    return savedBookmarks
        .map((bookmark) => BookmarkModel.fromJson(json.decode(bookmark)))
        .toList();
  }
}
