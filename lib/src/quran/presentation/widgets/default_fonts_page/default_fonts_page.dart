part of '/quran.dart';

class _DefaultFontsPage extends StatelessWidget {
  final BuildContext context;
  final int pageIndex;
  final int? surahNumber;
  final BannerStyle? bannerStyle;
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
  final List<String> newSurahs;
  final String? languageCode;
  final String? juzName;
  final String? sajdaName;
  final Widget? topTitleChild;
  final bool isDark;
  final List<int> ayahBookmarked;
  final Widget? anotherMenuChild;
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;
  final Widget? secondMenuChild;
  final void Function(AyahModel ayah)? secondMenuChildOnTap;

  _DefaultFontsPage({
    required this.context,
    required this.pageIndex,
    this.surahNumber,
    this.bannerStyle,
    this.surahNameStyle,
    this.surahInfoStyle,
    this.onSurahBannerPress,
    this.basmalaStyle,
    required this.deviceSize,
    this.onAyahLongPress,
    this.bookmarksColor,
    this.textColor,
    this.bookmarkList,
    this.ayahSelectedBackgroundColor,
    this.onPagePress,
    required this.newSurahs,
    this.languageCode,
    this.juzName,
    this.sajdaName,
    this.topTitleChild,
    required this.isDark,
    required this.ayahBookmarked,
    this.anotherMenuChild,
    this.anotherMenuChildOnTap,
    this.secondMenuChild,
    this.secondMenuChildOnTap,
  });

  final quranCtrl = QuranCtrl.instance;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      height: MediaQuery.sizeOf(context).height,
      padding: EdgeInsets.symmetric(
          horizontal: UiHelper.currentOrientation(16.0, 64.0, context),
          vertical: 16.0),
      child: pageIndex == 0 || pageIndex == 1

          /// This is for first 2 pages of Quran: Al-Fatihah and Al-Baqarah
          ? TopAndBottomWidget(
              pageIndex: pageIndex,
              languageCode: languageCode,
              juzName: juzName,
              sajdaName: sajdaName,
              isRight: pageIndex.isEven ? true : false,
              topTitleChild: topTitleChild,
              child: Platform.isAndroid || Platform.isIOS
                  ? isLandscape
                      ? SingleChildScrollView(
                          child: DefaultFirstTwoSurahs(
                              surahNumber: surahNumber,
                              quranCtrl: quranCtrl,
                              pageIndex: pageIndex,
                              bannerStyle: bannerStyle,
                              isDark: isDark,
                              surahNameStyle: surahNameStyle,
                              surahInfoStyle: surahInfoStyle,
                              onSurahBannerPress: onSurahBannerPress,
                              basmalaStyle: basmalaStyle,
                              deviceSize: deviceSize,
                              onAyahLongPress: onAyahLongPress,
                              bookmarksColor: bookmarksColor,
                              textColor: textColor,
                              bookmarkList: bookmarkList,
                              ayahSelectedBackgroundColor:
                                  ayahSelectedBackgroundColor,
                              onPagePress: onPagePress,
                              ayahBookmarked: ayahBookmarked,
                              anotherMenuChild: anotherMenuChild,
                              anotherMenuChildOnTap: anotherMenuChildOnTap,
                              secondMenuChild: secondMenuChild,
                              secondMenuChildOnTap: secondMenuChildOnTap,
                              context: context))
                      : DefaultFirstTwoSurahs(
                          surahNumber: surahNumber,
                          quranCtrl: quranCtrl,
                          pageIndex: pageIndex,
                          bannerStyle: bannerStyle,
                          isDark: isDark,
                          surahNameStyle: surahNameStyle,
                          surahInfoStyle: surahInfoStyle,
                          onSurahBannerPress: onSurahBannerPress,
                          basmalaStyle: basmalaStyle,
                          deviceSize: deviceSize,
                          onAyahLongPress: onAyahLongPress,
                          bookmarksColor: bookmarksColor,
                          textColor: textColor,
                          bookmarkList: bookmarkList,
                          ayahSelectedBackgroundColor:
                              ayahSelectedBackgroundColor,
                          onPagePress: onPagePress,
                          ayahBookmarked: ayahBookmarked,
                          anotherMenuChild: anotherMenuChild,
                          anotherMenuChildOnTap: anotherMenuChildOnTap,
                          secondMenuChild: secondMenuChild,
                          secondMenuChildOnTap: secondMenuChildOnTap,
                          context: context)
                  : DefaultFirstTwoSurahs(
                      surahNumber: surahNumber,
                      quranCtrl: quranCtrl,
                      pageIndex: pageIndex,
                      bannerStyle: bannerStyle,
                      isDark: isDark,
                      surahNameStyle: surahNameStyle,
                      surahInfoStyle: surahInfoStyle,
                      onSurahBannerPress: onSurahBannerPress,
                      basmalaStyle: basmalaStyle,
                      deviceSize: deviceSize,
                      onAyahLongPress: onAyahLongPress,
                      bookmarksColor: bookmarksColor,
                      textColor: textColor,
                      bookmarkList: bookmarkList,
                      ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
                      onPagePress: onPagePress,
                      ayahBookmarked: ayahBookmarked,
                      anotherMenuChild: anotherMenuChild,
                      anotherMenuChildOnTap: anotherMenuChildOnTap,
                      secondMenuChild: secondMenuChild,
                      secondMenuChildOnTap: secondMenuChildOnTap,
                      context: context,
                    ),
            )
          : DefaultOtherSurahs(
              pageIndex: pageIndex,
              languageCode: languageCode,
              juzName: juzName,
              sajdaName: sajdaName,
              topTitleChild: topTitleChild,
              quranCtrl: quranCtrl,
              newSurahs: newSurahs,
              surahNumber: surahNumber,
              bannerStyle: bannerStyle,
              isDark: isDark,
              surahNameStyle: surahNameStyle,
              surahInfoStyle: surahInfoStyle,
              onSurahBannerPress: onSurahBannerPress,
              basmalaStyle: basmalaStyle,
              deviceSize: deviceSize,
              onAyahLongPress: onAyahLongPress,
              bookmarksColor: bookmarksColor,
              textColor: textColor,
              bookmarkList: bookmarkList,
              ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
              onPagePress: onPagePress,
              ayahBookmarked: ayahBookmarked,
              anotherMenuChild: anotherMenuChild,
              anotherMenuChildOnTap: anotherMenuChildOnTap,
              secondMenuChild: secondMenuChild,
              secondMenuChildOnTap: secondMenuChildOnTap,
              context: context),
    );
  }
}
