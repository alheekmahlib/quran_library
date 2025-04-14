part of '../../../../quran.dart';

TextSpan _span({
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
}) {
  // if (bookmarkList!.isEmpty) {
  //   bookmarkList = bookmarks as List<BookmarkModel>;
  // }
  bool pageSpacing = pageIndex == 45 ||
          pageIndex == 54 ||
          pageIndex == 56 ||
          pageIndex == 75 ||
          pageIndex == 76 ||
          pageIndex == 150 ||
          pageIndex == 539
      ? true
      : false;
  if (text.isNotEmpty) {
    final String partOne = pageSpacing
        ? text.length < 3
            ? ' ${text[0]}'
            : ' ${text[0]} ${text[1]}'
        : text.length < 3
            ? text[0]
            : '${text[0]}${text[1]}';
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
    final String lastCharacter = text.substring(text.length - 1);
    final allBookmarks = bookmarks.values.expand((list) => list).toList();
    final quranCtrl = QuranCtrl.instance;
    ayahBookmarked == false
        ? (bookmarksAyahs.contains(ayahUQNum) ? true : false)
        : ayahBookmarked;
    TextSpan? first;
    TextSpan? second;
    if (isFirstAyah) {
      first = TextSpan(
        text: partOne,
        style: TextStyle(
          fontFamily: isFontsLocal ? fontsName : 'p${(pageIndex + 2001)}',
          fontSize: fontSize,
          height: 2.1,
          letterSpacing: pageSpacing ? -5 : 30,
          color: quranCtrl.state.fontsSelected2.value == 1
              ? textColor ?? Colors.transparent
              : null,
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
          fontFamily: isFontsLocal ? fontsName : 'p${(pageIndex + 2001)}',
          fontSize: fontSize,
          height: 2.1,
          letterSpacing: 0,
          // wordSpacing: wordSpacing + 10,
          color: quranCtrl.state.fontsSelected2.value == 1
              ? textColor ?? Colors.transparent
              : null,
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
      text: initialPart,
      style: TextStyle(
        fontFamily: isFontsLocal ? fontsName : 'p${(pageIndex + 2001)}',
        fontSize: fontSize,
        height: 2.1,
        letterSpacing: 0,
        color: quranCtrl.state.fontsSelected2.value == 1
            ? textColor ?? Colors.transparent
            : null,
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
            showAyahBookmarkedIcon
        ? WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SvgPicture.asset(
                _AssetsPath().ayahBookmarked,
                height: 100,
                width: 100,
              ),
            ))
        : TextSpan(
            text: lastCharacter,
            style: TextStyle(
              fontFamily: isFontsLocal ? fontsName : 'p${(pageIndex + 2001)}',
              fontSize: fontSize,
              height: 2.1,
              letterSpacing: isFirstAyah &&
                      (pageIndex == 1 ||
                          pageIndex == 49 ||
                          pageIndex == 476 ||
                          pageIndex == 482 ||
                          pageIndex == 495 ||
                          pageIndex == 498)
                  ? 20
                  : null,
              color: ayahIconColor,
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
  Color? ayahSelectedFontColor,
  String? languageCode,
  required bool hasBookmark,
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
            color: textColor ?? Colors.black,
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
                    _AssetsPath().ayahBookmarked,
                    height: 35,
                  ),
                ))
            : TextSpan(
                text: ayahNumber
                    .toString()
                    .convertNumbersAccordingToLang(languageCode: languageCode),
                style: TextStyle(
                  fontFamily: 'hafs',
                  fontSize: fontSize,
                  height: 2.1,
                  color: ayahIconColor,
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
