part of '/quran.dart';

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
    this.secondMenuChild,
    this.secondMenuChildOnTap,
    this.ayahStyle,
    this.surahStyle,
    this.isShowAudioSlider = true,
    this.appIconUrlForPlayAudioInBackground,
    required this.parentContext,
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

  /// زر إضافي أول لقائمة خيارات الآية - يمكن إضافة أيقونة أو نص مخصص [anotherMenuChild]
  ///
  /// [anotherMenuChild] First additional button for ayah options menu - you can add custom icon or text
  final Widget? anotherMenuChild;

  /// دالة يتم استدعاؤها عند الضغط على الزر الإضافي الأول في قائمة خيارات الآية [anotherMenuChildOnTap]
  ///
  /// [anotherMenuChildOnTap] Function called when pressing the first additional button in ayah options menu
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;

  /// زر إضافي ثاني لقائمة خيارات الآية - يمكن إضافة أيقونة أو نص مخصص [secondMenuChild]
  ///
  /// [secondMenuChild] Second additional button for ayah options menu - you can add custom icon or text
  final Widget? secondMenuChild;

  /// دالة يتم استدعاؤها عند الضغط على الزر الإضافي الثاني في قائمة خيارات الآية [secondMenuChildOnTap]
  ///
  /// [secondMenuChildOnTap] Function called when pressing the second additional button in ayah options menu
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

  @override
  Widget build(BuildContext context) {
    // تحديث رابط أيقونة التطبيق إذا تم تمريره / Update app icon URL if provided
    // Update app icon URL if provided
    if (appIconUrlForPlayAudioInBackground != null &&
        appIconUrlForPlayAudioInBackground!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AudioCtrl.instance
            .updateAppIconUrl(appIconUrlForPlayAudioInBackground!);
      });
    }

    // if (isDark!) {
    //   QuranCtrl.instance.state.isTajweed.value = 1;
    //   GetStorage().write(StorageConstants().isTajweed, 1);
    // }
    return ScreenUtilInit(
      designSize: const Size(392.72727272727275, 800.7272727272727),
      minTextAdapt: true,
      splitScreenMode: true,
      // Use builder only if you need to use library outside ScreenUtilInit context
      builder: (_, __) => GetBuilder<QuranCtrl>(
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
                          builder: (buildContext) => IconButton(
                            icon: Icon(
                              Icons.menu,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            onPressed: () {
                              Scaffold.of(buildContext).openDrawer();
                            },
                          ),
                        ),
                        elevation: 0,
                        actions: [
                          FontsDownloadDialog(
                            downloadFontsDialogStyle:
                                downloadFontsDialogStyle ??
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
                                      downloadButtonBackgroundColor:
                                          Colors.blue,
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
                ? _DefaultDrawer(languageCode ?? 'ar', isDark,
                    style: surahStyle ?? SurahAudioStyle())
                : null,
            body: SafeArea(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  withPageView
                      ? PageView.builder(
                          itemCount: 604,
                          controller: quranCtrl.quranPagesController,
                          padEnds: false,
                          // شرح: اختيار نوع الفيزياء حسب إعداد التحسين
                          // Explanation: Choose physics type based on optimization setting
                          physics: const ClampingScrollPhysics(),
                          // شرح: إضافة allowImplicitScrolling لتحسين الأداء
                          // Explanation: Adding allowImplicitScrolling for better performance
                          allowImplicitScrolling: true,
                          // شرح: إضافة clipBehavior لتحسين الرسم
                          // Explanation: Adding clipBehavior for better rendering
                          clipBehavior: Clip.hardEdge,
                          // شرح: تحسين معالجة تغيير الصفحة لتقليل التقطيع
                          // Explanation: Optimized page change handling to reduce stuttering
                          onPageChanged: (pageIndex) {
                            // تشغيل العمليات في الخلفية لتجنب تجميد UI
                            // Run operations in background to avoid UI freeze
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) async {
                              if (onPageChanged != null) {
                                onPageChanged!(pageIndex);
                              } else {
                                quranCtrl.state.overlayEntry?.remove();
                                quranCtrl.state.overlayEntry = null;
                              }
                              quranCtrl.state.currentPageNumber.value =
                                  pageIndex + 1;
                              quranCtrl.saveLastPage(pageIndex + 1);
                            });
                          },
                          pageSnapping: true,
                          itemBuilder: (ctx, index) {
                            // شرح: تحسين أداء itemBuilder لتقليل التقطيع
                            // Explanation: Optimize itemBuilder performance to reduce stuttering
                            return RepaintBoundary(
                              key: ValueKey('quran_page_$index'),
                              child: PageViewBuild(
                                  circularProgressWidget:
                                      circularProgressWidget,
                                  languageCode: languageCode,
                                  juzName: juzName,
                                  sajdaName: sajdaName,
                                  topTitleChild: topTitleChild,
                                  bookmarkList: bookmarkList,
                                  ayahSelectedFontColor: ayahSelectedFontColor,
                                  textColor: textColor,
                                  ayahIconColor: ayahIconColor,
                                  showAyahBookmarkedIcon:
                                      showAyahBookmarkedIcon,
                                  onAyahLongPress: onAyahLongPress,
                                  bookmarksColor: bookmarksColor,
                                  surahInfoStyle: surahInfoStyle,
                                  surahNameStyle: surahNameStyle,
                                  bannerStyle: bannerStyle,
                                  basmalaStyle: basmalaStyle,
                                  onSurahBannerPress: onSurahBannerPress,
                                  surahNumber: surahNumber,
                                  ayahSelectedBackgroundColor:
                                      ayahSelectedBackgroundColor,
                                  onPagePress: onPagePress,
                                  isDark: isDark,
                                  fontsName: fontsName,
                                  ayahBookmarked: ayahBookmarked,
                                  anotherMenuChild: anotherMenuChild,
                                  anotherMenuChildOnTap: anotherMenuChildOnTap,
                                  secondMenuChild: secondMenuChild,
                                  secondMenuChildOnTap: secondMenuChildOnTap,
                                  userContext: parentContext,
                                  pageIndex: index,
                                  quranCtrl: quranCtrl,
                                  isFontsLocal: isFontsLocal!),
                            );
                          },
                        )
                      : PageViewBuild(
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
                          ayahSelectedBackgroundColor:
                              ayahSelectedBackgroundColor,
                          onPagePress: onPagePress,
                          isDark: isDark,
                          fontsName: fontsName,
                          ayahBookmarked: ayahBookmarked,
                          anotherMenuChild: anotherMenuChild,
                          anotherMenuChildOnTap: anotherMenuChildOnTap,
                          secondMenuChild: secondMenuChild,
                          secondMenuChildOnTap: secondMenuChildOnTap,
                          userContext: parentContext,
                          pageIndex: pageIndex,
                          quranCtrl: quranCtrl,
                          isFontsLocal: isFontsLocal!),

                  // السلايدر السفلي - يظهر من الأسفل للأعلى
                  // Bottom slider - appears from bottom to top
                  isShowAudioSlider!
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Obx(() => BottomSlider(
                                isVisible:
                                    QuranCtrl.instance.isShowControl.value,
                                onClose: () {
                                  QuranCtrl.instance.isShowControl.value =
                                      false;
                                  SliderController.instance.hideBottomContent();
                                },
                                style: ayahStyle ?? AyahAudioStyle(),
                                contentChild: SizedBox.shrink(),
                                child: Flexible(
                                  child: AyahsAudioWidget(
                                      style: ayahStyle ?? AyahAudioStyle()),
                                ),
                              )),
                        )
                      : SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
