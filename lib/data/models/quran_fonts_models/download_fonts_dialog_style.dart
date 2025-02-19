part of '../../../quran.dart';

/// A class that defines the style for the download fonts dialog.
///
/// This class can be used to customize the appearance and behavior of the
/// dialog that is shown when downloading fonts in the application.
class DownloadFontsDialogStyle {
  /// The background color of the dialog. This can be null, in which case
  /// the default background color will be used.
  final Color? backgroundColor;

  /// The text to be displayed as the title for the default font.
  final String? defaultFontText;

  /// The color of the divider in the dialog. This can be null, in which case
  /// the default color will be used.
  final Color? dividerColor;

  /// The text to be displayed as the title for the quran font.
  final String? downloadedFontsText;

  /// The background color of the download button in the dialog.
  ///
  /// This property allows you to customize the appearance of the download button
  /// by specifying a [Color]. If no color is provided, the default color will be used.
  final Color? downloadButtonBackgroundColor;

  /// The text to be displayed while the font is being downloaded.

  final String? downloadingText;

  /// The text style to be applied to the downloading text in the dialog.
  ///
  /// This style can be used to customize the appearance of the text
  /// displayed while fonts are being downloaded.
  ///
  /// If no style is provided, the default text style will be used.
  final TextStyle? downloadingStyle;

  /// The text style for displaying the font name in the download fonts dialog.
  ///
  /// This style can be customized to change the appearance of the font name text.
  ///
  /// If no style is provided, the default text style will be used.
  final TextStyle? fontNameStyle;

  /// An optional widget to display an icon in the dialog.
  ///
  /// This widget can be used to provide a custom icon for the dialog,
  /// enhancing the visual representation and user experience.
  final Widget? iconWidget;

  /// The color of the icon in the dialog.
  ///
  /// This property allows you to customize the color of the icon displayed
  /// in the download fonts dialog. If no color is provided, the default
  /// color will be used.
  final Color? iconColor;

  /// The size of the icon to be displayed in the dialog.
  ///
  /// This property is optional and can be null. If null, a default size
  /// will be used.
  final double? iconSize;

  /// The background color for the linear progress indicator in the download fonts dialog.
  ///
  /// This color is used to fill the background of the linear progress indicator.
  /// If no color is provided, the default color will be used.
  final Color? linearProgressBackgroundColor;

  /// The color of the linear progress indicator.
  ///
  /// This property is optional and can be null. If null, the default color
  /// will be used.
  final Color? linearProgressColor;

  /// Optional notes associated with the download fonts dialog style.
  final String? notes;

  /// The color used for notes in the download fonts dialog.
  ///
  /// This property is optional and can be null.
  final Color? notesColor;

  /// The text style to be applied to the notes section in the download fonts dialog.
  ///
  /// This style can be customized to change the appearance of the notes text.
  /// If no style is provided, the default text style will be used.
  final TextStyle? notesStyle;

  /// The title of the download fonts dialog.
  ///
  /// This property is optional and can be null. If null, the default title
  /// will be used.
  final String? title;

  /// The color of the title text in the download fonts dialog.
  ///
  /// This property allows you to customize the color of the title text.
  /// If no color is provided, the default color will be used.
  final Color? titleColor;

  /// The style to be applied to the title text in the download fonts dialog.
  ///
  /// This property allows you to customize the appearance of the title text,
  /// such as font size, color, weight, etc. If no style is provided, the default
  /// style will be used.
  final TextStyle? titleStyle;

  // final String? downloadedNotesBody;
  // final Color? downloadButtonTextColor;
  // final String? downloadButtonText;
  // final String? deleteButtonText;
  // final String? downloadedFontsTajweedText;
  // final String? downloadedNotesTitle;
  // final String? withTajweedText;
  // final String? withoutTajweedText;

  /// A class representing the style for the download fonts dialog.
  ///
  /// This class is used to define the visual appearance and behavior of the
  /// dialog that is shown when downloading fonts in the Quran Library.
  ///
  /// The [DownloadFontsDialogStyle] constructor allows you to create an instance
  /// of this class with specific style properties.
  DownloadFontsDialogStyle({
    this.backgroundColor,
    this.defaultFontText,
    this.dividerColor,
    this.downloadedFontsText,
    this.downloadButtonBackgroundColor,
    this.downloadingStyle,
    this.downloadingText,
    this.fontNameStyle,
    this.iconColor,
    this.iconSize,
    this.iconWidget,
    this.linearProgressBackgroundColor,
    this.linearProgressColor,
    this.notes,
    this.notesColor,
    this.notesStyle,
    this.title,
    this.titleColor,
    this.titleStyle,
  });
}
