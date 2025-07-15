part of '/quran.dart';

/// شاشة لعرض سورة واحدة باستخدام SurahCtrl و _QuranLinePage
/// Screen for displaying a single surah using SurahCtrl and _QuranLinePage
class SurahDisplayScreen extends StatelessWidget {
  /// إنشاء مثيل جديد من SurahDisplayScreen
  /// Creates a new instance of SurahDisplayScreen
  const SurahDisplayScreen({
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

  final Widget? anotherMenuChild;
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;

  /// اسم الجزء
  /// Juz name
  final String? juzName;

  /// اسم السجدة
  /// Sajda name
  final String? sajdaName;

  @override
  Widget build(BuildContext context) {
    // شرح: تهيئة الشاشة وإعداد المقاييس
    // Explanation: Initialize screen and setup dimensions
    return ScreenUtilInit(
      designSize: const Size(392.72727272727275, 800.7272727272727),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetBuilder<SurahCtrl>(
          init: SurahCtrl.instance,
          initState: (state) {
            // شرح: تحميل السورة عند بناء الشاشة
            // Explanation: Load surah when building screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final ctrl = state.controller!;
              // شرح: إعادة تحميل السورة إذا تغير رقمها
              // Explanation: Reload surah if its number changed
              if (ctrl.surahNumber != surahNumber) {
                ctrl.loadSurah(surahNumber);
              }
            });
          },
          builder: (surahCtrl) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                backgroundColor: backgroundColor ??
                    (isDark
                        ? const Color(0xff1E1E1E)
                        : const Color(0xfffaf7f3)),
                appBar: appBar ??
                    (useDefaultAppBar
                        ? AppBar(
                            backgroundColor: backgroundColor ??
                                (isDark
                                    ? const Color(0xff1E1E1E)
                                    : const Color(0xfffaf7f3)),
                            elevation: 0,
                            centerTitle: true,
                            title: Text(
                              surahCtrl.getSurahName(),
                              style: QuranLibrary().naskhStyle.copyWith(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 22,
                                  ),
                            ),
                            iconTheme: IconThemeData(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          )
                        : null),
                drawer: appBar == null && useDefaultAppBar
                    ? _DefaultDrawer(languageCode ?? 'ar', isDark)
                    : null,
                body: SafeArea(child: _buildSurahBody(context, surahCtrl)),
              ),
            );
          },
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
            color: isDark ? Colors.white : Colors.black,
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
        horizontal: context.currentOrientation(16.0, 64.0),
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
    return AllQuranWidget(
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
            if (isFirstPage) _buildSurahHeader(),

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
                          child: QuranLine(
                            context,
                            line,
                            isDark: isDark,
                            bookmarkCtrl.bookmarksAyahs,
                            bookmarkCtrl.bookmarks,
                            boxFit: line.ayahs.last.centered!
                                ? BoxFit.scaleDown
                                : BoxFit.fill,
                            onDefaultAyahLongPress: onAyahLongPress,
                            bookmarksColor: bookmarksColor,
                            textColor: textColor ??
                                (isDark ? Colors.white : Colors.black),
                            bookmarkList: bookmarkList,
                            pageIndex:
                                surahCtrl.getRealQuranPageNumber(pageIndex),
                            ayahSelectedBackgroundColor:
                                ayahSelectedBackgroundColor,
                            onPagePress: onPagePress,
                            ayahBookmarked: ayahBookmarked,
                            anotherMenuChildOnTap: anotherMenuChildOnTap,
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
  Widget _buildSurahHeader() {
    return SurahHeaderWidget(
      surahNumber,
      bannerStyle: bannerStyle ??
          BannerStyle(
            isImage: false,
            bannerSvgPath: isDark
                ? _AssetsPath().surahSvgBannerDark
                : _AssetsPath().surahSvgBanner,
            bannerSvgHeight: 40.0,
            bannerSvgWidth: 150.0,
            bannerImagePath: '',
            bannerImageHeight: 50,
            bannerImageWidth: double.infinity,
          ),
      surahNameStyle: surahNameStyle ??
          SurahNameStyle(
            surahNameWidth: 70,
            surahNameHeight: 30,
            surahNameColor: isDark ? Colors.white : Colors.black,
          ),
      surahInfoStyle: surahInfoStyle ??
          SurahInfoStyle(
            ayahCount: 'عدد الآيات',
            secondTabText: 'عن السورة',
            firstTabText: 'أسماء السورة',
            backgroundColor:
                isDark ? const Color(0xff1E1E1E) : const Color(0xfffaf7f3),
            closeIconColor: isDark ? Colors.white : Colors.black,
            indicatorColor: Colors.amber.withValues(alpha: .2),
            primaryColor: Colors.amber.withValues(alpha: .2),
            surahNameColor: isDark ? Colors.white : Colors.black,
            surahNumberColor: isDark ? Colors.white : Colors.black,
            textColor: isDark ? Colors.white : Colors.black,
            titleColor: isDark ? Colors.white : Colors.black,
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
              basmalaColor: isDark ? Colors.white : Colors.black,
              basmalaWidth: 160.0,
              basmalaHeight: 30.0,
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
    final currentPage = surahCtrl.getRealQuranPageNumber(pageIndex);
    return AllQuranWidget(
        pageIndex: currentPage - 1,
        languageCode: languageCode,
        juzName: juzName,
        sajdaName: sajdaName,
        isRight: pageIndex.isEven ? true : false,
        topTitleChild: topTitleChild,
        surahName: surahCtrl.getSurahName(),
        isSurah: true,
        child: Platform.isAndroid || Platform.isIOS
            ? isLandscape
                ? SingleChildScrollView(
                    child: _firstTwoSurahs(
                        context,
                        isFirstPageInFirstOrSecondSurah,
                        surahPage,
                        deviceSize,
                        surahCtrl,
                        pageIndex,
                        currentPage - 1))
                : _firstTwoSurahs(
                    context,
                    isFirstPageInFirstOrSecondSurah,
                    surahPage,
                    deviceSize,
                    surahCtrl,
                    pageIndex,
                    currentPage - 1)
            : _firstTwoSurahs(context, isFirstPageInFirstOrSecondSurah,
                surahPage, deviceSize, surahCtrl, pageIndex, currentPage - 1));
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
              vertical: context.currentOrientation(
                  MediaQuery.sizeOf(context).width * .16,
                  MediaQuery.sizeOf(context).height * .01),
              horizontal: context.currentOrientation(
                  MediaQuery.sizeOf(context).width * .12, 0.0))
          : EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // شرح: عرض شعار السورة في الصفحة الأولى فقط
          // Explanation: Display surah banner only on first page
          if (isFirstPage) _buildSurahHeader(),

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
                            child: QuranLine(
                              context,
                              line,
                              isDark: isDark,
                              bookmarkCtrl.bookmarksAyahs,
                              bookmarkCtrl.bookmarks,
                              boxFit: BoxFit.scaleDown,
                              onDefaultAyahLongPress: onAyahLongPress,
                              bookmarksColor: bookmarksColor,
                              textColor: textColor ??
                                  (isDark ? Colors.white : Colors.black),
                              bookmarkList: bookmarkList,
                              pageIndex: currentPage,
                              ayahSelectedBackgroundColor:
                                  ayahSelectedBackgroundColor,
                              onPagePress: onPagePress,
                              ayahBookmarked: ayahBookmarked,
                              anotherMenuChild: anotherMenuChild,
                              anotherMenuChildOnTap: anotherMenuChildOnTap,
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
