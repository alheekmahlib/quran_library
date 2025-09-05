part of '/quran.dart';

/// شرح: صفحة عرض القرآن بالخطوط المحسنة مع تحسينات الأداء
/// Explanation: Optimized Quran page display with fonts and performance improvements
class _QuranFontsPage extends StatelessWidget {
  final BuildContext context;
  final int pageIndex;
  final List? bookmarkList;
  final BasmalaStyle? basmalaStyle;
  final int? surahNumber;
  final SurahInfoStyle? surahInfoStyle;
  final SurahNameStyle? surahNameStyle;
  final BannerStyle? bannerStyle;
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
  final bool isDark;
  final bool showAyahBookmarkedIcon;
  final Widget? circularProgressWidget;
  final bool? isFontsLocal;
  final String? fontsName;
  final List<int> ayahBookmarked;
  final Widget? anotherMenuChild;
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;
  final Widget? secondMenuChild;
  final void Function(AyahModel ayah)? secondMenuChildOnTap;

  const _QuranFontsPage({
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
    this.bookmarksColor,
    this.textColor,
    this.ayahIconColor,
    this.showAyahBookmarkedIcon = true,
    required this.bookmarks,
    required this.bookmarksAyahs,
    this.ayahSelectedBackgroundColor,
    this.onPagePress,
    this.isDark = false,
    this.circularProgressWidget,
    this.isFontsLocal,
    this.fontsName,
    required this.ayahBookmarked,
    this.anotherMenuChild,
    this.anotherMenuChildOnTap,
    this.secondMenuChild,
    this.secondMenuChildOnTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return GetBuilder<QuranCtrl>(
      builder: (quranCtrl) => GestureDetector(
        onTap: () {
          if (onPagePress != null) {
            onPagePress!();
          } else {
            quranCtrl.isShowControl.toggle();
            quranCtrl.clearSelection();
            quranCtrl.state.overlayEntry?.remove();
            quranCtrl.state.overlayEntry = null;
          }
        },
        child: Container(
          padding: pageIndex == 0 || pageIndex == 1
              ? EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width * .08)
              : const EdgeInsets.symmetric(horizontal: 16.0),
          margin: pageIndex == 0 || pageIndex == 1
              ? EdgeInsets.symmetric(
                  vertical: UiHelper.currentOrientation(
                      MediaQuery.sizeOf(context).width * .16,
                      MediaQuery.sizeOf(context).height * .01,
                      context))
              : EdgeInsets.zero,
          child: quranCtrl.state.pages.isEmpty
              ? circularProgressWidget ??
                  const CircularProgressIndicator.adaptive()
              : Platform.isAndroid || Platform.isIOS
                  ? isLandscape &&
                          (Responsive.isMobile(context) ||
                              Responsive.isMobileLarge(context))
                      ? SingleChildScrollView(
                          child: PageBuild(
                            pageIndex: pageIndex,
                            surahNumber: surahNumber,
                            bannerStyle: bannerStyle,
                            isDark: isDark,
                            surahNameStyle: surahNameStyle,
                            surahInfoStyle: surahInfoStyle,
                            onSurahBannerPress: onSurahBannerPress,
                            basmalaStyle: basmalaStyle,
                            textColor: textColor,
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
                            isFontsLocal: isFontsLocal,
                            fontsName: fontsName,
                            ayahBookmarked: ayahBookmarked,
                            anotherMenuChild: anotherMenuChild,
                            anotherMenuChildOnTap: anotherMenuChildOnTap,
                            context: context,
                            quranCtrl: quranCtrl,
                          ),
                        )
                      : PageBuild(
                          pageIndex: pageIndex,
                          surahNumber: surahNumber,
                          bannerStyle: bannerStyle,
                          isDark: isDark,
                          surahNameStyle: surahNameStyle,
                          surahInfoStyle: surahInfoStyle,
                          onSurahBannerPress: onSurahBannerPress,
                          basmalaStyle: basmalaStyle,
                          textColor: textColor,
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
                          isFontsLocal: isFontsLocal,
                          fontsName: fontsName,
                          ayahBookmarked: ayahBookmarked,
                          anotherMenuChild: anotherMenuChild,
                          anotherMenuChildOnTap: anotherMenuChildOnTap,
                          context: context,
                          quranCtrl: quranCtrl,
                        )
                  : PageBuild(
                      pageIndex: pageIndex,
                      surahNumber: surahNumber,
                      bannerStyle: bannerStyle,
                      isDark: isDark,
                      surahNameStyle: surahNameStyle,
                      surahInfoStyle: surahInfoStyle,
                      onSurahBannerPress: onSurahBannerPress,
                      basmalaStyle: basmalaStyle,
                      textColor: textColor,
                      bookmarks: bookmarks,
                      onAyahLongPress: onAyahLongPress,
                      secondMenuChild: secondMenuChild,
                      secondMenuChildOnTap: secondMenuChildOnTap,
                      bookmarkList: bookmarkList,
                      ayahIconColor: ayahIconColor,
                      showAyahBookmarkedIcon: showAyahBookmarkedIcon,
                      bookmarksAyahs: bookmarksAyahs,
                      bookmarksColor: bookmarksColor,
                      ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
                      isFontsLocal: isFontsLocal,
                      fontsName: fontsName,
                      ayahBookmarked: ayahBookmarked,
                      anotherMenuChild: anotherMenuChild,
                      anotherMenuChildOnTap: anotherMenuChildOnTap,
                      context: context,
                      quranCtrl: quranCtrl,
                    ),
        ),
      ),
    );
  }
}
