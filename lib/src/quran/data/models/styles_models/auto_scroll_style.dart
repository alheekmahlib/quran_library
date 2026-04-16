part of '/quran.dart';

/// نمط تخصيص مظهر السكرول التلقائي
///
/// [AutoScrollStyle] Style customization for the auto-scroll overlay
class AutoScrollStyle {
  final Color? sliderActiveColor;
  final Color? sliderInactiveColor;
  final Color? sliderThumbColor;
  final Color? overlayBackgroundColor;
  final Color? iconColor;
  final Color? activeIconColor;
  final Color? textColor;
  final Color? chipSelectedColor;
  final Color? chipUnselectedColor;
  final double? borderRadius;
  final TextStyle? labelStyle;
  final TextStyle? speedLabelStyle;

  const AutoScrollStyle({
    this.sliderActiveColor,
    this.sliderInactiveColor,
    this.sliderThumbColor,
    this.overlayBackgroundColor,
    this.iconColor,
    this.activeIconColor,
    this.textColor,
    this.chipSelectedColor,
    this.chipUnselectedColor,
    this.borderRadius,
    this.labelStyle,
    this.speedLabelStyle,
  });

  factory AutoScrollStyle.defaults(
      {required bool isDark, required BuildContext context}) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    return AutoScrollStyle(
      sliderActiveColor: primary,
      sliderInactiveColor: primary.withValues(alpha: .3),
      sliderThumbColor: primary,
      overlayBackgroundColor:
          AppColors.getBackgroundColor(isDark).withValues(alpha: .92),
      iconColor: AppColors.getTextColor(isDark),
      activeIconColor: primary,
      textColor: AppColors.getTextColor(isDark),
      chipSelectedColor: primary.withValues(alpha: .15),
      chipUnselectedColor: Colors.transparent,
      borderRadius: 16,
      labelStyle: TextStyle(
        fontSize: 13,
        fontFamily: 'cairo',
        color: AppColors.getTextColor(isDark),
        package: 'quran_library',
      ),
      speedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        fontFamily: 'cairo',
        color: primary,
        package: 'quran_library',
      ),
    );
  }
}

/// InheritedWidget for [AutoScrollStyle] injection
class AutoScrollTheme extends InheritedWidget {
  final AutoScrollStyle style;

  const AutoScrollTheme({
    super.key,
    required this.style,
    required super.child,
  });

  static AutoScrollTheme? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AutoScrollTheme>();

  @override
  bool updateShouldNotify(AutoScrollTheme oldWidget) =>
      style != oldWidget.style;
}
