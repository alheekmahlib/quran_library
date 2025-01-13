import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/src/extensions/quran_getters.dart';
import '../../flutter_quran.dart';
import '../controllers/bookmarks_ctrl.dart';
import '../controllers/quran_ctrl.dart';
import '../models/banner_style.dart';
import '../models/basmala_style.dart';
import '../models/surah_info_style.dart';
import '../models/surah_name_style.dart';
import 'custom_span.dart';

class QuranFontsPage extends StatelessWidget {
  final int pageIndex;
  final List? bookmarkList;
  final BasmalaStyle? basmalaStyle;
  final int? surahNumber;
  final SurahInfoStyle? surahInfoStyle;
  final SurahNameStyle? surahNameStyle;
  final BannerStyle? bannerStyle;
  final Function? onSurahBannerPress;
  final Function? onAyahLongPress;
  final Color? bookmarksColor;
  final Color? textColor;
  final Map<int, List<BookmarkModel>> bookmarks;
  final List<int> bookmarksAyahs;
  final Color? ayahSelectedBackgroundColor;
  const QuranFontsPage(
      {super.key,
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
      required this.bookmarks,
      required this.bookmarksAyahs,
      this.ayahSelectedBackgroundColor});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<QuranCtrl>(builder: (quranCtrl) {
      return Container(
        padding: pageIndex == 0 || pageIndex == 1
            ? EdgeInsets.symmetric(horizontal: Get.width * .13)
            : const EdgeInsets.symmetric(horizontal: 8.0),
        margin: pageIndex == 0 || pageIndex == 1
            ? EdgeInsets.symmetric(vertical: Get.width * .34)
            : const EdgeInsets.symmetric(vertical: 32.0, horizontal: 8.0),
        child: quranCtrl.state.pages.isEmpty
            ? const CircularProgressIndicator.adaptive()
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                      quranCtrl
                          .getCurrentPageAyahsSeparatedForBasmalah(pageIndex)
                          .length, (i) {
                    final ayahs = quranCtrl
                        .getCurrentPageAyahsSeparatedForBasmalah(pageIndex)[i];
                    return Column(children: [
                      ayahs.first.ayahNumber == 1 &&
                              !quranCtrl.topOfThePageIndex.contains(pageIndex)
                          ? SurahHeaderWidget(
                              surahNumber ??
                                  quranCtrl
                                      .getSurahDataByAyah(ayahs.first)
                                      .surahNumber,
                              bannerStyle: bannerStyle ??
                                  BannerStyle(
                                    isImage: false,
                                    bannerSvgPath: AssetsPath().surahSvgBanner,
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
                                    indicatorColor:
                                        Colors.amber.withValues(alpha: 2),
                                    primaryColor:
                                        Colors.amber.withValues(alpha: 2),
                                    surahNameColor: Colors.black,
                                    surahNumberColor: Colors.black,
                                    textColor: Colors.black,
                                    titleColor: Colors.black,
                                  ),
                              onSurahBannerPress: onSurahBannerPress,
                            )
                          : const SizedBox.shrink(),
                      quranCtrl.getSurahDataByAyah(ayahs.first).surahNumber ==
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
                                            basmalaColor: Colors.black,
                                            basmalaWidth: 160.0,
                                            basmalaHeight: 45.0,
                                          ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                      FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Obx(() => RichText(
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontFamily: 'p${(pageIndex + 2001)}',
                                  fontSize: 100,
                                  height: 1.7,
                                  letterSpacing: 2,
                                  color: textColor ?? Colors.black,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 0.5,
                                      color: quranCtrl.state.isBold.value == 0
                                          ? Colors.black
                                          : Colors.transparent,
                                      offset: const Offset(0.5, 0.5),
                                    ),
                                  ],
                                ),
                                children:
                                    List.generate(ayahs.length, (ayahIndex) {
                                  quranCtrl.state.isSelected = quranCtrl
                                      .selectedAyahIndexes
                                      .contains(ayahs[ayahIndex].ayahUQNumber);
                                  final allBookmarks = bookmarks.values
                                      .expand((list) => list)
                                      .toList();
                                  if (ayahIndex == 0) {
                                    return span(
                                      isFirstAyah: true,
                                      text:
                                          '${ayahs[ayahIndex].code_v2[0]}${ayahs[ayahIndex].code_v2.substring(1)}',
                                      pageIndex: pageIndex,
                                      isSelected: quranCtrl.state.isSelected,
                                      fontSize: 100,
                                      surahNum: quranCtrl
                                          .getCurrentSurahByPage(pageIndex)
                                          .surahNumber,
                                      ayahUQNum: ayahs[ayahIndex].ayahUQNumber,
                                      onLongPressStart: (details) {
                                        if (onAyahLongPress != null) {
                                          onAyahLongPress!(
                                              details, ayahs[ayahIndex]);
                                          quranCtrl.toggleAyahSelection(
                                              ayahs[ayahIndex].ayahUQNumber);
                                        } else {
                                          final bookmarkId = allBookmarks.any(
                                                  (bookmark) =>
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
                                            showDialog(
                                                context: context,
                                                builder: (ctx) =>
                                                    AyahLongClickDialog(
                                                        ayahFonts:
                                                            ayahs[ayahIndex]));
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
                                    );
                                  }
                                  return span(
                                    isFirstAyah: false,
                                    text: ayahs[ayahIndex].code_v2,
                                    pageIndex: pageIndex,
                                    isSelected: quranCtrl.state.isSelected,
                                    fontSize: 100,
                                    surahNum: quranCtrl
                                        .getCurrentSurahByPage(pageIndex)
                                        .surahNumber,
                                    ayahUQNum: ayahs[ayahIndex].ayahUQNumber,
                                    onLongPressStart: (details) {
                                      if (onAyahLongPress != null) {
                                        onAyahLongPress!(
                                            details, ayahs[ayahIndex]);
                                        quranCtrl.toggleAyahSelection(
                                            ayahs[ayahIndex].ayahUQNumber);
                                      } else {
                                        final bookmarkId = allBookmarks.any(
                                                (bookmark) =>
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
                                          showDialog(
                                              context: context,
                                              builder: (ctx) =>
                                                  AyahLongClickDialog(
                                                      ayahFonts:
                                                          ayahs[ayahIndex]));
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
                                  );
                                }),
                              ),
                            )),
                      ),
                      quranCtrl.downThePageIndex.contains(pageIndex)
                          ? SurahHeaderWidget(
                              surahNumber ??
                                  quranCtrl
                                          .getSurahDataByAyah(ayahs.first)
                                          .surahNumber +
                                      1,
                              bannerStyle: bannerStyle ??
                                  BannerStyle(
                                    isImage: false,
                                    bannerSvgPath: AssetsPath().surahSvgBanner,
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
                                    indicatorColor:
                                        Colors.amber.withValues(alpha: 2),
                                    primaryColor:
                                        Colors.amber.withValues(alpha: 2),
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
      );
    });
  }
}
