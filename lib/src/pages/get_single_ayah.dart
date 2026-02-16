part of '../../quran.dart';

class GetSingleAyah extends StatelessWidget {
  final int surahNumber;
  final int ayahNumber;
  final Color? textColor;
  final bool? isDark;
  final bool? isBold;
  final double? fontSize;
  final AyahModel? ayahs;
  final bool? isSingleAyah;
  final bool? islocalFont;
  final String? fontsName;
  final int? pageIndex;
  final Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;
  final Color? ayahIconColor;
  final bool showAyahBookmarkedIcon;
  final Color? bookmarksColor;
  final Color? ayahSelectedBackgroundColor;
  final TextAlign? textAlign;

  GetSingleAyah({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    this.textColor,
    this.isDark = false,
    this.fontSize,
    this.isBold = true,
    this.ayahs,
    this.isSingleAyah = true,
    this.islocalFont = false,
    this.fontsName,
    this.pageIndex,
    this.onAyahLongPress,
    this.ayahIconColor,
    this.showAyahBookmarkedIcon = false,
    this.bookmarksColor,
    this.ayahSelectedBackgroundColor,
    this.textAlign,
  });

  final QuranCtrl quranCtrl = QuranCtrl.instance;

  @override
  Widget build(BuildContext context) {
    if (surahNumber < 1 || surahNumber > 114) {
      return Text(
        'رقم السورة غير صحيح',
        style: TextStyle(
          fontSize: fontSize ?? 22,
          color: textColor ?? AppColors.getTextColor(isDark!),
        ),
        textAlign: textAlign,
      );
    }
    final ayah = ayahs ??
        QuranCtrl.instance
            .getSingleAyahByAyahAndSurahNumber(ayahNumber, surahNumber);
    final pageNumber = pageIndex ??
        QuranCtrl.instance
            .getPageNumberByAyahAndSurahNumber(ayahNumber, surahNumber);
    QuranFontsService.ensurePagesLoaded(pageNumber, radius: 1).then((_) {
      // update();
      // update(['_pageViewBuild']);
      // تحميل بقية الصفحات في الخلفية
      QuranFontsService.loadRemainingInBackground(
        startNearPage: pageNumber,
        progress: QuranCtrl.instance.state.fontsLoadProgress,
        ready: QuranCtrl.instance.state.fontsReady,
      ).then((_) {
        // update();
        QuranCtrl.instance.update(['single_ayah_$surahNumber-$ayahNumber']);
      });
    });
    log('surahNumber: $surahNumber, ayahNumber: $ayahNumber, pageNumber: $pageNumber');

    if (ayah.text.isEmpty) {
      return Text(
        'الآية غير موجودة',
        style: TextStyle(
          fontSize: fontSize ?? 22,
          color: textColor ?? AppColors.getTextColor(isDark!),
        ),
        textAlign: textAlign,
      );
    }

    // استخدام نفس طريقة عرض PageBuild إذا كان QPC Layout مفعل
    if (quranCtrl.isQpcLayoutEnabled) {
      return GetBuilder<QuranCtrl>(
          id: 'single_ayah_$surahNumber-$ayahNumber',
          builder: (_) {
            return _buildQpcLayout(context, pageNumber, ayah);
          });
    }

    // العرض التقليدي للخطوط الأخرى
    return _buildTraditionalLayout(context, pageNumber, ayah);
  }

  /// بناء الآية باستخدام نفس طريقة PageBuild (QPC Layout)
  Widget _buildQpcLayout(BuildContext context, int pageNumber, AyahModel ayah) {
    final blocks = quranCtrl.getQpcLayoutBlocksForPageSync(pageNumber);
    if (blocks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }
    final ayahUq = ayah.ayahUQNumber;

    // استخراج segments الخاصة بالآية المطلوبة فقط
    final List<QpcV4WordSegment> ayahSegments = [];
    for (final block in blocks) {
      if (block is QpcV4AyahLineBlock) {
        for (final seg in block.segments) {
          if (seg.surahNumber == surahNumber && seg.ayahNumber == ayahNumber) {
            ayahSegments.add(seg);
          }
        }
      }
    }

    if (ayahSegments.isEmpty) {
      // fallback للعرض التقليدي إذا لم يتم العثور على segments
      return _buildTraditionalLayout(context, pageNumber, ayah);
    }

    return GetBuilder<QuranCtrl>(
      id: 'single_ayah_$ayahUq',
      builder: (_) => LayoutBuilder(
        builder: (ctx, constraints) {
          final fs =
              (fontSize ?? PageFontSizeHelper.getFontSize(pageNumber - 1, ctx));

          return _buildRichTextFromSegments(
            context: context,
            segments: ayahSegments,
            fontSize: fs,
            ayahUq: ayahUq,
            pageNumber: pageNumber,
          );
        },
      ),
    );
  }

  /// بناء RichText من segments
  Widget _buildRichTextFromSegments({
    required BuildContext context,
    required List<QpcV4WordSegment> segments,
    required double fontSize,
    required int ayahUq,
    required int pageNumber,
  }) {
    final wordInfoCtrl = WordInfoCtrl.instance;
    final bookmarksCtrl = BookmarksCtrl.instance;
    final bookmarks = bookmarksCtrl.bookmarks;
    final bookmarksAyahs = bookmarksCtrl.bookmarksAyahs;
    final ayahBookmarked = bookmarksAyahs.toList();
    final allBookmarksList = bookmarks.values.expand((list) => list).toList();

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: textAlign ?? TextAlign.right,
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
            pageIndex: pageNumber - 1,
            isSelected: isSelectedCombined,
            showAyahBookmarkedIcon: showAyahBookmarkedIcon,
            fontSize: fontSize,
            ayahUQNum: uq,
            ayahNumber: seg.ayahNumber,
            glyphs: seg.glyphs,
            showAyahNumber: seg.isAyahEnd,
            wordRef: ref,
            isWordKhilaf: hasKhilaf,
            textColor: textColor ?? AppColors.getTextColor(isDark ?? false),
            ayahIconColor: ayahIconColor,
            allBookmarksList: allBookmarksList,
            bookmarksAyahs: bookmarksAyahs,
            bookmarksColor: bookmarksColor,
            ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
            isFontsLocal: islocalFont ?? false,
            fontsName: fontsName ?? '',
            fontFamilyOverride: null,
            fontPackageOverride: null,
            usePaintColoring: true,
            ayahBookmarked: ayahBookmarked,
            isDark: isDark ?? false,
          );
        }),
      ),
    );
  }

  /// العرض التقليدي للخطوط غير QPC
  Widget _buildTraditionalLayout(
      BuildContext context, int pageNumber, AyahModel ayah) {
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      softWrap: true,
      overflow: TextOverflow.visible,
      maxLines: null,
      text: TextSpan(
        style: TextStyle(
          fontFamily: islocalFont == true
              ? fontsName
              : QuranCtrl.instance
                  .getFontPath(pageNumber - 1, isDark: isDark ?? false),
          package: 'quran_library',
          fontSize: fontSize ?? 22,
          height: 2.0,
          fontWeight: isBold! ? FontWeight.bold : FontWeight.normal,
          color: textColor ?? AppColors.getTextColor(isDark!),
        ),
        children: [
          TextSpan(
            text: '${ayah.text.replaceAll('\n', '').split(' ').join(' ')} ',
          ),
          TextSpan(
            text: '${ayah.ayahNumber}'
                .convertEnglishNumbersToArabic('${ayah.ayahNumber}'),
            style: TextStyle(
              fontFamily: 'ayahNumber',
              package: 'quran_library',
              color: ayahIconColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
