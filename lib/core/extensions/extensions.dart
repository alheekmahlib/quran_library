part of '../../quran.dart';

/// Extension on [BuildContext] to provide additional utility methods.
extension ContextExtensions on BuildContext {
  /// Returns the current orientation based on the provided parameters.
  ///
  /// This method takes two parameters, [n1] and [n2], and determines the
  /// current orientation. The exact behavior and return type are dynamic
  /// and depend on the implementation details.
  ///
  /// - Parameters:
  ///   - n1: The first parameter used to determine the orientation.
  ///   - n2: The second parameter used to determine the orientation.
  ///
  /// - Returns: The current orientation based on the provided parameters.
  dynamic currentOrientation(var n1, var n2) {
    Orientation orientation = MediaQuery.orientationOf(this);
    return orientation == Orientation.portrait ? n1 : n2;
  }

  /// Determines the platform and returns the appropriate value based on the provided parameters.
  ///
  /// This method takes two parameters, [p1] and [p2], and returns one of them
  /// based on the current platform. If the platform is iOS, Android, or Fuchsia,
  /// it returns [p1]. Otherwise, it returns [p2].
  ///
  /// - Parameters:
  ///   - p1: The value to return if the platform is iOS, Android, or Fuchsia.
  ///   - p2: The value to return if the platform is not iOS, Android, or Fuchsia.
  ///
  /// - Returns: The appropriate value based on the current platform.
  dynamic definePlatform(var p1, var p2) =>
      (Platform.isIOS || Platform.isAndroid || Platform.isFuchsia) ? p1 : p2;

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
