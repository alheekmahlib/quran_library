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
                    vertical: context.currentOrientation(
                        MediaQuery.sizeOf(context).width * .16,
                        MediaQuery.sizeOf(context).height * .01))
                : EdgeInsets.zero,
            child: quranCtrl.state.pages.isEmpty
                ? circularProgressWidget ??
                    const CircularProgressIndicator.adaptive()
                : Platform.isAndroid || Platform.isIOS
                    ? isLandscape &&
                            (Responsive.isMobile(context) ||
                                Responsive.isMobileLarge(context))
                        ? SingleChildScrollView(
                            child: _pageBuild(context, quranCtrl))
                        : _pageBuild(context, quranCtrl)
                    : _pageBuild(context, quranCtrl)),
      ),
    );
  }

  Widget _pageBuild(BuildContext context, QuranCtrl quranCtrl) {
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
                                    ? _AssetsPath().surahSvgBannerDark
                                    : _AssetsPath().surahSvgBanner,
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
                      child: Obx(() => _richTextWidget(
                          context,
                          quranCtrl,
                          ayahs,
                          isFontsLocal!,
                          fontsName!,
                          ayahBookmarked,
                          anotherMenuChild,
                          anotherMenuChildOnTap)),
                    ),
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
                                    ? _AssetsPath().surahSvgBannerDark
                                    : _AssetsPath().surahSvgBanner,
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

  Widget _richTextWidget(
    BuildContext context,
    QuranCtrl quranCtrl,
    List<AyahModel> ayahs,
    bool isFontsLocal,
    String fontsName,
    List<int> ayahBookmarked,
    Widget? anotherMenuChild,
    Function(AyahModel ayah)? anotherMenuChildOnTap,
  ) {
    // شرح: تحسين RichText بإضافة خصائص الأداء
    // Explanation: Optimize RichText by adding performance properties
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      // شرح: تحسين أداء النص للنصوص الطويلة
      // Explanation: Optimize text performance for long texts
      softWrap: true,
      overflow: TextOverflow.visible,
      maxLines: null,
      text: TextSpan(
        style: TextStyle(
          fontFamily: isFontsLocal ? fontsName : 'p${(pageIndex + 2001)}',
          fontSize: 100,
          height: 1.7,
          letterSpacing: 2,
          shadows: [
            Shadow(
              blurRadius: 0.5,
              color: quranCtrl.state.isBold.value == 0
                  ? textColor ?? (isDark ? Colors.white : Colors.black)
                  : Colors.transparent,
              offset: const Offset(0.5, 0.5),
            ),
          ],
        ),
        children: List.generate(ayahs.length, (ayahIndex) {
          quranCtrl.selectedAyahsByUnequeNumber
              .contains(ayahs[ayahIndex].ayahUQNumber);
          final allBookmarks = bookmarks.values.expand((list) => list).toList();
          bool isFirstAyah = ayahIndex == 0 &&
              (ayahs[ayahIndex].ayahNumber != 1 ||
                  quranCtrl._startSurahsNumbers.contains(quranCtrl
                      .getSurahDataByAyah(ayahs[ayahIndex])
                      .surahNumber));
          String text = isFirstAyah
              ? '${ayahs[ayahIndex].codeV2![0]}${ayahs[ayahIndex].codeV2!.substring(1)}'
              : ayahs[ayahIndex].codeV2!;
          return _span(
            isFirstAyah: isFirstAyah,
            text: text,
            isDark: isDark,
            pageIndex: pageIndex,
            isSelected: quranCtrl.selectedAyahsByUnequeNumber
                .contains(ayahs[ayahIndex].ayahUQNumber),
            fontSize: 100,
            surahNum: quranCtrl.getCurrentSurahByPage(pageIndex).surahNumber,
            ayahUQNum: ayahs[ayahIndex].ayahUQNumber,
            ayahNum: ayahs[ayahIndex].ayahNumber,
            ayahBookmarked: ayahBookmarked,
            onLongPressStart: (details) {
              if (onAyahLongPress != null) {
                onAyahLongPress!(details, ayahs[ayahIndex]);
                quranCtrl.toggleAyahSelection(ayahs[ayahIndex].ayahUQNumber);
                quranCtrl.state.overlayEntry?.remove();
                quranCtrl.state.overlayEntry = null;
              } else {
                final bookmarkId = allBookmarks.any((bookmark) =>
                        bookmark.ayahId == ayahs[ayahIndex].ayahUQNumber)
                    ? allBookmarks
                        .firstWhere((bookmark) =>
                            bookmark.ayahId == ayahs[ayahIndex].ayahUQNumber)
                        .id
                    : null;
                if (bookmarkId != null) {
                  BookmarksCtrl.instance.removeBookmark(bookmarkId);
                } else {
                  quranCtrl.toggleAyahSelection(ayahs[ayahIndex].ayahUQNumber);
                  quranCtrl.state.overlayEntry?.remove();
                  quranCtrl.state.overlayEntry = null;

                  // إنشاء OverlayEntry جديد
                  final overlay = Overlay.of(context);
                  final newOverlayEntry = OverlayEntry(
                    builder: (context) => AyahLongClickDialog(
                      context: context,
                      isDark: isDark,
                      ayah: ayahs[ayahIndex],
                      position: details.globalPosition,
                      index: ayahIndex,
                      pageIndex: pageIndex,
                      anotherMenuChild: anotherMenuChild,
                      anotherMenuChildOnTap: anotherMenuChildOnTap,
                    ),
                  );

                  quranCtrl.state.overlayEntry = newOverlayEntry;

                  // إدخال OverlayEntry في Overlay
                  overlay.insert(newOverlayEntry);
                }
              }
            },
            bookmarkList: bookmarkList,
            textColor: textColor ?? (isDark ? Colors.white : Colors.black),
            ayahIconColor:
                ayahIconColor ?? (isDark ? Colors.white : Colors.black),
            showAyahBookmarkedIcon: showAyahBookmarkedIcon,
            bookmarks: bookmarks,
            bookmarksAyahs: bookmarksAyahs,
            bookmarksColor: bookmarksColor,
            ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
            isFontsLocal: isFontsLocal,
            fontsName: fontsName,
          );
        }),
      ),
    );
  }
}
