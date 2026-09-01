// تنفيذ أصلي لواجهة نظام الملفات — يستخدم dart:io (متوفر على كل المنصات عدا الويب).
//
// Native implementation of the file-system interface — uses dart:io (available on
// all platforms except web).
import 'dart:io' show Directory, File, Platform;
import 'dart:typed_data' show Uint8List;

import 'package:path_provider/path_provider.dart';

/// واجهة نظام الملفات عبر المنصات / Cross-platform file-system interface.
class PlatformIo {
  PlatformIo._();

  /// هل الملف موجود؟ / Does the file exist?
  static Future<bool> fileExists(String path) async => File(path).exists();

  /// اقرأ بايتات الملف / Read file bytes.
  static Future<Uint8List> readFile(String path) => File(path).readAsBytes();

  /// اكتب البايتات لملف / Write bytes to a file.
  static Future<void> writeFile(String path, Uint8List bytes) =>
      File(path).writeAsBytes(bytes, flush: true);

  /// حجم الملف بالبايت، أو -1 إن لم يوجد / File size in bytes, or -1.
  static Future<int> fileLength(String path) async {
    final f = File(path);
    if (!await f.exists()) return -1;
    return f.length();
  }

  /// أعد تسمية/انقل ملفاً / Rename (move) a file.
  static Future<void> renameFile(String from, String to) async {
    await File(from).rename(to);
  }

  /// احذف الملف (إن وُجد) / Delete a file (if it exists).
  static Future<void> deleteFile(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  /// أنشئ المجلد الأب للملف (بشكل متكرع) / Create the parent directory (recursively).
  static Future<void> ensureParentDir(String filePath) async {
    await Directory(dirName(filePath)).create(recursive: true);
  }

  /// مجلد مستندات التطبيق / App documents directory.
  static Future<String> get documentsDir =>
      getApplicationDocumentsDirectory().then((d) => d.path);

  /// المجلد المؤقت / Temp directory.
  static Future<String> get tempDir =>
      getTemporaryDirectory().then((d) => d.path);

  /// اسم المجلد الأب لمسار / Parent directory name of a path.
  static String dirName(String filePath) {
    final lastSlash = filePath.lastIndexOf('/');
    return lastSlash >= 0 ? filePath.substring(0, lastSlash) : '.';
  }

  /// هل المنصة الحالية سطح مكتب (Windows/macOS/Linux)؟
  /// Is the current platform desktop (Windows/macOS/Linux)?
  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// هل المنصة الحالية Windows؟ / Is the current platform Windows?
  static bool get isWindows => Platform.isWindows;

  /// هل المنصة الحالية macOS؟ / Is the current platform macOS?
  static bool get isMacOS => Platform.isMacOS;

  /// هل المنصة الحالية Linux؟ / Is the current platform Linux?
  static bool get isLinux => Platform.isLinux;
}
