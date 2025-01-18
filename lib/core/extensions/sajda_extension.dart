part of '../../presentation/pages/quran_library_screen.dart';

extension SajdaExtension on Widget {
  Widget showSajda(int pageIndex, String sajdaName) {
    log('checking sajda posision');
    QuranCtrl.instance.getAyahWithSajdaInPage(pageIndex);
    return QuranCtrl.instance.state.isSajda.value
        ? SizedBox(
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
                    fontSize: Get.context!.customOrientation(13.0, 18.0),
                    package: 'quran_library',
                  ),
                )
              ],
            ),
          )
        : const SizedBox.shrink();
  }
}
