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
    // شرح: تحسين RichText بإضافة خصائص الأداء
    // Explanation: Optimize RichText by adding performance properties
    return Obx(
      () => RichText(
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
            final allBookmarks =
                bookmarks.values.expand((list) => list).toList();
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
              surahNum: quranCtrl
                  .getCurrentSurahByPageNumber(pageIndex + 1)
                  .surahNumber,
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
                    quranCtrl
                        .toggleAyahSelection(ayahs[ayahIndex].ayahUQNumber);
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
                        secondMenuChild: secondMenuChild,
                        secondMenuChildOnTap: secondMenuChildOnTap,
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
      ),
    );
  }
}
