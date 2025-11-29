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
    this.ayahIconColor,
    required this.showAyahBookmarkedIcon,
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
  final Color? ayahIconColor;
  final bool showAyahBookmarkedIcon;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<QuranCtrl>(
      id: 'selection_page_',
      builder: (quranCtrl) => FittedBox(
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
                final isSelected = isUserSelected || isExternallyHighlighted;
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
                          if (!context.mounted) return;
                          final overlay = Overlay.of(context);
                          // التقاط النمط مبكرًا من سياق تحت QuranLibraryTheme
                          final themedTafsirStyle =
                              TafsirTheme.of(context)?.style;
                          final newOverlayEntry = OverlayEntry(
                            builder: (context) => AyahMenuDialog(
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
                              externalTafsirStyle: themedTafsirStyle,
                            ),
                          );

                          quranCtrl.state.overlayEntry = newOverlayEntry;

                          // إدخال OverlayEntry في Overlay
                          overlay.insert(newOverlayEntry);
                        }
                      }
                    },
                    child: AyahDisplayBuild(
                      ayahBookmarked: ayahBookmarked,
                      ayah: ayah,
                      bookmarksColor: bookmarksColor,
                      bookmarksAyahs: bookmarksAyahs,
                      allBookmarks: allBookmarks,
                      ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
                      textColor: textColor,
                      isDark: isDark,
                      showAyahBookmarkedIcon: showAyahBookmarkedIcon,
                      ayahIconColor: ayahIconColor,
                      isSelected: isSelected,
                    ),
                  ),
                );
              });
            }(),
            // style: TextStyle(
            //   color: textColor ?? AppColors.getTextColor(isDark),
            //   // fontSize: 22.55,
            //   fontFamily: 'hafs',
            //   // height: 1.3,
            //   package: 'quran_library',
            // ),
          ),
        ),
      ),
    );
  }
}

class AyahDisplayBuild extends StatelessWidget {
  const AyahDisplayBuild({
    super.key,
    required this.ayahBookmarked,
    required this.ayah,
    required this.bookmarksColor,
    required this.bookmarksAyahs,
    required this.allBookmarks,
    required this.ayahSelectedBackgroundColor,
    required this.textColor,
    required this.isDark,
    required this.showAyahBookmarkedIcon,
    required this.ayahIconColor,
    required this.isSelected,
  });

  final List<int> ayahBookmarked;
  final AyahModel ayah;
  final Color? bookmarksColor;
  final List<int> bookmarksAyahs;
  final List<BookmarkModel> allBookmarks;
  final Color? ayahSelectedBackgroundColor;
  final Color? textColor;
  final bool isDark;
  final bool showAyahBookmarkedIcon;
  final Color? ayahIconColor;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    // فصل رقم الآية من النص الأصلي لإتاحة تلوينه بشكل مستقل
    final parts = _splitAyahTail(ayah.text);
    final quranCtrl = QuranCtrl.instance;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        color: ayahBookmarked.contains(ayah.ayahUQNumber)
            ? bookmarksColor
            : (bookmarksAyahs.contains(ayah.ayahUQNumber)
                ? Color(
                    allBookmarks
                        .firstWhere((b) => b.ayahId == ayah.ayahUQNumber)
                        .colorCode,
                  ).withValues(alpha: .30)
                : isSelected
                    ? ayahSelectedBackgroundColor ??
                        const Color(0xffCDAD80).withValues(alpha: .25)
                    : null),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: textColor ?? AppColors.getTextColor(isDark),
            // fontSize: 22.55,
            fontFamily: quranCtrl.currentFontFamily,
            height: 2,
            package: 'quran_library',
          ),
          children: [
            TextSpan(text: parts.body),
            if (parts.tail.isNotEmpty)
              (ayahBookmarked.contains(ayah.ayahUQNumber) ||
                          bookmarksAyahs.contains(ayah.ayahUQNumber)) &&
                      showAyahBookmarkedIcon
                  ? WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SvgPicture.asset(
                          AssetsPath.assets.ayahBookmarked,
                          height: 22.55,
                        ),
                      ))
                  : TextSpan(
                      text: RegExp(r'[\u0660-\u0669\u06F0-\u06F9]')
                              .hasMatch(parts.tail)
                          ? ' ${parts.tail}'
                          : ' ${ayah.ayahNumber.toString().convertEnglishNumbersToArabic(ayah.ayahNumber.toString())}',
                      style: TextStyle(
                        color: ayahIconColor ??
                            Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                        fontFamily: 'ayahNumber',
                        package: 'quran_library',
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  // يُعيد جزئين: body (النص دون الذيل) و tail (علامة نهاية الآية + الرقم أو رمز)
  AyahParts _splitAyahTail(String input) {
    // نلتقط الكلمة الأخيرة فقط إذا كانت رقمًا أو رمز نهاية آية محتمل
    // (أرقام عربية/فارسية مع أقواس، أو حرف واحد غير عربي مثل الرموز الخاصة)
    final reg = RegExp(
        r'((?:\s*[\u06DD]\s*)?(?:\s*[﴿\uFD3F]\s*)?[\u0660-\u0669\u06F0-\u06F9]+\s*(?:[﴾\uFD3E])?|[^\u0600-\u06FF\s]+)\s*$');
    final m = reg.firstMatch(input);
    if (m == null) {
      return AyahParts(input, '');
    }
    final tail = m.group(1) ?? '';
    // تحقق: إذا كان الذيل كلمة عربية عادية، لا نفصلها
    if (RegExp(r'^[\u0600-\u06FF]+$').hasMatch(tail)) {
      return AyahParts(input, '');
    }
    final start = m.start;
    final body = input.substring(0, start).trimRight();
    return AyahParts(body, tail);
  }
}

class AyahParts {
  final String body;
  final String tail;
  const AyahParts(this.body, this.tail);
}
