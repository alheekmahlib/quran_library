part of '/quran.dart';

class TextScaleRichTextBuild extends StatelessWidget {
  TextScaleRichTextBuild({
    super.key,
    required this.textColor,
    required this.isDark,
    required this.ayahs,
    required this.bookmarks,
    required this.pageIndex,
    required this.ayahBookmarked,
    required this.onAyahLongPress,
    required this.anotherMenuChild,
    required this.anotherMenuChildOnTap,
    required this.secondMenuChild,
    required this.secondMenuChildOnTap,
    required this.bookmarkList,
    required this.ayahIconColor,
    required this.showAyahBookmarkedIcon,
    required this.bookmarksAyahs,
    required this.bookmarksColor,
    required this.ayahSelectedBackgroundColor,
    required this.languageCode,
  });

  final Color? textColor;
  final bool isDark;
  final List<AyahModel> ayahs;
  final Map<int, List<BookmarkModel>> bookmarks;
  final int pageIndex;
  final List<int> ayahBookmarked;
  final Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;
  final Widget? anotherMenuChild;
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;
  final Widget? secondMenuChild;
  final void Function(AyahModel ayah)? secondMenuChildOnTap;
  final List? bookmarkList;
  final Color? ayahIconColor;
  final bool showAyahBookmarkedIcon;
  final List<int> bookmarksAyahs;
  final Color? bookmarksColor;
  final Color? ayahSelectedBackgroundColor;
  final String? languageCode;
  final quranCtrl = QuranCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RichText(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'hafs',
            fontSize: 20 * quranCtrl.state.scaleFactor.value,
            height: 1.7,
            // letterSpacing: 2,
            fontWeight: FontWeight.bold,
            color: textColor ?? (isDark ? Colors.white : Colors.black),
            // shadows: [
            //   Shadow(
            //     blurRadius: 0.5,
            //     color: quranCtrl.state.isBold.value == 0
            //         ? Colors.black
            //         : Colors.transparent,
            //     offset: const Offset(0.5, 0.5),
            //   ),
            // ],
            package: 'quran_library',
          ),
          children: List.generate(ayahs.length, (ayahIndex) {
            final allBookmarks =
                bookmarks.values.expand((list) => list).toList();
            return _customSpan(
              text: ayahs[ayahIndex].text,
              isDark: isDark,
              pageIndex: pageIndex,
              isSelected: quranCtrl.selectedAyahsByUnequeNumber
                  .contains(ayahs[ayahIndex].ayahUQNumber),
              fontSize: 20 * quranCtrl.state.scaleFactor.value,
              surahNum: quranCtrl
                  .getCurrentSurahByPageNumber(pageIndex + 1)
                  .surahNumber,
              ayahUQNum: ayahs[ayahIndex].ayahUQNumber,
              hasBookmark:
                  ayahBookmarked.contains(ayahs[ayahIndex].ayahUQNumber),
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
              ayahNumber: ayahs[ayahIndex].ayahNumber,
              languageCode: languageCode,
            );
          }),
        ),
      ),
    );
  }
}
