part of '/quran.dart';

/// شاشة لعرض صفحة واحدة أو مجموعة صفحات محددة من المصحف
///
/// - مرر [page] لعرض صفحة واحدة (1..604)
/// - أو مرر [startPage] و [endPage] لعرض نطاق صفحات (1..604)
///
/// بقية الخصائص مطابقة تقريبًا لـ [QuranLibraryScreen] لضمان التوافق والمرونة.
class QuranPagesScreen extends StatelessWidget {
  const QuranPagesScreen({
    super.key,
    // التخصيص العام
    this.appBar,
    this.ayahIconColor,
    this.ayahSelectedBackgroundColor,
    this.ayahSelectedFontColor,
    this.bannerStyle,
    this.basmalaStyle,
    this.backgroundColor,
    this.bookmarkList = const [],
    this.bookmarksColor,
    this.circularProgressWidget,
    this.downloadFontsDialogStyle,
    this.isDark = false,
    this.juzName,
    this.languageCode = 'ar',
    this.onAyahLongPress,
    this.onPageChanged,
    this.onPagePress,
    this.onSurahBannerPress,
    this.sajdaName,
    this.showAyahBookmarkedIcon = true,
    this.surahInfoStyle,
    this.surahNameStyle,
    this.surahNumber,
    this.textColor,
    this.singleAyahTextColors,
    this.topTitleChild,
    this.useDefaultAppBar = true,
    this.withPageView = true,
    this.isFontsLocal = false,
    this.fontsName = '',
    this.ayahBookmarked = const [],
    this.anotherMenuChild,
    this.anotherMenuChildOnTap,
    this.secondMenuChild,
    this.secondMenuChildOnTap,
    this.ayahStyle,
    this.surahStyle,
    this.isShowAudioSlider = true,
    this.appIconUrlForPlayAudioInBackground,
    this.topBarStyle,
    // تحديد الصفحات
    this.page,
    this.startPage,
    this.endPage,
    this.enableMultiSelect = false,
    this.highlightedAyahs = const [],
    this.highlightedAyahNumbersBySurah = const {},
    this.highlightedAyahNumbersInPages = const [],
    this.highlightedRanges = const [],
    this.highlightedRangesText = const [],
    required this.parentContext,
  }) : assert(
          (page != null && startPage == null && endPage == null) ||
              (page == null && (startPage != null || endPage != null)),
          'حدد إما page لصفحة واحدة أو startPage/endPage لنطاق صفحات',
        );

  // ——— نفس خصائص شاشة المصحف الافتراضية تقريبًا ———
  final PreferredSizeWidget? appBar;
  final Color? ayahIconColor;
  final Color? ayahSelectedBackgroundColor;
  final Color? ayahSelectedFontColor;
  final BasmalaStyle? basmalaStyle;
  final BannerStyle? bannerStyle;
  final List bookmarkList;
  final Color? bookmarksColor;
  final Color? backgroundColor;
  final Widget? circularProgressWidget;
  final DownloadFontsDialogStyle? downloadFontsDialogStyle;
  final bool isDark;
  final String? languageCode;
  final String? juzName;
  final Function(int pageNumber)? onPageChanged;
  final VoidCallback? onPagePress;
  final void Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;
  final void Function(SurahNamesModel surah)? onSurahBannerPress;
  final String? sajdaName;
  final bool showAyahBookmarkedIcon;
  final int? surahNumber;
  final SurahInfoStyle? surahInfoStyle;
  final SurahNameStyle? surahNameStyle;
  final Widget? topTitleChild;
  final Color? textColor;
  final List<Color?>? singleAyahTextColors;
  final bool useDefaultAppBar;
  final bool withPageView;
  final bool? isFontsLocal;
  final String? fontsName;
  final List<int>? ayahBookmarked;
  final Widget? anotherMenuChild;
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;
  final Widget? secondMenuChild;
  final void Function(AyahModel ayah)? secondMenuChildOnTap;
  final AyahAudioStyle? ayahStyle;
  final SurahAudioStyle? surahStyle;
  final bool? isShowAudioSlider;
  final String? appIconUrlForPlayAudioInBackground;
  final QuranTopBarStyle? topBarStyle;
  final BuildContext parentContext;
  // تمكين تظليل/تحديد متعدد للآيات داخل هذه الشاشة فقط
  final bool enableMultiSelect;
  // قائمة أرقام الآيات الفريدة المراد تظليلها برمجياً
  final List<int> highlightedAyahs;
  // تظليل بحسب (رقم السورة -> قائمة أرقام الآيات داخل السورة)
  final Map<int, List<int>> highlightedAyahNumbersBySurah;
  // تظليل بحسب نطاق الصفحات مع أرقام آيات داخل السطر
  // مثال: [(start:6,end:11, ayahs:[1,3,5])]
  final List<({int start, int end, List<int> ayahs})>
      highlightedAyahNumbersInPages;
  // نطاقات عبر السور: من سورة/آية إلى سورة/آية
  // مثال: (startSurah:2,startAyah:15,endSurah:3,endAyah:25)
  final List<({int startSurah, int startAyah, int endSurah, int endAyah})>
      highlightedRanges;
  // صيغ نصية "2:15-3:25" (تدعم أرقام عربية أيضًا)
  final List<String> highlightedRangesText;

  // ——— تحديد صفحة واحدة أو نطاق صفحات ———
  final int? page; // 1..604
  final int? startPage; // 1..604
  final int? endPage; // 1..604 (شامل)

  // تحويل الإدخال إلى نطاق فعلي صالح (1..604)
  (int start, int end) _resolveRange() {
    int sp = page ?? startPage ?? 1;
    int ep = page ?? endPage ?? sp;
    // ضمان صحة القيم
    sp = sp.clamp(1, 604);
    ep = ep.clamp(1, 604);
    if (sp > ep) {
      final t = sp;
      sp = ep;
      ep = t;
    }
    return (sp, ep);
  }

  @override
  Widget build(BuildContext context) {
    // تحديث رابط أيقونة التطبيق إذا وُجد
    if (appIconUrlForPlayAudioInBackground != null &&
        appIconUrlForPlayAudioInBackground!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AudioCtrl.instance
            .updateAppIconUrl(appIconUrlForPlayAudioInBackground!);
      });
    }

    // إعداد وضع التحديد المتعدد والتظليل الخارجي (بدون Stateful)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = QuranCtrl.instance;
      ctrl.setMultiSelectMode(enableMultiSelect);
      final combined = <int>{};
      if (highlightedAyahs.isNotEmpty) {
        combined.addAll(highlightedAyahs);
      }
      if (highlightedAyahNumbersBySurah.isNotEmpty) {
        highlightedAyahNumbersBySurah.forEach((surah, ayahs) {
          for (final n in ayahs) {
            final id = ctrl.getAyahUQBySurahAndAyah(surah, n);
            if (id != null) combined.add(id);
          }
        });
      }
      if (highlightedAyahNumbersInPages.isNotEmpty) {
        for (final item in highlightedAyahNumbersInPages) {
          combined.addAll(ctrl.getAyahUQsForPagesByAyahNumbers(
              startPage: item.start,
              endPage: item.end,
              ayahNumbers: item.ayahs));
        }
      }
      if (highlightedRanges.isNotEmpty) {
        for (final r in highlightedRanges) {
          combined.addAll(ctrl.getAyahUQsForSurahAyahRange(
            startSurah: r.startSurah,
            startAyah: r.startAyah,
            endSurah: r.endSurah,
            endAyah: r.endAyah,
          ));
        }
      }
      if (highlightedRangesText.isNotEmpty) {
        for (final s in highlightedRangesText) {
          final parsed = ctrl.parseSurahAyahRangeString(s);
          if (parsed != null) {
            combined.addAll(ctrl.getAyahUQsForSurahAyahRange(
              startSurah: parsed.$1,
              startAyah: parsed.$2,
              endSurah: parsed.$3,
              endAyah: parsed.$4,
            ));
          }
        }
      }
      if (combined.isNotEmpty) {
        ctrl.setExternalHighlights(combined.toList());
      }
    });

    final (sp, ep) = _resolveRange();
    final int startIndex = sp - 1; // محول إلى 0-based
    final int count = (ep - sp) + 1; // عدد الصفحات

    // if (QuranCtrl.instance.isDownloadFonts) {
    //   // تنفيذ بعد انتهاء الإطار لتجنّب أي تجميد
    //   Future.microtask(() => QuranCtrl.instance
    //       .prepareFonts(startIndex, isFontsLocal: isFontsLocal!));
    // }
    return ScreenUtilInit(
      designSize: const Size(392.72727272727275, 800.7272727272727),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => GetBuilder<QuranCtrl>(
        builder: (quranCtrl) {
          Widget singlePage(int globalIndex) {
            return InkWell(
              onTap: () {
                if (onPagePress != null) {
                  onPagePress!();
                } else {
                  quranCtrl.showControlToggle();
                  if (!enableMultiSelect) {
                    quranCtrl.clearSelection();
                  }
                  quranCtrl.state.overlayEntry?.remove();
                  quranCtrl.state.overlayEntry = null;
                }
              },
              focusColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: RepaintBoundary(
                key: ValueKey('quran_partial_page_$globalIndex'),
                child: PageViewBuild(
                  circularProgressWidget: circularProgressWidget,
                  languageCode: languageCode,
                  juzName: juzName,
                  sajdaName: sajdaName,
                  topTitleChild: topTitleChild,
                  bookmarkList: bookmarkList,
                  ayahSelectedFontColor: ayahSelectedFontColor,
                  textColor: textColor,
                  ayahIconColor: ayahIconColor,
                  showAyahBookmarkedIcon: showAyahBookmarkedIcon,
                  onAyahLongPress: onAyahLongPress,
                  bookmarksColor: bookmarksColor,
                  surahInfoStyle: surahInfoStyle,
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
                  anotherMenuChild: anotherMenuChild,
                  anotherMenuChildOnTap: anotherMenuChildOnTap,
                  secondMenuChild: secondMenuChild,
                  secondMenuChildOnTap: secondMenuChildOnTap,
                  userContext: parentContext,
                  pageIndex: globalIndex,
                  quranCtrl: quranCtrl,
                  isFontsLocal: isFontsLocal!,
                ),
              ),
            );
          }

          Widget body;
          if (withPageView) {
            // PageView محلي على النطاق فقط
            final controller = PageController(initialPage: 0);
            body = NotificationListener<ScrollEndNotification>(
              onNotification: (notification) {
                final metrics = notification.metrics;
                if (metrics is PageMetrics) {
                  // final int currentLocal = (metrics.page ??
                  //         (metrics.pixels / metrics.viewportDimension))
                  //     .round();
                  // final int currentGlobal = startIndex + currentLocal;
                  // if (quranCtrl.isDownloadFonts) {
                  //   Future.microtask(() => quranCtrl.prepareFonts(
                  //         currentGlobal,
                  //         isFontsLocal: isFontsLocal!,
                  //       ));
                  // }
                }
                return false;
              },
              child: PageView.builder(
                itemCount: count,
                controller: controller,
                padEnds: false,
                physics: const ClampingScrollPhysics(),
                allowImplicitScrolling: false,
                clipBehavior: Clip.hardEdge,
                onPageChanged: (localIndex) {
                  final globalIndex = startIndex + localIndex;
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (onPageChanged != null) {
                      onPageChanged!(globalIndex);
                    } else {
                      quranCtrl.state.overlayEntry?.remove();
                      quranCtrl.state.overlayEntry = null;
                    }
                    quranCtrl.state.currentPageNumber.value = globalIndex + 1;
                    quranCtrl.saveLastPage(globalIndex + 1);
                  });
                  // if (quranCtrl.isDownloadFonts) {
                  //   // تنفيذ بعد انتهاء الإطار لتجنّب أي تجميد
                  //   Future.microtask(() => quranCtrl.prepareFonts(startIndex,
                  //       isFontsLocal: isFontsLocal!));
                  // }
                },
                itemBuilder: (ctx, localIndex) {
                  final globalIndex = startIndex + localIndex;
                  return singlePage(globalIndex);
                },
              ),
            );
          } else {
            if (count == 1) {
              body = singlePage(startIndex);
            } else {
              // عرض رأسي لعدة صفحات (استخدمه بحذر للنطاقات الكبيرة)
              body = ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: count,
                itemBuilder: (_, localIndex) {
                  final globalIndex = startIndex + localIndex;
                  return singlePage(globalIndex);
                },
              );
            }
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor:
                  backgroundColor ?? AppColors.getBackgroundColor(isDark),
              body: SafeArea(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    body,
                    // تم تفعيل وضع التحديد المتعدد في initState ويُعاد ضبطه في dispose
                    GetBuilder<QuranCtrl>(
                      id: 'isShowControl',
                      builder: (quranCtrl) => Stack(
                        alignment: Alignment.center,
                        children: [
                          isShowAudioSlider!
                              ? BottomSlider(
                                  isVisible:
                                      QuranCtrl.instance.isShowControl.value,
                                  onClose: () {
                                    QuranCtrl.instance.isShowControl.value =
                                        false;
                                    SliderController.instance
                                        .hideBottomContent();
                                  },
                                  isDark: isDark,
                                  sliderHeight: UiHelper.currentOrientation(
                                      0.0, 40.0, context),
                                  style: ayahStyle ?? AyahAudioStyle(),
                                  contentChild: const SizedBox.shrink(),
                                  child: Flexible(
                                    child: AyahsAudioWidget(
                                      style: ayahStyle ?? AyahAudioStyle(),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          appBar == null &&
                                  useDefaultAppBar &&
                                  quranCtrl.isShowControl.value
                              ? _QuranTopBar(
                                  languageCode ?? 'ar',
                                  isDark,
                                  style: surahStyle ?? SurahAudioStyle(),
                                  backgroundColor: backgroundColor,
                                  downloadFontsDialogStyle:
                                      downloadFontsDialogStyle,
                                  isFontsLocal: isFontsLocal,
                                  topBarStyle: topBarStyle ??
                                      QuranTopBarStyle.defaults(isDark: isDark),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
