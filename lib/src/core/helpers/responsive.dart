import 'package:flutter/material.dart';

// We will modify it once we have our final design

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? mobileLarge;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.mobileLarge,
  });

  static bool isMobile(BuildContext context) =>
      MediaQueryData.fromView(View.of(context)).size.width <= 400;

  static bool isMobileLarge(BuildContext context) =>
      MediaQueryData.fromView(View.of(context)).size.width <= 465;

  static bool isTablet(BuildContext context) =>
      MediaQueryData.fromView(View.of(context)).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQueryData.fromView(View.of(context)).size.width >= 1024;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQueryData.fromView(View.of(context)).size;
    if (size.width >= 1024) {
      return desktop;
    } else if (size.width >= 700 && tablet != null) {
      return tablet!;
    } else if (size.width >= 500 && mobileLarge != null) {
      return mobileLarge!;
    } else {
      return mobile;
    }
  }
}
