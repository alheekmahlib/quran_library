part of '../pages/quran_library_screen.dart';

class QuranLine extends StatelessWidget {
  QuranLine(this.line, this.bookmarksAyahs, this.bookmarks,
      {super.key,
      this.boxFit = BoxFit.fill,
      this.onAyahLongPress,
      this.bookmarksColor,
      this.textColor,
      this.ayahSelectedBackgroundColor,
      this.bookmarkList,
      this.onPagePress,
      required this.pageIndex});

  final quranCtrl = QuranCtrl.instance;

  final Line line;
  final List<int> bookmarksAyahs;
  final Map<int, List<BookmarkModel>> bookmarks;
  final BoxFit boxFit;
  final Function? onAyahLongPress;
  final Function? onPagePress;
  final Color? bookmarksColor;
  final Color? textColor;
  final Color? ayahSelectedBackgroundColor;
  final List? bookmarkList;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    RxBool hasBookmark(int surahNum, int ayahUQNum) {
      return (bookmarkList!.firstWhereOrNull(((element) =>
                  element.surahNumber == surahNum &&
                  element.ayahUQNumber == ayahUQNum)) !=
              null)
          ? true.obs
          : false.obs;
    }

    return GetX<QuranCtrl>(
      builder: (quranCtrl) {
        return FittedBox(
          fit: boxFit,
          child: RichText(
              text: TextSpan(
            children: line.ayahs.reversed.map((ayah) {
              quranCtrl.isAyahSelected =
                  quranCtrl.selectedAyahIndexes.contains(ayah.id);
              final allBookmarks =
                  bookmarks.values.expand((list) => list).toList();
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
                    if (onAyahLongPress != null) {
                      onAyahLongPress!(details, ayah);
                      quranCtrl.toggleAyahSelection(ayah.id);
                    } else {
                      final bookmarkId = allBookmarks
                              .any((bookmark) => bookmark.ayahId == ayah.id)
                          ? allBookmarks
                              .firstWhere(
                                  (bookmark) => bookmark.ayahId == ayah.id)
                              .id
                          : null;
                      if (bookmarkId != null) {
                        BookmarksCtrl.instance.removeBookmark(bookmarkId);
                      } else {
                        quranCtrl.toggleAyahSelection(ayah.id);
                        quranCtrl.state.overlayEntry?.remove();
                        quranCtrl.state.overlayEntry = null;

                        // إنشاء OverlayEntry جديد
                        final overlay = Overlay.of(context);
                        if (overlay != null) {
                          final newOverlayEntry = OverlayEntry(
                            builder: (context) => AyahLongClickDialog(
                              ayah: ayah,
                              position: details.globalPosition,
                            ),
                          );

                          quranCtrl.state.overlayEntry = newOverlayEntry;

                          // إدخال OverlayEntry في Overlay
                          overlay.insert(newOverlayEntry);
                        }
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color: hasBookmark(ayah.surahNumber, ayah.id).value
                          ? bookmarksColor
                          : (bookmarksAyahs.contains(ayah.id)
                              ? Color(allBookmarks
                                      .firstWhere(
                                        (b) => b.ayahId == ayah.id,
                                      )
                                      .colorCode)
                                  .withValues(alpha: 0.7)
                              : quranCtrl.isAyahSelected
                                  ? ayahSelectedBackgroundColor ??
                                      const Color(0xffCDAD80)
                                          .withValues(alpha: 0.25)
                                  : null),
                    ),
                    child: Text(
                      ayah.ayah,
                      style: TextStyle(
                        color: textColor ?? Colors.black,
                        fontSize: 23.55,
                        fontFamily: "hafs",
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

  Widget textScaleBuild(BuildContext context, var hasBookmark) {
    return RichText(
        text: TextSpan(
      children: quranCtrl.staticPages[pageIndex].ayahs.map((ayah) {
        quranCtrl.isAyahSelected =
            quranCtrl.selectedAyahIndexes.contains(ayah.id);
        final allBookmarks = bookmarks.values.expand((list) => list).toList();
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
              if (onAyahLongPress != null) {
                onAyahLongPress!(details, ayah);
                quranCtrl.toggleAyahSelection(ayah.id);
                quranCtrl.state.overlayEntry?.remove();
                quranCtrl.state.overlayEntry = null;
              } else {
                final bookmarkId = allBookmarks
                        .any((bookmark) => bookmark.ayahId == ayah.id)
                    ? allBookmarks
                        .firstWhere((bookmark) => bookmark.ayahId == ayah.id)
                        .id
                    : null;
                if (bookmarkId != null) {
                  BookmarksCtrl.instance.removeBookmark(bookmarkId);
                } else {
                  quranCtrl.toggleAyahSelection(ayah.id);
                  quranCtrl.state.overlayEntry?.remove();
                  quranCtrl.state.overlayEntry = null;

                  // إنشاء OverlayEntry جديد
                  final overlay = Overlay.of(context);
                  if (overlay != null) {
                    final newOverlayEntry = OverlayEntry(
                      builder: (context) => AyahLongClickDialog(
                        ayah: ayah,
                        position: details.globalPosition,
                      ),
                    );

                    quranCtrl.state.overlayEntry = newOverlayEntry;

                    // إدخال OverlayEntry في Overlay
                    overlay.insert(newOverlayEntry);
                  }
                }
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: hasBookmark(ayah.surahNumber, ayah.id).value
                    ? bookmarksColor
                    : (bookmarksAyahs.contains(ayah.id)
                        ? Color(allBookmarks
                                .firstWhere(
                                  (b) => b.ayahId == ayah.id,
                                )
                                .colorCode)
                            .withValues(alpha: 0.7)
                        : quranCtrl.isAyahSelected
                            ? ayahSelectedBackgroundColor ??
                                const Color(0xffCDAD80).withValues(alpha: 0.25)
                            : null),
              ),
              child: Text(
                ayah.ayah.replaceAll('\n', ''),
                style: TextStyle(
                  color: textColor ?? Colors.black,
                  fontSize: 23.55 * quranCtrl.state.scaleFactor.value,
                  fontFamily: "hafs",
                  package: "quran_library",
                ),
              ),
            ),
          ),
        );
      }).toList(),
      style: QuranLibrary().hafsStyle,
    ));
  }
}
