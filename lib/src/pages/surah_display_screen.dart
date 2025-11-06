part of '/quran.dart';

/// شاشة لعرض سورة واحدة باستخدام SurahCtrl و _QuranLinePage
/// Screen for displaying a single surah using SurahCtrl and _QuranLinePage
class SurahDisplayScreen extends StatelessWidget {
  /// إنشاء مثيل جديد من SurahDisplayScreen
  /// Creates a new instance of SurahDisplayScreen
  SurahDisplayScreen({
    super.key,
    required this.surahNumber,
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
    this.isDark = false,
    this.languageCode = 'ar',
    this.onAyahLongPress,
    this.onPageChanged,
    this.onPagePress,
    this.onSurahBannerPress,
    this.showAyahBookmarkedIcon = true,
    this.surahInfoStyle,
    this.surahNameStyle,
    this.textColor,
    this.topTitleChild,
    this.useDefaultAppBar = true,
    this.ayahBookmarked = const [],
    this.anotherMenuChild,
    this.anotherMenuChildOnTap,
    this.juzName,
    this.sajdaName,
    this.secondMenuChild,
    this.secondMenuChildOnTap,
    this.ayahStyle,
    this.surahStyle,
    this.isShowAudioSlider = true,
    this.appIconUrlForPlayAudioInBackground,
    required this.parentContext,
    this.indexTabStyle,
    this.searchTabStyle,
    this.ayahLongClickStyle,
    this.tafsirStyle,
  });

  /// رقم السورة المراد عرضها
  /// The surah number to display
  final int surahNumber;

  /// شريط التطبيقات المخصص
  /// Custom app bar
  final PreferredSizeWidget? appBar;

  /// لون أيقونة الآية
  /// Ayah icon color
  final Color? ayahIconColor;

  /// لون خلفية الآية المختارة
  /// Selected ayah background color
  final Color? ayahSelectedBackgroundColor;
  final Color? ayahSelectedFontColor;

  /// نمط البسملة
  /// Basmala style
  final BasmalaStyle? basmalaStyle;

  /// نمط الشعار
  /// Banner style
  final BannerStyle? bannerStyle;

  /// قائمة الإشارات المرجعية
  /// Bookmark list
  final List bookmarkList;

  /// لون الإشارات المرجعية
  /// Bookmarks color
  final Color? bookmarksColor;

  /// لون الخلفية
  /// Background color
  final Color? backgroundColor;

  /// ويدجت التحميل
  /// Loading widget
  final Widget? circularProgressWidget;

  /// النمط المظلم
  /// Dark mode
  final bool isDark;

  /// كود اللغة
  /// Language code
  final String? languageCode;

  /// دالة عند الضغط المطول على الآية
  /// Function when long pressing on ayah
  final void Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;

  /// دالة عند تغيير الصفحة
  /// Function when page changes
  final Function(int pageNumber)? onPageChanged;

  /// دالة عند الضغط على الصفحة
  /// Function when pressing on page
  final VoidCallback? onPagePress;

  /// دالة عند الضغط على شعار السورة
  /// Function when pressing on surah banner
  final void Function(SurahNamesModel surah)? onSurahBannerPress;

  /// إظهار أيقونة الإشارة المرجعية للآية
  /// Show ayah bookmark icon
  final bool showAyahBookmarkedIcon;

  /// نمط معلومات السورة
  /// Surah info style
  final SurahInfoStyle? surahInfoStyle;

  /// نمط اسم السورة
  /// Surah name style
  final SurahNameStyle? surahNameStyle;

  /// لون النص
  /// Text color
  final Color? textColor;

  /// عنصر في أعلى العنوان
  /// Top title child widget
  final Widget? topTitleChild;

  /// استخدام شريط التطبيقات الافتراضي
  /// Use default app bar
  final bool useDefaultAppBar;

  /// قائمة الآيات المحفوظة
  /// List of bookmarked ayahs
  final List<int> ayahBookmarked;

  /// اسم الجزء
  /// Juz name
  final String? juzName;

  /// اسم السجدة
  /// Sajda name
  final String? sajdaName;

  /// زر إضافي أول لقائمة خيارات الآية - يمكن إضافة أيقونة أو نص مخصص [anotherMenuChild]
  ///
  /// [anotherMenuChild] First additional button for ayah options menu - you can add custom icon or text
  @Deprecated(
      'In versions after 2.2.4 this parameter will be removed. Please use customMenuItems in AyahMenuStyle instead.')
  final Widget? anotherMenuChild;

  /// دالة يتم استدعاؤها عند الضغط على الزر الإضافي الأول في قائمة خيارات الآية [anotherMenuChildOnTap]
  ///
  /// [anotherMenuChildOnTap] Function called when pressing the first additional button in ayah options menu
  @Deprecated(
      'In versions after 2.2.4 this parameter will be removed. Please use customMenuItems in AyahMenuStyle instead.')
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;

  /// زر إضافي ثاني لقائمة خيارات الآية - يمكن إضافة أيقونة أو نص مخصص [secondMenuChild]
  ///
  /// [secondMenuChild] Second additional button for ayah options menu - you can add custom icon or text
  @Deprecated(
      'In versions after 2.2.4 this parameter will be removed. Please use customMenuItems in AyahMenuStyle instead.')
  final Widget? secondMenuChild;

  /// دالة يتم استدعاؤها عند الضغط على الزر الإضافي الثاني في قائمة خيارات الآية [secondMenuChildOnTap]
  ///
  /// [secondMenuChildOnTap] Function called when pressing the second additional button in ayah options menu
  @Deprecated(
      'In versions after 2.2.4 this parameter will be removed. Please use customMenuItems in AyahMenuStyle instead.')
  final void Function(AyahModel ayah)? secondMenuChildOnTap;

  /// نمط تخصيص مظهر المشغل الصوتي للآيات - يتحكم في الألوان والخطوط والأيقونات [ayahStyle]
  ///
  /// [ayahStyle] Audio player style customization for ayahs - controls colors, fonts, and icons
  final AyahAudioStyle? ayahStyle;

  /// نمط تخصيص مظهر المشغل الصوتي للسور - يتحكم في الألوان والخطوط والأيقونات [surahStyle]
  ///
  /// [surahStyle] Audio player style customization for surahs - controls colors, fonts, and icons
  final SurahAudioStyle? surahStyle;

  /// إظهار أو إخفاء سلايدر التحكم في الصوت السفلي [isShowAudioSlider]
  ///
  /// [isShowAudioSlider] Show or hide the bottom audio control slider
  final bool? isShowAudioSlider;

  /// رابط أيقونة التطبيق للمشغل الصوتي / App icon URL for audio player
  /// [appIconUrlForPlayAudioInBackground] يمكن تمرير رابط مخصص لأيقونة التطبيق في المشغل الصوتي
  /// [appIconUrlForPlayAudioInBackground] You can pass a custom URL for the app icon in the audio player
  final String? appIconUrlForPlayAudioInBackground;

  /// السياق المطلوب من المستخدم لإدارة العمليات الداخلية للمكتبة [parentContext]
  /// مثل الوصول إلى MediaQuery، Theme، والتنقل بين الصفحات
  ///
  /// مثال على الاستخدام:
  /// ```dart
  /// QuranLibraryScreen(
  ///   parentContext: context, // تمرير السياق من الويدجت الأب
  ///   // باقي المعاملات...
  /// )
  /// ```
  ///
  /// [parentContext] Required context from user for internal library operations
  /// such as accessing MediaQuery, Theme, and navigation between pages
  ///
  /// Usage example:
  /// ```dart
  /// QuranLibraryScreen(
  ///   parentContext: context, // Pass context from parent widget
  ///   // other parameters...
  /// )
  /// ```
  final BuildContext parentContext;

  /// تخصيص نمط تبويب الفهرس الخاص بالمصحف
  ///
  /// [indexTabStyle] Index tab style customization for the Quran
  final IndexTabStyle? indexTabStyle;

  /// تخصيص نمط تبويب البحث الخاص بالمصحف
  ///
  /// [searchTabStyle] Search tab style customization for the Quran
  final SearchTabStyle? searchTabStyle;

  /// تخصيص نمط التفسير الخاص بالمصحف
  ///
  /// [tafsirStyle] Tafsir style customization for the Quran
  final TafsirStyle? tafsirStyle;

  /// تخصيص نمط الضغط المطول على الآية
  ///
  /// [ayahLongClickStyle] Ayah long click style customization for the Quran
  final AyahMenuStyle? ayahLongClickStyle;

  final quranCtrl = QuranCtrl.instance;

  @override
  Widget build(BuildContext context) {
    AudioCtrl.instance;
    // تحديث رابط أيقونة التطبيق إذا تم تمريره / Update app icon URL if provided
    // Update app icon URL if provided
    if (appIconUrlForPlayAudioInBackground != null &&
        appIconUrlForPlayAudioInBackground!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AudioCtrl.instance
            .updateAppIconUrl(appIconUrlForPlayAudioInBackground!);
      });
    }
    // شرح: تهيئة الشاشة وإعداد المقاييس
    // Explanation: Initialize screen and setup dimensions
    return ScreenUtilInit(
      designSize: const Size(392.72727272727275, 800.7272727272727),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return QuranLibraryTheme(
          snackBarStyle:
              SnackBarStyle.defaults(isDark: isDark, context: parentContext),
          ayahLongClickStyle: ayahLongClickStyle ??
              AyahMenuStyle.defaults(isDark: isDark, context: parentContext),
          indexTabStyle: indexTabStyle ??
              IndexTabStyle.defaults(isDark: isDark, context: parentContext),
          topBarStyle:
              QuranTopBarStyle.defaults(isDark: isDark, context: parentContext),
          searchTabStyle: searchTabStyle ??
              SearchTabStyle.defaults(isDark: isDark, context: parentContext),
          surahInfoStyle: surahInfoStyle ??
              SurahInfoStyle.defaults(isDark: isDark, context: parentContext),
          tafsirStyle: tafsirStyle ??
              TafsirStyle.defaults(isDark: isDark, context: parentContext),
          bookmarksTabStyle: BookmarksTabStyle.defaults(
              isDark: isDark, context: parentContext),
          topBottomQuranStyle: TopBottomQuranStyle.defaults(
              isDark: isDark, context: parentContext),
          child: GetBuilder<SurahCtrl>(
            init: SurahCtrl.instance,
            initState: (state) {
              // شرح: تحميل السورة عند بناء الشاشة
              // Explanation: Load surah when building screen
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final ctrl = state.controller!;
                // شرح: إعادة تحميل السورة إذا تغير رقمها
                // Explanation: Reload surah if its number changed
                AudioCtrl.instance;
                if (ctrl.surahNumber != surahNumber) {
                  ctrl.loadSurah(surahNumber);
                }
              });
            },
            builder: (surahCtrl) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  backgroundColor:
                      backgroundColor ?? AppColors.getBackgroundColor(isDark),
                  appBar: appBar ??
                      (useDefaultAppBar
                          ? AppBar(
                              backgroundColor: backgroundColor ??
                                  AppColors.getBackgroundColor(isDark),
                              elevation: 0,
                              centerTitle: true,
                              title: Text(
                                surahCtrl.getSurahName(),
                                style: QuranLibrary().naskhStyle.copyWith(
                                      color: AppColors.getTextColor(isDark),
                                      fontSize: 22,
                                    ),
                              ),
                              iconTheme: IconThemeData(
                                color: AppColors.getTextColor(isDark),
                              ),
                            )
                          : null),
                  drawer: appBar == null && useDefaultAppBar
                      ? _QuranTopBar(
                          languageCode ?? 'ar',
                          isDark,
                          backgroundColor: backgroundColor,
                        )
                      : null,
                  body: SafeArea(
                      child: InkWell(
                    onTap: () {
                      if (onPagePress != null) {
                        onPagePress!();
                      } else {
                        quranCtrl.showControlToggle();
                        quranCtrl.state.overlayEntry?.remove();
                        quranCtrl.state.overlayEntry = null;
                      }
                    },
                    focusColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildSurahBody(parentContext, surahCtrl),

                        // السلايدر السفلي - يظهر من الأسفل للأعلى
                        // Bottom slider - appears from bottom to top
                        isShowAudioSlider!
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Obx(() => BottomSlider(
                                      isVisible: QuranCtrl
                                          .instance.isShowControl.value,
                                      onClose: () {
                                        QuranCtrl.instance.isShowControl.value =
                                            false;
                                        SliderController.instance
                                            .hideBottomContent();
                                      },
                                      style: ayahStyle ?? AyahAudioStyle(),
                                      contentChild: const SizedBox.shrink(),
                                      child: Flexible(
                                        child: AyahsAudioWidget(
                                          style: ayahStyle ??
                                              AyahAudioStyle.defaults(
                                                  isDark: isDark,
                                                  context: context),
                                        ),
                                      ),
                                    )),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  )),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// بناء محتوى السورة
  /// Build surah content
  Widget _buildSurahBody(BuildContext context, SurahCtrl surahCtrl) {
    // شرح: التحقق من تحميل البيانات
    // Explanation: Check if data is loaded
    if (surahCtrl.isLoading.value) {
      return Center(
        child: circularProgressWidget ??
            const CircularProgressIndicator.adaptive(),
      );
    }

    // شرح: التحقق من وجود صفحات السورة
    // Explanation: Check if surah pages exist
    if (surahCtrl.surahPages.isEmpty) {
      return Center(
        child: Text(
          'لا توجد آيات للسورة المحددة',
          style: TextStyle(
            color: AppColors.getTextColor(isDark),
            fontSize: 16,
          ),
        ),
      );
    }

    // شرح: استخدام PageView مع صفحات السورة من SurahCtrl
    // Explanation: Use PageView with surah pages from SurahCtrl
    return Obx(
      () => PageView.builder(
        controller: surahCtrl.pageController,
        itemCount: surahCtrl.surahPages.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, pageIndex) {
          return _buildSurahPage(
            context,
            surahCtrl.surahPages[pageIndex],
            pageIndex,
            surahCtrl,
          );
        },
      ),
    );
  }

  /// بناء صفحة السورة
  /// Build surah page
  Widget _buildSurahPage(BuildContext context, QuranPageModel surahPage,
      int pageIndex, SurahCtrl surahCtrl) {
    final deviceSize = MediaQuery.of(context).size;
    final isFirstPage = surahCtrl.isFirstPage(pageIndex);
    final isFirstPageInFirstOrSecondSurah =
        surahCtrl.isFirstPageInFirstOrSecondSurah(
            pageIndex, surahCtrl.surahPages[pageIndex].ayahs[0].surahNumber!);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: UiHelper.currentOrientation(16.0, 64.0, context),
        vertical: 16.0,
      ),
      child: (surahCtrl.surahPages[pageIndex].ayahs[0].surahNumber! == 1 ||
                  surahCtrl.surahPages[pageIndex].ayahs[0].surahNumber! == 2) &&
              pageIndex == 0
          ? isLandscape
              ? SingleChildScrollView(
                  child: towFirstSurahs(
                      context,
                      isFirstPageInFirstOrSecondSurah,
                      surahPage,
                      deviceSize,
                      surahCtrl,
                      pageIndex),
                )
              : towFirstSurahs(context, isFirstPageInFirstOrSecondSurah,
                  surahPage, deviceSize, surahCtrl, pageIndex)
          : isLandscape
              ? SingleChildScrollView(
                  child: _pageBuild(isFirstPage, surahCtrl, context, surahPage,
                      deviceSize, pageIndex))
              : _pageBuild(isFirstPage, surahCtrl, context, surahPage,
                  deviceSize, pageIndex),
    );
  }

  Widget _pageBuild(bool isFirstPage, SurahCtrl surahCtrl, BuildContext context,
      QuranPageModel surahPage, Size deviceSize, int pageIndex) {
    final currentPage = surahCtrl.getRealQuranPageNumber(pageIndex);
    return TopAndBottomWidget(
      pageIndex: currentPage - 1,
      languageCode: languageCode,
      juzName: juzName,
      sajdaName: sajdaName,
      isRight: pageIndex.isEven ? true : false,
      topTitleChild: topTitleChild,
      surahName: surahCtrl.getSurahName(),
      isSurah: true,
      surahNumber: surahNumber,
      child: RepaintBoundary(
        child: Column(
          children: [
            // شرح: عرض شعار السورة في الصفحة الأولى فقط
            // Explanation: Display surah banner only on first page
            if (isFirstPage) _buildSurahHeader(context),

            // شرح: عرض البسملة في الصفحة الأولى إذا لم تكن سورة التوبة
            // Explanation: Display Basmala on first page if not Surah At-Tawbah
            if (isFirstPage && surahCtrl.shouldShowBasmala()) _buildBasmala(),

            Flexible(
              child: GetBuilder<BookmarksCtrl>(
                builder: (bookmarkCtrl) {
                  return LayoutBuilder(builder: (context, constraints) {
                    return Column(
                      children: surahPage.lines.map((line) {
                        return SizedBox(
                          width: deviceSize.width - 20,
                          height: surahCtrl.calculateDynamicLineHeight(
                            availableHeight: constraints.maxHeight,
                            pageIndex: pageIndex,
                            hasHeader: pageIndex == 0,
                            hasBasmala:
                                pageIndex == 0 && surahCtrl.shouldShowBasmala(),
                          ),
                          child: DefaultFontsBuild(
                            context,
                            line,
                            isDark: isDark,
                            bookmarkCtrl.bookmarksAyahs,
                            bookmarkCtrl.bookmarks,
                            boxFit: line.ayahs.last.centered!
                                ? BoxFit.contain
                                : BoxFit.fill,
                            onDefaultAyahLongPress: onAyahLongPress,
                            bookmarksColor: bookmarksColor,
                            textColor:
                                textColor ?? (AppColors.getTextColor(isDark)),
                            bookmarkList: bookmarkList,
                            pageIndex:
                                surahCtrl.getRealQuranPageNumber(pageIndex),
                            ayahSelectedBackgroundColor:
                                ayahSelectedBackgroundColor,
                            ayahBookmarked: ayahBookmarked,
                            anotherMenuChildOnTap: anotherMenuChildOnTap,
                            anotherMenuChild: anotherMenuChild,
                            ayahSelectedFontColor: ayahSelectedFontColor,
                            secondMenuChild: secondMenuChild,
                            secondMenuChildOnTap: secondMenuChildOnTap,
                          ),
                        );
                      }).toList(),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء شعار السورة
  /// Build surah header
  Widget _buildSurahHeader(BuildContext context) {
    return SurahHeaderWidget(
      surahNumber,
      bannerStyle: bannerStyle ??
          BannerStyle(
            isImage: false,
            bannerSvgPath: isDark
                ? AssetsPath.assets.surahSvgBannerDark
                : AssetsPath.assets.surahSvgBanner,
            bannerSvgHeight: 40.0,
            bannerSvgWidth: 150.0,
            bannerImagePath: '',
            bannerImageHeight: 50,
            bannerImageWidth: double.infinity,
          ),
      surahNameStyle: surahNameStyle ??
          SurahNameStyle(
            surahNameSize: 70,
            surahNameColor: AppColors.getTextColor(isDark),
          ),
      onSurahBannerPress: onSurahBannerPress,
      isDark: isDark,
    );
  }

  /// بناء البسملة
  /// Build Basmala
  Widget _buildBasmala() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: BasmallahWidget(
        surahNumber: surahNumber,
        basmalaStyle: basmalaStyle ??
            BasmalaStyle(
              basmalaColor: AppColors.getTextColor(isDark),
              basmalaFontSize: 50.0,
            ),
      ),
    );
  }

  /// بناء محتوى الصفحة للسورة الأولى والثانية
  /// Build page content for first and second surah
  Widget towFirstSurahs(
    BuildContext context,
    bool isFirstPageInFirstOrSecondSurah,
    QuranPageModel surahPage,
    Size deviceSize,
    SurahCtrl surahCtrl,
    int pageIndex,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final currentPageNumber = surahCtrl.getRealQuranPageNumber(pageIndex);
    return TopAndBottomWidget(
        pageIndex: currentPageNumber - 1,
        languageCode: languageCode,
        juzName: juzName,
        sajdaName: sajdaName,
        isRight: pageIndex.isEven ? true : false,
        topTitleChild: topTitleChild,
        surahName: surahCtrl.getSurahName(),
        isSurah: true,
        child: (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
            ? isLandscape
                ? SingleChildScrollView(
                    child: _firstTwoSurahs(
                        context,
                        isFirstPageInFirstOrSecondSurah,
                        surahPage,
                        deviceSize,
                        surahCtrl,
                        pageIndex,
                        currentPageNumber - 1))
                : _firstTwoSurahs(
                    context,
                    isFirstPageInFirstOrSecondSurah,
                    surahPage,
                    deviceSize,
                    surahCtrl,
                    pageIndex,
                    currentPageNumber - 1)
            : _firstTwoSurahs(
                context,
                isFirstPageInFirstOrSecondSurah,
                surahPage,
                deviceSize,
                surahCtrl,
                pageIndex,
                currentPageNumber - 1));
  }

  Widget _firstTwoSurahs(
      BuildContext context,
      bool isFirstPage,
      QuranPageModel surahPage,
      Size deviceSize,
      SurahCtrl surahCtrl,
      int pageIndex,
      int currentPage) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      height: isFirstPage
          ? isLandscape
              ? MediaQuery.sizeOf(context).height
              : MediaQuery.sizeOf(context).height * .63
          : null,
      padding: isFirstPage
          ? EdgeInsets.symmetric(
              vertical: UiHelper.currentOrientation(
                  MediaQuery.sizeOf(context).width * .16,
                  MediaQuery.sizeOf(context).height * .01,
                  context),
              horizontal: UiHelper.currentOrientation(
                  MediaQuery.sizeOf(context).width * .12, 0.0, context))
          : EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // شرح: عرض شعار السورة في الصفحة الأولى فقط
          // Explanation: Display surah banner only on first page
          if (isFirstPage) _buildSurahHeader(context),

          // شرح: عرض البسملة في الصفحة الأولى إذا لم تكن سورة التوبة
          // Explanation: Display Basmala on first page if not Surah At-Tawbah
          if (isFirstPage && surahCtrl.shouldShowBasmala()) _buildBasmala(),

          ...surahCtrl.surahPages[pageIndex].lines.map((line) {
            return RepaintBoundary(
              child: GetBuilder<BookmarksCtrl>(
                builder: (bookmarkCtrl) {
                  return RepaintBoundary(
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Column(
                        children: [
                          SizedBox(
                            width: deviceSize.width - 32,
                            child: DefaultFontsBuild(
                              context,
                              line,
                              isDark: isDark,
                              bookmarkCtrl.bookmarksAyahs,
                              bookmarkCtrl.bookmarks,
                              boxFit: BoxFit.scaleDown,
                              onDefaultAyahLongPress: onAyahLongPress,
                              bookmarksColor: bookmarksColor,
                              textColor:
                                  textColor ?? (AppColors.getTextColor(isDark)),
                              bookmarkList: bookmarkList,
                              pageIndex: currentPage,
                              ayahSelectedBackgroundColor:
                                  ayahSelectedBackgroundColor,
                              ayahBookmarked: ayahBookmarked,
                              anotherMenuChild: anotherMenuChild,
                              anotherMenuChildOnTap: anotherMenuChildOnTap,
                              ayahSelectedFontColor: ayahSelectedFontColor,
                              secondMenuChild: secondMenuChild,
                              secondMenuChildOnTap: secondMenuChildOnTap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
