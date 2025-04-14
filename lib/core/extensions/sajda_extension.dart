part of '../../quran.dart';

/// An extension on the [Widget] class to provide additional functionality
/// related to Sajda (prostration) in the context of the Quran library.
///
/// This extension can be used to add custom behaviors or properties to
/// widgets that are specific to Sajda.
extension SajdaExtension on Widget {
  /// Displays a Sajda widget.
  ///
  /// This function takes the current build context, a page index, and a Sajda name,
  /// and returns a widget that shows the Sajda.
  ///
  /// - Parameters:
  ///   - context: The current build context.
  ///   - pageIndex: The index of the page where the Sajda is located.
  ///   - sajdaName: The name of the Sajda to be displayed.
  ///
  /// - Returns: A widget that displays the Sajda.
  Widget showSajda(context, int pageIndex, String sajdaName) {
    // log('checking sajda posision');
    QuranCtrl.instance.getAyahWithSajdaInPage(pageIndex);
    return QuranCtrl.instance.state.isSajda.value
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(_AssetsPath().sajdaIcon,
                      height: 15,
                      colorFilter: ColorFilter.mode(
                          const Color(0xff77554B), BlendMode.srcIn)),
                  const SizedBox(width: 8.0),
                  Text(
                    sajdaName,
                    style: TextStyle(
                      color: const Color(0xff77554B),
                      fontFamily: 'kufi',
                      fontSize: MediaQuery.orientationOf(context) ==
                              Orientation.portrait
                          ? 13.0
                          : 18.0,
                      package: 'quran_library',
                    ),
                  )
                ],
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}
