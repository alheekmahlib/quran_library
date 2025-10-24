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
  final List<int> ayahBookmarked;
  final Widget? anotherMenuChild;
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;
  final Widget? secondMenuChild;
  final void Function(AyahModel ayah)? secondMenuChildOnTap;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height,
      padding: EdgeInsets.symmetric(
        vertical: UiHelper.currentOrientation(
            MediaQuery.sizeOf(context).width * .16,
            MediaQuery.sizeOf(context).height * .01,
            context),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SurahHeaderWidget(
            surahNumber ??
                quranCtrl.staticPages[pageIndex].ayahs[0].surahNumber!,
            bannerStyle: bannerStyle ?? BannerStyle.defaults(isDark: isDark),
            surahNameStyle: surahNameStyle ??
                SurahNameStyle(
                  surahNameSize: 27,
                  surahNameColor: isDark ? Colors.white : Colors.black,
                ),
            surahInfoStyle:
                surahInfoStyle ?? SurahInfoStyle.defaults(isDark: isDark),
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
                    verticalPadding: 0.0,
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
                          width: Responsive.isDesktop(context)
                              ? deviceSize.width - 800
                              : deviceSize.width,
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
