part of '/quran.dart';

class RichTextBuild extends StatelessWidget {
  const RichTextBuild({
    super.key,
    required this.pageIndex,
    required this.textColor,
    required this.isDark,
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
    required this.context,
    required this.quranCtrl,
    required this.ayahs,
    required this.isFontsLocal,
    required this.fontsName,
    required this.ayahBookmarked,
    required this.anotherMenuChild,
    required this.anotherMenuChildOnTap,
  });

  final int pageIndex;
  final Color? textColor;
  final bool isDark;
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
  final BuildContext context;
  final QuranCtrl quranCtrl;
  final List<AyahModel> ayahs;
  final bool isFontsLocal;
  final String fontsName;
  final List<int> ayahBookmarked;
  final Widget? anotherMenuChild;
  final Function(AyahModel ayah)? anotherMenuChildOnTap;

  @override
  Widget build(BuildContext context) {
    // تحضيرات لتقليل الحسابات داخل الحلقة
    final Set<int> bookmarksSet = bookmarksAyahs.toSet();
    final currentSurahNumber =
        quranCtrl.getCurrentSurahByPageNumber(pageIndex + 1).surahNumber;

    // شرح: إعادة بناء انتقائي عند تغيّر تحديد الآيات في الصفحة فقط
    return GetBuilder<QuranCtrl>(
      id: 'selection_page_',
      builder: (_) => LayoutBuilder(
        builder: (ctx, constraints) {
          final fs = PageFontSizeHelper.qcfFontSize(
            context: ctx,
            pageIndex: pageIndex,
            maxWidth: constraints.maxWidth,
          );
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
                // fontFamily: isFontsLocal ? fontsName : 'p${(pageIndex + 2001)}',
                // fontFamily:
                //     isFontsLocal ? fontsName : quranCtrl.getFontPath(pageIndex),
                // fontSize: fs,
                // height: 1.7,
                shadows: quranCtrl.state.isBold.value
                    ? [
                        Shadow(
                          blurRadius: 0.5,
                          color: textColor ?? (AppColors.getTextColor(isDark)),
                          offset: const Offset(0.5, 0.5),
                        ),
                      ]
                    : const [],
              ),
              children: List.generate(ayahs.length, (ayahIndex) {
                final ayah = ayahs[ayahIndex];
                final isFirstAyah = ayahIndex == 0 &&
                    (ayah.ayahNumber != 1 ||
                        quranCtrl._startSurahsNumbers.contains(
                            quranCtrl.getSurahDataByAyah(ayah).surahNumber));
                final text = isFirstAyah
                    ? '${ayah.codeV2![0]}${ayah.codeV2!.substring(1)}'
                    : ayah.codeV2!;
                final uq = ayah.ayahUQNumber;
                final isSelectedCombined =
                    quranCtrl.selectedAyahsByUnequeNumber.contains(uq) ||
                        quranCtrl.externallyHighlightedAyahs.contains(uq);
                return _span(
                  context: context,
                  isFirstAyah: isFirstAyah,
                  text: text,
                  isDark: isDark,
                  pageIndex: pageIndex,
                  isSelected: isSelectedCombined,
                  fontSize: fs,
                  surahNum: currentSurahNumber,
                  ayahUQNum: uq,
                  ayahNum: ayah.ayahNumber,
                  ayahBookmarked: ayahBookmarked,
                  onLongPressStart: (details) {
                    if (onAyahLongPress != null) {
                      onAyahLongPress!(details, ayah);
                      quranCtrl.toggleAyahSelection(uq);
                      quranCtrl.state.isShowMenu.value = false;
                    } else {
                      int? bookmarkId;
                      for (final b in bookmarks.values.expand((list) => list)) {
                        if (b.ayahId == uq) {
                          bookmarkId = b.id;
                          break;
                        }
                      }
                      if (bookmarkId != null) {
                        BookmarksCtrl.instance.removeBookmark(bookmarkId);
                      } else {
                        // حدث التحديد (متعدد أو عادي)
                        if (quranCtrl.isMultiSelectMode.value) {
                          quranCtrl.toggleAyahSelectionMulti(uq);
                        } else {
                          quranCtrl.toggleAyahSelection(uq);
                        }
                        quranCtrl.state.isShowMenu.value = false;

                        final themedTafsirStyle =
                            TafsirTheme.of(context)?.style;
                        showAyahMenuDialog(
                          context: context,
                          isDark: isDark,
                          ayah: ayah,
                          position: details.globalPosition,
                          index: ayahIndex,
                          pageIndex: pageIndex,
                          anotherMenuChild: anotherMenuChild,
                          anotherMenuChildOnTap: anotherMenuChildOnTap,
                          secondMenuChild: secondMenuChild,
                          secondMenuChildOnTap: secondMenuChildOnTap,
                          externalTafsirStyle: themedTafsirStyle,
                        );
                      }
                    }
                  },
                  bookmarkList: bookmarkList,
                  textColor: textColor ?? (AppColors.getTextColor(isDark)),
                  ayahIconColor: ayahIconColor,
                  showAyahBookmarkedIcon: showAyahBookmarkedIcon,
                  bookmarks: bookmarks,
                  bookmarksAyahs: bookmarksSet.toList(),
                  bookmarksColor: bookmarksColor,
                  ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
                  isFontsLocal: isFontsLocal,
                  fontsName: fontsName,
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
