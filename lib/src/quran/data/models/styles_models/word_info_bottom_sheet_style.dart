part of '/quran.dart';

/// Style configuration for Word Info bottom sheet.
///
/// This matches the pattern used across the library styles:
/// - nullable fields for overrides
/// - `copyWith` for partial updates
/// - `defaults` factory based on `isDark` + `context`
class WordInfoBottomSheetStyle {
  // Sheet container
  final Color? backgroundColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Bottom sheet constraints as factors of screen size.
  ///
  /// Example: `maxHeightFactor = 0.9` means max height is 90% of screen height.
  final double? maxHeightFactor;
  final double? maxWidthFactor;

  // Drag handle
  final double? handleWidth;
  final double? handleHeight;
  final EdgeInsetsGeometry? handleMargin;
  final double? handleBorderRadius;
  final Color? handleColor;

  // Title
  final String? titleText;
  final TextStyle? titleTextStyle;
  final EdgeInsetsGeometry? titlePadding;

  // Tabs
  final TextStyle? tabLabelStyle;
  final EdgeInsetsGeometry? tabIndicatorPadding;
  final double? tabIndicatorRadius;
  final Color? tabIndicatorColor;
  final double? dividerHeight;

  // Content
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? bodyTextStyle;
  final TextStyle? buttonTextStyle;
  final TextStyle? progressTextStyle;

  // Inner tab container (content card)
  final double? verticalMargin;
  final double? horizontalMargin;
  final EdgeInsetsGeometry? innerContainerPadding;
  final Color? tafsirBackgroundColor;
  final Color? textBackgroundColor;
  final double? innerContainerBorderRadius;
  final Color? innerShadowColor;
  final double? innerShadowBlurRadius;
  final Offset? innerShadowOffset;
  final Color? innerBorderColor;
  final double? innerBorderWidth;

  const WordInfoBottomSheetStyle({
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.maxHeightFactor,
    this.maxWidthFactor,
    this.handleWidth,
    this.handleHeight,
    this.handleMargin,
    this.handleBorderRadius,
    this.handleColor,
    this.titleText,
    this.titleTextStyle,
    this.titlePadding,
    this.tabLabelStyle,
    this.tabIndicatorPadding,
    this.tabIndicatorRadius,
    this.tabIndicatorColor,
    this.dividerHeight,
    this.contentPadding,
    this.bodyTextStyle,
    this.buttonTextStyle,
    this.progressTextStyle,
    this.verticalMargin,
    this.horizontalMargin,
    this.innerContainerPadding,
    this.tafsirBackgroundColor,
    this.innerContainerBorderRadius,
    this.innerShadowColor,
    this.innerShadowBlurRadius,
    this.innerShadowOffset,
    this.innerBorderColor,
    this.innerBorderWidth,
    this.textBackgroundColor,
  });

  WordInfoBottomSheetStyle copyWith({
    Color? backgroundColor,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    double? maxHeightFactor,
    double? maxWidthFactor,
    double? handleWidth,
    double? handleHeight,
    EdgeInsetsGeometry? handleMargin,
    double? handleBorderRadius,
    Color? handleColor,
    String? titleText,
    TextStyle? titleTextStyle,
    EdgeInsetsGeometry? titlePadding,
    TextStyle? tabLabelStyle,
    EdgeInsetsGeometry? tabIndicatorPadding,
    double? tabIndicatorRadius,
    Color? tabIndicatorColor,
    double? dividerHeight,
    EdgeInsetsGeometry? contentPadding,
    TextStyle? bodyTextStyle,
    TextStyle? buttonTextStyle,
    TextStyle? progressTextStyle,
    double? verticalMargin,
    double? horizontalMargin,
    EdgeInsetsGeometry? innerContainerPadding,
    Color? tafsirBackgroundColor,
    double? innerContainerBorderRadius,
    Color? innerShadowColor,
    double? innerShadowBlurRadius,
    Offset? innerShadowOffset,
    Color? innerBorderColor,
    double? innerBorderWidth,
    Color? textBackgroundColor,
  }) {
    return WordInfoBottomSheetStyle(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        borderRadius: borderRadius ?? this.borderRadius,
        padding: padding ?? this.padding,
        maxHeightFactor: maxHeightFactor ?? this.maxHeightFactor,
        maxWidthFactor: maxWidthFactor ?? this.maxWidthFactor,
        handleWidth: handleWidth ?? this.handleWidth,
        handleHeight: handleHeight ?? this.handleHeight,
        handleMargin: handleMargin ?? this.handleMargin,
        handleBorderRadius: handleBorderRadius ?? this.handleBorderRadius,
        handleColor: handleColor ?? this.handleColor,
        titleText: titleText ?? this.titleText,
        titleTextStyle: titleTextStyle ?? this.titleTextStyle,
        titlePadding: titlePadding ?? this.titlePadding,
        tabLabelStyle: tabLabelStyle ?? this.tabLabelStyle,
        tabIndicatorPadding: tabIndicatorPadding ?? this.tabIndicatorPadding,
        tabIndicatorRadius: tabIndicatorRadius ?? this.tabIndicatorRadius,
        tabIndicatorColor: tabIndicatorColor ?? this.tabIndicatorColor,
        dividerHeight: dividerHeight ?? this.dividerHeight,
        contentPadding: contentPadding ?? this.contentPadding,
        bodyTextStyle: bodyTextStyle ?? this.bodyTextStyle,
        buttonTextStyle: buttonTextStyle ?? this.buttonTextStyle,
        progressTextStyle: progressTextStyle ?? this.progressTextStyle,
        verticalMargin: verticalMargin ?? this.verticalMargin,
        horizontalMargin: horizontalMargin ?? this.horizontalMargin,
        innerContainerPadding:
            innerContainerPadding ?? this.innerContainerPadding,
        tafsirBackgroundColor:
            tafsirBackgroundColor ?? this.tafsirBackgroundColor,
        innerContainerBorderRadius:
            innerContainerBorderRadius ?? this.innerContainerBorderRadius,
        innerShadowColor: innerShadowColor ?? this.innerShadowColor,
        innerShadowBlurRadius:
            innerShadowBlurRadius ?? this.innerShadowBlurRadius,
        innerShadowOffset: innerShadowOffset ?? this.innerShadowOffset,
        innerBorderColor: innerBorderColor ?? this.innerBorderColor,
        innerBorderWidth: innerBorderWidth ?? this.innerBorderWidth,
        textBackgroundColor: textBackgroundColor ?? this.textBackgroundColor);
  }

  factory WordInfoBottomSheetStyle.defaults({
    required bool isDark,
    required BuildContext context,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = AppColors.getTextColor(isDark);

    const fontFamily = 'cairo';

    return WordInfoBottomSheetStyle(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      maxHeightFactor: 0.9,
      maxWidthFactor: 1.0,
      handleWidth: 60,
      handleHeight: 5,
      handleMargin: const EdgeInsets.only(bottom: 8),
      handleBorderRadius: 3,
      handleColor: Colors.grey.shade500,
      titleText: 'عن الكلمة',
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontFamily: fontFamily,
        package: 'quran_library',
      ),
      titlePadding: EdgeInsets.zero,
      tabLabelStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontFamily: fontFamily,
        package: 'quran_library',
      ),
      tabIndicatorPadding: const EdgeInsets.all(4),
      tabIndicatorRadius: 10,
      tabIndicatorColor: scheme.primary.withValues(alpha: 0.2),
      dividerHeight: 1,
      contentPadding: const EdgeInsets.all(16),
      bodyTextStyle: TextStyle(
        fontSize: 14,
        color: textColor,
        fontFamily: fontFamily,
        package: 'quran_library',
      ),
      buttonTextStyle: TextStyle(
        fontSize: 14,
        color: textColor,
        fontFamily: fontFamily,
        package: 'quran_library',
      ),
      progressTextStyle: TextStyle(
        fontSize: 14,
        color: textColor,
        fontFamily: fontFamily,
        package: 'quran_library',
      ),
      verticalMargin: 8,
      horizontalMargin: 8,
      innerContainerPadding: const EdgeInsets.all(0),
      tafsirBackgroundColor: AppColors.getBackgroundColor(isDark),
      innerContainerBorderRadius: 16,
      innerShadowColor: Colors.grey.withValues(alpha: 0.1),
      innerShadowBlurRadius: 8,
      innerShadowOffset: const Offset(0, 0),
      innerBorderColor: Colors.grey.withValues(alpha: 0.3),
      innerBorderWidth: 1.2,
      textBackgroundColor: isDark ? const Color(0xFF151515) : Colors.white,
    );
  }
}
