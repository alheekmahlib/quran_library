part of '../../../quran.dart';

class QuranFontsPage extends StatelessWidget {
  final int pageIndex;
  final List? bookmarkList;
  final BasmalaStyle? basmalaStyle;
  final int? surahNumber;
  final SurahInfoStyle? surahInfoStyle;
  final SurahNameStyle? surahNameStyle;
  final BannerStyle? bannerStyle;
  final Function(SurahNamesModel surah)? onSurahBannerPress;
  final Function(LongPressStartDetails details, AyahFontsModel ayah)?
      onFontsAyahLongPress;
  final VoidCallback? onAyahPress;
  final Color? bookmarksColor;
  final Color? textColor;
  final Map<int, List<BookmarkModel>> bookmarks;
  final List<int> bookmarksAyahs;
  final Color? ayahSelectedBackgroundColor;
  final bool isDark;
  final Widget? circularProgressWidget;
  final String fFamily;
  const QuranFontsPage({
    super.key,
    required this.pageIndex,
    this.bookmarkList,
    this.basmalaStyle,
    this.surahNumber,
    this.surahInfoStyle,
    this.surahNameStyle,
    this.bannerStyle,
    this.onSurahBannerPress,
    this.onFontsAyahLongPress,
    this.bookmarksColor,
    this.textColor,
    required this.bookmarks,
    required this.bookmarksAyahs,
    this.ayahSelectedBackgroundColor,
    this.onAyahPress,
    this.isDark = false,
    this.circularProgressWidget,
    required this.fFamily,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<QuranCtrl>(
        builder: (quranCtrl) => GestureDetector(
              onTap: () {
                if (onAyahPress != null) {
                  onAyahPress!();
                }
                quranCtrl.clearSelection();
                quranCtrl.state.overlayEntry?.remove();
                quranCtrl.state.overlayEntry = null;
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
                    : const EdgeInsets.symmetric(horizontal: 8.0),
                child: quranCtrl.state.pages.isEmpty
                    ? circularProgressWidget ??
                        const CircularProgressIndicator.adaptive()
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                              quranCtrl
                                  .getCurrentPageAyahsSeparatedForBasmalah(
                                      pageIndex)
                                  .length, (i) {
                            final ayahs = quranCtrl
                                .getCurrentPageAyahsSeparatedForBasmalah(
                                    pageIndex)[i];
                            return Column(children: [
                              ayahs.first.ayahNumber == 1
                                  ? SurahHeaderWidget(
                                      surahNumber ??
                                          quranCtrl
                                              .getSurahDataByAyah(ayahs.first)
                                              .surahNumber,
                                      bannerStyle: bannerStyle ??
                                          BannerStyle(
                                            isImage: false,
                                            bannerSvgPath: isDark
                                                ? AssetsPath()
                                                    .surahSvgBannerDark
                                                : AssetsPath().surahSvgBanner,
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
                                            backgroundColor: Colors.white,
                                            closeIconColor: Colors.black,
                                            indicatorColor: Colors.amber
                                                .withValues(alpha: 2),
                                            primaryColor: Colors.amber
                                                .withValues(alpha: 2),
                                            surahNameColor: Colors.black,
                                            surahNumberColor: Colors.black,
                                            textColor: Colors.black,
                                            titleColor: Colors.black,
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
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: ayahs.first.ayahNumber == 1
                                          ? BasmallahWidget(
                                              surahNumber: quranCtrl
                                                  .getSurahDataByAyah(
                                                      ayahs.first)
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
                              FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Obx(() => _richTextWidget(
                                        context, quranCtrl, ayahs)
                                    // isTajweed
                                    // ? isDark
                                    //     ? Stack(
                                    //         children: [
                                    //           ColorFiltered(
                                    //             colorFilter: ColorFilter.mode(
                                    //                 Colors.white,
                                    //                 BlendMode.modulate),
                                    //             child: _richTextWidget(
                                    //                 context, quranCtrl, ayahs),
                                    //           ),
                                    //           ShaderMask(
                                    //             shaderCallback: (bounds) =>
                                    //                 LinearGradient(
                                    //               colors: [
                                    //                 Colors.white,
                                    //                 Colors.white
                                    //               ], // اللون الجديد للنص الأسود
                                    //             ).createShader(bounds),
                                    //             blendMode: BlendMode.srcATop,
                                    //             child: Opacity(
                                    //               opacity: 0.6,
                                    //               child: _richTextWidget(
                                    //                   context,
                                    //                   quranCtrl,
                                    //                   ayahs),
                                    //             ),
                                    //           ),
                                    //         ],
                                    //       )
                                    //     : _richTextWidget(
                                    //         context, quranCtrl, ayahs)
                                    // : isDark
                                    //     ? ColorFiltered(
                                    //         colorFilter: ColorFilter.mode(
                                    //             Colors.white, BlendMode.srcIn),
                                    //         child: _richTextWidget(
                                    //             context, quranCtrl, ayahs),
                                    //       )
                                    //     : _richTextWidget(
                                    //         context, quranCtrl, ayahs),
                                    ),
                              ),
                            ]);
                          }),
                        ),
                      ),
              ),
            ));
  }

  Widget _richTextWidget(
      BuildContext context, QuranCtrl quranCtrl, List<AyahFontsModel> ayahs) {
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontFamily: fFamily,
          fontSize: 100,
          height: 1.7,
          letterSpacing: 2,
          // color: isDark ? null : textColor,
          foreground: quranCtrl.state.isTajweed.value == 0
              ? isDark
                  ? (Paint()
                    ..color = Colors.white
                    //exclusion or difference
                    ..blendMode = BlendMode.exclusion)
                  : (Paint()
                    ..color = Colors.black
                    ..blendMode = BlendMode.srcATop)
              : isDark
                  ? (Paint()
                    ..color = Colors.white
                    ..colorFilter =
                        ColorFilter.mode(Colors.white, BlendMode.srcATop))
                  : (Paint()
                    ..color = Colors.black
                    ..colorFilter =
                        ColorFilter.mode(Colors.black, BlendMode.srcATop)),
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
          quranCtrl.state.isSelected = quranCtrl.selectedAyahIndexes
              .contains(ayahs[ayahIndex].ayahUQNumber);
          final allBookmarks = bookmarks.values.expand((list) => list).toList();
          if (ayahIndex == 0 &&
              (ayahs[ayahIndex].ayahNumber != 1 ||
                  quranCtrl.startSurahsNumbers.contains(quranCtrl
                      .getSurahDataByAyah(ayahs[ayahIndex])
                      .surahNumber))) {
            return span(
              fFamily: fFamily,
              isFirstAyah: true,
              text:
                  '${ayahs[ayahIndex].codeV2[0]}${ayahs[ayahIndex].codeV2.substring(1)}',
              pageIndex: pageIndex,
              isSelected: quranCtrl.state.isSelected,
              fontSize: 100,
              surahNum: quranCtrl.getCurrentSurahByPage(pageIndex).surahNumber,
              ayahUQNum: ayahs[ayahIndex].ayahUQNumber,
              ayahNum: ayahs[ayahIndex].ayahNumber,
              onLongPressStart: (details) {
                if (onFontsAyahLongPress != null) {
                  onFontsAyahLongPress!(details, ayahs[ayahIndex]);
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
                    quranCtrl
                        .toggleAyahSelection(ayahs[ayahIndex].ayahUQNumber);
                    quranCtrl.state.overlayEntry?.remove();
                    quranCtrl.state.overlayEntry = null;

                    // إنشاء OverlayEntry جديد
                    final overlay = Overlay.of(context);
                    final newOverlayEntry = OverlayEntry(
                      builder: (context) => AyahLongClickDialog(
                        ayahFonts: ayahs[ayahIndex],
                        position: details.globalPosition,
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
              bookmarks: bookmarks,
              bookmarksAyahs: bookmarksAyahs,
              bookmarksColor: bookmarksColor,
              ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
            );
          }
          return span(
            fFamily: fFamily,
            isFirstAyah: false,
            text: ayahs[ayahIndex].codeV2,
            pageIndex: pageIndex,
            isSelected: quranCtrl.state.isSelected,
            fontSize: 100,
            surahNum: quranCtrl.getCurrentSurahByPage(pageIndex).surahNumber,
            ayahUQNum: ayahs[ayahIndex].ayahUQNumber,
            ayahNum: ayahs[ayahIndex].ayahNumber,
            onLongPressStart: (details) {
              if (onFontsAyahLongPress != null) {
                onFontsAyahLongPress!(details, ayahs[ayahIndex]);
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
                      ayahFonts: ayahs[ayahIndex],
                      position: details.globalPosition,
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
            bookmarks: bookmarks,
            bookmarksAyahs: bookmarksAyahs,
            bookmarksColor: bookmarksColor,
            ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
          );
        }),
      ),
    );
  }
}
