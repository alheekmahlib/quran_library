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
    required this.ayahBookmarked,
    required this.anotherMenuChild,
    required this.anotherMenuChildOnTap,
    required this.secondMenuChild,
    required this.secondMenuChildOnTap,
    required this.context,
    required this.constraints,
    required this.ayahLongClickStyle,
    this.tafsirStyle,
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
  final List<int> ayahBookmarked;
  final Widget? anotherMenuChild;
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;
  final Widget? secondMenuChild;
  final void Function(AyahModel ayah)? secondMenuChildOnTap;
  final BuildContext context;
  final BoxConstraints constraints;
  final AyahLongClickStyle? ayahLongClickStyle;
  final TafsirStyle? tafsirStyle;

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
                final surahNum = quranCtrl
                    .getSurahDataByAyahUQ(line.ayahs[0].ayahUQNumber)
                    .surahNumber;
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
                                  bannerSvgHeight: Responsive.isDesktop(context)
                                      ? 90.0.h.clamp(90, 150)
                                      : 35.0.h.clamp(35, 90),
                                  bannerSvgWidth: 150.0.w.clamp(150, 250),
                                  bannerImagePath: '',
                                  bannerImageHeight: 50,
                                  bannerImageWidth: double.infinity,
                                ),
                            surahNameStyle: surahNameStyle ??
                                SurahNameStyle(
                                  surahNameSize: Responsive.isDesktop(context)
                                      ? 40.sp.clamp(40, 80)
                                      : 27.sp.clamp(27, 64),
                                  surahNameColor:
                                      isDark ? Colors.white : Colors.black,
                                ),
                            surahInfoStyle: surahInfoStyle ??
                                SurahInfoStyle.defaults(
                                    isDark: isDark, context: context),
                            onSurahBannerPress: onSurahBannerPress,
                            isDark: isDark,
                          ),
                        if (firstAyah && (line.ayahs[0].surahNumber != 9))
                          BasmallahWidget(
                            surahNumber: surahNum,
                            basmalaStyle: basmalaStyle ??
                                BasmalaStyle(
                                  basmalaColor:
                                      isDark ? Colors.white : Colors.black,
                                  basmalaFontSize: 50.0,
                                  verticalPadding: 8.0,
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
                              0.98 /
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
                            ayahBookmarked: ayahBookmarked,
                            anotherMenuChild: anotherMenuChild,
                            anotherMenuChildOnTap: anotherMenuChildOnTap,
                            secondMenuChild: secondMenuChild,
                            secondMenuChildOnTap: secondMenuChildOnTap,
                            ayahLongClickStyle: ayahLongClickStyle ??
                                AyahLongClickStyle.defaults(
                                    isDark: isDark, context: context),
                            tafsirStyle: tafsirStyle,
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
