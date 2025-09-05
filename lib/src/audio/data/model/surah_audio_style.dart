part of '../../audio.dart';

/// فئة لتخصيص أنماط واجهة تشغيل السور الصوتية
/// Class for customizing Surah audio interface styles
class SurahAudioStyle {
  /// لون النص الأساسي
  /// Primary text color
  final Color? textColor;

  /// مسار أيقونة التشغيل المخصصة
  /// Custom play icon path
  final String? playIconPath;

  /// ارتفاع أيقونة التشغيل
  /// Play icon height
  final double? playIconHeight;

  /// لون أيقونة التشغيل
  /// Play icon color
  final Color? playIconColor;

  /// مسار أيقونة الإيقاف المخصصة
  /// Custom pause icon path
  final String? pauseIconPath;

  /// ارتفاع أيقونة الإيقاف
  /// Pause icon height
  final double? pauseIconHeight;

  /// ارتفاع أيقونة السابق
  /// Previous icon height
  final double? previousIconHeight;

  /// ارتفاع أيقونة التالي
  /// Next icon height
  final double? nextIconHeight;

  /// لون اسم القارئ في العنصر
  /// Reader name color in item
  final Color? readerNameInItemColor;

  /// حجم خط اسم القارئ في العنصر
  /// Reader name font size in item
  final double? readerNameInItemFontSize;

  /// حجم خط اسم القارئ
  /// Reader name font size
  final double? readerNameFontSize;

  /// لون إبهام شريط التقدم
  /// Seek bar thumb color
  final Color? seekBarThumbColor;

  /// لون المسار النشط لشريط التقدم
  /// Seek bar active track color
  final Color? seekBarActiveTrackColor;

  /// لون المسار غير النشط لشريط التقدم
  /// Seek bar inactive track color
  final Color? seekBarInactiveTrackColor;

  /// الحشو الأفقي لشريط التقدم
  /// Seek bar horizontal padding
  final double? seekBarHorizontalPadding;

  /// لون الخلفية الأساسي
  /// Primary background color
  final Color? backgroundColor;

  /// نصف قطر الحدود
  /// Border radius
  final double? borderRadius;

  /// لون خلفية النوافذ المنبثقة
  /// Dialog background color
  final Color? dialogBackgroundColor;

  /// نصف قطر حدود النوافذ المنبثقة
  /// Dialog border radius
  final double? dialogBorderRadius;

  /// لون العنصر المحدد
  /// Selected item color
  final Color? selectedItemColor;

  /// لون الأيقونات الثانوية
  /// Secondary icons color
  final Color? secondaryIconColor;

  /// حجم الخط الثانوي
  /// Secondary font size
  final double? secondaryFontSize;

  /// لون الخط الثانوي
  /// Secondary text color
  final Color? secondaryTextColor;

  /// اللون الأساسي للواجهة
  /// Primary interface color
  final Color? primaryColor;

  /// لون الأيقونات العامة
  /// General icons color
  final Color? iconColor;

  /// لون الأيقونات العامة
  /// General icons color
  final Color? audioSliderBackgroundColor;

  /// لون اسم السورة
  /// Surah name color
  final Color? surahNameColor;

  /// منشئ فئة SurahAudioStyle
  /// SurahAudioStyle class constructor
  SurahAudioStyle({
    this.textColor,
    this.playIconPath,
    this.playIconHeight,
    this.playIconColor,
    this.pauseIconPath,
    this.pauseIconHeight,
    this.readerNameInItemColor,
    this.readerNameInItemFontSize,
    this.readerNameFontSize,
    this.seekBarThumbColor,
    this.seekBarActiveTrackColor,
    this.seekBarHorizontalPadding,
    this.previousIconHeight,
    this.nextIconHeight,
    this.seekBarInactiveTrackColor,
    this.backgroundColor,
    this.borderRadius,
    this.dialogBackgroundColor,
    this.dialogBorderRadius,
    this.selectedItemColor,
    this.secondaryIconColor,
    this.secondaryFontSize,
    this.secondaryTextColor,
    this.primaryColor,
    this.iconColor,
    this.audioSliderBackgroundColor,
    this.surahNameColor,
  });
}
