part of '/quran.dart';

class SurahInfoStyle {
  final Color? backgroundColor;
  final Color? closeIconColor;
  final Color? surahNameColor;
  final Color? surahNumberColor;
  final Color? primaryColor;
  final Color? titleColor;
  final Color? indicatorColor;
  final Color? textColor;
  final String? ayahCount;
  final String? secondTabText;
  final String? firstTabText;
  final double? bottomSheetWidth;
  final double? bottomSheetHeight;

  SurahInfoStyle({
    this.closeIconColor,
    this.surahNameColor,
    this.surahNumberColor,
    this.backgroundColor,
    this.primaryColor,
    this.titleColor,
    this.indicatorColor,
    this.textColor,
    this.ayahCount,
    this.secondTabText,
    this.firstTabText,
    this.bottomSheetWidth,
    this.bottomSheetHeight,
  });

  factory SurahInfoStyle.defaults(
      {required bool isDark, required BuildContext context}) {
    return SurahInfoStyle(
      ayahCount: 'عدد الآيات',
      secondTabText: 'عن السورة',
      firstTabText: 'أسماء السورة',
      backgroundColor: AppColors.getBackgroundColor(isDark),
      closeIconColor: isDark ? Colors.white : Colors.black,
      indicatorColor: Colors.teal.withValues(alpha: .2),
      primaryColor: Colors.teal.withValues(alpha: .2),
      surahNameColor: isDark ? Colors.white : Colors.black,
      surahNumberColor: isDark ? Colors.white : Colors.black,
      textColor: isDark ? Colors.white : Colors.black,
      titleColor: isDark ? Colors.white : Colors.black,
      bottomSheetWidth: MediaQuery.of(context).size.width,
      bottomSheetHeight: MediaQuery.of(context).size.height * 0.8,
    );
  }
}
