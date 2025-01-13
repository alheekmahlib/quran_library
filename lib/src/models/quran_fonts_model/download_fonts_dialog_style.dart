import 'package:flutter/material.dart' show Color, Widget;

class DownloadFontsDialogStyle {
  final Color? backgroundColor;
  final String? title;
  final Color? titleColor;
  final String? notes;
  final Color? notesColor;
  final Color? linearProgressBackgroundColor;
  final Color? linearProgressColor;
  final Color? downloadButtonBackgroundColor;
  final Color? downloadButtonTextColor;
  final String? downloadingText;
  final String? downloadButtonText;
  final String? deleteButtonText;
  final Widget? iconWidget;
  final Color? iconColor;
  final double? iconSize;

  DownloadFontsDialogStyle({
    this.title,
    this.titleColor,
    this.notes,
    this.notesColor,
    this.linearProgressBackgroundColor,
    this.linearProgressColor,
    this.downloadButtonBackgroundColor,
    this.downloadButtonTextColor,
    this.downloadingText,
    this.downloadButtonText,
    this.deleteButtonText,
    this.backgroundColor,
    this.iconWidget,
    this.iconColor,
    this.iconSize,
  });
}
