part of '../flutter_quran_screen.dart';

class QuranLine extends StatelessWidget {
  QuranLine(this.line, this.bookmarksAyahs, this.bookmarks,
      {super.key,
      this.boxFit = BoxFit.fill,
      this.onAyahLongPress,
      this.bookmarksColor,
      this.textColor,
      this.ayahSelectedBackgroundColor,
      this.bookmarkList,
      this.onAyahPress,
      required this.pageIndex});

  final quranCtrl = QuranCtrl.instance;

  final Line line;
  final List<int> bookmarksAyahs;
  final Map<int, List<BookmarkModel>> bookmarks;
  final BoxFit boxFit;
  final Function? onAyahLongPress;
  final Function? onAyahPress;
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
        return GestureDetector(
          onScaleStart: (details) =>
              quranCtrl.baseScaleFactor.value = quranCtrl.scaleFactor.value,
          onScaleUpdate: (ScaleUpdateDetails details) =>
              quranCtrl.updateTextScale(details),
          child: quranCtrl.textScale(textBuild(context, hasBookmark),
              textScaleBuild(context, hasBookmark)),
        );
      },
    );
  }

  Widget textBuild(BuildContext context, var hasBookmark) {
    return FittedBox(
      fit: boxFit,
      child: RichText(
          text: TextSpan(
        children: line.ayahs.reversed.map((ayah) {
          quranCtrl.isAyahSelected =
              quranCtrl.selectedAyahIndexes.contains(ayah.id);
          final allBookmarks = bookmarks.values.expand((list) => list).toList();
          // final String lastCharacter =
          //     ayah.ayah.substring(ayah.ayah.length - 1);
          return WidgetSpan(
            child: GestureDetector(
              onTap: () {
                if (onAyahPress != null) {
                  onAyahPress!();
                }
                quranCtrl.clearSelection();
              },
              onLongPressStart: (details) {
                if (onAyahLongPress != null) {
                  onAyahLongPress!(details, ayah);
                  quranCtrl.toggleAyahSelection(ayah.id);
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
                    showDialog(
                        context: context,
                        builder: (ctx) => AyahLongClickDialog(ayah: ayah));
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
        style: FlutterQuran().hafsStyle,
      )),
    );
  }

  Widget textScaleBuild(BuildContext context, var hasBookmark) {
    return RichText(
        text: TextSpan(
      children: line.ayahs.reversed.map((ayah) {
        quranCtrl.isAyahSelected =
            quranCtrl.selectedAyahIndexes.contains(ayah.id);
        final allBookmarks = bookmarks.values.expand((list) => list).toList();
        // final String lastCharacter =
        //     ayah.ayah.substring(ayah.ayah.length - 1);
        return WidgetSpan(
          child: GestureDetector(
            onTap: () {
              quranCtrl.clearSelection();
              onAyahPress!();
            },
            onLongPressStart: (details) {
              if (onAyahLongPress != null) {
                onAyahLongPress!(details, ayah);
                quranCtrl.toggleAyahSelection(ayah.id);
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
                  showDialog(
                      context: context,
                      builder: (ctx) => AyahLongClickDialog(ayah: ayah));
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
      style: FlutterQuran().hafsStyle,
    ));
  }
}
