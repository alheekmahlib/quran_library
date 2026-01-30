part of '/quran.dart';

class QpcV4RichTextLine extends StatelessWidget {
  const QpcV4RichTextLine({
    super.key,
    required this.pageIndex,
    required this.textColor,
    required this.isDark,
    required this.bookmarks,
    required this.onAyahLongPress,
    required this.bookmarkList,
    required this.ayahIconColor,
    required this.showAyahBookmarkedIcon,
    required this.bookmarksAyahs,
    required this.bookmarksColor,
    required this.ayahSelectedBackgroundColor,
    required this.context,
    required this.quranCtrl,
    required this.segments,
    required this.isFontsLocal,
    required this.fontsName,
    this.fontFamilyOverride,
    this.fontPackageOverride,
    this.usePaintColoring = true,
    this.useHafsSizing = false,
    required this.ayahBookmarked,
    required this.isCentered,
  });

  final int pageIndex;
  final Color? textColor;
  final bool isDark;
  final Map<int, List<BookmarkModel>> bookmarks;
  final Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;
  final List? bookmarkList;
  final Color? ayahIconColor;
  final bool showAyahBookmarkedIcon;
  final List<int> bookmarksAyahs;
  final Color? bookmarksColor;
  final Color? ayahSelectedBackgroundColor;
  final BuildContext context;
  final QuranCtrl quranCtrl;
  final List<QpcV4WordSegment> segments;
  final bool isFontsLocal;
  final String fontsName;
  final String? fontFamilyOverride;
  final String? fontPackageOverride;
  final bool usePaintColoring;
  final bool useHafsSizing;
  final List<int> ayahBookmarked;
  final bool isCentered;

  @override
  Widget build(BuildContext context) {
    final bookmarksSet = bookmarksAyahs.toSet();
    final wordInfoCtrl = WordInfoCtrl.instance;

    // بعد تحميل بيانات القراءات، نحاول تهيئة سور هذه السطر بالخلفية.
    // ملاحظة: استخدمنا prewarm مجمّع + حارس لتجنب تكرار الاستدعاءات أثناء build.
    if (wordInfoCtrl.isKindAvailable(WordInfoKind.recitations)) {
      final surahs = segments.map((s) => s.surahNumber);
      Future(() => wordInfoCtrl.prewarmRecitationsSurahs(surahs));
    }

    return GetBuilder<QuranCtrl>(
      id: 'selection_page_',
      builder: (_) => LayoutBuilder(
        builder: (ctx, constraints) {
          /// TODO: هنا يتم ضبط حجم الخط.
          final fs =
              // useHafsSizing
              //     ?
              useHafsSizing
                  ? PageFontSizeHelper.getFontSize(
                        pageIndex,
                        ctx,
                      ) -
                      4
                  : PageFontSizeHelper.getFontSize(
                      pageIndex,
                      ctx,
                    )
              //     :
              //     PageFontSizeHelper.qcfFontSize(
              //   context: ctx,
              //   pageIndex: pageIndex,
              //   maxWidth: constraints.maxWidth,
              // )
              ;

          return GetBuilder<WordInfoCtrl>(
            id: 'word_info_data',
            builder: (_) {
              return _richTextBuild(wordInfoCtrl, context, fs, bookmarksSet);
            },
          );
        },
      ),
    );
  }

  Widget _richTextBuild(WordInfoCtrl wordInfoCtrl, BuildContext context,
      double fs, Set<int> bookmarksSet) {
    /// TODO: وهنا يتم وضع الـ FittedBox لوضع النص على حسب حجم الشاشة.
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: isCentered ? TextAlign.center : TextAlign.justify,
      softWrap: true,
      overflow: TextOverflow.visible,
      maxLines: null,
      text: TextSpan(
        children: List.generate(segments.length, (segmentIndex) {
          final seg = segments[segmentIndex];
          final uq = seg.ayahUq;
          final isSelectedCombined =
              quranCtrl.selectedAyahsByUnequeNumber.contains(uq) ||
                  quranCtrl.externallyHighlightedAyahs.contains(uq);

          final ref = WordRef(
            surahNumber: seg.surahNumber,
            ayahNumber: seg.ayahNumber,
            wordNumber: seg.wordNumber,
          );

          final info = wordInfoCtrl.getRecitationsInfoSync(ref);
          final hasKhilaf = info?.hasKhilaf ?? false;

          return _qpcV4SpanSegment(
            context: context,
            pageIndex: pageIndex,
            isSelected: isSelectedCombined,
            showAyahBookmarkedIcon: showAyahBookmarkedIcon,
            fontSize: fs,
            ayahUQNum: uq,
            ayahNumber: seg.ayahNumber,
            glyphs: seg.glyphs,
            showAyahNumber: seg.isAyahEnd,
            wordRef: ref,
            isWordKhilaf: hasKhilaf,
            onLongPressStart: (details) {
              final ayahModel = quranCtrl.getAyahByUq(uq);

              if (onAyahLongPress != null) {
                onAyahLongPress!(details, ayahModel);
                quranCtrl.toggleAyahSelection(uq);
                quranCtrl.state.isShowMenu.value = false;
                return;
              }

              int? bookmarkId;
              for (final b in bookmarks.values.expand((list) => list)) {
                if (b.ayahId == uq) {
                  bookmarkId = b.id;
                  break;
                }
              }

              if (bookmarkId != null) {
                BookmarksCtrl.instance.removeBookmark(bookmarkId);
                return;
              }

              if (quranCtrl.isMultiSelectMode.value) {
                quranCtrl.toggleAyahSelectionMulti(uq);
              } else {
                quranCtrl.toggleAyahSelection(uq);
              }
              quranCtrl.state.isShowMenu.value = false;

              final themedTafsirStyle = TafsirTheme.of(context)?.style;
              showAyahMenuDialog(
                context: context,
                isDark: isDark,
                ayah: ayahModel,
                position: details.globalPosition,
                index: segmentIndex,
                pageIndex: pageIndex,
                externalTafsirStyle: themedTafsirStyle,
              );
            },
            textColor: textColor ?? (AppColors.getTextColor(isDark)),
            ayahIconColor: ayahIconColor,
            bookmarks: bookmarks,
            bookmarksAyahs: bookmarksSet.toList(),
            bookmarksColor: bookmarksColor,
            ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
            isFontsLocal: isFontsLocal,
            fontsName: fontsName,
            fontFamilyOverride: fontFamilyOverride,
            fontPackageOverride: fontPackageOverride,
            usePaintColoring: usePaintColoring,
            ayahBookmarked: ayahBookmarked,
            isDark: isDark,
          );
        }),
      ),
    );
  }
}
