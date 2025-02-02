part of '../../quran.dart';

extension SajdaExtension on Widget {
  Widget showSajda(context, int pageIndex, String sajdaName) {
    // log('checking sajda posision');
    QuranCtrl.instance.getAyahWithSajdaInPage(pageIndex);
    return QuranCtrl.instance.state.isSajda.value
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 15,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(AssetsPath().sajdaIcon,
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
