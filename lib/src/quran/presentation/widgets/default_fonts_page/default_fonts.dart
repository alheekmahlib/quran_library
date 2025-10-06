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
            children: line.ayahs.reversed.map((ayah) {
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
                  ? (bookmarksAyahs.contains(ayah.ayahUQNumber) ? true : false)
                  : ayahBookmarked;
              // final String lastCharacter =
              //     ayah.ayah.substring(ayah.ayah.length - 1);
              return WidgetSpan(
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
                      color: (isUserSelected || isExternallyHighlighted)
                          ? ayahSelectedFontColor
                          : textColor ?? (isDark ? Colors.white : Colors.black),
                      fontSize: 22.55,
                      fontFamily: "hafs",
                      height: 1.3,
                      package: "quran_library",
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
