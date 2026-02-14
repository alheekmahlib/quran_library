part of '/quran.dart';

/// Extension to handle font-related operations for the QuranCtrl class.
///
/// الخطوط تُحمّل ديناميكيًا عبر [QuranFontsService] من ملفات `.ttf.gz`
/// مضغوطة في الـ assets.
extension FontsExtension on QuranCtrl {
  /// يُرجع اسم عائلة الخط للصفحة المحددة (page1 .. page604).
  String getFontPath(int pageIndex) {
    return QuranFontsService.getFontFamily(pageIndex);
  }
}
