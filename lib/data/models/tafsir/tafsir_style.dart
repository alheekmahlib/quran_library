part of '../../../quran.dart';

class TafsirStyle {
  final Widget? iconCloseWidget;
  final Widget? tafsirNameWidget;
  final Widget? fontSizeWidget;
  final String? translateName;
  final Color? linesColor;
  final Color? selectedTafsirColor;
  final Color? unSelectedTafsirColor;

  TafsirStyle({
    this.fontSizeWidget,
    this.iconCloseWidget,
    this.tafsirNameWidget,
    this.translateName,
    this.linesColor,
    this.selectedTafsirColor,
    this.unSelectedTafsirColor,
  });
}
