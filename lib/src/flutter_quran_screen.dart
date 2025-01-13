import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '/flutter_quran.dart';
import '/src/extensions/fonts_extension.dart';
import '/src/extensions/quran_getters.dart';
import '/src/extensions/surah_info_extension.dart';
import '/src/utils/string_extensions.dart';
import 'controllers/bookmarks_ctrl.dart';
import 'controllers/quran_ctrl.dart';
import 'models/banner_style.dart';
import 'models/basmala_style.dart';
import 'models/quran_constants.dart';
import 'models/quran_fonts_model/download_fonts_dialog_style.dart';
import 'models/quran_fonts_model/surahs_model.dart';
import 'models/quran_page.dart';
import 'models/surah_info_style.dart';
import 'models/surah_name_style.dart';
import 'widgets/fonts_download_dialog.dart';
import 'widgets/quran_fonts_page.dart';

part 'utils/assets_path.dart';
part 'utils/toast_utils.dart';
part 'widgets/ayah_long_click_dialog.dart';
part 'widgets/bsmallah_widget.dart';
part 'widgets/default_drawer.dart';
part 'widgets/quran_line.dart';
part 'widgets/quran_page_bottom_info.dart';
part 'widgets/surah_header_widget.dart';

class FlutterQuranScreen extends StatelessWidget {
  const FlutterQuranScreen({
    this.showBottomWidget = true,
    this.useDefaultAppBar = true,
    this.bottomWidget,
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
    this.bookmarkList,
    this.onSurahBannerLongPress,
    this.onPagePress,
    this.surahNameStyle,
    this.backgroundColor,
    this.surahInfoStyle,
    this.languageCode,
    this.downloadFontsDialogStyle,
  });

  /// متغير لتعطيل أو تمكين القطعة السفلية الافتراضية [showBottomWidget]
  /// [showBottomWidget] is a bool to disable or enable the default bottom widget
  final bool showBottomWidget;

  /// متغير لتعطيل أو تمكين شريط التطبيقات الافتراضية [useDefaultAppBar]
  /// [useDefaultAppBar] is a bool to disable or enable the default app bar widget
  final bool useDefaultAppBar;

  /// إذا قمت بإضافة قطعة هنا فإنه سيحل محل القطعة السفلية الافتراضية [bottomWidget]
  /// [bottomWidget] if if provided it will replace the default bottom widget
  final Widget? bottomWidget;

  /// إذا قمت بإضافة شريط التطبيقات هنا فإنه سيحل محل شريط التطبيقات الافتراضية [appBar]
  /// [appBar] if if provided it will replace the default app bar
  final PreferredSizeWidget? appBar;

  /// إذا تم توفيره فسيتم استدعاؤه عند تغيير صفحة القرآن [onPageChanged]
  /// [onPageChanged] if provided it will be called when a quran page changed
  final Function(int)? onPageChanged;

  /// تغيير نمط البسملة بواسطة هذه الفئة [BasmalaStyle]
  /// [BasmalaStyle] Change the style of Basmala by BasmalaStyle class
  final BasmalaStyle? basmalaStyle;

  /// تغيير نمط الشعار من خلال هذه الفئة [BannerStyle]
  /// [BannerStyle] Change the style of banner by BannerStyle class
  final BannerStyle? bannerStyle;

  /// تغيير نمط اسم السورة بهذه الفئة [SurahNameStyle]
  /// [SurahNameStyle] Change the style of surah name by SurahNameStyle class
  final SurahNameStyle? surahNameStyle;

  /// تغيير نمط معلومات السورة بواسطة هذه الفئة [SurahInfoStyle]
  /// [SurahInfoStyle] Change the style of surah information by SurahInfoStyle class
  final SurahInfoStyle? surahInfoStyle;

  /// تغيير نمط نافذة تحميل الخطوط بواسطة هذه الفئة [DownloadFontsDialogStyle]
  /// [DownloadFontsDialogStyle] Change the style of Download fonts dialog by DownloadFontsDialogStyle class
  final DownloadFontsDialogStyle? downloadFontsDialogStyle;

  /// قم بتمكين هذا المتغير إذا كنت تريد عرض القرآن باستخدام PageView [withPageView]
  /// [withPageView] Enable this variable if you want to display the Quran with PageView
  final bool? withPageView;

  /// قم بتمرير رقم الصفحة إذا كنت لا تريد عرض القرآن باستخدام PageView [pageIndex]
  /// [pageIndex] pass the page number if you do not want to display the Quran with PageView
  final int? pageIndex;

  /// تغيير لون الإشارة المرجعية (اختياري) [bookmarksColor]
  /// [bookmarksColor] Change the bookmark color (optional)
  final Color? bookmarksColor;

  /// عند الضغط لفترة طويلة على أي آية، يمكنك إضافة بعض الميزات، مثل نسخ الآية ومشاركتها وما إلى ذلك [onAyahLongPress]
  /// [onAyahLongPress] When you long press on any verse, you can add some features, such as copying the verse, sharing it, etc
  final Function? onAyahLongPress;

  /// عند الضغط لفترة طويلة على أي لافتة سورة، يمكنك إضافة بعض التفاصيل حول السورة [onSurahBannerLongPress]
  /// [onSurahBannerLongPress] When you long press on any Surah banner, you can add some details about the surah
  final Function? onSurahBannerLongPress;

  /// عند الضغط على الصفحة يمكنك إضافة بعض المميزات مثل حذف التظليل عن الآية وغيرها [onPagePress]
  /// [onPagePress] When you click on the page, you can add some features, such as deleting the shading from the verse and others
  final Function? onPagePress;

  /// يمكنك تمرير لون نص القرآن [textColor]
  /// [textColor] You can pass the color of the Quran text
  final Color? textColor;

  /// يمكنك تمرير رقم السورة [surahNumber]
  /// [surahNumber] You can pass the Surah number
  final int? surahNumber;

  /// يمكنك تمرير لون خلفية الآية المحدد [ayahSelectedBackgroundColor]
  /// [ayahSelectedBackgroundColor] You can pass the color of the Ayah selected background
  final Color? ayahSelectedBackgroundColor;

  /// إذا كنت تريد إضافة الارتفاع لاسم السورة [bookmarkList]
  /// [bookmarkList] if you wanna add the height for the surah name
  final List? bookmarkList;

  /// إذا كنت تريد تغيير لون خلفية صفحة القرآن [backgroundColor]
  /// [backgroundColor] if you wanna change the background color of Quran page
  final Color? backgroundColor;

  /// إذا كنت تريد تمرير كود اللغة الخاصة بالتطبيق لتغيير الأرقام على حسب اللغة،
  /// :رمز اللغة الإفتراضي هو 'ar' [languageCode]
  /// [languageCode] If you want to pass the application's language code to change the numbers according to the language,
  /// the default language code is 'ar'
  final String? languageCode;

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    Orientation currentOrientation = MediaQuery.of(context).orientation;
    return GetBuilder<QuranCtrl>(builder: (quranCtrl) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: backgroundColor ?? Colors.transparent,
          appBar: appBar ??
              (useDefaultAppBar
                  ? AppBar(
                      elevation: 0,
                      actions: [
                        FontsDownloadDialog(
                          downloadFontsDialogStyle: downloadFontsDialogStyle ??
                              DownloadFontsDialogStyle(
                                iconWidget: Icon(
                                  Icons.downloading_outlined,
                                  size: 24,
                                  color: Colors.black,
                                ),
                                title: 'تحميل الخطوط',
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
                              ),
                          languageCode: languageCode,
                        )
                      ],
                    )
                  : null),
          drawer: appBar == null && useDefaultAppBar
              ? const _DefaultDrawer()
              : null,
          body: SafeArea(
            child: withPageView!
                ? PageView.builder(
                    itemCount: 604,
                    controller: quranCtrl.pageController,
                    onPageChanged: (page) {
                      if (onPageChanged != null) onPageChanged!(page);
                      quranCtrl.saveLastPage(page + 1);
                    },
                    pageSnapping: true,
                    itemBuilder: (ctx, index) {
                      return _pageViewBuild(
                        context,
                        index,
                        surahNumber,
                        quranCtrl,
                        deviceSize,
                        currentOrientation,
                        textColor: textColor!,
                        onAyahLongPress: onAyahLongPress,
                        bookmarksColor: bookmarksColor,
                        bookmarkList: bookmarkList,
                        ayahSelectedBackgroundColor:
                            ayahSelectedBackgroundColor,
                        onSurahBannerPress: onSurahBannerLongPress,
                        onAyahPress: onPagePress,
                      );
                    },
                  )
                : _pageViewBuild(
                    context,
                    pageIndex!,
                    surahNumber,
                    quranCtrl,
                    deviceSize,
                    currentOrientation,
                    textColor: textColor!,
                    onAyahLongPress: onAyahLongPress,
                    bookmarksColor: bookmarksColor,
                    bookmarkList: bookmarkList,
                    ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
                    onSurahBannerPress: onSurahBannerLongPress,
                    onAyahPress: onPagePress,
                  ),
          ),
        ),
      );
    });
  }

  Widget _pageViewBuild(BuildContext context, int pageIndex, int? surahNumber,
      QuranCtrl quranCtrl, Size deviceSize, Orientation currentOrientation,
      {Color? bookmarksColor,
      Color? textColor,
      Color? ayahSelectedBackgroundColor,
      List? bookmarkList,
      Function? onAyahLongPress,
      Function? onSurahBannerPress,
      Function? onAyahPress}) {
    List<String> newSurahs = [];
    quranCtrl.state.isDownloadedV2Fonts.value
        ? quranCtrl.prepareFonts(pageIndex)
        : null;
    return GetBuilder<QuranCtrl>(
        init: QuranCtrl.instance,
        builder: (quranCtrl) => quranCtrl.state.isDownloadedV2Fonts.value
            ? GetBuilder<BookmarksCtrl>(
                builder: (bookmarkCtrl) {
                  return QuranFontsPage(
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
                  );
                },
              )
            : quranCtrl.staticPages.isEmpty || quranCtrl.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    height: deviceSize.height * 0.8,
                    padding: const EdgeInsets.all(16.0),
                    child: pageIndex == 0 || pageIndex == 1

                        /// This is for first 2 pages of Quran: Al-Fatihah and Al-Baqarah
                        ? Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SurahHeaderWidget(
                                    surahNumber ??
                                        quranCtrl.staticPages[pageIndex]
                                            .ayahs[0].surahNumber,
                                    bannerStyle: bannerStyle ??
                                        BannerStyle(
                                          isImage: false,
                                          bannerSvgPath:
                                              AssetsPath().surahSvgBanner,
                                          bannerSvgHeight: 40.0,
                                          bannerSvgWidth: 150.0,
                                          bannerImagePath: '',
                                          bannerImageHeight: 50,
                                          bannerImageWidth: double.infinity,
                                        ),
                                    surahNameStyle: surahNameStyle ??
                                        SurahNameStyle(
                                          surahNameWidth: 70,
                                          surahNameHeight: 37,
                                          surahNameColor: Colors.black,
                                        ),
                                    surahInfoStyle: surahInfoStyle ??
                                        SurahInfoStyle(
                                          ayahCount: 'عدد الآيات',
                                          secondTabText: 'عن السورة',
                                          firstTabText: 'أسماء السورة',
                                          backgroundColor: Colors.white,
                                          closeIconColor: Colors.black,
                                          indicatorColor:
                                              Colors.amber.withValues(alpha: 2),
                                          primaryColor:
                                              Colors.amber.withValues(alpha: 2),
                                          surahNameColor: Colors.black,
                                          surahNumberColor: Colors.black,
                                          textColor: Colors.black,
                                          titleColor: Colors.black,
                                        ),
                                    onSurahBannerPress: onSurahBannerPress,
                                  ),
                                  if (pageIndex == 1)
                                    BasmallahWidget(
                                      surahNumber: quranCtrl
                                          .staticPages[pageIndex]
                                          .ayahs[0]
                                          .surahNumber,
                                      basmalaStyle: basmalaStyle ??
                                          BasmalaStyle(
                                            basmalaColor: Colors.black,
                                            basmalaWidth: 150.0,
                                            basmalaHeight: 30.0,
                                          ),
                                    ),
                                  ...quranCtrl.staticPages[pageIndex].lines
                                      .map((line) {
                                    return GetBuilder<BookmarksCtrl>(
                                      builder: (bookmarkCtrl) {
                                        return Column(
                                          children: [
                                            SizedBox(
                                                width: deviceSize.width - 32,
                                                child: QuranLine(
                                                  line,
                                                  bookmarkCtrl.bookmarksAyahs,
                                                  bookmarkCtrl.bookmarks,
                                                  boxFit: BoxFit.scaleDown,
                                                  onAyahLongPress:
                                                      onAyahLongPress,
                                                  bookmarksColor:
                                                      bookmarksColor,
                                                  textColor: textColor,
                                                  bookmarkList: bookmarkList,
                                                  pageIndex: pageIndex,
                                                  ayahSelectedBackgroundColor:
                                                      ayahSelectedBackgroundColor,
                                                  onAyahPress: onAyahPress,
                                                )),
                                          ],
                                        );
                                      },
                                    );
                                  }),
                                ],
                              ),
                            ),
                          )

                        /// Other Quran pages
                        : LayoutBuilder(builder: (context, constraints) {
                            return ListView(
                                physics:
                                    currentOrientation == Orientation.portrait
                                        ? const NeverScrollableScrollPhysics()
                                        : null,
                                children: [
                                  ...quranCtrl.staticPages[pageIndex].lines
                                      .map((line) {
                                    bool firstAyah = false;
                                    if (line.ayahs[0].ayahNumber == 1 &&
                                        !newSurahs.contains(
                                            line.ayahs[0].surahNameAr)) {
                                      newSurahs.add(line.ayahs[0].surahNameAr);
                                      firstAyah = true;
                                    }
                                    return GetBuilder<BookmarksCtrl>(
                                      builder: (bookmarkCtrl) {
                                        return Column(
                                          children: [
                                            if (firstAyah)
                                              SurahHeaderWidget(
                                                surahNumber ??
                                                    line.ayahs[0].surahNumber,
                                                bannerStyle: bannerStyle ??
                                                    BannerStyle(
                                                      isImage: false,
                                                      bannerSvgPath:
                                                          AssetsPath()
                                                              .surahSvgBanner,
                                                      bannerSvgHeight: 40.0,
                                                      bannerSvgWidth: 150.0,
                                                      bannerImagePath: '',
                                                      bannerImageHeight: 50,
                                                      bannerImageWidth:
                                                          double.infinity,
                                                    ),
                                                surahNameStyle:
                                                    surahNameStyle ??
                                                        SurahNameStyle(
                                                          surahNameWidth: 70,
                                                          surahNameHeight: 37,
                                                          surahNameColor:
                                                              Colors.black,
                                                        ),
                                                surahInfoStyle:
                                                    surahInfoStyle ??
                                                        SurahInfoStyle(
                                                          ayahCount:
                                                              'عدد الآيات',
                                                          secondTabText:
                                                              'عن السورة',
                                                          firstTabText:
                                                              'أسماء السورة',
                                                          backgroundColor:
                                                              Colors.white,
                                                          closeIconColor:
                                                              Colors.black,
                                                          indicatorColor: Colors
                                                              .amber
                                                              .withValues(
                                                                  alpha: 2),
                                                          primaryColor: Colors
                                                              .amber
                                                              .withValues(
                                                                  alpha: 2),
                                                          surahNameColor:
                                                              Colors.black,
                                                          surahNumberColor:
                                                              Colors.black,
                                                          textColor:
                                                              Colors.black,
                                                          titleColor:
                                                              Colors.black,
                                                        ),
                                                onSurahBannerPress:
                                                    onSurahBannerPress,
                                              ),
                                            if (firstAyah &&
                                                (line.ayahs[0].surahNumber !=
                                                    9))
                                              BasmallahWidget(
                                                surahNumber: quranCtrl
                                                    .staticPages[pageIndex]
                                                    .ayahs[0]
                                                    .surahNumber,
                                                basmalaStyle: basmalaStyle ??
                                                    BasmalaStyle(
                                                      basmalaColor:
                                                          Colors.black,
                                                      basmalaWidth: 150.0,
                                                      basmalaHeight: 30.0,
                                                    ),
                                              ),
                                            SizedBox(
                                              width: deviceSize.width - 30,
                                              height: ((currentOrientation ==
                                                              Orientation
                                                                  .portrait
                                                          ? constraints
                                                              .maxHeight
                                                          : Get.width) -
                                                      (quranCtrl
                                                              .staticPages[
                                                                  pageIndex]
                                                              .numberOfNewSurahs *
                                                          (line.ayahs[0]
                                                                      .surahNumber !=
                                                                  9
                                                              ? 110
                                                              : 80))) *
                                                  0.95 /
                                                  quranCtrl
                                                      .staticPages[pageIndex]
                                                      .lines
                                                      .length,
                                              child: QuranLine(
                                                line,
                                                bookmarkCtrl.bookmarksAyahs,
                                                bookmarkCtrl.bookmarks,
                                                boxFit: line.ayahs.last.centered
                                                    ? BoxFit.scaleDown
                                                    : BoxFit.fill,
                                                onAyahLongPress:
                                                    onAyahLongPress,
                                                bookmarksColor: bookmarksColor,
                                                textColor: textColor,
                                                bookmarkList: bookmarkList,
                                                pageIndex: pageIndex,
                                                ayahSelectedBackgroundColor:
                                                    ayahSelectedBackgroundColor,
                                                onAyahPress: onAyahPress,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }),
                                ]);
                          }),
                  ));
  }
}

class FlutterQuranSearchScreen extends StatelessWidget {
  const FlutterQuranSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بحث'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                GetBuilder<QuranCtrl>(
                    builder: (quranCtrl) => TextField(
                          onChanged: (txt) {
                            final searchResult = FlutterQuran().search(txt);
                            quranCtrl.ayahsList.value = [...searchResult];
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            hintText: 'بحث',
                          ),
                        )),
                Expanded(
                  child: GetX<QuranCtrl>(
                    builder: (quranCtrl) => ListView(
                      children: quranCtrl.ayahsList
                          .map((ayah) => Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      ayah.ayah.replaceAll('\n', ' '),
                                    ),
                                    subtitle: Text(ayah.surahNameAr),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      FlutterQuran().jumpToAyah(ayah);
                                    },
                                  ),
                                  const Divider(
                                    color: Colors.grey,
                                    thickness: 1,
                                  ),
                                ],
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
