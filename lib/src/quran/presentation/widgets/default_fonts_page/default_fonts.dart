part of '/quran.dart';

class DefaultFontsBuild extends StatelessWidget {
  DefaultFontsBuild(
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
    required this.pageIndex,
    required this.ayahBookmarked,
    this.ayahSelectedFontColor,
    this.anotherMenuChild,
    this.anotherMenuChildOnTap,
    required this.isDark,
    this.secondMenuChild,
    this.secondMenuChildOnTap,
  });

  final quranCtrl = QuranCtrl.instance;

  final BuildContext context;
  final LineModel line;
  final List<int> bookmarksAyahs;
  final Map<int, List<BookmarkModel>> bookmarks;
  final BoxFit boxFit;
  final Function(LongPressStartDetails details, AyahModel ayah)?
      onDefaultAyahLongPress;
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
  final Widget? secondMenuChild;
  final void Function(AyahModel ayah)? secondMenuChildOnTap;

  @override
  Widget build(BuildContext context) {
    return GetX<QuranCtrl>(
      builder: (quranCtrl) {
        return FittedBox(
          fit: boxFit,
          child: RichText(
            text: TextSpan(
              children: () {
                final reversedAyahs = line.ayahs.reversed.toList();
                return List.generate(reversedAyahs.length, (i) {
                  final ayah = reversedAyahs[i];
                  final isUserSelected = quranCtrl.selectedAyahsByUnequeNumber
                      .contains(ayah.ayahUQNumber);
                  final isExternallyHighlighted = quranCtrl
                      .externallyHighlightedAyahs
                      .contains(ayah.ayahUQNumber);
                  quranCtrl.isAyahSelected =
                      isUserSelected || isExternallyHighlighted;
                  final allBookmarks =
                      bookmarks.values.expand((list) => list).toList();
                  ayahBookmarked.isEmpty
                      ? (bookmarksAyahs.contains(ayah.ayahUQNumber)
                          ? true
                          : false)
                      : ayahBookmarked;
                  return WidgetSpan(
                    child: GestureDetector(
                      onLongPressStart: (details) {
                        // استدعِ رد النداء إن وجد
                        if (onDefaultAyahLongPress != null) {
                          onDefaultAyahLongPress!(details, ayah);
                        }
                        // إزالة الإشارة المرجعية إن وجدت
                        final bookmarkId = allBookmarks.any((bookmark) =>
                                bookmark.ayahId == ayah.ayahUQNumber)
                            ? allBookmarks
                                .firstWhere((bookmark) =>
                                    bookmark.ayahId == ayah.ayahUQNumber)
                                .id
                            : null;
                        if (bookmarkId != null) {
                          BookmarksCtrl.instance.removeBookmark(bookmarkId);
                          return;
                        }

                        // تحديث التحديد
                        if (quranCtrl.isMultiSelectMode.value) {
                          quranCtrl.toggleAyahSelectionMulti(ayah.ayahUQNumber);
                        } else {
                          quranCtrl.toggleAyahSelection(ayah.ayahUQNumber);
                        }

                        // عرض حوار الخيارات
                        quranCtrl.state.overlayEntry?.remove();
                        quranCtrl.state.overlayEntry = null;
                        final overlay = Overlay.of(context);
                        final newOverlayEntry = OverlayEntry(
                          builder: (context) => AyahLongClickDialog(
                            context: context,
                            isDark: isDark,
                            ayah: ayah,
                            position: details.globalPosition,
                            index: i,
                            pageIndex: pageIndex,
                            anotherMenuChild: anotherMenuChild,
                            anotherMenuChildOnTap: anotherMenuChildOnTap,
                            secondMenuChild: secondMenuChild,
                            secondMenuChildOnTap: secondMenuChildOnTap,
                          ),
                        );
                        quranCtrl.state.overlayEntry = newOverlayEntry;
                        overlay.insert(newOverlayEntry);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                          color: ayahBookmarked.contains(ayah.ayahUQNumber)
                              ? bookmarksColor
                              : (bookmarksAyahs.contains(ayah.ayahUQNumber)
                                  ? Color(allBookmarks
                                          .firstWhere(
                                            (b) =>
                                                b.ayahId == ayah.ayahUQNumber,
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
                            color: (isUserSelected || isExternallyHighlighted)
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
                });
              }(),
              style: QuranLibrary().hafsStyle,
            ),
          ),
        );
      },
    );
  }
}
