part of '/quran.dart';

class DefaultFirstTwoSurahs extends StatelessWidget {
  const DefaultFirstTwoSurahs({
    super.key,
    required this.surahNumber,
    required this.quranCtrl,
    required this.pageIndex,
    required this.bannerStyle,
    required this.isDark,
    required this.surahNameStyle,
    required this.surahInfoStyle,
    required this.onSurahBannerPress,
    required this.basmalaStyle,
    required this.deviceSize,
    required this.onAyahLongPress,
    required this.bookmarksColor,
    required this.textColor,
    required this.bookmarkList,
    required this.ayahSelectedBackgroundColor,
    required this.onPagePress,
    required this.ayahBookmarked,
    required this.anotherMenuChild,
    required this.anotherMenuChildOnTap,
    required this.secondMenuChild,
    required this.secondMenuChildOnTap,
    required this.context,
  });

  final int? surahNumber;
  final QuranCtrl quranCtrl;
  final int pageIndex;
  final BannerStyle? bannerStyle;
  final bool isDark;
  final SurahNameStyle? surahNameStyle;
  final SurahInfoStyle? surahInfoStyle;
  final Function(SurahNamesModel surah)? onSurahBannerPress;
  final BasmalaStyle? basmalaStyle;
  final Size deviceSize;
  final Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;
  final Color? bookmarksColor;
  final Color? textColor;
  final List? bookmarkList;
  final Color? ayahSelectedBackgroundColor;
  final VoidCallback? onPagePress;
  final List<int> ayahBookmarked;
  final Widget? anotherMenuChild;
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;
  final Widget? secondMenuChild;
  final void Function(AyahModel ayah)? secondMenuChildOnTap;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      height: isLandscape
          ? MediaQuery.sizeOf(context).height
          : MediaQuery.sizeOf(context).height * .63,
      padding: EdgeInsets.symmetric(
          vertical: UiHelper.currentOrientation(
              MediaQuery.sizeOf(context).width * .16,
              MediaQuery.sizeOf(context).height * .01,
              context),
          horizontal: UiHelper.currentOrientation(0.0, 0.0, context)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SurahHeaderWidget(
            surahNumber ??
                quranCtrl.staticPages[pageIndex].ayahs[0].surahNumber!,
            bannerStyle: bannerStyle ??
                BannerStyle(
                  isImage: false,
                  bannerSvgPath: isDark
                      ? AssetsPath.assets.surahSvgBannerDark
                      : AssetsPath.assets.surahSvgBanner,
                  bannerSvgHeight: 40.0,
                  bannerSvgWidth: 150.0,
                  bannerImagePath: '',
                  bannerImageHeight: 50,
                  bannerImageWidth: double.infinity,
                ),
            surahNameStyle: surahNameStyle ??
                SurahNameStyle(
                  surahNameWidth: 70,
                  surahNameHeight: 30,
                  surahNameColor: isDark ? Colors.white : Colors.black,
                ),
            surahInfoStyle: surahInfoStyle ??
                SurahInfoStyle(
                  ayahCount: 'عدد الآيات',
                  secondTabText: 'عن السورة',
                  firstTabText: 'أسماء السورة',
                  backgroundColor: isDark
                      ? const Color(0xff1E1E1E)
                      : const Color(0xfffaf7f3),
                  closeIconColor: isDark ? Colors.white : Colors.black,
                  indicatorColor: Colors.amber.withValues(alpha: .2),
                  primaryColor: Colors.amber.withValues(alpha: .2),
                  surahNameColor: isDark ? Colors.white : Colors.black,
                  surahNumberColor: isDark ? Colors.white : Colors.black,
                  textColor: isDark ? Colors.white : Colors.black,
                  titleColor: isDark ? Colors.white : Colors.black,
                ),
            onSurahBannerPress: onSurahBannerPress,
            isDark: isDark,
          ),
          if (pageIndex == 1)
            BasmallahWidget(
              surahNumber:
                  quranCtrl.staticPages[pageIndex].ayahs[0].surahNumber!,
              basmalaStyle: basmalaStyle ??
                  BasmalaStyle(
                    basmalaColor: isDark ? Colors.white : Colors.black,
                    basmalaWidth: 160.0,
                    basmalaHeight: 30.0,
                  ),
            ),
          ...quranCtrl.staticPages[pageIndex].lines.map((line) {
            return RepaintBoundary(
              child: FittedBox(
                fit: BoxFit.fitWidth,
                child: GetBuilder<BookmarksCtrl>(
                  builder: (bookmarkCtrl) {
                    return Column(
                      children: [
                        SizedBox(
                          width: deviceSize.width,
                          // width: deviceSize.width - 32,
                          child: DefaultFontsBuild(
                            context,
                            line,
                            isDark: isDark,
                            bookmarkCtrl.bookmarksAyahs,
                            bookmarkCtrl.bookmarks,
                            boxFit: BoxFit.scaleDown,
                            onDefaultAyahLongPress: onAyahLongPress,
                            bookmarksColor: bookmarksColor,
                            textColor: textColor ??
                                (isDark ? Colors.white : Colors.black),
                            bookmarkList: bookmarkList,
                            pageIndex: pageIndex,
                            ayahSelectedBackgroundColor:
                                ayahSelectedBackgroundColor,
                            onPagePress: onPagePress,
                            ayahBookmarked: ayahBookmarked,
                            anotherMenuChild: anotherMenuChild,
                            anotherMenuChildOnTap: anotherMenuChildOnTap,
                            secondMenuChild: secondMenuChild,
                            secondMenuChildOnTap: secondMenuChildOnTap,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
