part of '/quran.dart';

/// وضع عرض المصحف مع التفسير الجانبي (أفقي فقط)
///
/// يعرض صفحة المصحف على الجانب الأيمن (RTL) والتفسير على الجانب الأيسر.
/// يدعم تغيير مصدر التفسير وحجم الخط.
///
/// [QuranWithTafsirSide] Displays the Quran page on one side and tafsir
/// on the other side. Supports switching tafsir source and font size.
class QuranWithTafsirSide extends StatelessWidget {
  const QuranWithTafsirSide({
    super.key,
    required this.quranCtrl,
    required this.isDark,
    required this.languageCode,
    required this.onPageChanged,
    required this.onPagePress,
    required this.circularProgressWidget,
    required this.bookmarkList,
    required this.ayahSelectedFontColor,
    required this.textColor,
    required this.ayahIconColor,
    required this.showAyahBookmarkedIcon,
    required this.onAyahLongPress,
    required this.bookmarksColor,
    required this.surahNameStyle,
    required this.bannerStyle,
    required this.basmalaStyle,
    required this.onSurahBannerPress,
    required this.surahNumber,
    required this.ayahSelectedBackgroundColor,
    required this.fontsName,
    required this.ayahBookmarked,
    required this.isAyahBookmarked,
    required this.parentContext,
    required this.isFontsLocal,
    this.style,
  });

  final QuranCtrl quranCtrl;
  final bool isDark;
  final String languageCode;
  final Function(int pageNumber)? onPageChanged;
  final VoidCallback? onPagePress;
  final Widget? circularProgressWidget;
  final List<dynamic> bookmarkList;
  final Color? ayahSelectedFontColor;
  final Color? textColor;
  final Color? ayahIconColor;
  final bool showAyahBookmarkedIcon;
  final void Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;
  final Color? bookmarksColor;
  final SurahNameStyle? surahNameStyle;
  final BannerStyle? bannerStyle;
  final BasmalaStyle? basmalaStyle;
  final void Function(SurahNamesModel surah)? onSurahBannerPress;
  final int? surahNumber;
  final Color? ayahSelectedBackgroundColor;
  final String? fontsName;
  final List<int>? ayahBookmarked;
  final bool Function(AyahModel ayah)? isAyahBookmarked;
  final BuildContext parentContext;
  final bool? isFontsLocal;
  final QuranTafsirSideStyle? style;

  @override
  Widget build(BuildContext context) {
    final s = style ??
        (QuranTafsirSideTheme.of(context)?.style ??
            QuranTafsirSideStyle.defaults(isDark: isDark, context: context));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          // قسم المصحف
          Expanded(
            flex: ((s.quranWidthFraction ?? 0.5) * 10).round(),
            child: PatchedPreloadPageView.builder(
              preloadPagesCount: 2,
              padEnds: false,
              itemCount: 604,
              controller: quranCtrl.getPageController(context),
              physics: quranCtrl.state.isScaling.value
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              onPageChanged: (pageIndex) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  if (onPageChanged != null) onPageChanged!(pageIndex);
                  quranCtrl.state.currentPageNumber.value = pageIndex + 1;
                  quranCtrl.saveLastPage(pageIndex + 1);
                  if (quranCtrl.state.fontsSelected.value == 0) {
                    quranCtrl.scheduleQpcV4AllPagesPrebuild();
                  }
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
                child: RepaintBoundary(
                  key: ValueKey('tafsir_side_quran_$index'),
                  child: _KeepAlive(
                    child: PageViewBuild(
                      circularProgressWidget: circularProgressWidget,
                      languageCode: languageCode,
                      bookmarkList: bookmarkList,
                      ayahSelectedFontColor: ayahSelectedFontColor,
                      textColor: textColor,
                      ayahIconColor: ayahIconColor,
                      showAyahBookmarkedIcon: showAyahBookmarkedIcon,
                      onAyahLongPress: onAyahLongPress,
                      bookmarksColor: bookmarksColor,
                      surahNameStyle: surahNameStyle,
                      bannerStyle: bannerStyle,
                      basmalaStyle: basmalaStyle,
                      onSurahBannerPress: onSurahBannerPress,
                      surahNumber: surahNumber,
                      ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
                      onPagePress: onPagePress,
                      isDark: isDark,
                      fontsName: fontsName,
                      ayahBookmarked: ayahBookmarked,
                      isAyahBookmarked: isAyahBookmarked,
                      userContext: parentContext,
                      pageIndex: index,
                      quranCtrl: quranCtrl,
                      isFontsLocal: isFontsLocal!,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // الفاصل العمودي
          Container(
            width: s.verticalDividerWidth ?? 1.0,
            color: s.verticalDividerColor ??
                (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
          // قسم التفسير
          Expanded(
            flex: (((1 - (s.quranWidthFraction ?? 0.5)) * 10).round()),
            child: _TafsirSidePanel(
              isDark: isDark,
              style: s,
              languageCode: languageCode,
            ),
          ),
        ],
      ),
    );
  }
}

/// لوحة التفسير الجانبية
class _TafsirSidePanel extends StatelessWidget {
  const _TafsirSidePanel({
    required this.isDark,
    required this.style,
    required this.languageCode,
  });

  final bool isDark;
  final QuranTafsirSideStyle style;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final tafsirCtrl = TafsirCtrl.instance;
    final quranCtrl = QuranCtrl.instance;

    return Container(
      color: style.tafsirPanelBackgroundColor ??
          (isDark ? Colors.grey.shade900 : Colors.grey.shade50),
      child: Column(
        children: [
          // شريط التفسير العلوي
          _TafsirSideHeader(
            isDark: isDark,
            style: style,
            languageCode: languageCode,
          ),
          // قائمة الآيات مع التفسير
          Expanded(
            child: Obx(() {
              final currentPage = quranCtrl.state.currentPageNumber.value;
              return FutureBuilder<void>(
                key: ValueKey('tafsir_side_$currentPage'
                    '_${tafsirCtrl.radioValue.value}'),
                future: _loadTafsirForPage(currentPage),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final pageAyahs =
                      quranCtrl.getPageAyahsByIndex(currentPage - 1);
                  if (pageAyahs.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return GetBuilder<TafsirCtrl>(
                    id: 'change_font_size',
                    builder: (ctrl) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: pageAyahs.length,
                        separatorBuilder: (_, __) => Divider(
                          color: style.ayahDividerColor ??
                              (isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final ayah = pageAyahs[index];
                          final tafsir = _getTafsirForAyah(
                              ayah, ctrl, pageAyahs.first.ayahUQNumber);
                          final surah =
                              quranCtrl.getCurrentSurahByPageNumber(ayah.page);

                          return _TafsirSideAyahItem(
                            ayah: ayah,
                            tafsir: tafsir,
                            surah: surah,
                            isDark: isDark,
                            style: style,
                            tafsirCtrl: ctrl,
                            pageIndex: currentPage - 1,
                            languageCode: languageCode,
                          );
                        },
                      );
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _loadTafsirForPage(int pageNumber) async {
    final tafsirCtrl = TafsirCtrl.instance;
    if (tafsirCtrl.selectedTafsir.isTafsir) {
      await tafsirCtrl.fetchData(pageNumber);
    } else {
      await tafsirCtrl.fetchTranslate();
    }
  }

  TafsirTableData _getTafsirForAyah(
    AyahModel ayah,
    TafsirCtrl ctrl,
    int firstAyahUQ,
  ) {
    final ayahIndex = ayah.ayahUQNumber;
    return ctrl.tafseerList.firstWhere(
      (e) => e.id == ayahIndex,
      orElse: () => const TafsirTableData(
        id: 0,
        tafsirText: '',
        ayahNum: 0,
        pageNum: 0,
        surahNum: 0,
      ),
    );
  }
}

/// شريط التفسير العلوي — اسم التفسير + تغيير + حجم الخط
class _TafsirSideHeader extends StatelessWidget {
  const _TafsirSideHeader({
    required this.isDark,
    required this.style,
    required this.languageCode,
  });

  final bool isDark;
  final QuranTafsirSideStyle style;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final tafsirCtrl = TafsirCtrl.instance;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: style.tafsirHeaderColor ??
            (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        border: Border(
          bottom: BorderSide(
            color: style.verticalDividerColor ??
                (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
        ),
      ),
      child: Obx(() {
        final currentTafsirName = tafsirCtrl
            .tafsirAndTranslationsItems[tafsirCtrl.radioValue.value].name;
        return Row(
          children: [
            Expanded(
              child: Text(
                currentTafsirName,
                style: TextStyle(
                  color: style.tafsirHeaderTextColor ??
                      AppColors.getTextColor(isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // زر تغيير التفسير
            IconButton(
              icon: Icon(
                Icons.swap_horiz_rounded,
                color: style.fontSizeIconColor ??
                    Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => DailogBuild(
                    tafsirStyle: TafsirTheme.of(context)?.style ??
                        TafsirStyle.defaults(isDark: isDark, context: context),
                    pageNumber: null,
                    tafsirNameList: null,
                    isDark: isDark,
                  ),
                );
              },
              tooltip: languageCode == 'ar' ? 'تغيير التفسير' : 'Change Tafsir',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 4),
            // زر حجم الخط
            _FontSizeControl(
              isDark: isDark,
              style: style,
            ),
          ],
        );
      }),
    );
  }
}

/// التحكم بحجم الخط
class _FontSizeControl extends StatelessWidget {
  const _FontSizeControl({
    required this.isDark,
    required this.style,
  });

  final bool isDark;
  final QuranTafsirSideStyle style;

  @override
  Widget build(BuildContext context) {
    final tafsirCtrl = TafsirCtrl.instance;

    return PopupMenuButton<double>(
      icon: Icon(
        Icons.text_fields_rounded,
        color: style.fontSizeIconColor ?? Theme.of(context).colorScheme.primary,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      itemBuilder: (_) => [
        PopupMenuItem<double>(
          enabled: false,
          child: StatefulBuilder(
            builder: (context, setState) => Obx(() {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tafsirCtrl.fontSizeArabic.value.toInt()}',
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: style.fontSizeActiveTrackColor ??
                            Theme.of(context).colorScheme.primary,
                        inactiveTrackColor: style.fontSizeInactiveTrackColor ??
                            (isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400),
                        thumbColor: style.fontSizeThumbColor ??
                            Theme.of(context).colorScheme.primary,
                      ),
                      child: Slider(
                        value: tafsirCtrl.fontSizeArabic.value,
                        min: 12,
                        max: 32,
                        onChanged: (v) {
                          tafsirCtrl.fontSizeArabic.value = v;
                          tafsirCtrl.update(['change_font_size']);
                        },
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// عنصر آية مع تفسيرها في اللوحة الجانبية
class _TafsirSideAyahItem extends StatelessWidget {
  const _TafsirSideAyahItem({
    required this.ayah,
    required this.tafsir,
    required this.surah,
    required this.isDark,
    required this.style,
    required this.tafsirCtrl,
    required this.pageIndex,
    required this.languageCode,
  });

  final AyahModel ayah;
  final TafsirTableData tafsir;
  final SurahModel surah;
  final bool isDark;
  final QuranTafsirSideStyle style;
  final TafsirCtrl tafsirCtrl;
  final int pageIndex;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final isTafsir = tafsirCtrl.selectedTafsir.isTafsir;
    final fontSize = tafsirCtrl.fontSizeArabic.value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رقم الآية واسم السورة
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${surah.arabicName} : ${ayah.ayahNumber}',
                  style: TextStyle(
                    color:
                        style.ayahTextColor ?? AppColors.getTextColor(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // نص الآية
          GetSingleAyah(
            surahNumber: surah.surahNumber,
            ayahNumber: ayah.ayahNumber,
            fontSize: style.ayahFontSize ?? 20,
            isBold: false,
            ayahs: ayah,
            isSingleAyah: false,
            isDark: isDark,
            pageIndex: pageIndex + 1,
            textColor: style.ayahTextColor,
            textAlign: TextAlign.center,
            enabledTajweed: QuranCtrl.instance.state.isTajweedEnabled.value,
          ),
          const SizedBox(height: 8),
          // التفسير مع ReadMoreLess
          if (tafsir.tafsirText.isNotEmpty)
            ReadMoreLess(
              text: isTafsir
                  ? tafsir.tafsirText
                      .toFlutterText(isDark)
                      .map((e) => e is TextSpan ? e : const TextSpan())
                      .toList()
                      .cast<TextSpan>()
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
                    (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                fontSize: fontSize,
                height: 1.5,
              ),
              textAlign: TextAlign.start,
              buttonTextStyle: style.readMoreTextStyle ??
                  TextStyle(
                    color: style.readMoreButtonColor ??
                        Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
              iconColor: style.readMoreButtonColor ??
                  Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }
}
