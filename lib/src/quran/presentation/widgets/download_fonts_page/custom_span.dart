part of '/quran.dart';

TextSpan _span({
  required BuildContext context,
  required String text,
  required int pageIndex,
  required bool isSelected,
  double? fontSize,
  required int surahNum,
  required int ayahNum,
  required int ayahUQNum,
  _LongPressStartDetailsFunction? onLongPressStart,
  required bool isFirstAyah,
  required bool showAyahBookmarkedIcon,
  required List? bookmarkList,
  required Color? textColor,
  required Color? ayahIconColor,
  required Map<int, List<BookmarkModel>> bookmarks,
  required List<int> bookmarksAyahs,
  Color? bookmarksColor,
  Color? ayahSelectedBackgroundColor,
  required bool isFontsLocal,
  required String fontsName,
  required List<int> ayahBookmarked,
  required bool isDark,
}) {
  // if (bookmarkList!.isEmpty) {
  //   bookmarkList = bookmarks as List<BookmarkModel>;
  // }
  // bool pageSpacing = pageIndex == 45 ||
  //         pageIndex == 54 ||
  //         pageIndex == 56 ||
  //         pageIndex == 75 ||
  //         pageIndex == 76 ||
  //         pageIndex == 150 ||
  //         pageIndex == 539
  //     ? true
  //     : false;
  if (text.isNotEmpty) {
    final String partOne =
        text.length < 3 ? "${text[0]}\u200A" : "${text[0]}\u200A${text[1]}";
    // final String partOne = pageSpacing
    //     ? text.length < 3
    //         ? ' ${text[0]}'
    //         : ' ${text[0]} ${text[1]}'
    //     : text.length < 3
    //         ? text[0]
    //         : '${text[0]}${text[1]}';
    // final String partOne = pageIndex == 250
    //     ? text.length < 3
    //         ? text[0]
    //         : text[0] + text[1]
    //     : text.length < 3
    //         ? text[0]
    //         : text[0] + text[1];
    final String? partTwo =
        text.length > 2 ? text.substring(2, text.length - 1) : null;
    final String initialPart = text.substring(0, text.length - 1);
    // final String lastCharacter = text.substring(text.length - 1);
    final allBookmarks = bookmarks.values.expand((list) => list).toList();
    final quranCtrl = QuranCtrl.instance;
    ayahBookmarked.isEmpty
        ? (bookmarksAyahs.contains(ayahUQNum) ? true : false)
        : ayahBookmarked;
    TextSpan? first;
    TextSpan? second;
    if (isFirstAyah) {
      first = TextSpan(
        text: partOne,
        style: TextStyle(
          fontFamily:
              isFontsLocal ? fontsName : quranCtrl.getFontPath(pageIndex),
          fontSize: fontSize,
          height: 2.1,
          // letterSpacing: 6,
          color: quranCtrl.state.fontsSelected.value == 1
              ? textColor ?? Colors.transparent
              : isDark
                  ? Colors.white
                  : Colors.black,
          backgroundColor: ayahBookmarked.contains(ayahUQNum)
              ? bookmarksColor
              : (bookmarksAyahs.contains(ayahUQNum)
                  ? bookmarksColor ??
                      Color(allBookmarks
                              .firstWhere(
                                (b) => b.ayahId == ayahUQNum,
                              )
                              .colorCode)
                          .withValues(alpha: 0.3)
                  : isSelected
                      ? ayahSelectedBackgroundColor ??
                          const Color(0xffCDAD80).withValues(alpha: 0.25)
                      : null),
        ),
        recognizer: LongPressGestureRecognizer(
            duration: const Duration(milliseconds: 500))
          ..onLongPressStart = onLongPressStart,
      );
      second = TextSpan(
        text: partTwo,
        style: TextStyle(
          fontFamily:
              isFontsLocal ? fontsName : quranCtrl.getFontPath(pageIndex),
          fontSize: fontSize,
          height: 2.1,
          // letterSpacing: 6,
          color: quranCtrl.state.fontsSelected.value == 1
              ? textColor ?? Colors.transparent
              : isDark
                  ? Colors.white
                  : Colors.black,
          backgroundColor: ayahBookmarked.contains(ayahUQNum)
              ? bookmarksColor
              : (bookmarksAyahs.contains(ayahUQNum)
                  ? bookmarksColor ??
                      Color(allBookmarks
                              .firstWhere(
                                (b) => b.ayahId == ayahUQNum,
                              )
                              .colorCode)
                          .withValues(alpha: 0.3)
                  : isSelected
                      ? ayahSelectedBackgroundColor ??
                          const Color(0xffCDAD80).withValues(alpha: 0.25)
                      : null),
        ),
        recognizer: LongPressGestureRecognizer(
            duration: const Duration(milliseconds: 500))
          ..onLongPressStart = onLongPressStart,
      );
    }

    final TextSpan initialTextSpan = TextSpan(
      text: '\u200A\u200A$initialPart',
      style: TextStyle(
        fontFamily: isFontsLocal ? fontsName : quranCtrl.getFontPath(pageIndex),
        fontSize: fontSize,
        height: 2.1,
        // letterSpacing: 6,
        color: quranCtrl.state.fontsSelected.value == 1
            ? textColor ?? Colors.transparent
            : isDark
                ? Colors.white
                : Colors.black,
        backgroundColor: ayahBookmarked.contains(ayahUQNum)
            ? bookmarksColor
            : (bookmarksAyahs.contains(ayahUQNum)
                ? bookmarksColor ??
                    Color(allBookmarks
                            .firstWhere(
                              (b) => b.ayahId == ayahUQNum,
                            )
                            .colorCode)
                        .withValues(alpha: 0.3)
                : isSelected
                    ? ayahSelectedBackgroundColor ??
                        const Color(0xffCDAD80).withValues(alpha: 0.25)
                    : null),
      ),
      recognizer: LongPressGestureRecognizer(
          duration: const Duration(milliseconds: 500))
        ..onLongPressStart = onLongPressStart,
    );

    var lastCharacterSpan = (ayahBookmarked.contains(ayahUQNum) ||
                bookmarksAyahs.contains(ayahUQNum)) &&
            showAyahBookmarkedIcon &&
            !kIsWeb
        ? WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SvgPicture.asset(
                AssetsPath.assets.ayahBookmarked,
                height: 140,
                width: 140,
              ),
            ),
          )
        : TextSpan(
            text: '$ayahNum'.convertEnglishNumbersToArabic(ayahNum.toString()),
            style: TextStyle(
              fontFamily: 'ayahNumber',
              fontSize: fontSize! + 25,
              // letterSpacing: 5,
              height: 1.6,
              package: 'quran_library',
              color: ayahIconColor ?? Theme.of(context).colorScheme.primary,
              backgroundColor: ayahBookmarked.contains(ayahUQNum)
                  ? bookmarksColor
                  : (bookmarksAyahs.contains(ayahUQNum)
                      ? bookmarksColor ??
                          Color(allBookmarks
                                  .firstWhere(
                                    (b) => b.ayahId == ayahUQNum,
                                  )
                                  .colorCode)
                              .withValues(alpha: 0.3)
                      : isSelected
                          ? ayahSelectedBackgroundColor ??
                              const Color(0xffCDAD80).withValues(alpha: 0.25)
                          : null),
            ),
            recognizer: LongPressGestureRecognizer(
                duration: const Duration(milliseconds: 500))
              ..onLongPressStart = onLongPressStart,
          );

    return TextSpan(
      children: isFirstAyah
          ? [first!, second!, lastCharacterSpan]
          : [initialTextSpan, lastCharacterSpan],
      recognizer: LongPressGestureRecognizer(
          duration: const Duration(milliseconds: 500))
        ..onLongPressStart = onLongPressStart,
    );
  } else {
    return const TextSpan(text: '');
  }
}

TextSpan _customSpan({
  required BuildContext context,
  required String text,
  required int pageIndex,
  required bool isSelected,
  required bool showAyahBookmarkedIcon,
  double? fontSize,
  required int surahNum,
  required int ayahUQNum,
  required int ayahNumber,
  _LongPressStartDetailsFunction? onLongPressStart,
  required List? bookmarkList,
  required Color? textColor,
  required Color? ayahIconColor,
  required Map<int, List<BookmarkModel>> bookmarks,
  required List<int> bookmarksAyahs,
  Color? bookmarksColor,
  Color? ayahSelectedBackgroundColor,
  String? languageCode,
  required bool hasBookmark,
  required bool isDark,
}) {
  final allBookmarks = bookmarks.values.expand((list) => list).toList();
  hasBookmark == false
      ? (bookmarksAyahs.contains(ayahUQNum) ? true : false)
      : hasBookmark;
  if (text.isNotEmpty) {
    return TextSpan(
      children: [
        TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'hafs',
            fontSize: fontSize,
            height: 2.1,
            color: textColor ?? (AppColors.getTextColor(isDark)),
            backgroundColor: hasBookmark
                ? bookmarksColor
                : (bookmarksAyahs.contains(ayahUQNum)
                    ? bookmarksColor ??
                        Color(allBookmarks
                                .firstWhere(
                                  (b) => b.ayahId == ayahUQNum,
                                )
                                .colorCode)
                            .withValues(alpha: 0.3)
                    : isSelected
                        ? ayahSelectedBackgroundColor ??
                            const Color(0xffCDAD80).withValues(alpha: 0.25)
                        : null),
            package: "quran_library",
          ),
          recognizer: LongPressGestureRecognizer(
              duration: const Duration(milliseconds: 500))
            ..onLongPressStart = onLongPressStart,
        ),
        (hasBookmark || bookmarksAyahs.contains(ayahUQNum)) &&
                showAyahBookmarkedIcon
            ? WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SvgPicture.asset(
                    AssetsPath.assets.ayahBookmarked,
                    height: fontSize,
                  ),
                ))
            : TextSpan(
                text: ' $ayahNumber '
                    .convertNumbersAccordingToLang(languageCode: languageCode),
                style: TextStyle(
                  fontFamily: 'ayahNumber',
                  fontSize: fontSize,
                  height: 2.1,
                  color: ayahIconColor ?? Theme.of(context).colorScheme.primary,
                  backgroundColor: hasBookmark
                      ? bookmarksColor
                      : (bookmarksAyahs.contains(ayahUQNum)
                          ? bookmarksColor ??
                              Color(allBookmarks
                                      .firstWhere(
                                        (b) => b.ayahId == ayahUQNum,
                                      )
                                      .colorCode)
                                  .withValues(alpha: 0.3)
                          : isSelected
                              ? ayahSelectedBackgroundColor ??
                                  const Color(0xffCDAD80)
                                      .withValues(alpha: 0.25)
                              : null),
                  package: "quran_library",
                ),
                recognizer: LongPressGestureRecognizer(
                    duration: const Duration(milliseconds: 500))
                  ..onLongPressStart = onLongPressStart,
              ),
      ],
      recognizer: LongPressGestureRecognizer(
          duration: const Duration(milliseconds: 500))
        ..onLongPressStart = onLongPressStart,
    );
  } else {
    return const TextSpan(text: '');
  }
}

typedef _LongPressStartDetailsFunction = void Function(LongPressStartDetails)?;
