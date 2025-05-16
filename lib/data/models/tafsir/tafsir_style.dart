part of '../../../quran.dart';

class TafsirStyle {
  final Widget? tafsirNameWidget;
  final Widget? fontSizeWidget;
  final String? translateName;
  final Color? linesColor;
  final Color? selectedTafsirColor;
  final Color? unSelectedTafsirColor;
  final Color? backgroundColor;
  final Color? textColor;

  TafsirStyle({
    this.backgroundColor,
    this.textColor,
    this.fontSizeWidget,
    this.tafsirNameWidget,
    this.translateName,
    this.linesColor,
    this.selectedTafsirColor,
    this.unSelectedTafsirColor,
  });
}
