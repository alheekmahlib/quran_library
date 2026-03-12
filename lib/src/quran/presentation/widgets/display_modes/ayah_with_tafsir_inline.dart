part of '/quran.dart';

/// وضع عرض آيات الصفحة مع تفسير كل آية (عمودي وأفقي)
///
/// يعرض آيات الصفحة الحالية مع تفسير كل آية تحتها مباشرة.
/// يمكن التمرير عموديًا لقراءة كل الآيات، والتقليب يمين/يسار لتغيير الصفحة.
///
/// [AyahWithTafsirInline] Displays page ayahs with inline tafsir below each
/// ayah. Vertically scrollable, swipe left/right to change pages.
class AyahWithTafsirInline extends StatelessWidget {
  const AyahWithTafsirInline({
    super.key,
    required this.quranCtrl,
    required this.isDark,
    required this.languageCode,
    required this.onPageChanged,
    required this.onPagePress,
    required this.parentContext,
    this.style,
    this.bannerStyle,
    this.surahNameStyle,
    this.onSurahBannerPress,
    this.basmalaStyle,
    this.audioStyle,
    this.ayahDownloadManagerStyle,
    this.ayahBookmarked,
    this.isAyahBookmarked,
    this.showAyahBookmarkedIcon = true,
    this.bookmarksColor,
    this.usePageView = true,
    this.withOptionsBar = true,
    this.showAyahNumber = false,
  });

  final QuranCtrl quranCtrl;
  final bool isDark;
  final String languageCode;
  final Function(int pageNumber)? onPageChanged;
  final VoidCallback? onPagePress;
  final BuildContext parentContext;
  final AyahTafsirInlineStyle? style;
  final BannerStyle? bannerStyle;
  final SurahNameStyle? surahNameStyle;
  final Function(SurahNamesModel surah)? onSurahBannerPress;
  final BasmalaStyle? basmalaStyle;
  final AyahAudioStyle? audioStyle;
  final AyahDownloadManagerStyle? ayahDownloadManagerStyle;
  final List<int>? ayahBookmarked;
  final bool Function(AyahModel ayah)? isAyahBookmarked;
  final bool showAyahBookmarkedIcon;
  final Color? bookmarksColor;

  /// عند `false` يُعرض المحتوى بدون PageView ويستمع لتغيّر الصفحة من [QuranCtrl].
  /// عند استخدامه داخل [QuranWithTafsirSide] يجب أن يكون `false`.
  ///
  /// When `false`, content is shown without PageView and listens to
  /// page changes from [QuranCtrl]. Set to `false` inside [QuranWithTafsirSide].
  final bool usePageView;
  final bool? withOptionsBar;
  final bool? showAyahNumber;

  @override
  Widget build(BuildContext context) {
    final s = style ??
        (AyahTafsirInlineTheme.of(context)?.style ??
            AyahTafsirInlineStyle.defaults(isDark: isDark, context: context));

    // بدون PageView: يستمع لرقم الصفحة الحالية ويعرض المحتوى مباشرة
    if (!usePageView) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Obx(() {
          final currentPage = quranCtrl.state.currentPageNumber.value;
          final pageIndex = (currentPage - 1).clamp(0, 603);
          return _AyahTafsirInlinePage(
            key: ValueKey('inline_page_$pageIndex'),
            pageIndex: pageIndex,
            isDark: isDark,
            style: s,
            languageCode: languageCode,
            bannerStyle: bannerStyle,
            surahNameStyle: surahNameStyle,
            onSurahBannerPress: onSurahBannerPress,
            basmalaStyle: basmalaStyle,
            audioStyle: audioStyle,
            ayahDownloadManagerStyle: ayahDownloadManagerStyle,
            ayahBookmarked: ayahBookmarked ?? const [],
            isAyahBookmarked: isAyahBookmarked,
            showAyahBookmarkedIcon: showAyahBookmarkedIcon,
            bookmarksColor: bookmarksColor,
            withOptionsBar: withOptionsBar,
            showAyahNumber: showAyahNumber,
          );
        }),
      );
    }

    // مع PageView: التقليب الأفقي بين الصفحات
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PatchedPreloadPageView.builder(
        preloadPagesCount: 1,
        padEnds: false,
        itemCount: 604,
        controller: quranCtrl.getPageController(context),
        physics: const ClampingScrollPhysics(),
        onPageChanged: (pageIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            if (onPageChanged != null) onPageChanged!(pageIndex);
            quranCtrl.state.currentPageNumber.value = pageIndex + 1;
            quranCtrl.saveLastPage(pageIndex + 1);
          });
        },
        pageSnapping: true,
        itemBuilder: (ctx, index) => InkWell(
          onTap: () {
            if (onPagePress != null) {
              onPagePress!();
            } else {
              quranCtrl.showControlToggle();
              QuranCtrl.instance.state.isShowMenu.value = false;
            }
          },
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: _AyahTafsirInlinePage(
            pageIndex: index,
            isDark: isDark,
            style: s,
            languageCode: languageCode,
            bannerStyle: bannerStyle,
            surahNameStyle: surahNameStyle,
            onSurahBannerPress: onSurahBannerPress,
            basmalaStyle: basmalaStyle,
            audioStyle: audioStyle,
            ayahDownloadManagerStyle: ayahDownloadManagerStyle,
            ayahBookmarked: ayahBookmarked ?? const [],
            isAyahBookmarked: isAyahBookmarked,
            showAyahBookmarkedIcon: showAyahBookmarkedIcon,
            bookmarksColor: bookmarksColor,
            withOptionsBar: withOptionsBar,
            showAyahNumber: showAyahNumber,
          ),
        ),
      ),
    );
  }
}

/// صفحة واحدة في وضع الآية مع التفسير
class _AyahTafsirInlinePage extends StatefulWidget {
  const _AyahTafsirInlinePage({
    super.key,
    required this.pageIndex,
    required this.isDark,
    required this.style,
    required this.languageCode,
    this.bannerStyle,
    this.surahNameStyle,
    this.onSurahBannerPress,
    this.basmalaStyle,
    this.audioStyle,
    this.ayahDownloadManagerStyle,
    required this.ayahBookmarked,
    this.isAyahBookmarked,
    this.showAyahBookmarkedIcon = true,
    this.bookmarksColor,
    this.withOptionsBar = true,
    this.showAyahNumber = false,
  });

  final int pageIndex;
  final bool isDark;
  final AyahTafsirInlineStyle style;
  final String languageCode;
  final BannerStyle? bannerStyle;
  final SurahNameStyle? surahNameStyle;
  final Function(SurahNamesModel surah)? onSurahBannerPress;
  final BasmalaStyle? basmalaStyle;
  final AyahAudioStyle? audioStyle;
  final AyahDownloadManagerStyle? ayahDownloadManagerStyle;
  final List<int> ayahBookmarked;
  final bool Function(AyahModel ayah)? isAyahBookmarked;
  final bool showAyahBookmarkedIcon;
  final Color? bookmarksColor;
  final bool? withOptionsBar;
  final bool? showAyahNumber;

  @override
  State<_AyahTafsirInlinePage> createState() => _AyahTafsirInlinePageState();
}

class _AyahTafsirInlinePageState extends State<_AyahTafsirInlinePage>
    with AutomaticKeepAliveClientMixin {
  /// حفظ الـ Future مرة واحدة لتجنب إعادة التحميل في كل build
  late Future<void> _tafsirFuture;
  late int _lastRadioValue;

  /// كاش نتائج toFlutterText لتجنب إعادة تحليل HTML/Regex في كل build
  final Map<int, List<TextSpan>> _parsedTafsirCache = {};
  bool _lastIsDark = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _lastRadioValue = TafsirCtrl.instance.radioValue.value;
    _lastIsDark = widget.isDark;
    _tafsirFuture = _loadTafsir(widget.pageIndex + 1);
  }

  @override
  void didUpdateWidget(covariant _AyahTafsirInlinePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentRadio = TafsirCtrl.instance.radioValue.value;
    // أعد تحميل التفسير فقط إذا تغيّر رقم الصفحة أو مصدر التفسير
    if (oldWidget.pageIndex != widget.pageIndex ||
        _lastRadioValue != currentRadio) {
      _lastRadioValue = currentRadio;
      _parsedTafsirCache.clear();
      _tafsirFuture = _loadTafsir(widget.pageIndex + 1);
    }
    if (widget.isDark != _lastIsDark) {
      _lastIsDark = widget.isDark;
      _parsedTafsirCache.clear();
    }
  }

  Future<void> _loadTafsir(int pageNumber) async {
    final tafsirCtrl = TafsirCtrl.instance;
    if (tafsirCtrl.selectedTafsir.isTafsir) {
      await tafsirCtrl.fetchData(pageNumber);
    } else {
      await tafsirCtrl.fetchTranslate();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin
    final quranCtrl = QuranCtrl.instance;

    return FutureBuilder<void>(
      future: _tafsirFuture,
      builder: (context, snapshot) {
        final pageAyahs = quranCtrl.getPageAyahsByIndex(widget.pageIndex);
        if (pageAyahs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // شريط تغيير التفسير وحجم الخط
            widget.style.headerWidget ??
                _InlineTafsirHeader(
                  isDark: widget.isDark,
                  style: widget.style,
                  languageCode: widget.languageCode,
                ),
            // الآيات مع التفسير
            Expanded(
              child: GetBuilder<TafsirCtrl>(
                id: 'change_font_size',
                builder: (ctrl) {
                  // بناء Map للتفسير مرة واحدة بدل البحث الخطي لكل آية
                  final tafsirMap = <int, TafsirTableData>{};
                  for (final t in ctrl.tafseerList) {
                    tafsirMap[t.id] = t;
                  }
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: pageAyahs.length,
                    addAutomaticKeepAlives: true,
                    itemBuilder: (context, index) {
                      final ayah = pageAyahs[index];
                      final tafsir = tafsirMap[ayah.ayahUQNumber] ??
                          const TafsirTableData(
                            id: 0,
                            tafsirText: '',
                            ayahNum: 0,
                            pageNum: 0,
                            surahNum: 0,
                          );
                      // O(1) بدل O(n) — الوصول المباشر عبر surahNumber
                      final surahNum = ayah.surahNumber ?? 0;
                      final surah = (surahNum > 0 &&
                              surahNum <= quranCtrl.surahs.length)
                          ? quranCtrl.surahs[surahNum - 1]
                          : quranCtrl.getCurrentSurahByPageNumber(ayah.page);

                      // كاش toFlutterText لتجنب HTML parsing متكرر
                      List<TextSpan>? cachedSpans;
                      if (tafsir.tafsirText.isNotEmpty &&
                          ctrl.selectedTafsir.isTafsir) {
                        cachedSpans = _parsedTafsirCache[ayah.ayahUQNumber];
                        if (cachedSpans == null) {
                          cachedSpans = tafsir.tafsirText
                              .toFlutterText(widget.isDark)
                              .map((e) => e is TextSpan ? e : const TextSpan())
                              .toList()
                              .cast<TextSpan>();
                          _parsedTafsirCache[ayah.ayahUQNumber] = cachedSpans;
                        }
                      }

                      return RepaintBoundary(
                        child: _InlineAyahTafsirItem(
                          ayah: ayah,
                          tafsir: tafsir,
                          surah: surah,
                          isDark: widget.isDark,
                          style: widget.style,
                          tafsirCtrl: ctrl,
                          pageIndex: widget.pageIndex,
                          languageCode: widget.languageCode,
                          bannerStyle: widget.bannerStyle,
                          surahNameStyle: widget.surahNameStyle,
                          onSurahBannerPress: widget.onSurahBannerPress,
                          basmalaStyle: widget.basmalaStyle,
                          audioStyle: widget.audioStyle,
                          ayahDownloadManagerStyle:
                              widget.ayahDownloadManagerStyle,
                          ayahBookmarked: widget.ayahBookmarked,
                          isAyahBookmarked: widget.isAyahBookmarked,
                          showAyahBookmarkedIcon: widget.showAyahBookmarkedIcon,
                          bookmarksColor: widget.bookmarksColor,
                          withOptionsBar: widget.withOptionsBar,
                          showAyahNumber: widget.showAyahNumber,
                          cachedTafsirSpans: cachedSpans,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// شريط تغيير التفسير العلوي لوضع الآية مع التفسير
class _InlineTafsirHeader extends StatelessWidget {
  const _InlineTafsirHeader({
    required this.isDark,
    required this.style,
    required this.languageCode,
  });

  final bool isDark;
  final AyahTafsirInlineStyle style;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style.backgroundColor ?? AppColors.getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          bottom: BorderSide(
            width: 5,
            color: style.dividerColor ?? Colors.teal,
          ),
        ),
      ),
      child: Row(
        children: [
          ChangeTafsirDialog(
              tafsirStyle: TafsirTheme.of(context)?.style ??
                  TafsirStyle.defaults(isDark: isDark, context: context),
              isDark: isDark),
          const Spacer(),
          style.fontSizeWidget ??
              fontSizeDropDown(
                height: 30.0,
                tafsirStyle: TafsirTheme.of(context)?.style ??
                    TafsirStyle.defaults(isDark: isDark, context: context),
                isDark: isDark,
              ),
        ],
      ),
    );
  }
}

/// عنصر آية واحدة مع التفسير في وضع العرض المدمج
class _InlineAyahTafsirItem extends StatelessWidget {
  const _InlineAyahTafsirItem({
    required this.ayah,
    required this.tafsir,
    required this.surah,
    required this.isDark,
    required this.style,
    required this.tafsirCtrl,
    required this.pageIndex,
    required this.languageCode,
    this.bannerStyle,
    this.surahNameStyle,
    this.onSurahBannerPress,
    this.basmalaStyle,
    this.audioStyle,
    this.ayahDownloadManagerStyle,
    required this.ayahBookmarked,
    this.isAyahBookmarked,
    this.showAyahBookmarkedIcon = true,
    this.bookmarksColor,
    this.withOptionsBar = true,
    this.showAyahNumber = false,
    this.cachedTafsirSpans,
  });

  final AyahModel ayah;
  final TafsirTableData tafsir;
  final SurahModel surah;
  final bool isDark;
  final AyahTafsirInlineStyle style;
  final TafsirCtrl tafsirCtrl;
  final int pageIndex;
  final String languageCode;
  final BannerStyle? bannerStyle;
  final SurahNameStyle? surahNameStyle;
  final Function(SurahNamesModel surah)? onSurahBannerPress;
  final BasmalaStyle? basmalaStyle;
  final AyahAudioStyle? audioStyle;
  final AyahDownloadManagerStyle? ayahDownloadManagerStyle;
  final List<int> ayahBookmarked;
  final bool Function(AyahModel ayah)? isAyahBookmarked;
  final bool showAyahBookmarkedIcon;
  final Color? bookmarksColor;
  final bool? withOptionsBar;
  final bool? showAyahNumber;
  final List<TextSpan>? cachedTafsirSpans;

  @override
  Widget build(BuildContext context) {
    final isTafsir = tafsirCtrl.selectedTafsir.isTafsir;
    final fontSize = tafsirCtrl.fontSizeArabic.value;

    // الحصول على نمط الصوت / Get audio style
    final sAudio =
        audioStyle ?? AyahAudioStyle.defaults(isDark: isDark, context: context);
    final sDownloadManager = ayahDownloadManagerStyle ??
        AyahDownloadManagerStyle.defaults(isDark: isDark, context: context);

    final colors = style.bookmarkColorCodes ??
        const [
          0xAAFFD354,
          0xAAF36077,
          0xAA00CD00,
        ];

    final language =
        tafsirCtrl.tafsirAndTranslationsItems[tafsirCtrl.radioValue.value].name;

    return Container(
      padding: style.ayahPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: style.backgroundColor ?? AppColors.getBackgroundColor(isDark),
        border: Border(
          bottom: BorderSide(
            color: style.dividerColor ??
                (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: style.dividerThickness ?? 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ayah.ayahNumber == 1
              ? SurahHeaderWidget(
                  surah.surahNumber,
                  bannerStyle: bannerStyle ??
                      BannerStyle().copyWith(
                        bannerSvgHeight: 35.w,
                      ),
                  surahNameStyle: surahNameStyle ??
                      SurahNameStyle(
                        surahNameSize: 35.w,
                        surahNameColor: AppColors.getTextColor(isDark),
                      ),
                  onSurahBannerPress: onSurahBannerPress,
                  isDark: isDark,
                )
              : const SizedBox.shrink(),
          ayah.ayahNumber == 1 &&
                  surah.surahNumber != 9 &&
                  surah.surahNumber != 1
              ? BasmallahWidget(
                  surahNumber: surah.surahNumber,
                  basmalaStyle: basmalaStyle ??
                      BasmalaStyle(
                        basmalaColor: AppColors.getTextColor(isDark),
                        basmalaFontSize: 23.0.w,
                        verticalPadding: 0.0,
                      ),
                )
              : const SizedBox.shrink(),
          // رقم الآية واسم السورة — يتفاعل مع تغييرات الإشارات المرجعية

          if (withOptionsBar == true)
            (style.optionsBarWidget?.call(ayah, surah, pageIndex)) ??
                GetBuilder<BookmarksCtrl>(
                  id: 'bookmarks',
                  builder: (bookmarksCtrl) {
                    final bookmarksSet = bookmarksCtrl.bookmarksAyahsSet;
                    final int ayahUQNum = ayah.ayahUQNumber;
                    final hasBookmark = isAyahBookmarked != null
                        ? isAyahBookmarked!(ayah)
                        : (ayahBookmarked.contains(ayahUQNum) ||
                            bookmarksSet.contains(ayahUQNum));

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: style.optionsBarBackgroundColor ??
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          (hasBookmark && showAyahBookmarkedIcon)
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  child: SvgPicture.asset(
                                    AssetsPath.assets.ayahBookmarked,
                                    height: 30,
                                    width: 30,
                                  ),
                                )
                              : Text(
                                  '${ayah.ayahNumber}'
                                      .convertEnglishNumbersToArabic(
                                          ayah.ayahNumber.toString()),
                                  style: TextStyle(
                                    fontFamily: 'ayahNumber',
                                    fontSize: (fontSize + 5),
                                    height: 1.5,
                                    package: 'quran_library',
                                    color: style.ayahNumberColor ??
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                          const Spacer(),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  AudioCtrl.instance.playAyah(
                                    context,
                                    ayah.ayahUQNumber,
                                    playSingleAyah: true,
                                    ayahAudioStyle: sAudio,
                                    ayahDownloadManagerStyle: sDownloadManager,
                                    isDarkMode: isDark,
                                  );
                                  log('Second Menu Child Tapped: ${ayah.ayahUQNumber}');
                                },
                                child: Icon(
                                  style.playIconData,
                                  color: style.playIconColor,
                                  size: style.iconSize,
                                ),
                              ),
                              SizedBox(
                                  width: style.iconHorizontalPadding ?? 4.0),
                              GestureDetector(
                                onTap: () {
                                  AudioCtrl.instance.playAyah(
                                    context,
                                    ayah.ayahUQNumber,
                                    playSingleAyah: false,
                                    ayahAudioStyle: sAudio,
                                    ayahDownloadManagerStyle: sDownloadManager,
                                    isDarkMode: isDark,
                                  );
                                  log('Second Menu Child Tapped: ${ayah.ayahUQNumber}');
                                },
                                child: Icon(
                                  style.playAllIconData,
                                  color: style.playAllIconColor,
                                  size: style.iconSize,
                                ),
                              ),
                              SizedBox(
                                  width: style.iconHorizontalPadding ?? 4.0),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: ayah.text));
                                },
                                child: Icon(
                                  style.copyIconData,
                                  color: style.copyIconColor,
                                  size: style.iconSize,
                                ),
                              ),
                              SizedBox(
                                  width: style.iconHorizontalPadding ?? 4.0),

                              // أزرار العلامات المرجعية

                              for (final colorCode in colors) ...{
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        style.iconHorizontalPadding ?? 4.0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      BookmarksCtrl.instance.saveBookmark(
                                        surahName: surah.arabicName,
                                        ayahNumber: ayah.ayahNumber,
                                        ayahId: ayah.ayahUQNumber,
                                        page: ayah.page,
                                        colorCode: colorCode,
                                      );
                                    },
                                    child: Icon(
                                      style.bookmarkIconData,
                                      color: Color(colorCode),
                                      size: style.iconSize,
                                    ),
                                  ),
                                ),
                              }
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
          // نص الآية
          GetSingleAyah(
            surahNumber: surah.surahNumber,
            ayahNumber: ayah.ayahNumber,
            fontSize: fontSize,
            isBold: false,
            ayahs: ayah,
            isSingleAyah: false,
            showAyahNumber: showAyahNumber,
            isDark: isDark,
            pageIndex: pageIndex + 1,
            textColor: style.ayahTextColor,
            textAlign: TextAlign.center,
            enabledTajweed: QuranCtrl.instance.state.isTajweedEnabled.value,
          ),
          const SizedBox(height: 10),
          // خلفية التفسير
          Container(
            width: double.infinity,
            padding: style.tafsirPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: style.tafsirBackgroundColor ??
                  (isDark
                      ? Colors.grey.shade900.withValues(alpha: .5)
                      : Colors.grey.shade100.withValues(alpha: .7)),
              borderRadius: BorderRadius.circular(
                  style.tafsirBackgroundBorderRadius ?? 12.0),
            ),
            child: tafsir.tafsirText.isNotEmpty
                ? ReadMoreLess(
                    text: isTafsir
                        ? (cachedTafsirSpans ??
                            tafsir.tafsirText
                                .toFlutterText(isDark)
                                .map(
                                    (e) => e is TextSpan ? e : const TextSpan())
                                .toList()
                                .cast<TextSpan>())
                        : [
                            TextSpan(
                              text: tafsir.tafsirText,
                              style: TextStyle(
                                color: style.tafsirTextColor ??
                                    (isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade800),
                                fontSize: fontSize,
                                height: 1.5,
                              ),
                            ),
                          ],
                    maxLines: style.tafsirMaxLines ?? 4,
                    collapsedHeight: style.tafsirCollapsedHeight ?? 80,
                    readMoreText: style.readMoreText ?? 'اقرأ المزيد',
                    readLessText: style.readLessText ?? 'اقرأ أقل',
                    textStyle: TextStyle(
                      color: style.tafsirTextColor ??
                          (isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade800),
                      fontSize: fontSize,
                      height: 1.5,
                    ),
                    textDirection: context.alignmentLayoutWPassLang(
                        language, TextDirection.rtl, TextDirection.ltr),
                    textAlign: TextAlign.justify,
                    buttonTextStyle: style.readMoreTextStyle ??
                        TextStyle(
                          color: style.readMoreButtonColor ??
                              Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                    iconColor: style.readMoreButtonColor ??
                        Theme.of(context).colorScheme.primary,
                  )
                : Text(
                    languageCode == 'ar'
                        ? 'لا يوجد تفسير متاح'
                        : 'No tafsir available',
                    style: TextStyle(
                      color:
                          isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
