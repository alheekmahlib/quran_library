// تنفيذ ويب/وهمي لواجهة نظام الملفات — لا يستخدم dart:io (غير متوفر على الويب).
//
// Web/stub implementation of the file-system interface — does not use dart:io
// (unavailable on web).
//
// ملاحظة: جميع النداءات الفعلية محميّة بـ `kIsWeb` في الكود المستهلك، لذا هذه
// الدوال لا تُستدعى على الويب عادةً. لكنها يجب أن تتوفر (compile) بدون dart:io.
//
// Note: all actual call sites are guarded by `kIsWeb` in consumers, so these are
// normally never invoked on web. They only need to compile without dart:io.
import 'dart:typed_data' show Uint8List;

/// واجهة نظام الملفات عبر المنصات / Cross-platform file-system interface.
class PlatformIo {
  PlatformIo._();

  /// على المنصات الأصلية: هل الملف موجود؟ / Native: does the file exist?
  /// على الويب: دائماً false (لا نظام ملفات). / Web: always false.
  static Future<bool> fileExists(String path) async => false;

  /// على المنصات الأصلية: اقرأ بايتات الملف. / Native: read file bytes.
  /// على الويب: غير مدعوم. / Web: unsupported.
  static Future<Uint8List> readFile(String path) {
    throw UnsupportedError('File reading is not supported on web');
  }

  /// على المنصات الأصلية: اكتب البايتات لملف. / Native: write bytes to a file.
  /// على الويب: غير مدعوم. / Web: unsupported.
  static Future<void> writeFile(String path, Uint8List bytes) async {
    throw UnsupportedError('File writing is not supported on web');
  }

  /// على المنصات الأصلية: احذف الملف. / Native: delete a file.
  /// على الويب: لا شيء. / Web: no-op.
  static Future<void> deleteFile(String path) async {}

  /// على المنصات الأصلية: أنشئ المجلد الأب. / Native: create parent directory.
  /// على الويب: لا شيء. / Web: no-op.
  static Future<void> ensureParentDir(String filePath) async {}

  /// على المنصات الأصلية: مجلد مستندات التطبيق. / Native: app documents dir.
  /// على الويب: غير مدعوم. / Web: unsupported.
  static Future<String> get documentsDir {
    throw UnsupportedError('Documents directory is not supported on web');
  }

  /// على المنصات الأصلية: المجلد المؤقت. / Native: temp directory.
  /// على الويب: غير مدعوم. / Web: unsupported.
  static Future<String> get tempDir {
    throw UnsupportedError('Temp directory is not supported on web');
  }

  /// اسم المجلد الأب لمسار (متوفر عبر حزمة path، لا يحتاج dart:io).
  /// Parent directory name of a path (available via the path package; no dart:io).
  static String dirName(String filePath) {
    final lastSlash = filePath.lastIndexOf('/');
    return lastSlash >= 0 ? filePath.substring(0, lastSlash) : '.';
  }

  /// هل المنصة الحالية سطح مكتب (Windows/macOS/Linux)؟
  /// على الويب: false.
  ///
  /// Is the current platform desktop (Windows/macOS/Linux)?
  /// On web: false.
  static bool get isDesktop => false;

  /// هل المنصة الحالية Windows؟ / Is the current platform Windows?
  static bool get isWindows => false;

  /// هل المنصة الحالية macOS؟ / Is the current platform macOS?
  static bool get isMacOS => false;

  /// هل المنصة الحالية Linux؟ / Is the current platform Linux?
  static bool get isLinux => false;
}
