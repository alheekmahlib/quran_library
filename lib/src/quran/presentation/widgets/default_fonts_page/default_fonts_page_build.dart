part of '/quran.dart';

class DefaultFontsPageBuild extends StatelessWidget {
  const DefaultFontsPageBuild({
    super.key,
    required this.quranCtrl,
    required this.pageIndex,
    required this.newSurahs,
    required this.surahNumber,
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
    required this.constraints,
  });

  final QuranCtrl quranCtrl;
  final int pageIndex;
  final List<String> newSurahs;
  final int? surahNumber;
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
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: Column(
          children: [
            ...quranCtrl.staticPages[pageIndex].lines.map(
              (line) {
                bool firstAyah = false;
                if (line.ayahs[0].ayahNumber == 1 &&
                    !newSurahs.contains(line.ayahs[0].arabicName)) {
                  newSurahs.add(line.ayahs[0].arabicName!);
                  firstAyah = true;
                }
                return GetBuilder<BookmarksCtrl>(
                  builder: (bookmarkCtrl) {
                    return Column(
                      children: [
                        if (firstAyah)
                          SurahHeaderWidget(
                            surahNumber ?? line.ayahs[0].surahNumber!,
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
                                  surahNameHeight: 37,
                                  surahNameColor:
                                      isDark ? Colors.white : Colors.black,
                                ),
                            surahInfoStyle: surahInfoStyle ??
                                SurahInfoStyle(
                                  ayahCount: 'عدد الآيات',
                                  secondTabText: 'عن السورة',
                                  firstTabText: 'أسماء السورة',
                                  backgroundColor: isDark
                                      ? const Color(0xff1E1E1E)
                                      : const Color(0xfffaf7f3),
                                  closeIconColor:
                                      isDark ? Colors.white : Colors.black,
                                  indicatorColor:
                                      Colors.amber.withValues(alpha: .2),
                                  primaryColor:
                                      Colors.amber.withValues(alpha: .2),
                                  surahNameColor:
                                      isDark ? Colors.white : Colors.black,
                                  surahNumberColor:
                                      isDark ? Colors.white : Colors.black,
                                  textColor:
                                      isDark ? Colors.white : Colors.black,
                                  titleColor:
                                      isDark ? Colors.white : Colors.black,
                                ),
                            onSurahBannerPress: onSurahBannerPress,
                            isDark: isDark,
                          ),
                        if (firstAyah && (line.ayahs[0].surahNumber != 9))
                          BasmallahWidget(
                            surahNumber: quranCtrl
                                .getSurahDataByAyahUQ(
                                    line.ayahs[0].ayahUQNumber)
                                .surahNumber,
                            basmalaStyle: basmalaStyle ??
                                BasmalaStyle(
                                  basmalaColor:
                                      isDark ? Colors.white : Colors.black,
                                  basmalaWidth: 160.0,
                                  basmalaHeight: 40.0,
                                ),
                          ),
                        SizedBox(
                          width: deviceSize.width - 20,
                          height: (UiHelper.currentOrientation(
                                      constraints.maxHeight,
                                      MediaQuery.sizeOf(context).width * 1.6,
                                      context) -
                                  (quranCtrl.staticPages[pageIndex]
                                          .numberOfNewSurahs *
                                      (line.ayahs[0].surahNumber != 9
                                          ? 110
                                          : 80))) *
                              0.97 /
                              quranCtrl.staticPages[pageIndex].lines.length,
                          child: DefaultFontsBuild(
                            context,
                            line,
                            isDark: isDark,
                            bookmarkCtrl.bookmarksAyahs,
                            bookmarkCtrl.bookmarks,
                            boxFit: line.ayahs.last.centered!
                                ? BoxFit.contain
                                : BoxFit.fill,
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
