part of '/quran.dart';

class PageBuild extends StatelessWidget {
  const PageBuild({
    super.key,
    required this.pageIndex,
    required this.surahNumber,
    required this.bannerStyle,
    required this.isDark,
    required this.surahNameStyle,
    required this.surahInfoStyle,
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
  final SurahInfoStyle? surahInfoStyle;
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
    // شرح: تحسين FittedBox بإضافة RepaintBoundary لتقليل إعادة الرسم
    // Explanation: Optimize FittedBox by adding RepaintBoundary to reduce repainting
    return RepaintBoundary(
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            quranCtrl.getCurrentPageAyahsSeparatedForBasmalah(pageIndex).length,
            (i) {
              final ayahs = quranCtrl
                  .getCurrentPageAyahsSeparatedForBasmalah(pageIndex)[i];
              return Column(
                children: [
                  ayahs.first.ayahNumber == 1 &&
                          !quranCtrl._topOfThePageIndex.contains(pageIndex)
                      ? SurahHeaderWidget(
                          surahNumber ??
                              quranCtrl
                                  .getSurahDataByAyah(ayahs.first)
                                  .surahNumber,
                          bannerStyle: bannerStyle ??
                              BannerStyle(
                                isImage: false,
                                bannerSvgPath: isDark
                                    ? AssetsPath.assets.surahSvgBannerDark
                                    : AssetsPath.assets.surahSvgBanner,
                                bannerSvgHeight: 100.0,
                                bannerSvgWidth: 150.0,
                                bannerImagePath: '',
                                bannerImageHeight: 100.0,
                                bannerImageWidth: double.infinity,
                              ),
                          surahNameStyle: surahNameStyle ??
                              SurahNameStyle(
                                surahNameWidth: 70,
                                surahNameHeight: 80,
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
                                textColor: isDark ? Colors.white : Colors.black,
                                titleColor:
                                    isDark ? Colors.white : Colors.black,
                              ),
                          onSurahBannerPress: onSurahBannerPress,
                          isDark: isDark,
                        )
                      : const SizedBox.shrink(),
                  quranCtrl.getSurahDataByAyah(ayahs.first).surahNumber == 9 ||
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
                                        basmalaHeight: 140.0,
                                      ),
                                )
                              : const SizedBox.shrink(),
                        ),
                  // شرح: إضافة RepaintBoundary للنص لتحسين الأداء
                  // Explanation: Add RepaintBoundary for text to improve performance
                  RepaintBoundary(
                    child: FittedBox(
                        fit: BoxFit.fitWidth,
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
                            anotherMenuChildOnTap: anotherMenuChildOnTap)),
                  ),
                  quranCtrl._downThePageIndex.contains(pageIndex)
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
                                    ? AssetsPath.assets.surahSvgBannerDark
                                    : AssetsPath.assets.surahSvgBanner,
                                bannerSvgHeight: 140.0,
                                bannerSvgWidth: 150.0,
                                bannerImagePath: '',
                                bannerImageHeight: 100.0,
                                bannerImageWidth: double.infinity,
                              ),
                          surahNameStyle: surahNameStyle ??
                              SurahNameStyle(
                                surahNameWidth: 70,
                                surahNameHeight: 100,
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
                                textColor: isDark ? Colors.white : Colors.black,
                                titleColor:
                                    isDark ? Colors.white : Colors.black,
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
    );
  }
}
