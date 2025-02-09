part of '../../quran.dart';

class QuranLibraryScreen extends StatelessWidget {
  const QuranLibraryScreen({
    // this.showBottomWidget = true,
    // this.bottomWidget,
    this.appBar,
    this.onPageChanged,
    super.key,
    this.basmalaStyle,
    this.bannerStyle,
    this.withPageView = true,
    this.pageIndex = 0,
    this.bookmarksColor,
    this.textColor,
    this.surahNumber,
    this.ayahSelectedBackgroundColor,
    this.bookmarkList = const [],
    this.onSurahBannerPress,
    this.onPagePress,
    this.surahNameStyle,
    this.backgroundColor,
    this.surahInfoStyle,
    this.languageCode = 'ar',
    this.downloadFontsDialogStyle,
    this.juzName,
    this.sajdaName,
    this.topTitleChild,
    this.onFontsAyahLongPress,
    this.isDark = false,
    this.circularProgressWidget,
    required this.fFamily,
  });

  // /// متغير لتعطيل أو تمكين الويدجت السفلية الافتراضية [showBottomWidget]
  // ///
  // /// [showBottomWidget] is a bool to disable or enable the default bottom widget
  // final bool showBottomWidget;
  final String fFamily;

  // /// إذا قمت بإضافة قطعة هنا فإنه سيحل محل القطعة السفلية الافتراضية [bottomWidget]
  // ///
  // /// [bottomWidget] if if provided it will replace the default bottom widget
  // final Widget? bottomWidget;

  /// إذا قمت بإضافة شريط التطبيقات هنا فإنه سيحل محل شريط التطبيقات الافتراضية [appBar]
  ///
  /// [appBar] if if provided it will replace the default app bar
  final PreferredSizeWidget? appBar;

  /// إذا تم توفيره فسيتم استدعاؤه عند تغيير صفحة القرآن [onPageChanged]
  ///
  /// [onPageChanged] if provided it will be called when a quran page changed
  final Function(int pageNumper)? onPageChanged;

  /// تغيير نمط البسملة بواسطة هذه الفئة [BasmalaStyle]
  ///
  /// [BasmalaStyle] Change the style of Basmala by BasmalaStyle class
  final BasmalaStyle? basmalaStyle;

  /// تغيير نمط الشعار من خلال هذه الفئة [BannerStyle]
  ///
  /// [BannerStyle] Change the style of banner by BannerStyle class
  final BannerStyle? bannerStyle;

  /// تغيير نمط اسم السورة بهذه الفئة [SurahNameStyle]
  ///
  /// [SurahNameStyle] Change the style of surah name by SurahNameStyle class
  final SurahNameStyle? surahNameStyle;

  /// تغيير نمط معلومات السورة بواسطة هذه الفئة [SurahInfoStyle]
  ///
  /// [SurahInfoStyle] Change the style of surah information by SurahInfoStyle class
  final SurahInfoStyle? surahInfoStyle;

  /// تغيير نمط نافذة تحميل الخطوط بواسطة هذه الفئة [DownloadFontsDialogStyle]
  ///
  /// [DownloadFontsDialogStyle] Change the style of Download fonts dialog by DownloadFontsDialogStyle class
  final DownloadFontsDialogStyle? downloadFontsDialogStyle;

  /// قم بتمكين هذا المتغير إذا كنت تريد عرض القرآن باستخدام PageView [withPageView]
  ///
  /// [withPageView] Enable this variable if you want to display the Quran with PageView
  final bool withPageView;

  /// قم بتمرير رقم الصفحة إذا كنت لا تريد عرض القرآن باستخدام PageView [pageIndex]
  ///
  /// [pageIndex] pass the page number if you do not want to display the Quran with PageView
  final int pageIndex;

  /// تغيير لون الإشارة المرجعية (اختياري) [bookmarksColor]
  ///
  /// [bookmarksColor] Change the bookmark color (optional)
  final Color? bookmarksColor;

  /// * تُستخدم مع الخطوط المحملة *
  /// عند الضغط المطوّل على أي آية باستخدام الخطوط المحملة، يمكنك تفعيل ميزات إضافية
  /// مثل نسخ الآية أو مشاركتها وغير ذلك عبر [onFontsAyahLongPress].
  ///
  /// * Used with loaded fonts *
  /// When long-pressing on any verse with the loaded fonts, you can enable additional features
  /// such as copying the verse, sharing it, and more using [onFontsAyahLongPress].
  final void Function(LongPressStartDetails details, AyahFontsModel ayah)?
      onFontsAyahLongPress;

  /// * تُستخدم مع الخطوط المحملة *
  /// عند الضغط على أي لافتة سورة باستخدام الخطوط المحملة، يمكنك إضافة بعض التفاصيل حول السورة [onSurahBannerPress]
  ///
  /// * Used with loaded fonts *
  /// [onSurahBannerPress] When you press on any Surah banner with the loaded fonts,
  /// you can add some details about the surah
  final void Function(SurahNamesModel surah)? onSurahBannerPress;

  /// عند الضغط على الصفحة يمكنك إضافة بعض المميزات مثل حذف التظليل عن الآية وغيرها [onPagePress]
  ///
  /// [onPagePress] When you click on the page, you can add some features,
  /// such as deleting the shading from the verse and others
  final VoidCallback? onPagePress;

  /// يمكنك تمرير لون نص القرآن [textColor]
  ///
  /// [textColor] You can pass the color of the Quran text
  final Color? textColor;

  /// يمكنك تمرير رقم السورة [surahNumber]
  ///
  /// [surahNumber] You can pass the Surah number
  final int? surahNumber;

  /// يمكنك تمرير لون خلفية الآية المحدد [ayahSelectedBackgroundColor]
  ///
  /// [ayahSelectedBackgroundColor] You can pass the color of the Ayah selected background
  final Color? ayahSelectedBackgroundColor;

  /// إذا كنت تريد إضافة قائمة إشارات مرجعية خاصة، فقط قم بتمريرها لـ [bookmarkList]
  ///
  /// If you want to add a private bookmark list, just pass it to [bookmarkList]
  final List bookmarkList;

  /// إذا كنت تريد تغيير لون خلفية صفحة القرآن [backgroundColor]
  ///
  /// [backgroundColor] if you wanna change the background color of Quran page
  final Color? backgroundColor;

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

  /// إذا كنت تريد تغيير كلمة "سجدة" إلى كلمة أخرى أو ترجمتها فقط قم بتمريرها لـ [sajdaName]
  ///
  /// If you want to change the word “سجدة” to another word or translate it just pass it to [juzName].
  ///
  final String? sajdaName;

  /// إذا كنت تريد إضافة ويدجت بجانب اسم السورة [topTitleChild]
  ///
  /// If you want to add a widget next to the surah name [topTitleChild]
  ///
  final Widget? topTitleChild;

  /// قم بتمكين هذا المتغير إذا كنت تريد عرض القرآن في النمط المظلم [isDark]
  ///
  /// [isDark] Enable this variable if you want to display the Quran with dark mode
  ///
  final bool isDark;

  /// إذا كنت تريد إضافة ويدجت بدلًا من الويدجت الإفتراضية [circularProgressWidget]
  ///
  /// If you want to add a widget instead of the default widget [circularProgressWidget]
  ///
  final Widget? circularProgressWidget;

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
              (isDark ? const Color(0xff202020) : const Color(0xfffaf7f3)),
          body: SafeArea(
            child: withPageView
                ? PageView.builder(
                    itemCount: 604,
                    controller: quranCtrl.pageController,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: (page) async {
                      if (onPageChanged != null) onPageChanged!(page);
                      quranCtrl.saveLastPage(page + 1);
                      quranCtrl.state.overlayEntry?.remove();
                      quranCtrl.state.overlayEntry = null;
                    },
                    pageSnapping: true,
                    itemBuilder: (ctx, index) {
                      return _pageViewBuild(
                        context,
                        index,
                        quranCtrl,
                      );
                    },
                  )
                : _pageViewBuild(
                    context,
                    pageIndex,
                    quranCtrl,
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
  ) {
    final bookmarkCtrl = BookmarksCtrl.instance;
    return GetBuilder<QuranCtrl>(
      init: QuranCtrl.instance,
      builder: (quranCtrl) => GestureDetector(
        onScaleStart: (details) => quranCtrl.state.baseScaleFactor.value =
            quranCtrl.state.scaleFactor.value,
        onScaleUpdate: (ScaleUpdateDetails details) =>
            quranCtrl.updateTextScale(details),
        child: quranCtrl.textScale(
          quranCtrl.state.allAyahs.isEmpty ||
                  quranCtrl.state.surahs.isEmpty ||
                  quranCtrl.state.pages.isEmpty
              ? Center(
                  child: circularProgressWidget ?? CircularProgressIndicator())
              : Align(
                  alignment: Alignment.topCenter,
                  child: AllQuranWidget(
                    pageIndex: pageIndex,
                    languageCode: languageCode,
                    juzName: juzName,
                    sajdaName: sajdaName,
                    isRight: pageIndex.isEven ? true : false,
                    topTitleChild: topTitleChild,
                    child: QuranFontsPage(
                      fFamily: fFamily,
                      pageIndex: pageIndex,
                      bookmarkList: bookmarkList,
                      textColor: textColor,
                      bookmarks: bookmarkCtrl.bookmarks,
                      onFontsAyahLongPress: onFontsAyahLongPress,
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
                      isDark: isDark,
                    ),
                  )),
          AllQuranWidget(
            pageIndex: pageIndex,
            languageCode: languageCode,
            juzName: juzName,
            sajdaName: sajdaName,
            isRight: pageIndex.isEven ? true : false,
            topTitleChild: topTitleChild,
            child: QuranTextScale(
              pageIndex: pageIndex,
              bookmarkList: bookmarkList,
              textColor: textColor,
              bookmarks: bookmarkCtrl.bookmarks,
              onFontsAyahLongPress: onFontsAyahLongPress,
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
            ),
          ),
        ),
      ),
    );
  }
}
