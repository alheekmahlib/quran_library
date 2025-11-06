part of '/quran.dart';

class PageBuild extends StatelessWidget {
  const PageBuild({
    super.key,
    required this.pageIndex,
    required this.surahNumber,
    required this.bannerStyle,
    required this.isDark,
    required this.surahNameStyle,
    required this.onSurahBannerPress,
    required this.basmalaStyle,
    required this.textColor,
    required this.bookmarks,
    required this.onAyahLongPress,
    required this.secondMenuChild,
    required this.secondMenuChildOnTap,
    required this.bookmarkList,
    required this.ayahIconColor,
    required this.showAyahBookmarkedIcon,
    required this.bookmarksAyahs,
    required this.bookmarksColor,
    required this.ayahSelectedBackgroundColor,
    required this.isFontsLocal,
    required this.fontsName,
    required this.ayahBookmarked,
    required this.anotherMenuChild,
    required this.anotherMenuChildOnTap,
    required this.context,
    required this.quranCtrl,
  });

  final int pageIndex;
  final int? surahNumber;
  final BannerStyle? bannerStyle;
  final bool isDark;
  final SurahNameStyle? surahNameStyle;
  final Function(SurahNamesModel surah)? onSurahBannerPress;
  final BasmalaStyle? basmalaStyle;
  final Color? textColor;
  final Map<int, List<BookmarkModel>> bookmarks;
  final Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;
  final Widget? secondMenuChild;
  final void Function(AyahModel ayah)? secondMenuChildOnTap;
  final List? bookmarkList;
  final Color? ayahIconColor;
  final bool showAyahBookmarkedIcon;
  final List<int> bookmarksAyahs;
  final Color? bookmarksColor;
  final Color? ayahSelectedBackgroundColor;
  final bool? isFontsLocal;
  final String? fontsName;
  final List<int> ayahBookmarked;
  final Widget? anotherMenuChild;
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;
  final BuildContext context;
  final QuranCtrl quranCtrl;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: () {
            final pageAyahsGroups =
                quranCtrl.getCurrentPageAyahsSeparatedForBasmalah(pageIndex);
            return List.generate(
              pageAyahsGroups.length,
              (i) {
                final ayahs = pageAyahsGroups[i];
                final surahData = quranCtrl.getSurahDataByAyah(ayahs.first);
                return Column(
                  children: [
                    ayahs.first.ayahNumber == 1 &&
                            !quranCtrl._topOfThePageIndex.contains(pageIndex)
                        ? SurahHeaderWidget(
                            surahNumber ?? surahData.surahNumber,
                            bannerStyle: bannerStyle ?? BannerStyle(),
                            surahNameStyle: surahNameStyle ??
                                SurahNameStyle(
                                  surahNameSize: 120,
                                  surahNameColor:
                                      AppColors.getTextColor(isDark),
                                ),
                            onSurahBannerPress: onSurahBannerPress,
                            isDark: isDark,
                          )
                        : const SizedBox.shrink(),
                    surahData.surahNumber == 9 || surahData.surahNumber == 1
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ayahs.first.ayahNumber == 1
                                ? BasmallahWidget(
                                    surahNumber: surahData.surahNumber,
                                    basmalaStyle: basmalaStyle ??
                                        BasmalaStyle(
                                          basmalaColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          basmalaFontSize: 100.0,
                                        ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                    // شرح: إزالة FittedBox الداخلي لتقليل كلفة القياس المزدوج
                    // Explanation: Remove inner FittedBox to avoid double measurement cost
                    RepaintBoundary(
                      child: RichTextBuild(
                        pageIndex: pageIndex,
                        textColor: textColor,
                        isDark: isDark,
                        bookmarks: bookmarks,
                        onAyahLongPress: onAyahLongPress,
                        secondMenuChild: secondMenuChild,
                        secondMenuChildOnTap: secondMenuChildOnTap,
                        bookmarkList: bookmarkList,
                        ayahIconColor: ayahIconColor,
                        showAyahBookmarkedIcon: showAyahBookmarkedIcon,
                        bookmarksAyahs: bookmarksAyahs,
                        bookmarksColor: bookmarksColor,
                        ayahSelectedBackgroundColor:
                            ayahSelectedBackgroundColor,
                        context: context,
                        quranCtrl: quranCtrl,
                        ayahs: ayahs,
                        isFontsLocal: isFontsLocal!,
                        fontsName: fontsName!,
                        ayahBookmarked: ayahBookmarked,
                        anotherMenuChild: anotherMenuChild,
                        anotherMenuChildOnTap: anotherMenuChildOnTap,
                      ),
                    ),
                  ],
                );
              },
            );
          }(),
        ),
      ),
    );
  }
}
