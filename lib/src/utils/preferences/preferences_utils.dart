import 'package:shared_preferences/shared_preferences.dart';

class PreferencesUtils {
  late SharedPreferences preferences;

  Future<bool> clear() async {
    return await preferences.clear();
  }

  bool? containsKey(String key) {
    return preferences.containsKey(key);
  }

  int? getInt(String key) {
    return preferences.getInt(key);
  }

  String? getString(String key) {
    return preferences.getString(key);
  }

  List<String>? getStringList(String key) {
    return preferences.getStringList(key);
  }

  Future<bool> setInt(String key, int value) async {
    return await preferences.setInt(key, value);
  }

  Future<bool> setString(String key, String value) async {
    return await preferences.setString(key, value);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    return await preferences.setStringList(key, value);
  }

  ///Singleton factory
  static final PreferencesUtils _instance = PreferencesUtils._internal();

  factory PreferencesUtils() {
    return _instance;
  }

  PreferencesUtils._internal();
}
