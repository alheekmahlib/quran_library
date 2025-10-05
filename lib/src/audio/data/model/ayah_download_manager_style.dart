part of '../../audio.dart';

typedef AyahCountTextBuilder = String Function(int downloaded, int total);

class AyahDownloadManagerStyle {
  // Header
  final String? titleText;
  final TextStyle? titleTextStyle;
  final Widget? headerIcon;
  final double? surahNameSize;

  // Handle (top bar)
  final Color? handleColor;
  final double? handleWidth;
  final double? handleHeight;
  final double? handleRadius;

  // Stop/Cancel button
  final String? stopButtonText;
  final IconData? stopButtonIcon;
  final Color? stopButtonForeground;
  final Color? stopButtonBackground;

  // List/Item visuals
  final Color? separatorColor;
  final double? itemHorizontalPadding;
  final double? itemVerticalPadding;
  final TextStyle? surahTitleStyle;
  final TextStyle? surahSubtitleStyle;

  // Avatar
  final Color? avatarDownloadedColor;
  final Color? avatarUndownloadedColor;
  final TextStyle? avatarTextStyle;

  // Progress
  final Color? progressColor;
  final Color? progressBackgroundColor;
  final double? progressHeight;
  final double? progressRadius;

  // Delete action
  final String? deleteTooltipText;
  final IconData? deleteIcon;
  final Color? deleteIconColor;

  // Download action
  final String? downloadText;
  final IconData? downloadIcon;
  final String? redownloadText;
  final IconData? redownloadIcon;
  final Color? downloadForeground;
  final Color? downloadBackground;

  // Count text
  final AyahCountTextBuilder? countTextBuilder;

  const AyahDownloadManagerStyle({
    this.titleText,
    this.titleTextStyle,
    this.headerIcon,
    this.surahNameSize,
    this.handleColor,
    this.handleWidth,
    this.handleHeight,
    this.handleRadius,
    this.stopButtonText,
    this.stopButtonIcon,
    this.stopButtonForeground,
    this.stopButtonBackground,
    this.separatorColor,
    this.itemHorizontalPadding,
    this.itemVerticalPadding,
    this.surahTitleStyle,
    this.surahSubtitleStyle,
    this.avatarDownloadedColor,
    this.avatarUndownloadedColor,
    this.avatarTextStyle,
    this.progressColor,
    this.progressBackgroundColor,
    this.progressHeight,
    this.progressRadius,
    this.deleteTooltipText,
    this.deleteIcon,
    this.deleteIconColor,
    this.downloadText,
    this.downloadIcon,
    this.redownloadText,
    this.redownloadIcon,
    this.downloadForeground,
    this.downloadBackground,
    this.countTextBuilder,
  });
}
