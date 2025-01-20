import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:quran_library/core/extensions/convert_number_extension.dart';
import 'package:quran_library/core/extensions/extensions.dart';

import '/quran_library.dart';
import '../../core/extensions/fonts_extension.dart';
import '../../core/extensions/string_extensions.dart';
import '../../core/extensions/surah_info_extension.dart';
import '../../data/models/quran_constants.dart';
import '../../data/models/quran_fonts_models/download_fonts_dialog_style.dart';
import '../../data/models/quran_fonts_models/surahs_model.dart';
import '../../data/models/quran_page.dart';
import '../../data/models/styles_models/banner_style.dart';
import '../../data/models/styles_models/basmala_style.dart';
import '../../data/models/styles_models/surah_info_style.dart';
import '../../data/models/styles_models/surah_name_style.dart';
import '../controllers/bookmark/bookmarks_ctrl.dart';
import '../controllers/quran/quran_ctrl.dart';
import '../controllers/quran/quran_getters.dart';
import '../widgets/custom_span.dart';
import '../widgets/fonts_download_dialog.dart';
import '../widgets/quran_fonts_page.dart';

part '../../core/extensions/sajda_extension.dart';
part '../../core/utils/assets_path.dart';
part '../../core/utils/toast_utils.dart';
part '../widgets/all_quran_widget.dart';
part '../widgets/ayah_long_click_dialog.dart';
part '../widgets/bsmallah_widget.dart';
part '../widgets/default_drawer.dart';
part '../widgets/quran_library_search_screen.dart';
part '../widgets/quran_line.dart';
part '../widgets/quran_line_page.dart';
part '../widgets/quran_page_bottom_info.dart';
part '../widgets/quran_text_scale.dart';
part '../widgets/surah_header_widget.dart';

class QuranLibraryScreen extends StatelessWidget {
  const QuranLibraryScreen({
    // this.showBottomWidget = true,
    this.useDefaultAppBar = true,
    // this.bottomWidget,
    this.appBar,
    this.onPageChanged,
    super.key,
    this.basmalaStyle,
    this.bannerStyle,
    this.withPageView = true,
    this.pageIndex,
    this.bookmarksColor,
    this.onAyahLongPress,
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
  });

  // /// متغير لتعطيل أو تمكين الويدجت السفلية الافتراضية [showBottomWidget]
  // ///
  // /// [showBottomWidget] is a bool to disable or enable the default bottom widget
  // final bool showBottomWidget;

  /// متغير لتعطيل أو تمكين شريط التطبيقات الافتراضية [useDefaultAppBar]
  ///
  /// [useDefaultAppBar] is a bool to disable or enable the default app bar widget
  final bool useDefaultAppBar;

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
  final Function(int)? onPageChanged;

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
  final bool? withPageView;

  /// قم بتمرير رقم الصفحة إذا كنت لا تريد عرض القرآن باستخدام PageView [pageIndex]
  ///
  /// [pageIndex] pass the page number if you do not want to display the Quran with PageView
  final int? pageIndex;

  /// تغيير لون الإشارة المرجعية (اختياري) [bookmarksColor]
  ///
  /// [bookmarksColor] Change the bookmark color (optional)
  final Color? bookmarksColor;

  /// عند الضغط لفترة طويلة على أي آية، يمكنك إضافة بعض الميزات، مثل نسخ الآية ومشاركتها وما إلى ذلك [onAyahLongPress]
  ///
  /// [onAyahLongPress] When you long press on any verse, you can add some features, such as copying the verse, sharing it, etc
  final Function? onAyahLongPress;

  /// عند الضغط لفترة طويلة على أي لافتة سورة، يمكنك إضافة بعض التفاصيل حول السورة [onSurahBannerPress]
  ///
  /// [onSurahBannerPress] When you long press on any Surah banner, you can add some details about the surah
  final Function? onSurahBannerPress;

  /// عند الضغط على الصفحة يمكنك إضافة بعض المميزات مثل حذف التظليل عن الآية وغيرها [onPagePress]
  ///
  /// [onPagePress] When you click on the page, you can add some features, such as deleting the shading from the verse and others
  final Function? onPagePress;

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

  @override
  Widget build(BuildContext context) {
    return GetBuilder<QuranCtrl>(
      builder: (quranCtrl) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: backgroundColor ?? const Color(0xfffaf7f3),
          appBar: appBar ??
              (useDefaultAppBar
                  ? AppBar(
                      backgroundColor: backgroundColor,
                      elevation: 0,
                      actions: [
                        FontsDownloadDialog(
                          downloadFontsDialogStyle: downloadFontsDialogStyle ??
                              DownloadFontsDialogStyle(
                                iconWidget: Icon(
                                  quranCtrl.state.isDownloadedV2Fonts.value
                                      ? Icons.settings
                                      : Icons.downloading_outlined,
                                  size: 24,
                                  color: Colors.black,
                                ),
                                title: 'الخطوط',
                                titleColor: Colors.black,
                                notes:
                                    'لجعل مظهر المصحف مشابه لمصحف المدينة يمكنك تحميل خطوط المصحف',
                                notesColor: Colors.black,
                                linearProgressBackgroundColor:
                                    Colors.blue.shade100,
                                linearProgressColor: Colors.blue,
                                downloadButtonBackgroundColor: Colors.blue,
                                downloadButtonTextColor: Colors.white,
                                downloadingText: 'جارِ التحميل',
                                downloadButtonText: 'تحميل',
                                deleteButtonText: 'حذف الخطوط',
                                backgroundColor: const Color(0xFFF7EFE0),
                                defaultFontText: 'الخطوط الأساسية',
                                downloadedFontsText: 'خطوط المصحف المحملة',
                                downloadedNotesTitle: 'ملاحظة:',
                                downloadedNotesBody: 'يرجى تحميل الخطوط أولًا!',
                              ),
                          languageCode: languageCode,
                        )
                      ],
                    )
                  : null),
          drawer: appBar == null && useDefaultAppBar
              ? _DefaultDrawer(languageCode ?? 'ar')
              : null,
          body: SafeArea(
            child: withPageView!
                ? PageView.builder(
                    itemCount: 604,
                    controller: quranCtrl.pageController,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: (page) {
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
                    pageIndex!,
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
    final deviceSize = MediaQuery.of(context).size;
    List<String> newSurahs = [];
    quranCtrl.state.fontsSelected.value
        ? quranCtrl.prepareFonts(pageIndex)
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
          (quranCtrl.state.fontsSelected.value
              ? quranCtrl.state.allAyahs.isEmpty ||
                      quranCtrl.state.surahs.isEmpty ||
                      quranCtrl.state.pages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
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
                          pageIndex: pageIndex,
                          bookmarkList: bookmarkList,
                          textColor: textColor,
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
                          onAyahPress: onPagePress,
                        ),
                      ))
              : quranCtrl.staticPages.isEmpty || quranCtrl.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : QuranLinePage(
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
            ),
          ),
        ),
      ),
    );
  }
}
