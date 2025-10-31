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
  });

  factory TafsirStyle.defaults(
      {required bool isDark, required BuildContext context}) {
    final bg = AppColors.getBackgroundColor(isDark);
    final onBg = isDark ? Colors.white : Colors.black87;
    final titleOnBg = isDark ? Colors.white : Colors.white;

    // أسماء افتراضية نصية
    const defaultTafsirName = 'التفسير';
    const defaultTranslateName = 'الترجمة';
    const defaultFootnotesName = 'الحواشي';
    const defaultEmptyNote = 'لا يوجد تفسير متاح';

    return TafsirStyle(
      // الألوان العامة
      backgroundColor: bg,
      textColor: onBg,
      tafsirBackgroundColor: isDark ? const Color(0xFF151515) : Colors.white,
      dividerColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,

      // العناوين والشريط العلوي
      textTitleColor: titleOnBg,
      backgroundTitleColor: Colors.teal,
      currentTafsirColor: Colors.teal,

      // ألوان عناصر الاختيار للقوائم/الأزرار داخل شاشة التفسير
      selectedTafsirColor: Colors.teal.withValues(alpha: .10),
      unSelectedTafsirColor:
          isDark ? const Color(0xFF1F1F1F) : Colors.transparent,
      selectedTafsirTextColor: onBg,
      unSelectedTafsirTextColor: onBg,
      selectedTafsirBorderColor: Colors.teal,
      unSelectedTafsirBorderColor: Colors.teal.withValues(alpha: 0.3),
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
      widthOfBottomSheet: MediaQuery.of(context).size.width,

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
    );
  }
}
