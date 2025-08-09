import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:toastification/toastification.dart';

import '../../quran.dart';

class UiHelper {
  UiHelper._();

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
  static dynamic currentOrientation(var n1, var n2, BuildContext context) {
    Orientation orientation = MediaQuery.orientationOf(context);
    return orientation == Orientation.portrait ? n1 : n2;
  }

  static void showCustomErrorSnackBar(String text, BuildContext context,
      {bool? isDone = false}) {
    final backgroundColor = Theme.of(context).colorScheme.primaryContainer;
    final borderColor =
        Theme.of(context).colorScheme.primary.withValues(alpha: .3);
    final hintColor = Theme.of(context).hintColor;
    toastification.showCustom(
      context: context,
      builder: (context, _) {
        return Container(
          height: 50,
          decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.all(
                Radius.circular(8),
              ),
              border: Border.all(
                color: borderColor,
                width: 2,
              )),
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Opacity(
                    opacity: .8,
                    child: SvgPicture.asset(
                      isDone!
                          ? AssetsPath.assets.checkMark
                          : AssetsPath.assets.alert,
                      height: 25,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                flex: 8,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      text,
                      style: TextStyle(
                          color: hintColor, fontFamily: 'naskh', fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      autoCloseDuration: const Duration(milliseconds: 3000),
    );
  }

  static void customMobileNoteSnackBar(String text, BuildContext context) {
    toastification.showCustom(
      context: context,
      builder: (context, builder) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(8),
              )),
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Opacity(
                  opacity: .8,
                  child: SvgPicture.asset(
                    AssetsPath.assets.alert,
                    height: 25,
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 300,
                  child: Text(
                    text,
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'kufi',
                        fontStyle: FontStyle.italic,
                        fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      autoCloseDuration: const Duration(milliseconds: 3000),
    );
  }
}
