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
  final Color? dividerColor;
  final double? fontSize;
  final String? footnotesName;

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
  });
}
