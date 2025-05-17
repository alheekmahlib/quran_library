## Quran Library - مكتبة القرآن
<p align="center">
<img src="https://raw.githubusercontent.com/alheekmahlib/thegarlanded/refs/heads/master/Photos/quran_library.svg" width="150"/>
</p>

### This package is a continuation of [flutter_quran](https://pub.dev/packages/flutter_quran) by [Hesham Erfan](https://www.linkedin.com/in/hesham-erfan-876b83105/) with many new features.

<p align="center">
<img src="https://github.com/alheekmahlib/thegarlanded/blob/master/Photos/quran_package_banner.png?raw=true" width="500"/>
</p>

### :ملاحظة مهمة قبل البدء بالإستخدام: يرجى جعل 
```dart
  useMaterial3: false,
```
### لكي لا تسبب أي مشاكل في التشكيل 
### Important note before starting to use: Please make:
```dart
  useMaterial3: false,
```
### In order not to cause any formation problems
#

## Getting started - بدء الإستخدام

In the `pubspec.yaml` of your flutter project, add the following dependency:

```yaml
dependencies:
  ...
  quran_library: ^1.0.1
```


Import it:

```dart
import 'package:quran_library/quran_library.dart';
```

Initialize it - تهيئة المكتبة:

```dart
QuranLibrary().init();
```

## Usage Example - مثال الإستخدام

### Basic Quran Screen

```dart
/// You can just add it to your code like this:
/// يمكنك فقط إضافته إلى الكود الخاص بك هكذا:
Scaffold(body: QuranLibraryScreen());
```


#### or give it some options:
#### أو يمكنك تمرير بعض الخيارات:

```dart
QuranLibraryScreen(
    /// إذا قمت بإضافة شريط التطبيقات هنا فإنه سيحل محل شريط التطبيقات الافتراضية [appBar]
    /// [appBar] if if provided it will replace the default app bar
    appBar: ...,
    /// متغير لتعطيل أو تمكين شريط التطبيقات الافتراضية [useDefaultAppBar]
    /// [useDefaultAppBar] is a bool to disable or enable the default app bar widget
    useDefaultAppBar: // true or false,
    /// إذا تم توفيره فسيتم استدعاؤه عند تغيير صفحة القرآن [onPageChanged]
    /// [onPageChanged] if provided it will be called when a quran page changed
    onPageChanged: (int pageIndex) => print("Page changed: $pageIndex"),
    /// تغيير نمط البسملة بواسطة هذه الفئة [BasmalaStyle]
    /// [BasmalaStyle] Change the style of Basmala by BasmalaStyle class
    basmalaStyle: // BasmalaStyle(),
    /// تغيير نمط الشعار من خلال هذه الفئة [BannerStyle]
    /// [BannerStyle] Change the style of banner by BannerStyle class
    bannerStyle: // BannerStyle(),
    /// تغيير نمط اسم السورة بهذه الفئة [SurahNameStyle]
    /// [SurahNameStyle] Change the style of surah name by SurahNameStyle class
    surahNameStyle: // SurahNameStyle(),
    /// تغيير نمط معلومات السورة بواسطة هذه الفئة [SurahInfoStyle]
    /// [SurahInfoStyle] Change the style of surah information by SurahInfoStyle class
    surahInfoStyle: // SurahInfoStyle(),
    /// تغيير نمط نافذة تحميل الخطوط بواسطة هذه الفئة [DownloadFontsDialogStyle]
    /// [DownloadFontsDialogStyle] Change the style of Download fonts dialog by DownloadFontsDialogStyle class
    downloadFontsDialogStyle: // DownloadFontsDialogStyle(),
    
    /// and more ................
),
```


### توفر الحزمة الكثير من الأدوات مثل:
### The package provides a lot of utils like:

* ### الحصول على جميع أجزاء القرآن والأحزاب والسور
* ### Getting all Quran's Jozzs, Hizbs, and Surahs

```dart
final jozzs = QuranLibrary().allJoz;
final hizbs = QuranLibrary().allHizb;
final surahs = QuranLibrary().getAllSurahs();
final ayahsOnPage = QuranLibrary().getAyahsByPage();

/// [getSurahInfo] تتيح لك الحصول على سورة مع جميع بياناتها عند تمرير رقم السورة لها.
///
/// [getSurahInfo] let's you get a Surah with all its data when you pass Surah number
final surah = QuranLibrary().getSurahInfo(1);
```

* ### للتنقل بين الصفحات أو السور أو الأجزاء يمكنك استخدام:
* ### to jump between pages, Surahs or Hizbs you can use:
```dart
/// [navigateToAyah] يتيح لك التنقل إلى أي آية.
/// من الأفضل استدعاء هذه الطريقة أثناء عرض شاشة القرآن،
/// وإذا تم استدعاؤها ولم تكن شاشة القرآن معروضة،
/// فسيتم بدء العرض من صفحة هذه الآية عند فتح شاشة القرآن في المرة التالية.
///
/// [jumpToAyah] let's you navigate to any ayah..
/// It's better to call this method while Quran screen is displayed
/// and if it's called and the Quran screen is not displayed, the next time you
/// open quran screen it will start from this ayah's page
QuranLibrary().jumpToAyah(AyahModel ayah);
/// أو يمكنك استخدام:
/// or you can use:
/// jumpToPage, jumpToJoz, jumpToHizb, jumpToBookmark and jumpToSurah.
```

<img src="https://github.com/alheekmahlib/thegarlanded/blob/master/Photos/Quran_package_jumpTo.png?raw=true" width="320"/>

* ### إضافة الإشارات المرجعية وإعدادها وإزالتها والحصول عليها والانتقال إليها:
* ### Adding, setting, removing, getting and navigating to bookmarks:

```dart
// In init function
QuranLibrary().init(userBookmarks: [Bookmark(id: 0, colorCode: Colors.red.value, name: "Red Bookmark")]);
final usedBookmarks = QuranLibrary().getUsedBookmarks();
QuranLibrary().setBookmark(surahName: 'الفاتحة', ayahNumber: 5, ayahId: 5, page: 1, bookmarkId: 0);
QuranLibrary().removeBookmark(bookmarkId: 0);
QuranLibrary().jumpToBookmark(BookmarkModel bookmark);
```

<img src="https://github.com/alheekmahlib/thegarlanded/blob/master/Photos/Quran_package_bookmark.png?raw=true" width="320"/> <img src="https://github.com/alheekmahlib/thegarlanded/blob/master/Photos/Quran_package_bookmark2.png?raw=true" width="320"/>

* ### للبحث عن أي آية
* ### searching for any Ayah
```dart
TextField(
  onChanged: (txt) {
    final _ayahs = QuranLibrary().search(txt);
      setState(() {
        ayahs = [..._ayahs];
      });
  },
  decoration: InputDecoration(
    border:  OutlineInputBorder(borderSide: BorderSide(color: Colors.black),),
    hintText: 'بحث',
  ),
),
```
<img src="https://github.com/alheekmahlib/thegarlanded/blob/master/Photos/Quran_package_search.png?raw=true" width="320"/>

## لتحميل خطوط المصحف لديك خيارين:
* ### أما استخدام نافذة الحوار الافتراضية ويمكنك تعديل الخصائص التي فيها.
* ### أو يمكنك عمل تصميم خاص بك مع استخدام جميع الدوال الخاصة بتحميل الخطوط.
## To download Quran fonts, you have two options:
* ### As for using the default dialog, you can modify the style in it.
* ### Or you can create your own design using all the functions for downloading fonts.
```dart
///
/// to get the fonts download dialog just call [getFontsDownloadDialog]
///
/// and pass the language code to translate the number if you want,
/// the default language code is 'ar' [languageCode]
/// and style [DownloadFontsDialogStyle] is optional.
/// للحصول على نافذة حوار خاصة بتحميل الخطوط، قم فقط باستدعاء: [getFontsDownloadDialog].
///
/// قم بتمرير رمز اللغة ليتم عرض الأرقام على حسب اللغة،
/// رمز اللغة الإفتراضي هو: 'ar' [languageCode].
/// كما أن التمرير الاختياري لنمط [DownloadFontsDialogStyle] ممكن.
QuranLibrary().getFontsDownloadDialog(downloadFontsDialogStyle, languageCode);

/// للحصول على الويدجت الخاصة بتنزيل الخطوط فقط قم بإستدعاء [getFontsDownloadWidget]
///
/// to get the fonts download widget just call [getFontsDownloadWidget]
Widget getFontsDownloadWidget(context, {downloadFontsDialogStyle, languageCode});

/// للحصول على طريقة تنزيل الخطوط فقط قم بإستدعاء [fontsDownloadMethod]
///
/// to get the fonts download method just call [fontsDownloadMethod]
QuranLibrary().fontsDownloadMethod;

/// للحصول على طريقة تنزيل الخطوط فقط قم بإستدعاء [getFontsPrepareMethod]
/// مطلوب تمرير رقم الصفحة [pageIndex]
///
/// to prepare the fonts was downloaded before just call [getFontsPrepareMethod]
/// required to pass [pageIndex]
QuranLibrary().getFontsPrepareMethod(pageIndex);

/// لحذف الخطوط فقط قم بإستدعاء [deleteFontsMethod]
///
/// to delete the fonts just call [deleteFontsMethod]
QuranLibrary().deleteFontsMethod;

/// للحصول على تقدم تنزيل الخطوط، ما عليك سوى إستدعاء [fontsDownloadProgress]
///
/// to get fonts download progress just call [fontsDownloadProgress]
QuranLibrary().fontsDownloadProgress;

/// لمعرفة ما إذا كانت الخطوط محملة او لا، ما عليك سوى إستدعاء [isFontsDownloaded]
///
/// To find out whether fonts are downloaded or not, just call [isFontsDownloaded]
QuranLibrary().isFontsDownloaded;
```

<img src="https://github.com/alheekmahlib/thegarlanded/blob/master/Photos/Quran_package_fontes.png?raw=true" width="320"/>

## Tafsir - التفسير

### :ملاحظة مهمة قبل البدء بالإستخدام التفسير: يرجى إضافة هذه المكتبة إلى ملف pubspec.yaml الخاص بك للاندرويد فقط:
# Important note before starting to use: Please add this library to your pubspec.yaml file only for Android:
```yaml
 dependencies:
 ...
  drift_flutter: ^0.2.4
 ...
```
# لكي لا تسبب أي مشاكل عند عرض التفسير 
# to avoid any problems when showing the tafsir


* ### Initialize tafsir - تهيئة التفسير:

```dart
QuranLibrary().initTafsir();
```

* ### Usage Example - مثال الإستخدام

```dart
/// Show a popup menu to change the tafsir style.
/// إظهار قائمة منبثقة لتغيير نوع التفسير.
QuranLibrary().changeTafsirPopupMenu(TafsirStyle tafsirStyle, {int? pageNumber});

/// إغلاق قاعدة البيانات وإعادة تهيئتها (عادة عند تغيير التفسير).
/// Close and re-initialize the database (usually when changing the tafsir).
QuranLibrary().closeAndInitializeDatabase({int? pageNumber});

/// جلب التفسير الخاص بصفحة معينة من خلال رقم الصفحة.
/// Fetch tafsir for a specific page by its page number.
QuranLibrary().fetchTafsir({required int pageNumber});

/// التحقق إذا كان التفسير تم تحميله مسبقاً.
/// Check if the tafsir is already downloaded.
QuranLibrary().getTafsirDownloaded(int index);

/// الحصول على قائمة أسماء التفاسير والترجمات.
/// Get the list of tafsir and translation names.
QuranLibrary().tafsirAndTraslationCollection;

/// تغيير التفسير المختار عند الضغط على زر التبديل.
/// Change the selected tafsir when the switch button is pressed.
QuranLibrary().changeTafsirSwitch(int index, {int? pageNumber});

/// الحصول على قائمة بيانات التفاسير المتوفرة.
/// Get the list of available tafsir data.
QuranLibrary().tafsirList;

/// الحصول على قائمة الترجمات المتوفرة.
/// Get the list of available translations.
QuranLibrary().translationList;

/// جلب الترجمات من المصدر.
/// Fetch translations from the source.
QuranLibrary().fetchTranslation();

/// تحميل التفسير المحدد حسب الفهرس.
/// Download the tafsir by the given index.
QuranLibrary().tafsirDownload(int i);
```

* ### كما يمكنك إستخدام الخط الإفتراضي للمصحف أو خط النسخ
```dart
/// [hafsStyle] هو النمط الافتراضي للقرآن، مما يضمن عرض جميع الأحرف الخاصة بشكل صحيح.
///
/// [hafsStyle] is the default style for Quran so all special characters will be rendered correctly
QuranLibrary().hafsStyle;

/// [naskhStyle] هو النمط الافتراضي للنصوص الآخرى.
///
/// [naskhStyle] is the default style for other text.
QuranLibrary().naskhStyle;
```


## لا تنسونا من صالح الدعاء 