part of '/quran.dart';

class PageBuild extends StatelessWidget {
  const PageBuild({
    super.key,
    required this.pageIndex,
    required this.surahNumber,
    this.surahFilterNumber,
    required this.bannerStyle,
    required this.isDark,
    required this.surahNameStyle,
    required this.onSurahBannerPress,
    required this.basmalaStyle,
    required this.textColor,
    required this.bookmarks,
    required this.onAyahLongPress,
    required this.bookmarkList,
    required this.ayahIconColor,
    required this.showAyahBookmarkedIcon,
    required this.bookmarksAyahs,
    required this.bookmarksColor,
    required this.ayahSelectedBackgroundColor,
    required this.isFontsLocal,
    required this.fontsName,
    required this.ayahBookmarked,
    required this.context,
    required this.quranCtrl,
  });

  final int pageIndex;
  final int? surahNumber;
  final int? surahFilterNumber;
  final BannerStyle? bannerStyle;
  final bool isDark;
  final SurahNameStyle? surahNameStyle;
  final Function(SurahNamesModel surah)? onSurahBannerPress;
  final BasmalaStyle? basmalaStyle;
  final Color? textColor;
  final Map<int, List<BookmarkModel>> bookmarks;
  final Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;
  final List? bookmarkList;
  final Color? ayahIconColor;
  final bool showAyahBookmarkedIcon;
  final List<int> bookmarksAyahs;
  final Color? bookmarksColor;
  final Color? ayahSelectedBackgroundColor;
  final bool? isFontsLocal;
  final String? fontsName;
  final List<int> ayahBookmarked;
  final BuildContext context;
  final QuranCtrl quranCtrl;

  @override
  Widget build(BuildContext context) {
    if (!quranCtrl.isQpcLayoutEnabled) {
      return const SizedBox.shrink();
    }

    final blocks = quranCtrl.getQpcLayoutBlocksForPageSync(pageIndex + 1);
    if (blocks.isEmpty) {
      // أثناء غياب بيانات هذه الصفحة نعرض مؤشر تحميل بدل بناء متزامن.
      // تحضير الصفحة/المجاورة يتم عبر getQpcV4BlocksForPageSync.
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final isHafs = quranCtrl.state.fontsSelected.value == 0;

    return RepaintBoundary(
      child: Padding(
        padding: isHafs ? const EdgeInsets.all(8.0) : EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: blocks.map((b) {
            // عند عرض سورة واحدة: نتجاهل الهيدر/البسملة من الـ layout ونتركها للـ SurahPage.
            if (surahFilterNumber != null &&
                (b is QpcV4SurahHeaderBlock || b is QpcV4BasmallahBlock)) {
              return const SizedBox.shrink();
            }

            if (b is QpcV4SurahHeaderBlock) {
              return SurahHeaderWidget(
                b.surahNumber,
                bannerStyle: bannerStyle ??
                    BannerStyle().copyWith(
                      bannerSvgHeight: 40,
                    ),
                surahNameStyle: surahNameStyle ??
                    SurahNameStyle(
                      surahNameSize: 35,
                      surahNameColor: AppColors.getTextColor(isDark),
                    ),
                onSurahBannerPress: onSurahBannerPress,
                isDark: isDark,
              );
            }

            if (b is QpcV4BasmallahBlock) {
              return BasmallahWidget(
                surahNumber: b.surahNumber,
                basmalaStyle: basmalaStyle ??
                    BasmalaStyle(
                      basmalaColor: AppColors.getTextColor(isDark),
                      basmalaFontSize: 25.0,
                      verticalPadding: 0.0,
                    ),
              );
            }

            if (b is QpcV4AyahLineBlock) {
              final filteredSegments = (surahFilterNumber == null)
                  ? b.segments
                  : b.segments
                      .where((s) => s.surahNumber == surahFilterNumber)
                      .toList(growable: false);

              if (filteredSegments.isEmpty) {
                return const SizedBox.shrink();
              }

              return RepaintBoundary(
                child: QpcV4RichTextLine(
                  pageIndex: pageIndex,
                  textColor: textColor,
                  isDark: isDark,
                  bookmarks: bookmarks,
                  onAyahLongPress: onAyahLongPress,
                  bookmarkList: bookmarkList,
                  ayahIconColor: ayahIconColor,
                  showAyahBookmarkedIcon: showAyahBookmarkedIcon,
                  bookmarksAyahs: bookmarksAyahs,
                  bookmarksColor: bookmarksColor,
                  ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
                  context: context,
                  quranCtrl: quranCtrl,
                  segments: filteredSegments,
                  isFontsLocal: isFontsLocal ?? false,
                  fontsName: fontsName ?? '',
                  fontFamilyOverride:
                      isHafs ? quranCtrl.currentFontFamily : null,
                  fontPackageOverride: isHafs ? 'quran_library' : null,
                  usePaintColoring: !isHafs,
                  useHafsSizing: isHafs,
                  ayahBookmarked: ayahBookmarked,
                  isCentered: b.isCentered,
                ),
              );
            }

            return const SizedBox.shrink();
          }).toList(),
        ),
      ),
    );
  }
}
