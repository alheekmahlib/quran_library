part of '../../quran.dart';

class QuranLine extends StatelessWidget {
  QuranLine(
    this.context,
    this.line,
    this.bookmarksAyahs,
    this.bookmarks, {
    super.key,
    this.boxFit = BoxFit.fill,
    this.onDefaultAyahLongPress,
    this.bookmarksColor,
    this.textColor,
    this.ayahSelectedBackgroundColor,
    this.bookmarkList,
    this.onPagePress,
    required this.pageIndex,
    required this.ayahBookmarked,
    this.ayahSelectedFontColor,
    this.anotherMenuChild,
    this.anotherMenuChildOnTap,
    required this.isDark,
  });

  final quranCtrl = QuranCtrl.instance;

  final BuildContext context;
  final LineModel line;
  final List<int> bookmarksAyahs;
  final Map<int, List<BookmarkModel>> bookmarks;
  final BoxFit boxFit;
  final Function(LongPressStartDetails details, AyahModel ayah)?
      onDefaultAyahLongPress;
  final VoidCallback? onPagePress;
  final Color? bookmarksColor;
  final Color? textColor;
  final Color? ayahSelectedBackgroundColor;
  final Color? ayahSelectedFontColor;
  final List? bookmarkList;
  final int pageIndex;
  final List<int> ayahBookmarked;
  final Widget? anotherMenuChild;
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GetX<QuranCtrl>(
      builder: (quranCtrl) {
        return FittedBox(
          fit: boxFit,
          child: RichText(
              text: TextSpan(
            children: line.ayahs.reversed.map((ayah) {
              quranCtrl.isAyahSelected = quranCtrl.selectedAyahsByUnequeNumber
                  .contains(ayah.ayahUQNumber);
              final allBookmarks =
                  bookmarks.values.expand((list) => list).toList();
              ayahBookmarked.isEmpty
                  ? (bookmarksAyahs.contains(ayah.ayahUQNumber) ? true : false)
                  : ayahBookmarked;
              // final String lastCharacter =
              //     ayah.ayah.substring(ayah.ayah.length - 1);
              return WidgetSpan(
                child: GestureDetector(
                  onTap: () {
                    if (onPagePress != null) {
                      onPagePress!();
                    }
                    quranCtrl.clearSelection();
                    quranCtrl.state.overlayEntry?.remove();
                    quranCtrl.state.overlayEntry = null;
                  },
                  onLongPressStart: (details) {
                    if (onDefaultAyahLongPress != null) {
                      onDefaultAyahLongPress!(details, ayah);
                      quranCtrl.toggleAyahSelection(ayah.ayahUQNumber);
                    } else {
                      final bookmarkId = allBookmarks.any((bookmark) =>
                              bookmark.ayahId == ayah.ayahUQNumber)
                          ? allBookmarks
                              .firstWhere((bookmark) =>
                                  bookmark.ayahId == ayah.ayahUQNumber)
                              .id
                          : null;
                      if (bookmarkId != null) {
                        BookmarksCtrl.instance.removeBookmark(bookmarkId);
                      } else {
                        quranCtrl.toggleAyahSelection(ayah.ayahUQNumber);
                        quranCtrl.state.overlayEntry?.remove();
                        quranCtrl.state.overlayEntry = null;

                        // إنشاء OverlayEntry جديد
                        final overlay = Overlay.of(context);
                        final newOverlayEntry = OverlayEntry(
                          builder: (context) => AyahLongClickDialog(
                            context: context,
                            isDark: isDark,
                            ayah: ayah,
                            position: details.globalPosition,
                            index: ayah.ayahNumber,
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color: ayahBookmarked.contains(ayah.ayahUQNumber)
                          ? bookmarksColor
                          : (bookmarksAyahs.contains(ayah.ayahUQNumber)
                              ? Color(allBookmarks
                                      .firstWhere(
                                        (b) => b.ayahId == ayah.ayahUQNumber,
                                      )
                                      .colorCode)
                                  .withValues(alpha: 0.3)
                              : quranCtrl.isAyahSelected
                                  ? ayahSelectedBackgroundColor ??
                                      const Color(0xffCDAD80)
                                          .withValues(alpha: 0.25)
                                  : null),
                    ),
                    child: Text(
                      ayah.text,
                      style: TextStyle(
                        color: quranCtrl.selectedAyahsByUnequeNumber
                                .contains(ayah.ayahUQNumber)
                            ? ayahSelectedFontColor
                            : textColor ??
                                (isDark ? Colors.white : Colors.black),
                        fontSize: 22.55,
                        fontFamily: "hafs",
                        height: 1.3,
                        package: "quran_library",
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            style: QuranLibrary().hafsStyle,
          )),
        );
      },
    );
  }
}
