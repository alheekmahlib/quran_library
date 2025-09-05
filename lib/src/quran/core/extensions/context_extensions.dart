part of '/quran.dart';

/// Extension on [BuildContext] to provide additional utility methods.
extension ContextExtensions on BuildContext {
  /// Creates a vertical divider widget with the specified width, height, and color.
  ///
  /// The [width] parameter specifies the width of the divider. If not provided, it defaults to a standard width.
  /// The [height] parameter specifies the height of the divider. If not provided, it defaults to a standard height.
  /// The [color] parameter specifies the color of the divider. If not provided, it defaults to a standard color.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// verticalDivider(width: 2.0, height: 50.0, color: Colors.black);
  /// ```
  ///
  /// This will create a vertical divider with a width of 2.0, height of 50.0, and black color.
  Widget verticalDivider({
    double? width,
    double? height,
    Color? color,
  }) {
    return Container(
      height: height ?? 20,
      width: width ?? 2,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      color: color ?? Colors.black,
    );
  }

  /// Creates a horizontal divider widget with the specified width, height, and color.
  ///
  /// The [width] parameter specifies the width of the divider. If null, the default width is used.
  /// The [height] parameter specifies the height of the divider. If null, the default height is used.
  /// The [color] parameter specifies the color of the divider. If null, the default color is used.
  ///
  /// Example usage:
  /// ```dart
  /// horizontalDivider(width: 100.0, height: 2.0, color: Colors.grey);
  /// ```
  Widget horizontalDivider({double? width, double? height, Color? color}) {
    return Container(
      height: height ?? 2,
      width: width ?? MediaQuery.sizeOf(this).width,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      color: color ?? Colors.black,
    );
  }
}
