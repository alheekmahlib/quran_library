// واجهة نظام الملفات الشرطية — تختار التنفيذ حسب المنصة.
//
// Conditional file-system interface — selects the implementation per platform.
//
// على المنصات الأصلية (dart:io متوفر) → platform_io_io.dart
// على الويب → platform_io_stub.dart (تنفيذ آمن/وهمي)
//
// Native platforms (dart:io available) → platform_io_io.dart
// Web → platform_io_stub.dart (safe/no-op implementation)
export 'platform_io_stub.dart' if (dart.library.io) 'platform_io_io.dart';
