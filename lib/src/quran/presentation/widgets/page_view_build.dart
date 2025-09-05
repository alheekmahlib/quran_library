part of '/quran.dart';

class PageViewBuild extends StatelessWidget {
  const PageViewBuild({
    super.key,
    required this.circularProgressWidget,
    required this.languageCode,
    required this.juzName,
    required this.sajdaName,
    required this.topTitleChild,
    required this.bookmarkList,
    required this.ayahSelectedFontColor,
    required this.textColor,
    required this.ayahIconColor,
    required this.showAyahBookmarkedIcon,
    required this.onAyahLongPress,
    required this.bookmarksColor,
    required this.surahInfoStyle,
    required this.surahNameStyle,
    required this.bannerStyle,
    required this.basmalaStyle,
    required this.onSurahBannerPress,
    required this.surahNumber,
    required this.ayahSelectedBackgroundColor,
    required this.onPagePress,
    required this.isDark,
    required this.fontsName,
    required this.ayahBookmarked,
    required this.anotherMenuChild,
    required this.anotherMenuChildOnTap,
    required this.secondMenuChild,
    required this.secondMenuChildOnTap,
    required this.userContext,
    required this.pageIndex,
    required this.quranCtrl,
    required this.isFontsLocal,
  });

  final Widget? circularProgressWidget;
  final String? languageCode;
  final String? juzName;
  final String? sajdaName;
  final Widget? topTitleChild;
  final List bookmarkList;
  final Color? ayahSelectedFontColor;
  final Color? textColor;
  final Color? ayahIconColor;
  final bool showAyahBookmarkedIcon;
  final void Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;
  final Color? bookmarksColor;
  final SurahInfoStyle? surahInfoStyle;
  final SurahNameStyle? surahNameStyle;
  final BannerStyle? bannerStyle;
  final BasmalaStyle? basmalaStyle;
  final void Function(SurahNamesModel surah)? onSurahBannerPress;
  final int? surahNumber;
  final Color? ayahSelectedBackgroundColor;
  final VoidCallback? onPagePress;
  final bool isDark;
  final String? fontsName;
  final List<int>? ayahBookmarked;
  final Widget? anotherMenuChild;
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;
  final Widget? secondMenuChild;
  final void Function(AyahModel ayah)? secondMenuChildOnTap;
  final BuildContext userContext;
  final int pageIndex;
  final QuranCtrl quranCtrl;
  final bool isFontsLocal;

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(userContext)
        .size; // استخدام سياق المستخدم / Using user context
    List<String> newSurahs = [];
    quranCtrl.isDownloadFonts
        ? quranCtrl.prepareFonts(pageIndex, isFontsLocal: isFontsLocal)
        : null;
    final bookmarkCtrl = BookmarksCtrl.instance;
    return GetBuilder<QuranCtrl>(
      id: '_pageViewBuild',
      init: QuranCtrl.instance,
      builder: (quranCtrl) => GestureDetector(
        onScaleStart: (details) => quranCtrl.state.baseScaleFactor.value =
            quranCtrl.state.scaleFactor.value,
        onScaleUpdate: (ScaleUpdateDetails details) =>
            quranCtrl.updateTextScale(details),
        child: quranCtrl.textScale(
          (quranCtrl.isDownloadFonts
              ? quranCtrl.state.allAyahs.isEmpty ||
                      quranCtrl.state.surahs.isEmpty ||
                      quranCtrl.state.pages.isEmpty
                  ? Center(
                      child: circularProgressWidget ??
                          const CircularProgressIndicator())
                  : Align(
                      alignment: Alignment.topCenter,
                      child: TopAndBottomWidget(
                        pageIndex: pageIndex,
                        languageCode: languageCode,
                        juzName: juzName,
                        sajdaName: sajdaName,
                        isRight: pageIndex.isEven ? true : false,
                        topTitleChild: topTitleChild,
                        child: _QuranFontsPage(
                          context: userContext,
                          pageIndex: pageIndex,
                          bookmarkList: bookmarkList,
                          textColor: ayahSelectedFontColor ?? textColor,
                          ayahIconColor: ayahIconColor,
                          showAyahBookmarkedIcon: showAyahBookmarkedIcon,
                          bookmarks: bookmarkCtrl.bookmarks,
                          onAyahLongPress: onAyahLongPress,
                          bookmarksColor: bookmarksColor,
                          surahInfoStyle: surahInfoStyle,
                          surahNameStyle: surahNameStyle,
                          bannerStyle: bannerStyle,
                          basmalaStyle: basmalaStyle,
                          onSurahBannerPress: onSurahBannerPress,
                          surahNumber: surahNumber,
                          bookmarksAyahs: bookmarkCtrl.bookmarksAyahs,
                          ayahSelectedBackgroundColor:
                              ayahSelectedBackgroundColor,
                          onPagePress: onPagePress,
                          isDark: isDark,
                          circularProgressWidget: circularProgressWidget,
                          isFontsLocal: isFontsLocal,
                          fontsName: fontsName,
                          ayahBookmarked: ayahBookmarked!,
                          anotherMenuChild: anotherMenuChild,
                          anotherMenuChildOnTap: anotherMenuChildOnTap,
                          secondMenuChild: secondMenuChild,
                          secondMenuChildOnTap: secondMenuChildOnTap,
                        ),
                      ))
              : quranCtrl.staticPages.isEmpty || quranCtrl.isLoading.value
                  ? Center(
                      child: circularProgressWidget ??
                          const CircularProgressIndicator())
                  : _DefaultFontsPage(
                      context: userContext,
                      pageIndex: pageIndex,
                      bookmarkList: bookmarkList,
                      textColor: textColor,
                      languageCode: languageCode,
                      onAyahLongPress: onAyahLongPress,
                      bookmarksColor: bookmarksColor,
                      surahInfoStyle: surahInfoStyle,
                      surahNameStyle: surahNameStyle,
                      bannerStyle: bannerStyle,
                      basmalaStyle: basmalaStyle,
                      onSurahBannerPress: onSurahBannerPress,
                      surahNumber: surahNumber,
                      newSurahs: newSurahs,
                      ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
                      onPagePress: onPagePress,
                      deviceSize: deviceSize,
                      juzName: juzName,
                      sajdaName: sajdaName,
                      topTitleChild: topTitleChild,
                      isDark: isDark,
                      ayahBookmarked: ayahBookmarked!,
                      anotherMenuChild: anotherMenuChild,
                      anotherMenuChildOnTap: anotherMenuChildOnTap,
                      secondMenuChild: secondMenuChild,
                      secondMenuChildOnTap: secondMenuChildOnTap,
                    )),
          quranCtrl.staticPages.isEmpty || quranCtrl.isLoading.value
              ? Center(
                  child: circularProgressWidget ??
                      const CircularProgressIndicator())
              : TopAndBottomWidget(
                  pageIndex: pageIndex,
                  languageCode: languageCode,
                  juzName: juzName,
                  sajdaName: sajdaName,
                  isRight: pageIndex.isEven ? true : false,
                  topTitleChild: topTitleChild,
                  child: _QuranTextScale(
                    context: userContext,
                    pageIndex: pageIndex,
                    bookmarkList: bookmarkList,
                    textColor: ayahSelectedFontColor ?? textColor,
                    ayahIconColor: ayahIconColor,
                    showAyahBookmarkedIcon: showAyahBookmarkedIcon,
                    bookmarks: bookmarkCtrl.bookmarks,
                    onAyahLongPress: onAyahLongPress,
                    bookmarksColor: bookmarksColor,
                    surahInfoStyle: surahInfoStyle,
                    surahNameStyle: surahNameStyle,
                    bannerStyle: bannerStyle,
                    basmalaStyle: basmalaStyle,
                    onSurahBannerPress: onSurahBannerPress,
                    surahNumber: surahNumber,
                    bookmarksAyahs: bookmarkCtrl.bookmarksAyahs,
                    ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
                    onPagePress: onPagePress,
                    languageCode: languageCode,
                    isDark: isDark,
                    circularProgressWidget: circularProgressWidget,
                    ayahBookmarked: ayahBookmarked!,
                    anotherMenuChild: anotherMenuChild,
                    anotherMenuChildOnTap: anotherMenuChildOnTap,
                    secondMenuChild: secondMenuChild,
                    secondMenuChildOnTap: secondMenuChildOnTap,
                  ),
                ),
        ),
      ),
    );
  }
}
