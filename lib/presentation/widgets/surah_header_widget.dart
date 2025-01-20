part of '../pages/quran_library_screen.dart';

class SurahHeaderWidget extends StatelessWidget {
  SurahHeaderWidget(
    this.surahNumber, {
    super.key,
    this.bannerStyle,
    this.surahNameStyle,
    this.onSurahBannerPress,
    this.surahInfoStyle,
  });

  final int surahNumber;
  final BannerStyle? bannerStyle;
  final SurahNameStyle? surahNameStyle;
  final Function? onSurahBannerPress;
  final SurahInfoStyle? surahInfoStyle;

  final quranCtrl = QuranCtrl.instance;

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.sizeOf(context);
    if (bannerStyle!.isImage ?? false) {
      return GestureDetector(
        onTap: () {
          if (onSurahBannerPress != null) {
            onSurahBannerPress!();
          } else {
            surahInfoDialogWidget(context, surahNumber - 1,
                surahStyle: surahInfoStyle!, deviceWidth: deviceWidth);
          }
        },
        child: Container(
          height: bannerStyle!.bannerImageHeight ?? 50.0,
          width: bannerStyle!.bannerImageWidth ?? double.infinity,
          margin: EdgeInsets.symmetric(
              vertical: quranCtrl.state.fontsSelected.value ? 8.0 : 16.0),
          padding: const EdgeInsets.symmetric(vertical: 0.0),
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage(bannerStyle!.bannerImagePath ??
                    AssetsPath().surahSvgBanner),
                fit: BoxFit.fill),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'packages/quran_library/lib/assets/svg/surah_name/00$surahNumber.svg',
            width: surahNameStyle!.surahNameWidth ?? 70,
            height: surahNameStyle!.surahNameHeight ?? 37,
            colorFilter: ColorFilter.mode(
                surahNameStyle!.surahNameColor ?? Colors.black,
                BlendMode.srcIn),
          ),
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
              vertical: quranCtrl.state.fontsSelected.value ? 0.0 : 16.0),
          child: GestureDetector(
            onTap: () {
              if (onSurahBannerPress != null) {
                onSurahBannerPress!();
              } else {
                surahInfoDialogWidget(context, surahNumber - 1,
                    surahStyle: surahInfoStyle!, deviceWidth: deviceWidth);
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  bannerStyle!.bannerSvgPath ?? AssetsPath().surahSvgBanner,
                  width: bannerStyle!.bannerSvgWidth ?? 150.0,
                  height: bannerStyle!.bannerSvgHeight ?? 40.0,
                ),
                SvgPicture.asset(
                  'packages/quran_library/lib/assets/svg/surah_name/00$surahNumber.svg',
                  width: surahNameStyle!.surahNameWidth ?? 70,
                  height: surahNameStyle!.surahNameHeight ?? 37,
                  colorFilter: ColorFilter.mode(
                      surahNameStyle!.surahNameColor ?? Colors.black,
                      BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
