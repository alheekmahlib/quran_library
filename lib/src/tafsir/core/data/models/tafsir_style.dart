part of '../../../tafsir.dart';

class TafsirStyle {
  final Widget? tafsirNameWidget;
  final Widget? fontSizeWidget;
  final String? translateName;
  final String? tafsirName;
  final Color? currentTafsirColor;
  final Color? textTitleColor;
  final Color? backgroundTitleColor;
  final Color? selectedTafsirColor;
  final Color? unSelectedTafsirColor;
  final Color? selectedTafsirTextColor;
  final Color? unSelectedTafsirTextColor;
  final Color? selectedTafsirBorderColor;
  final Color? unSelectedTafsirBorderColor;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? tafsirBackgroundColor;
  final Color? dividerColor;
  final double? fontSize;
  final String? footnotesName;
  final double? horizontalMargin;
  final double? verticalMargin;
  final String? tafsirIsEmptyNote;
  final double? heightOfBottomSheet;
  final double? widthOfBottomSheet;
  final double? changeTafsirDialogHeight;
  final double? changeTafsirDialogWidth;
  final Widget? fontSizeIconWidget;
  final Color? fontSizeBackgroundColor;
  final Color? fontSizeThumbColor;
  final Color? fontSizeActiveTrackColor;
  final Color? fontSizeInactiveTrackColor;
  final double? fontSizeIconSize;

  TafsirStyle({
    this.backgroundColor,
    this.textColor,
    this.fontSizeWidget,
    this.tafsirNameWidget,
    this.translateName,
    this.tafsirName,
    this.textTitleColor,
    this.currentTafsirColor,
    this.backgroundTitleColor,
    this.selectedTafsirColor,
    this.unSelectedTafsirColor,
    this.selectedTafsirBorderColor,
    this.unSelectedTafsirBorderColor,
    this.selectedTafsirTextColor,
    this.unSelectedTafsirTextColor,
    this.fontSize,
    this.footnotesName,
    this.dividerColor,
    this.horizontalMargin,
    this.verticalMargin,
    this.tafsirBackgroundColor,
    this.tafsirIsEmptyNote,
    this.heightOfBottomSheet,
    this.widthOfBottomSheet,
    this.changeTafsirDialogHeight,
    this.changeTafsirDialogWidth,
    this.fontSizeIconWidget,
    this.fontSizeBackgroundColor,
    this.fontSizeThumbColor,
    this.fontSizeActiveTrackColor,
    this.fontSizeInactiveTrackColor,
    this.fontSizeIconSize,
  });

  TafsirStyle copyWith({
    Widget? tafsirNameWidget,
    Widget? fontSizeWidget,
    String? translateName,
    String? tafsirName,
    Color? currentTafsirColor,
    Color? textTitleColor,
    Color? backgroundTitleColor,
    Color? selectedTafsirColor,
    Color? unSelectedTafsirColor,
    Color? selectedTafsirTextColor,
    Color? unSelectedTafsirTextColor,
    Color? selectedTafsirBorderColor,
    Color? unSelectedTafsirBorderColor,
    Color? backgroundColor,
    Color? textColor,
    Color? tafsirBackgroundColor,
    Color? dividerColor,
    double? fontSize,
    String? footnotesName,
    double? horizontalMargin,
    double? verticalMargin,
    String? tafsirIsEmptyNote,
    double? heightOfBottomSheet,
    double? widthOfBottomSheet,
    double? changeTafsirDialogHeight,
    double? changeTafsirDialogWidth,
    Widget? fontSizeIconWidget,
    Color? fontSizeBackgroundColor,
    Color? fontSizeThumbColor,
    Color? fontSizeActiveTrackColor,
    Color? fontSizeInactiveTrackColor,
    double? fontSizeIconSize,
  }) {
    return TafsirStyle(
      tafsirNameWidget: tafsirNameWidget ?? this.tafsirNameWidget,
      fontSizeWidget: fontSizeWidget ?? this.fontSizeWidget,
      translateName: translateName ?? this.translateName,
      tafsirName: tafsirName ?? this.tafsirName,
      currentTafsirColor: currentTafsirColor ?? this.currentTafsirColor,
      textTitleColor: textTitleColor ?? this.textTitleColor,
      backgroundTitleColor: backgroundTitleColor ?? this.backgroundTitleColor,
      selectedTafsirColor: selectedTafsirColor ?? this.selectedTafsirColor,
      unSelectedTafsirColor:
          unSelectedTafsirColor ?? this.unSelectedTafsirColor,
      selectedTafsirTextColor:
          selectedTafsirTextColor ?? this.selectedTafsirTextColor,
      unSelectedTafsirTextColor:
          unSelectedTafsirTextColor ?? this.unSelectedTafsirTextColor,
      selectedTafsirBorderColor:
          selectedTafsirBorderColor ?? this.selectedTafsirBorderColor,
      unSelectedTafsirBorderColor:
          unSelectedTafsirBorderColor ?? this.unSelectedTafsirBorderColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      tafsirBackgroundColor:
          tafsirBackgroundColor ?? this.tafsirBackgroundColor,
      dividerColor: dividerColor ?? this.dividerColor,
      fontSize: fontSize ?? this.fontSize,
      footnotesName: footnotesName ?? this.footnotesName,
      horizontalMargin: horizontalMargin ?? this.horizontalMargin,
      verticalMargin: verticalMargin ?? this.verticalMargin,
      tafsirIsEmptyNote: tafsirIsEmptyNote ?? this.tafsirIsEmptyNote,
      heightOfBottomSheet: heightOfBottomSheet ?? this.heightOfBottomSheet,
      widthOfBottomSheet: widthOfBottomSheet ?? this.widthOfBottomSheet,
      changeTafsirDialogHeight:
          changeTafsirDialogHeight ?? this.changeTafsirDialogHeight,
      changeTafsirDialogWidth:
          changeTafsirDialogWidth ?? this.changeTafsirDialogWidth,
      fontSizeIconWidget: fontSizeIconWidget ?? this.fontSizeIconWidget,
      fontSizeBackgroundColor:
          fontSizeBackgroundColor ?? this.fontSizeBackgroundColor,
      fontSizeThumbColor: fontSizeThumbColor ?? this.fontSizeThumbColor,
      fontSizeActiveTrackColor:
          fontSizeActiveTrackColor ?? this.fontSizeActiveTrackColor,
      fontSizeInactiveTrackColor:
          fontSizeInactiveTrackColor ?? this.fontSizeInactiveTrackColor,
      fontSizeIconSize: fontSizeIconSize ?? this.fontSizeIconSize,
    );
  }

  factory TafsirStyle.defaults(
      {required bool isDark, required BuildContext context}) {
    final bg = AppColors.getBackgroundColor(isDark);
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final onBg = isDark ? Colors.white : Colors.black87;
    final titleOnBg = primary;

    // أسماء افتراضية نصية
    const defaultTafsirName = 'التفسير';
    const defaultTranslateName = 'الترجمة';
    const defaultFootnotesName = 'الحواشي';
    const defaultEmptyNote = '\n\nتفسير هذه الآية في الأيات السابقة';

    return TafsirStyle(
      // الألوان العامة
      backgroundColor: bg,
      textColor: onBg,
      tafsirBackgroundColor: isDark ? const Color(0xFF151515) : Colors.white,
      dividerColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,

      // العناوين والشريط العلوي
      textTitleColor: Colors.white,
      backgroundTitleColor: primary,
      currentTafsirColor: primary,

      // ألوان عناصر الاختيار للقوائم/الأزرار داخل شاشة التفسير
      selectedTafsirColor: primary.withValues(alpha: .10),
      unSelectedTafsirColor:
          isDark ? const Color(0xFF1F1F1F) : Colors.transparent,
      selectedTafsirTextColor: onBg,
      unSelectedTafsirTextColor: onBg,
      selectedTafsirBorderColor: primary,
      unSelectedTafsirBorderColor: primary.withValues(alpha: 0.3),
      changeTafsirDialogHeight: MediaQuery.of(context).size.height * 0.7,
      changeTafsirDialogWidth: MediaQuery.of(context).size.width * 0.9,

      // النصوص والأحجام
      fontSize: 18.0,
      footnotesName: defaultFootnotesName,
      tafsirIsEmptyNote: defaultEmptyNote,

      // الهوامش
      horizontalMargin: 0.0,
      verticalMargin: 0.0,

      // الحجم المقترح للـ BottomSheet
      heightOfBottomSheet: MediaQuery.of(context).size.height * 0.9,
      widthOfBottomSheet: null, // MediaQuery.of(context).size.width,

      // الأسماء
      translateName: defaultTranslateName,
      tafsirName: defaultTafsirName,

      // ودجت اسم التفسير
      tafsirNameWidget: Text(
        defaultTafsirName,
        style: QuranLibrary().cairoStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleOnBg,
            ),
      ),

      // ودجت تغيير الخط
      fontSizeWidget: const SizedBox().fontSizeDropDown(
        height: 30.0,
        isDark: isDark,
      ),

      fontSizeIconWidget: Semantics(
        button: true,
        enabled: true,
        label: 'Change Font Size',
        child: Icon(
          Icons.text_format_outlined,
          size: 34,
          color: AppColors.getTextColor(isDark),
        ),
      ),
      fontSizeBackgroundColor: primary,
      fontSizeThumbColor: Colors.white,
      fontSizeActiveTrackColor: Colors.white,
      fontSizeInactiveTrackColor: primary.withValues(alpha: 0.5),
      fontSizeIconSize: 34.0,
    );
  }
}
