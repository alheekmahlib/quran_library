part of '/quran.dart';

class DefaultFontsPageBuild extends StatelessWidget {
  const DefaultFontsPageBuild({
    super.key,
    required this.quranCtrl,
    required this.pageIndex,
    required this.newSurahs,
    required this.surahNumber,
    required this.bannerStyle,
    required this.isDark,
    required this.surahNameStyle,
    required this.onSurahBannerPress,
    required this.basmalaStyle,
    // required this.deviceSize,
    required this.onAyahLongPress,
    required this.bookmarksColor,
    required this.textColor,
    required this.bookmarkList,
    required this.ayahSelectedBackgroundColor,
    required this.ayahBookmarked,
    required this.context,
    required this.constraints,
    required this.ayahIconColor,
    required this.showAyahBookmarkedIcon,
  });

  final QuranCtrl quranCtrl;
  final int pageIndex;
  final List<String> newSurahs;
  final int? surahNumber;
  final BannerStyle? bannerStyle;
  final bool isDark;
  final SurahNameStyle? surahNameStyle;
  final Function(SurahNamesModel surah)? onSurahBannerPress;
  final BasmalaStyle? basmalaStyle;
  // final Size deviceSize;
  final Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;
  final Color? bookmarksColor;
  final Color? textColor;
  final List? bookmarkList;
  final Color? ayahSelectedBackgroundColor;
  final List<int> ayahBookmarked;
  final BuildContext context;
  final BoxConstraints constraints;
  final Color ayahIconColor;
  final bool showAyahBookmarkedIcon;

  @override
  Widget build(BuildContext context) {
    final bookmarkCtrl = BookmarksCtrl.instance;

    final deviceSize = MediaQuery.sizeOf(context);
    final isDesktop = Responsive.isDesktop(context);
    final page = quranCtrl.staticPages[pageIndex];
    final width = isDesktop ? deviceSize.width - 120.w : deviceSize.width - 20;
    // حساب الارتفاع الأساسي حسب الاتجاه
    final baseHeight = UiHelper.currentOrientation(
      constraints.maxHeight,
      deviceSize.width * 1.6,
      context,
    );

    // ارتفاع ثابت لعنوان السورة (البسملة + البانر)
    const double surahHeaderHeight = 110.0;
    const double surahHeaderHeightPage186 = 80.0;

    final surahHeaderOffset =
        pageIndex != 186 ? surahHeaderHeight : surahHeaderHeightPage186;

    // المساحة المتاحة بعد خصم ارتفاعات رؤوس السور
    final totalSurahHeadersHeight = page.numberOfNewSurahs * surahHeaderOffset;

    // نسبة الهامش للمسافات بين الأسطر
    const double lineSpacingFactor = 0.98;

    // الارتفاع المتاح للأسطر
    final availableHeight =
        (baseHeight - totalSurahHeadersHeight) * lineSpacingFactor;

    // ارتفاع السطر الواحد
    final height = availableHeight / page.lines.length;

    final ayahsSepratededBySurahs = quranCtrl
        .getCurrentPageAyahsSeparatedForBasmalahQcfV1AsLines(pageIndex);

    return RepaintBoundary(
      child: ListView.separated(
        itemCount: ayahsSepratededBySurahs.length,
        separatorBuilder: (context, index) {
          final line = ayahsSepratededBySurahs[index].first;
          final surahNum = line.ayahs.first.surahNumber!;
          return _surahName(line, isDesktop, surahNum);
        },
        itemBuilder: (context, index) {
          final lines = ayahsSepratededBySurahs[index].map((e) {
            return SizedBox(
              width: width,
              height: height,
              child: DefaultFontsBuild(
                context,
                e,
                isDark: isDark,
                bookmarkCtrl.bookmarksAyahs,
                bookmarkCtrl.bookmarks,
                boxFit:
                    e.ayahs.last.centered! ? BoxFit.contain : BoxFit.fitWidth,
                onDefaultAyahLongPress: onAyahLongPress,
                bookmarksColor: bookmarksColor,
                textColor: textColor ?? (AppColors.getTextColor(isDark)),
                bookmarkList: bookmarkList,
                pageIndex: pageIndex,
                ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
                ayahBookmarked: ayahBookmarked,
                ayahIconColor: ayahIconColor,
                showAyahBookmarkedIcon: showAyahBookmarkedIcon,
              ),
            );
          }).toList();
          return Column(
            children: [
              if (ayahsSepratededBySurahs[index].first.ayahs.first.ayahNumber ==
                      1 &&
                  ayahsSepratededBySurahs[index] ==
                      ayahsSepratededBySurahs.first)
                _surahName(
                    ayahsSepratededBySurahs[index].first,
                    isDesktop,
                    ayahsSepratededBySurahs[index]
                        .first
                        .ayahs
                        .first
                        .surahNumber!),
              ...lines
            ],
          );
        },
      ),
    );
  }

  Widget _surahName(LineModel line, bool isDesktop, int surahNum) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SurahHeaderWidget(
          surahNumber ?? line.ayahs.first.surahNumber!,
          bannerStyle: bannerStyle ??
              BannerStyle(
                isImage: false,
                bannerSvgPath: AssetsPath.assets.surahSvgBanner,
                bannerSvgHeight:
                    isDesktop ? 50.0.h.clamp(70, 150) : 35.0.h.clamp(35, 90),
                bannerSvgWidth: 150.0.w.clamp(150, 250),
                bannerImagePath: '',
                bannerImageHeight: 50,
                bannerImageWidth: double.infinity,
              ),
          surahNameStyle: surahNameStyle ??
              SurahNameStyle(
                surahNameSize:
                    isDesktop ? 40.sp.clamp(40, 80) : 27.sp.clamp(27, 64),
                surahNameColor: AppColors.getTextColor(isDark),
              ),
          onSurahBannerPress: onSurahBannerPress,
          isDark: isDark,
        ),
        if (pageIndex != 186)
          BasmallahWidget(
            surahNumber: surahNum,
            basmalaStyle: basmalaStyle ??
                BasmalaStyle(
                  basmalaColor: AppColors.getTextColor(isDark),
                  basmalaFontSize: 22.0.sp.clamp(22, 50),
                  verticalPadding: 0.0,
                ),
          ),
      ],
    );
  }
}
