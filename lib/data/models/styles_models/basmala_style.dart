part of '../../../quran.dart';

/// A class that represents the style for Basmala text in the application.
///
/// This class can be used to define and manage the styling properties
/// for the Basmala text, such as font size, color, and other text attributes.
class BasmalaStyle {
  ///[basmalaColor] If you wanna change the color for the basmalah.
  final Color? basmalaColor;

  ///[basmalaWidth] If you wanna change the width for the basmalah.
  final double? basmalaWidth;

  ///[basmalaHeight] If you wanna change the height for the basmalah.
  final double? basmalaHeight;

  /// A class that defines the style for the Basmala.
  ///
  /// The Basmala is the phrase "Bismillah" which is often used in Islamic texts.
  /// This class allows customization of the Basmala's color, width, and height.
  ///
  /// Example usage:
  /// ```dart
  /// BasmalaStyle(
  ///   basmalaColor: Colors.black,
  ///   basmalaWidth: 100.0,
  ///   basmalaHeight: 50.0,
  /// );
  /// ```
  ///
  /// Properties:
  /// - `basmalaColor`: The color of the Basmala.
  /// - `basmalaWidth`: The width of the Basmala.
  /// - `basmalaHeight`: The height of the Basmala.
  BasmalaStyle({
    this.basmalaColor,
    this.basmalaWidth,
    this.basmalaHeight,
  });
}
