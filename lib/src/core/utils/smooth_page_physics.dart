import 'package:flutter/material.dart';

/// شرح: فئة مخصصة لتحسين فيزياء السكرول في PageView
/// Explanation: Custom class to improve scrolling physics in PageView
class SmoothPageScrollPhysics extends PageScrollPhysics {
  const SmoothPageScrollPhysics({super.parent});

  @override
  SmoothPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        // شرح: تقليل الكتلة لتحسين الاستجابة
        // Explanation: Reduce mass for better responsiveness
        mass: 50,
        // شرح: تقليل الصلابة لسكرول أكثر سلاسة
        // Explanation: Reduce stiffness for smoother scrolling
        stiffness: 100,
        // شرح: زيادة التخميد لتقليل الاهتزاز
        // Explanation: Increase damping to reduce oscillation
        damping: 0.8,
      );

  @override
  double get minFlingVelocity => 50.0; // pixels/second

  @override
  double get maxFlingVelocity => 8000.0; // pixels/second
}
