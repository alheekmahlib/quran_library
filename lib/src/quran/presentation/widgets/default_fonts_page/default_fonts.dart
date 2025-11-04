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
    this.ayahLongClickStyle,
    this.tafsirStyle,
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
  final AyahLongClickStyle? ayahLongClickStyle;
  final TafsirStyle? tafsirStyle;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<QuranCtrl>(
      id: 'selection_page_',
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
                            // تحديث التحديد
                            if (quranCtrl.isMultiSelectMode.value) {
                              quranCtrl
                                  .toggleAyahSelectionMulti(ayah.ayahUQNumber);
                            } else {
                              quranCtrl.toggleAyahSelection(ayah.ayahUQNumber);
                            }
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
                                secondMenuChild: secondMenuChild,
                                secondMenuChildOnTap: secondMenuChildOnTap,
                                style: ayahLongClickStyle ??
                                    AyahLongClickStyle.defaults(
                                        isDark: isDark, context: context),
                                tafsirStyle: tafsirStyle ??
                                    TafsirStyle.defaults(
                                        isDark: isDark, context: context),
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
                                : textColor ?? (AppColors.getTextColor(isDark)),
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
