part of '/quran.dart';

/// نمط مخصص لحوار الضغط المطوّل على الآية (AyahLongClickDialog).
///
/// يتيح تخصيص الألوان والأبعاد والهوامش وقائمة ألوان العلامات المرجعية
/// بالإضافة إلى خصائص الأيقونات والفواصل والظل. استخدم المصنع [defaults]
/// للحصول على قيم افتراضية متناسقة مع الوضع الليلي/النهاري.
class AyahLongClickStyle {
  /// لون خلفية الحاوية الأساسية للحوار.
  final Color? backgroundColor;

  /// لون حدود الحاوية الداخلية للحوار.
  final Color? borderColor;

  /// سماكة الحدود للحاوية الداخلية.
  final double? borderWidth;

  /// نصف قطر الانحناء للحواف.
  final double? borderRadius;

  /// نصف قطر انحناء الحاوية الخارجية (الخلفية ذات الظل).
  final double? outerBorderRadius;

  /// قائمة ألوان العلامات المرجعية (كقيم ARGB صحيحة).
  final List<int>? bookmarkColorCodes;

  /// لون أيقونة النسخ.
  final Color? copyIconColor;

  /// لون أيقونة عرض التفسير.
  final Color? tafsirIconColor;

  /// لون فواصل الخطوط العمودية بين العناصر.
  final Color? dividerColor;

  /// ظل الحاوية الخارجية.
  final List<BoxShadow>? boxShadow;

  /// الحشوات الداخلية للحاوية الثانية (حول الصف داخل الحدود).
  final EdgeInsetsGeometry? padding;

  /// الهوامش بين الحاويتين (الخارجية والداخلية).
  final EdgeInsetsGeometry? margin;

  /// الارتفاع المقترح للحوار.
  final double? dialogHeight;

  /// حجم الأيقونات داخل شريط الأدوات.
  final double? iconSize;

  /// التباعد الأفقي حول كل أيقونة.
  final double? iconHorizontalPadding;

  /// عرض الأساس لكل عنصر (يُستخدم لحساب العرض الكلي).
  final double? itemBaseWidth;

  /// التباعد بين العناصر أثناء حساب العرض.
  final double? itemSpacing;

  /// مسافة أفقية إضافية تُضاف عند حساب عرض الحوار.
  final double? extraHorizontalSpace;

  /// ارتفاع الفاصل العمودي بين العناصر.
  final double? dividerHeight;

  /// سماكة الفاصل العمودي.
  final double? dividerThickness;

  /// إظهار/إخفاء أزرار العلامات المرجعية.
  final bool? showBookmarkButtons;

  /// إظهار/إخفاء زر النسخ.
  final bool? showCopyButton;

  /// إظهار/إخفاء زر التفسير.
  final bool? showTafsirButton;

  /// الأيقونة المستخدمة لعنصر العلامة المرجعية.
  final IconData? bookmarkIconData;

  /// الأيقونة المستخدمة لزر النسخ.
  final IconData? copyIconData;

  /// الأيقونة المستخدمة لزر التفسير.
  final IconData? tafsirIconData;

  /// مسافة الإزاحة من موضع النقر لحساب موضع الحوار عموديًا.
  final double? tapOffsetSpacing;

  /// هامش الأمان من حواف الشاشة عند تموضع الحوار.
  final double? edgeSafeMargin;

  /// رسالة نجاح النسخ (مستحسن ربطها بـ i18n/intl).
  final String? copySuccessMessage;

  const AyahLongClickStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.outerBorderRadius,
    this.bookmarkColorCodes,
    this.copyIconColor,
    this.tafsirIconColor,
    this.dividerColor,
    this.boxShadow,
    this.padding,
    this.margin,
    this.dialogHeight,
    this.iconSize,
    this.iconHorizontalPadding,
    this.itemBaseWidth,
    this.itemSpacing,
    this.extraHorizontalSpace,
    this.dividerHeight,
    this.dividerThickness,
    this.showBookmarkButtons,
    this.showCopyButton,
    this.showTafsirButton,
    this.bookmarkIconData,
    this.copyIconData,
    this.tafsirIconData,
    this.tapOffsetSpacing,
    this.edgeSafeMargin,
    this.copySuccessMessage,
  });

  /// القيم الافتراضية للنمط بحسب الوضع الليلي/النهاري.
  factory AyahLongClickStyle.defaults({
    required bool isDark,
    required BuildContext context,
  }) {
    return AyahLongClickStyle(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      borderColor: Colors.teal.shade100,
      borderWidth: 2.0,
      borderRadius: 6.0,
      outerBorderRadius: 8.0,
      bookmarkColorCodes: const [
        0xAAFFD354, // أصفر باهت
        0xAAF36077, // وردي داكن
        0xAA00CD00, // أخضر
      ],
      copyIconColor: Colors.teal,
      tafsirIconColor: Colors.teal,
      dividerColor: Colors.teal.shade100,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.3),
          blurRadius: 10,
          spreadRadius: 5,
          offset: const Offset(0, 5),
        ),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      margin: const EdgeInsets.all(4.0),
      dialogHeight: 80.0,
      iconSize: 24.0,
      iconHorizontalPadding: 8.0,
      itemBaseWidth: 40.0,
      itemSpacing: 16.0,
      extraHorizontalSpace: 40.0,
      dividerHeight: 30.0,
      dividerThickness: 1.0,
      showBookmarkButtons: true,
      showCopyButton: true,
      showTafsirButton: true,
      bookmarkIconData: Icons.bookmark,
      copyIconData: Icons.copy_rounded,
      tafsirIconData: Icons.text_snippet_rounded,
      tapOffsetSpacing: 10.0,
      edgeSafeMargin: 10.0,
      copySuccessMessage: 'تم النسخ الى الحافظة',
    );
  }
}
