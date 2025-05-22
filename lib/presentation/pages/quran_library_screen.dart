part of '../../quran.dart';

/// A widget that displays the Quran library screen.
///
/// This screen is used to display the Quran library, which includes
/// the text of the Quran, bookmarks, and other relevant information.
///
/// The screen is customizable, with options to set the app bar,
/// ayah icon color, ayah selected background color, banner style,
/// basmala style, background color, bookmarks color, circular progress
/// widget, download fonts dialog style, and language code.
///
/// The screen also provides a callback for when the default ayah is
/// long pressed.
class QuranLibraryScreen extends StatelessWidget {
  /// Creates a new instance of [QuranLibraryScreen].
  ///
  /// This constructor is used to create a new instance of the
  /// [QuranLibraryScreen] widget.
  const QuranLibraryScreen({
    super.key,
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
    this.pageIndex = 0,
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
  });

  /// إذا قمت بإضافة شريط التطبيقات هنا فإنه سيحل محل شريط التطبيقات الافتراضية [appBar]
  ///
  /// [appBar] if if provided it will replace the default app bar
  final PreferredSizeWidget? appBar;

  /// يمكنك تمرير لون لأيقونة الآية [ayahIconColor]
  ///
  /// [ayahIconColor] You can pass the color of the Ayah icon
  final Color? ayahIconColor;

  /// يمكنك تمرير لون خلفية الآية المحدد [ayahSelectedBackgroundColor]
  ///
  /// [ayahSelectedBackgroundColor] You can pass the color of the Ayah selected background
  final Color? ayahSelectedBackgroundColor;
  final Color? ayahSelectedFontColor;

  /// تغيير نمط البسملة بواسطة هذه الفئة [BasmalaStyle]
  ///
  /// [BasmalaStyle] Change the style of Basmala by BasmalaStyle class
  final BasmalaStyle? basmalaStyle;

  /// تغيير نمط الشعار من خلال هذه الفئة [BannerStyle]
  ///
  /// [BannerStyle] Change the style of banner by BannerStyle class
  final BannerStyle? bannerStyle;

  /// إذا كنت تريد إضافة قائمة إشارات مرجعية خاصة، فقط قم بتمريرها لـ [bookmarkList]
  ///
  /// If you want to add a private bookmark list, just pass it to [bookmarkList]
  final List bookmarkList;

  /// تغيير لون الإشارة المرجعية (اختياري) [bookmarksColor]
  ///
  /// [bookmarksColor] Change the bookmark color (optional)
  final Color? bookmarksColor;

  /// إذا كنت تريد تغيير لون خلفية صفحة القرآن [backgroundColor]
  ///
  /// [backgroundColor] if you wanna change the background color of Quran page
  final Color? backgroundColor;

  /// إذا كنت تريد إضافة ويدجت بدلًا من الويدجت الإفتراضية [circularProgressWidget]
  ///
  /// If you want to add a widget instead of the default widget [circularProgressWidget]
  final Widget? circularProgressWidget;

  /// تغيير نمط نافذة تحميل الخطوط بواسطة هذه الفئة [DownloadFontsDialogStyle]
  ///
  /// [DownloadFontsDialogStyle] Change the style of Download fonts dialog by DownloadFontsDialogStyle class
  final DownloadFontsDialogStyle? downloadFontsDialogStyle;

  /// قم بتمرير رقم الصفحة إذا كنت لا تريد عرض القرآن باستخدام PageView [pageIndex]
  ///
  /// [pageIndex] pass the page number if you do not want to display the Quran with PageView
  final int pageIndex;

  /// قم بتمكين هذا المتغير إذا كنت تريد عرض القرآن في النمط المظلم [isDark]
  ///
  /// [isDark] Enable this variable if you want to display the Quran with dark mode
  final bool isDark;

  /// إذا كنت تريد تمرير كود اللغة الخاصة بالتطبيق لتغيير الأرقام على حسب اللغة،
  /// :رمز اللغة الإفتراضي هو 'ar' [languageCode]
  ///
  /// [languageCode] If you want to pass the application's language code to change the numbers according to the language,
  /// the default language code is 'ar'
  final String? languageCode;

  /// إذا كنت تريد تغيير كلمة "الجزء" إلى كلمة أخرى أو ترجمتها فقط قم بتمريرها لـ [juzName]
  ///
  /// If you want to change the word “الجزء” to another word or translate it just pass it to [juzName].
  ///
  final String? juzName;

  /// إذا تم توفيره فسيتم استدعاؤه عند تغيير صفحة القرآن [onPageChanged]
  ///
  /// [onPageChanged] if provided it will be called when a quran page changed
  final Function(int pageNumber)? onPageChanged;

  /// عند الضغط على الصفحة يمكنك إضافة بعض المميزات مثل حذف التظليل عن الآية وغيرها [onPagePress]
  ///
  /// [onPagePress] When you click on the page, you can add some features,
  /// such as deleting the shading from the verse and others
  final VoidCallback? onPagePress;

  /// * تُستخدم مع الخطوط المحملة *
  /// عند الضغط المطوّل على أي آية باستخدام الخطوط المحملة، يمكنك تفعيل ميزات إضافية
  /// مثل نسخ الآية أو مشاركتها وغير ذلك عبر [onAyahLongPress].
  ///
  /// * Used with loaded fonts *
  /// When long-pressing on any verse with the loaded fonts, you can enable additional features
  /// such as copying the verse, sharing it, and more using [onAyahLongPress].
  final void Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;

  /// * تُستخدم مع الخطوط المحملة *
  /// عند الضغط على أي لافتة سورة باستخدام الخطوط المحملة، يمكنك إضافة بعض التفاصيل حول السورة [onSurahBannerPress]
  ///
  /// * Used with loaded fonts *
  /// [onSurahBannerPress] When you press on any Surah banner with the loaded fonts,
  /// you can add some details about the surah
  final void Function(SurahNamesModel surah)? onSurahBannerPress;

  /// إذا كنت تريد تغيير كلمة "سجدة" إلى كلمة أخرى أو ترجمتها فقط قم بتمريرها لـ [sajdaName]
  ///
  /// If you want to change the word “سجدة” to another word or translate it just pass it to [sajdaName].
  ///
  final String? sajdaName;

  /// يمكنك تمكين أو تعطيل عرض أيقونة الإشارة المرجعية للآية [showAyahBookmarkedIcon]
  ///
  /// [showAyahBookmarkedIcon] You can enable or disable the display of the Ayah bookmarked icon
  final bool showAyahBookmarkedIcon;

  /// يمكنك تمرير رقم السورة [surahNumber]
  ///
  /// [surahNumber] You can pass the Surah number
  final int? surahNumber;

  /// تغيير نمط معلومات السورة بواسطة هذه الفئة [SurahInfoStyle]
  ///
  /// [SurahInfoStyle] Change the style of surah information by SurahInfoStyle class
  final SurahInfoStyle? surahInfoStyle;

  /// تغيير نمط اسم السورة بهذه الفئة [SurahNameStyle]
  ///
  /// [SurahNameStyle] Change the style of surah name by SurahNameStyle class
  final SurahNameStyle? surahNameStyle;

  /// إذا كنت تريد إضافة ويدجت بجانب اسم السورة [topTitleChild]
  ///
  /// If you want to add a widget next to the surah name [topTitleChild]
  ///
  final Widget? topTitleChild;

  /// يمكنك تمرير لون نص القرآن [textColor]
  ///
  /// [textColor] You can pass the color of the Quran text
  final Color? textColor;
  final List<Color?>? singleAyahTextColors;

  /// متغير لتعطيل أو تمكين شريط التطبيقات الافتراضية [useDefaultAppBar]
  ///
  /// [useDefaultAppBar] is a bool to disable or enable the default app bar widget
  ///
  final bool useDefaultAppBar;

  /// قم بتمكين هذا المتغير إذا كنت تريد عرض القرآن باستخدام PageView [withPageView]
  ///
  /// [withPageView] Enable this variable if you want to display the Quran with PageView
  final bool withPageView;

  /// إذا كنت تريد استخدام خطوط موجودة مسبقًا في التطبيق، اجعل هذا المتغيير true [isFontsLocal]
  ///
  /// [isFontsLocal] If you want to use fonts that exists in the app, make this variable true
  final bool? isFontsLocal;

  /// قم بتمرير إسم الخط الموجود في التطبيق لكي تستطيع إستخدامه [fontsName]
  ///
  /// [fontsName] Pass the name of the font that exists in the app so you can use it
  final String? fontsName;

  /// قم بتمرير قائمة الآيات المحفوظة [ayahBookmarked]
  ///
  /// [ayahBookmarked] Pass the list of bookmarked ayahs
  final List<int>? ayahBookmarked;

  final Widget? anotherMenuChild;
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;

  @override
  Widget build(BuildContext context) {
    // if (isDark!) {
    //   QuranCtrl.instance.state.isTajweed.value = 1;
    //   GetStorage().write(StorageConstants().isTajweed, 1);
    // }
    return GetBuilder<QuranCtrl>(
      builder: (quranCtrl) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: backgroundColor ??
              (isDark ? const Color(0xff1E1E1E) : const Color(0xfffaf7f3)),
          appBar: appBar ??
              (useDefaultAppBar
                  ? AppBar(
                      backgroundColor: backgroundColor ??
                          (isDark
                              ? const Color(0xff1E1E1E)
                              : const Color(0xfffaf7f3)),
                      leading: Builder(
                        builder: (context) => IconButton(
                          icon: Icon(
                            Icons.menu,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ),
                      elevation: 0,
                      actions: [
                        FontsDownloadDialog(
                          downloadFontsDialogStyle: downloadFontsDialogStyle ??
                              DownloadFontsDialogStyle(
                                title: 'الخطوط',
                                titleColor:
                                    isDark ? Colors.white : Colors.black,
                                notes:
                                    'لجعل مظهر المصحف مشابه لمصحف المدينة يمكنك تحميل خطوط المصحف',
                                notesColor:
                                    isDark ? Colors.white : Colors.black,
                                linearProgressBackgroundColor:
                                    Colors.blue.shade100,
                                linearProgressColor: Colors.blue,
                                downloadButtonBackgroundColor: Colors.blue,
                                downloadingText: 'جارِ التحميل',
                                backgroundColor: isDark
                                    ? Color(0xff1E1E1E)
                                    : const Color(0xFFF7EFE0),
                              ),
                          languageCode: languageCode,
                          isFontsLocal: isFontsLocal,
                          isDark: isDark,
                        )
                      ],
                    )
                  : null),
          drawer: appBar == null && useDefaultAppBar
              ? _DefaultDrawer(languageCode ?? 'ar', isDark)
              : null,
          body: SafeArea(
            child: withPageView
                ? PageView.builder(
                    itemCount: 604,
                    controller: quranCtrl.pageController,
                    padEnds: false,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (page) async {
                      if (onPageChanged != null) {
                        onPageChanged!(page);
                      } else {
                        quranCtrl.state.overlayEntry?.remove();
                        quranCtrl.state.overlayEntry = null;
                      }
                      quranCtrl.saveLastPage(page + 1);
                    },
                    pageSnapping: true,
                    itemBuilder: (ctx, index) {
                      return _pageViewBuild(
                        context,
                        index,
                        quranCtrl,
                        isFontsLocal!,
                      );
                    },
                  )
                : _pageViewBuild(
                    context,
                    pageIndex,
                    quranCtrl,
                    isFontsLocal!,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _pageViewBuild(
    BuildContext context,
    int pageIndex,
    QuranCtrl quranCtrl,
    bool isFontsLocal,
  ) {
    final deviceSize = MediaQuery.of(context).size;
    List<String> newSurahs = [];
    quranCtrl.isDownloadFonts
        ? quranCtrl.prepareFonts(pageIndex, isFontsLocal: isFontsLocal)
        : null;
    final bookmarkCtrl = BookmarksCtrl.instance;
    return GetBuilder<QuranCtrl>(
      init: QuranCtrl.instance,
      builder: (quranCtrl) => GestureDetector(
        onScaleStart: (details) => quranCtrl.state.baseScaleFactor.value =
            quranCtrl.state.scaleFactor.value,
        onScaleUpdate: (ScaleUpdateDetails details) =>
            quranCtrl.updateTextScale(details),
        child: quranCtrl.textScale(
          (quranCtrl.isDownloadFonts
              ? quranCtrl.state.allAyahs.isEmpty ||
                      quranCtrl.state.surahs.isEmpty ||
                      quranCtrl.state.pages.isEmpty
                  ? Center(
                      child: circularProgressWidget ??
                          const CircularProgressIndicator())
                  : Align(
                      alignment: Alignment.topCenter,
                      child: AllQuranWidget(
                        pageIndex: pageIndex,
                        languageCode: languageCode,
                        juzName: juzName,
                        sajdaName: sajdaName,
                        isRight: pageIndex.isEven ? true : false,
                        topTitleChild: topTitleChild,
                        child: _QuranFontsPage(
                          context: context,
                          pageIndex: pageIndex,
                          bookmarkList: bookmarkList,
                          textColor: ayahSelectedFontColor ?? textColor,
                          ayahIconColor: ayahIconColor,
                          showAyahBookmarkedIcon: showAyahBookmarkedIcon,
                          bookmarks: bookmarkCtrl.bookmarks,
                          onAyahLongPress: onAyahLongPress,
                          bookmarksColor: bookmarksColor,
                          surahInfoStyle: surahInfoStyle,
                          surahNameStyle: surahNameStyle,
                          bannerStyle: bannerStyle,
                          basmalaStyle: basmalaStyle,
                          onSurahBannerPress: onSurahBannerPress,
                          surahNumber: surahNumber,
                          bookmarksAyahs: bookmarkCtrl.bookmarksAyahs,
                          ayahSelectedBackgroundColor:
                              ayahSelectedBackgroundColor,
                          onPagePress: onPagePress,
                          isDark: isDark,
                          circularProgressWidget: circularProgressWidget,
                          isFontsLocal: isFontsLocal,
                          fontsName: fontsName,
                          ayahBookmarked: ayahBookmarked!,
                          anotherMenuChild: anotherMenuChild,
                          anotherMenuChildOnTap: anotherMenuChildOnTap,
                        ),
                      ))
              : quranCtrl.staticPages.isEmpty || quranCtrl.isLoading.value
                  ? Center(
                      child: circularProgressWidget ??
                          const CircularProgressIndicator())
                  : _QuranLinePage(
                      context: context,
                      pageIndex: pageIndex,
                      bookmarkList: bookmarkList,
                      textColor: textColor,
                      languageCode: languageCode,
                      onAyahLongPress: onAyahLongPress,
                      bookmarksColor: bookmarksColor,
                      surahInfoStyle: surahInfoStyle,
                      surahNameStyle: surahNameStyle,
                      bannerStyle: bannerStyle,
                      basmalaStyle: basmalaStyle,
                      onSurahBannerPress: onSurahBannerPress,
                      surahNumber: surahNumber,
                      newSurahs: newSurahs,
                      ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
                      onPagePress: onPagePress,
                      deviceSize: deviceSize,
                      juzName: juzName,
                      sajdaName: sajdaName,
                      topTitleChild: topTitleChild,
                      isDark: isDark,
                      ayahBookmarked: ayahBookmarked!,
                      anotherMenuChild: anotherMenuChild,
                      anotherMenuChildOnTap: anotherMenuChildOnTap,
                    )),
          quranCtrl.staticPages.isEmpty || quranCtrl.isLoading.value
              ? Center(
                  child: circularProgressWidget ??
                      const CircularProgressIndicator())
              : AllQuranWidget(
                  pageIndex: pageIndex,
                  languageCode: languageCode,
                  juzName: juzName,
                  sajdaName: sajdaName,
                  isRight: pageIndex.isEven ? true : false,
                  topTitleChild: topTitleChild,
                  child: _QuranTextScale(
                    context: context,
                    pageIndex: pageIndex,
                    bookmarkList: bookmarkList,
                    textColor: ayahSelectedFontColor ?? textColor,
                    ayahIconColor: ayahIconColor,
                    showAyahBookmarkedIcon: showAyahBookmarkedIcon,
                    bookmarks: bookmarkCtrl.bookmarks,
                    onAyahLongPress: onAyahLongPress,
                    bookmarksColor: bookmarksColor,
                    surahInfoStyle: surahInfoStyle,
                    surahNameStyle: surahNameStyle,
                    bannerStyle: bannerStyle,
                    basmalaStyle: basmalaStyle,
                    onSurahBannerPress: onSurahBannerPress,
                    surahNumber: surahNumber,
                    bookmarksAyahs: bookmarkCtrl.bookmarksAyahs,
                    ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
                    onAyahPress: onPagePress,
                    languageCode: languageCode,
                    isDark: isDark,
                    circularProgressWidget: circularProgressWidget,
                    ayahBookmarked: ayahBookmarked!,
                    anotherMenuChild: anotherMenuChild,
                    anotherMenuChildOnTap: anotherMenuChildOnTap,
                  ),
                ),
        ),
      ),
    );
  }
}
