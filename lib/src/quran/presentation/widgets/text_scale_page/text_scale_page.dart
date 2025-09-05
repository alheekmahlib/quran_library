part of '/quran.dart';

class _QuranTextScale extends StatelessWidget {
  _QuranTextScale({
    required this.context,
    required this.pageIndex,
    this.bookmarkList,
    this.basmalaStyle,
    this.surahNumber,
    this.surahInfoStyle,
    this.surahNameStyle,
    this.bannerStyle,
    this.onSurahBannerPress,
    this.onAyahLongPress,
    this.onPagePress,
    this.bookmarksColor,
    this.textColor,
    this.ayahIconColor,
    this.showAyahBookmarkedIcon = true,
    required this.bookmarks,
    required this.bookmarksAyahs,
    this.ayahSelectedBackgroundColor,
    this.languageCode,
    this.circularProgressWidget,
    required this.isDark,
    required this.ayahBookmarked,
    this.anotherMenuChild,
    this.anotherMenuChildOnTap,
    this.secondMenuChild,
    this.secondMenuChildOnTap,
  });

  final quranCtrl = QuranCtrl.instance;
  final BuildContext context;
  final int pageIndex;
  final List? bookmarkList;
  final BasmalaStyle? basmalaStyle;
  final int? surahNumber;
  final SurahInfoStyle? surahInfoStyle;
  final SurahNameStyle? surahNameStyle;
  final BannerStyle? bannerStyle;
  final List<int> ayahBookmarked;
  final Function(SurahNamesModel surah)? onSurahBannerPress;
  final Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;
  final VoidCallback? onPagePress;
  final Color? bookmarksColor;
  final Color? textColor;
  final Color? ayahIconColor;
  final Map<int, List<BookmarkModel>> bookmarks;
  final List<int> bookmarksAyahs;
  final Color? ayahSelectedBackgroundColor;
  final String? languageCode;
  final Widget? circularProgressWidget;
  final bool isDark;
  final bool showAyahBookmarkedIcon;
  final Widget? anotherMenuChild;
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;
  final Widget? secondMenuChild;
  final void Function(AyahModel ayah)? secondMenuChildOnTap;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<QuranCtrl>(
      builder: (quranCtrl) => GestureDetector(
        onTap: () {
          if (onPagePress != null) {
            onPagePress!();
          }
          quranCtrl.isShowControl.toggle();
          quranCtrl.clearSelection();
          quranCtrl.state.overlayEntry?.remove();
          quranCtrl.state.overlayEntry = null;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: quranCtrl.state.pages.isEmpty
              ? circularProgressWidget ?? CircularProgressIndicator.adaptive()
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      quranCtrl
                          .getCurrentPageAyahsSeparatedForBasmalah(pageIndex)
                          .length,
                      (i) {
                        final ayahs =
                            quranCtrl.getCurrentPageAyahsSeparatedForBasmalah(
                                pageIndex)[i];
                        return Column(
                          children: [
                            ayahs.first.ayahNumber == 1 &&
                                    (!quranCtrl._topOfThePageIndex
                                            .contains(pageIndex) ||
                                        quranCtrl.state.fontsSelected.value ==
                                            0)
                                ? SurahHeaderWidget(
                                    surahNumber ??
                                        quranCtrl
                                            .getSurahDataByAyah(ayahs.first)
                                            .surahNumber,
                                    bannerStyle: bannerStyle ??
                                        BannerStyle(
                                          isImage: false,
                                          bannerSvgPath: isDark
                                              ? AssetsPath
                                                  .assets.surahSvgBannerDark
                                              : AssetsPath
                                                  .assets.surahSvgBanner,
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
                                          surahNameColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                    surahInfoStyle: surahInfoStyle ??
                                        SurahInfoStyle(
                                          ayahCount: 'عدد الآيات',
                                          secondTabText: 'عن السورة',
                                          firstTabText: 'أسماء السورة',
                                          backgroundColor: isDark
                                              ? const Color(0xff1E1E1E)
                                              : const Color(0xfffaf7f3),
                                          closeIconColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          indicatorColor: Colors.amber
                                              .withValues(alpha: .2),
                                          primaryColor: Colors.amber
                                              .withValues(alpha: .2),
                                          surahNameColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          surahNumberColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          textColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          titleColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                    onSurahBannerPress: onSurahBannerPress,
                                    isDark: isDark,
                                  )
                                : const SizedBox.shrink(),
                            quranCtrl
                                            .getSurahDataByAyah(ayahs.first)
                                            .surahNumber ==
                                        9 ||
                                    quranCtrl
                                            .getSurahDataByAyah(ayahs.first)
                                            .surahNumber ==
                                        1
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: ayahs.first.ayahNumber == 1
                                        ? BasmallahWidget(
                                            surahNumber: quranCtrl
                                                .getSurahDataByAyah(ayahs.first)
                                                .surahNumber,
                                            basmalaStyle: basmalaStyle ??
                                                BasmalaStyle(
                                                  basmalaColor: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                  basmalaWidth: 160.0,
                                                  basmalaHeight: 45.0,
                                                ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                            TextScaleRichTextBuild(
                                textColor: textColor,
                                isDark: isDark,
                                ayahs: ayahs,
                                bookmarks: bookmarks,
                                pageIndex: pageIndex,
                                ayahBookmarked: ayahBookmarked,
                                onAyahLongPress: onAyahLongPress,
                                anotherMenuChild: anotherMenuChild,
                                anotherMenuChildOnTap: anotherMenuChildOnTap,
                                secondMenuChild: secondMenuChild,
                                secondMenuChildOnTap: secondMenuChildOnTap,
                                bookmarkList: bookmarkList,
                                ayahIconColor: ayahIconColor,
                                showAyahBookmarkedIcon: showAyahBookmarkedIcon,
                                bookmarksAyahs: bookmarksAyahs,
                                bookmarksColor: bookmarksColor,
                                ayahSelectedBackgroundColor:
                                    ayahSelectedBackgroundColor,
                                languageCode: languageCode),
                            quranCtrl._downThePageIndex.contains(pageIndex) &&
                                    quranCtrl.state.fontsSelected.value == 1
                                ? SurahHeaderWidget(
                                    surahNumber ??
                                        quranCtrl
                                                .getSurahDataByAyah(ayahs.first)
                                                .surahNumber +
                                            1,
                                    bannerStyle: bannerStyle ??
                                        BannerStyle(
                                          isImage: false,
                                          bannerSvgPath: isDark
                                              ? AssetsPath
                                                  .assets.surahSvgBannerDark
                                              : AssetsPath
                                                  .assets.surahSvgBanner,
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
                                          surahNameColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                    surahInfoStyle: surahInfoStyle ??
                                        SurahInfoStyle(
                                          ayahCount: 'عدد الآيات',
                                          secondTabText: 'عن السورة',
                                          firstTabText: 'أسماء السورة',
                                          backgroundColor: isDark
                                              ? const Color(0xff1E1E1E)
                                              : const Color(0xfffaf7f3),
                                          closeIconColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          indicatorColor: Colors.amber
                                              .withValues(alpha: .2),
                                          primaryColor: Colors.amber
                                              .withValues(alpha: .2),
                                          surahNameColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          surahNumberColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          textColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          titleColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                    onSurahBannerPress: onSurahBannerPress,
                                    isDark: isDark,
                                  )
                                : const SizedBox.shrink(),
                            // context.surahBannerLastPlace(pageIndex, i),
                          ],
                        );
                      },
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
