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
    if (bannerStyle!.isImage!) {
      return GestureDetector(
        onTap: () {
          if (onSurahBannerPress != null) {
            onSurahBannerPress!();
          } else {
            surahInfoDialogWidget(surahNumber - 1, surahInfoStyle!);
          }
        },
        child: Container(
          height: bannerStyle!.bannerImageHeight,
          width: bannerStyle!.bannerImageWidth,
          margin: EdgeInsets.symmetric(
              vertical: quranCtrl.state.fontsSelected.value ? 8.0 : 16.0),
          padding: const EdgeInsets.symmetric(vertical: 0.0),
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage(bannerStyle!.bannerImagePath!),
                fit: BoxFit.fill),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'packages/quran_library/lib/assets/svg/surah_name/00$surahNumber.svg',
            width: surahNameStyle!.surahNameWidth,
            height: surahNameStyle!.surahNameHeight,
            colorFilter: ColorFilter.mode(
                surahNameStyle!.surahNameColor, BlendMode.srcIn),
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
                surahInfoDialogWidget(surahNumber - 1, surahInfoStyle!);
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  bannerStyle!.bannerSvgPath!,
                  width: bannerStyle!.bannerSvgWidth,
                  height: bannerStyle!.bannerSvgHeight,
                ),
                SvgPicture.asset(
                  'packages/quran_library/lib/assets/svg/surah_name/00$surahNumber.svg',
                  width: surahNameStyle!.surahNameWidth,
                  height: surahNameStyle!.surahNameHeight,
                  colorFilter: ColorFilter.mode(
                      surahNameStyle!.surahNameColor, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
