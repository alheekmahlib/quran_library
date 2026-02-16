part of '/quran.dart';

TextSpan _qpcV4SpanSegment({
  required BuildContext context,
  required int pageIndex,
  required bool isSelected,
  required bool showAyahBookmarkedIcon,
  required double fontSize,
  required int ayahUQNum,
  required int ayahNumber,
  required WordRef wordRef,
  required bool isWordKhilaf,
  required String glyphs,
  required bool showAyahNumber,
  _LongPressStartDetailsFunction? onLongPressStart,
  required Color? textColor,
  required Color? ayahIconColor,
  required List<int> bookmarksAyahs,
  required List<int> ayahBookmarked,
  required List<BookmarkModel> allBookmarksList,
  Color? bookmarksColor,
  Color? ayahSelectedBackgroundColor,
  required bool isFontsLocal,
  required String fontsName,
  String? fontFamilyOverride,
  String? fontPackageOverride,
  bool usePaintColoring = true,
  required bool isDark,
}) {
  final quranCtrl = QuranCtrl.instance;
  final wordInfoCtrl = WordInfoCtrl.instance;

  final withTajweed = QuranCtrl.instance.state.isTajweedEnabled.value;
  final isTenRecitations = WordInfoCtrl.instance.isTenRecitations;
  final bool forceRed = isWordKhilaf && !withTajweed && isTenRecitations;

  // اختيار الخط: كلمات الخلاف تستخدم خط CPAL أحمر بدلاً من foreground Paint
  final String fontFamily;
  if (fontFamilyOverride != null) {
    fontFamily = fontFamilyOverride;
  } else if (isFontsLocal) {
    fontFamily = fontsName;
  } else if (forceRed) {
    fontFamily = quranCtrl.getRedFontPath(pageIndex);
  } else {
    fontFamily = quranCtrl.getFontPath(pageIndex, isDark: isDark);
  }

  final baseTextStyle = TextStyle(
    fontFamily: fontFamily,
    package: fontPackageOverride,
    fontSize: fontSize,
    height: 2.2,
    wordSpacing: usePaintColoring ? -2 : 0,
    color: textColor ?? AppColors.getTextColor(isDark),
  );

  InlineSpan? tail;
  final hasBookmark =
      ayahBookmarked.contains(ayahUQNum) || bookmarksAyahs.contains(ayahUQNum);
  if (showAyahNumber) {
    tail = hasBookmark && showAyahBookmarkedIcon && !kIsWeb
        ? WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: quranCtrl.isQpcV4Enabled
                  ? const EdgeInsets.symmetric(horizontal: 4.0)
                  : const EdgeInsets.only(right: 4.0, left: 4.0, bottom: 16.0),
              child: SvgPicture.asset(
                AssetsPath.assets.ayahBookmarked,
                height: quranCtrl.isQpcV4Enabled ? 30 : 100,
                width: quranCtrl.isQpcV4Enabled ? 30 : 100,
              ),
            ),
          )
        : TextSpan(
            text: usePaintColoring
                ? '${'$ayahNumber'.convertEnglishNumbersToArabic(ayahNumber.toString())}\u202F\u202F'
                : '\u202F${'$ayahNumber'.convertEnglishNumbersToArabic(ayahNumber.toString())}\u202F',
            style: TextStyle(
              fontFamily: 'ayahNumber',
              fontSize: usePaintColoring ? (fontSize + 5) : (fontSize + 5),
              height: 1.5,
              package: 'quran_library',
              color: ayahIconColor ?? Theme.of(context).colorScheme.primary,
            ),
            recognizer: LongPressGestureRecognizer(
                duration: const Duration(milliseconds: 500))
              ..onLongPressStart = onLongPressStart,
          );
  }

  final GestureRecognizer recognizer;
  if (!wordInfoCtrl.isWordSelectionEnabled) {
    // تحديد الكلمة معطّل: الضغط القصير لا يفعل شيئاً، الضغط المطوّل يفتح قائمة الآية
    recognizer = TapLongPressRecognizer(
      shortHoldDuration: const Duration(milliseconds: 150),
      longHoldDuration: const Duration(milliseconds: 500),
    )
      ..onShortHoldStartCallback = () {
        // فارغ عمداً — لإبقاء الحدث حياً حتى يصل للضغط المطوّل
      }
      ..onShortHoldCompleteCallback = null
      ..onLongHoldStartCallback = (details) {
        onLongPressStart?.call(details);
      };
  } else {
    recognizer = TapLongPressRecognizer(
      shortHoldDuration: const Duration(milliseconds: 150),
      longHoldDuration: const Duration(milliseconds: 500),
    )
      ..onShortHoldStartCallback = () {
        wordInfoCtrl.setSelectedWord(wordRef);
      }
      ..onShortHoldCompleteCallback = () {
        () async {
          await showWordInfoBottomSheet(
              context: context, ref: wordRef, isDark: isDark);
          wordInfoCtrl.clearSelectedWord();
        }();
      }
      ..onLongHoldStartCallback = (details) {
        wordInfoCtrl.clearSelectedWord();
        onLongPressStart?.call(details);
      };
  }

  return TextSpan(
    children: <InlineSpan>[
      TextSpan(
        text: glyphs,
        style: baseTextStyle,
        recognizer: recognizer,
      ),
      if (tail != null) tail,
    ],
  );
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
