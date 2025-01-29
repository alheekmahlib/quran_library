part of '../../quran.dart';

class QuranTextScale extends StatelessWidget {
  QuranTextScale(
      {super.key,
      required this.pageIndex,
      this.bookmarkList,
      this.basmalaStyle,
      this.surahNumber,
      this.surahInfoStyle,
      this.surahNameStyle,
      this.bannerStyle,
      this.onSurahBannerPress,
      this.onFontsAyahLongPress,
      this.onAyahPress,
      this.bookmarksColor,
      this.textColor,
      required this.bookmarks,
      required this.bookmarksAyahs,
      this.ayahSelectedBackgroundColor,
      this.languageCode});

  final quranCtrl = QuranCtrl.instance;

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
  final String? languageCode;

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
                color: const Color(0xfffaf7f3),
                padding: pageIndex == 0 || pageIndex == 1
                    ? EdgeInsets.symmetric(
                        horizontal: MediaQuery.sizeOf(context).width * .13)
                    : const EdgeInsets.symmetric(horizontal: 8.0),
                margin: pageIndex == 0 || pageIndex == 1
                    ? EdgeInsets.symmetric(
                        vertical: MediaQuery.sizeOf(context).width * .34)
                    : const EdgeInsets.symmetric(horizontal: 8.0),
                child: quranCtrl.state.pages.isEmpty
                    ? const CircularProgressIndicator.adaptive()
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
                              ayahs.first.ayahNumber == 1 &&
                                      !quranCtrl.topOfThePageIndex
                                          .contains(pageIndex)
                                  ? SurahHeaderWidget(
                                      surahNumber ??
                                          quranCtrl
                                              .getSurahDataByAyah(ayahs.first)
                                              .surahNumber,
                                      bannerStyle: bannerStyle ??
                                          BannerStyle(
                                            isImage: false,
                                            bannerSvgPath:
                                                AssetsPath().surahSvgBanner,
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
                                            surahNameColor: Colors.black,
                                          ),
                                      surahInfoStyle: surahInfoStyle ??
                                          SurahInfoStyle(
                                            ayahCount: 'عدد الآيات',
                                            secondTabText: 'عن السورة',
                                            firstTabText: 'أسماء السورة',
                                            backgroundColor: Colors.white,
                                            closeIconColor: Colors.black,
                                            indicatorColor: Colors.amber
                                                .withValues(alpha: .2),
                                            primaryColor: Colors.amber
                                                .withValues(alpha: .2),
                                            surahNameColor: Colors.black,
                                            surahNumberColor: Colors.black,
                                            textColor: Colors.black,
                                            titleColor: Colors.black,
                                          ),
                                      onSurahBannerPress: onSurahBannerPress,
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
                                                    basmalaColor: Colors.black,
                                                    basmalaWidth: 160.0,
                                                    basmalaHeight: 45.0,
                                                  ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                              Obx(() => RichText(
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: TextStyle(
                                          fontFamily: 'hafs',
                                          fontSize: 20 *
                                              quranCtrl.state.scaleFactor.value,
                                          height: 1.7,
                                          letterSpacing: 2,
                                          color: textColor ?? Colors.black,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 0.5,
                                              color: quranCtrl
                                                          .state.isBold.value ==
                                                      0
                                                  ? Colors.black
                                                  : Colors.transparent,
                                              offset: const Offset(0.5, 0.5),
                                            ),
                                          ],
                                          package: 'quran_library'),
                                      children: List.generate(ayahs.length,
                                          (ayahIndex) {
                                        quranCtrl.state.isSelected = quranCtrl
                                            .selectedAyahIndexes
                                            .contains(
                                                ayahs[ayahIndex].ayahUQNumber);
                                        final allBookmarks = bookmarks.values
                                            .expand((list) => list)
                                            .toList();
                                        if (ayahIndex == 0) {
                                          return customSpan(
                                            isFirstAyah: true,
                                            text:
                                                '${ayahs[ayahIndex].text[0]}${ayahs[ayahIndex].text.substring(1)}',
                                            pageIndex: pageIndex,
                                            isSelected:
                                                quranCtrl.state.isSelected,
                                            fontSize: 20 *
                                                quranCtrl
                                                    .state.scaleFactor.value,
                                            surahNum: quranCtrl
                                                .getCurrentSurahByPage(
                                                    pageIndex)
                                                .surahNumber,
                                            ayahUQNum:
                                                ayahs[ayahIndex].ayahUQNumber,
                                            onLongPressStart: (details) {
                                              if (onFontsAyahLongPress !=
                                                  null) {
                                                onFontsAyahLongPress!(
                                                    details, ayahs[ayahIndex]);
                                                quranCtrl.toggleAyahSelection(
                                                    ayahs[ayahIndex]
                                                        .ayahUQNumber);
                                                quranCtrl.state.overlayEntry
                                                    ?.remove();
                                                quranCtrl.state.overlayEntry =
                                                    null;
                                              } else {
                                                final bookmarkId = allBookmarks
                                                        .any((bookmark) =>
                                                            bookmark.ayahId ==
                                                            ayahs[ayahIndex]
                                                                .ayahUQNumber)
                                                    ? allBookmarks
                                                        .firstWhere((bookmark) =>
                                                            bookmark.ayahId ==
                                                            ayahs[ayahIndex]
                                                                .ayahUQNumber)
                                                        .id
                                                    : null;
                                                if (bookmarkId != null) {
                                                  BookmarksCtrl.instance
                                                      .removeBookmark(
                                                          bookmarkId);
                                                } else {
                                                  quranCtrl.toggleAyahSelection(
                                                      ayahs[ayahIndex]
                                                          .ayahUQNumber);
                                                  quranCtrl.state.overlayEntry
                                                      ?.remove();
                                                  quranCtrl.state.overlayEntry =
                                                      null;

                                                  // إنشاء OverlayEntry جديد
                                                  final overlay =
                                                      Overlay.of(context);
                                                  final newOverlayEntry =
                                                      OverlayEntry(
                                                    builder: (context) =>
                                                        AyahLongClickDialog(
                                                      ayahFonts:
                                                          ayahs[ayahIndex],
                                                      position: details
                                                          .globalPosition,
                                                    ),
                                                  );

                                                  quranCtrl.state.overlayEntry =
                                                      newOverlayEntry;

                                                  // إدخال OverlayEntry في Overlay
                                                  overlay
                                                      .insert(newOverlayEntry);
                                                }
                                              }
                                            },
                                            bookmarkList: bookmarkList,
                                            textColor: textColor,
                                            bookmarks: bookmarks,
                                            bookmarksAyahs: bookmarksAyahs,
                                            bookmarksColor: bookmarksColor,
                                            ayahSelectedBackgroundColor:
                                                ayahSelectedBackgroundColor,
                                            ayahNumber:
                                                ayahs[ayahIndex].ayahNumber,
                                            languageCode: languageCode,
                                          );
                                        }
                                        return customSpan(
                                          isFirstAyah: false,
                                          text: ayahs[ayahIndex].text,
                                          pageIndex: pageIndex,
                                          isSelected:
                                              quranCtrl.state.isSelected,
                                          fontSize: 20 *
                                              quranCtrl.state.scaleFactor.value,
                                          surahNum: quranCtrl
                                              .getCurrentSurahByPage(pageIndex)
                                              .surahNumber,
                                          ayahUQNum:
                                              ayahs[ayahIndex].ayahUQNumber,
                                          onLongPressStart: (details) {
                                            if (onFontsAyahLongPress != null) {
                                              onFontsAyahLongPress!(
                                                  details, ayahs[ayahIndex]);
                                              quranCtrl.toggleAyahSelection(
                                                  ayahs[ayahIndex]
                                                      .ayahUQNumber);
                                              quranCtrl.state.overlayEntry
                                                  ?.remove();
                                              quranCtrl.state.overlayEntry =
                                                  null;
                                            } else {
                                              final bookmarkId = allBookmarks
                                                      .any((bookmark) =>
                                                          bookmark.ayahId ==
                                                          ayahs[ayahIndex]
                                                              .ayahUQNumber)
                                                  ? allBookmarks
                                                      .firstWhere((bookmark) =>
                                                          bookmark.ayahId ==
                                                          ayahs[ayahIndex]
                                                              .ayahUQNumber)
                                                      .id
                                                  : null;
                                              if (bookmarkId != null) {
                                                BookmarksCtrl.instance
                                                    .removeBookmark(bookmarkId);
                                              } else {
                                                quranCtrl.toggleAyahSelection(
                                                    ayahs[ayahIndex]
                                                        .ayahUQNumber);
                                                quranCtrl.state.overlayEntry
                                                    ?.remove();
                                                quranCtrl.state.overlayEntry =
                                                    null;

                                                // إنشاء OverlayEntry جديد
                                                final overlay =
                                                    Overlay.of(context);
                                                final newOverlayEntry =
                                                    OverlayEntry(
                                                  builder: (context) =>
                                                      AyahLongClickDialog(
                                                    ayahFonts: ayahs[ayahIndex],
                                                    position:
                                                        details.globalPosition,
                                                  ),
                                                );

                                                quranCtrl.state.overlayEntry =
                                                    newOverlayEntry;

                                                // إدخال OverlayEntry في Overlay
                                                overlay.insert(newOverlayEntry);
                                              }
                                            }
                                          },
                                          bookmarkList: bookmarkList,
                                          textColor: textColor,
                                          bookmarks: bookmarks,
                                          bookmarksAyahs: bookmarksAyahs,
                                          bookmarksColor: bookmarksColor,
                                          ayahSelectedBackgroundColor:
                                              ayahSelectedBackgroundColor,
                                          ayahNumber:
                                              ayahs[ayahIndex].ayahNumber,
                                          languageCode: languageCode,
                                        );
                                      }),
                                    ),
                                  )),
                              quranCtrl.downThePageIndex.contains(pageIndex)
                                  ? SurahHeaderWidget(
                                      surahNumber ??
                                          quranCtrl
                                                  .getSurahDataByAyah(
                                                      ayahs.first)
                                                  .surahNumber +
                                              1,
                                      bannerStyle: bannerStyle ??
                                          BannerStyle(
                                            isImage: false,
                                            bannerSvgPath:
                                                AssetsPath().surahSvgBanner,
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
                                            surahNameColor: Colors.black,
                                          ),
                                      surahInfoStyle: surahInfoStyle ??
                                          SurahInfoStyle(
                                            ayahCount: 'عدد الآيات',
                                            secondTabText: 'عن السورة',
                                            firstTabText: 'أسماء السورة',
                                            backgroundColor: Colors.white,
                                            closeIconColor: Colors.black,
                                            indicatorColor: Colors.amber
                                                .withValues(alpha: .2),
                                            primaryColor: Colors.amber
                                                .withValues(alpha: .2),
                                            surahNameColor: Colors.black,
                                            surahNumberColor: Colors.black,
                                            textColor: Colors.black,
                                            titleColor: Colors.black,
                                          ),
                                      onSurahBannerPress: onSurahBannerPress,
                                    )
                                  : const SizedBox.shrink(),
                              // context.surahBannerLastPlace(pageIndex, i),
                            ]);
                          }),
                        ),
                      ),
              ),
            ));
  }
}
