## Quran Library - مكتبة القرآن
<p align="center">
<img src="https://raw.githubusercontent.com/alheekmahlib/thegarlanded/refs/heads/master/Photos/quran_library.svg" width="150"/>
</p>

### This package is a continuation of [flutter_quran](https://pub.dev/packages/flutter_quran) by [Hesham Erfan](https://www.linkedin.com/in/hesham-erfan-876b83105/) with many new features.

<p align="center">
<img src="https://github.com/alheekmahlib/thegarlanded/blob/master/Photos/quran_package_banner.png?raw=true" width="500"/>
</p>

### :ملاحظة مهمة قبل البدء بالإستخدام: يرجى جعل:
### Important note before starting to use: Please make:
```dart
  useMaterial3: false,
```
### لكي لا تسبب أي مشاكل في التشكيل 
### In order not to cause any formation problems

#

## Table of Contents - جدول المحتويات

- [Getting started - بدء الاستخدام](#getting-started---بدء-الاستخدام)
- [Usage Example - مثال الاستخدام](#usage-example---مثال-الاستخدام)
  - [Basic Quran Screen](#basic-quran-screen)
  - [Individual Surah Display - عرض السورة المنفصلة](#individual-surah-display---عرض-السورة-المنفصلة)
- [Utils - الأدوات](#utils---الأدوات)
  - [الحصول على جميع أجزاء القرآن والأحزاب والسور](#الحصول-على-جميع-أجزاء-القرآن-والأحزاب-والسور)
  - [للتنقل بين الصفحات أو السور أو الأجزاء](#للتنقل-بين-الصفحات-أو-السور-أو-الأجزاء-يمكنك-استخدام)
  - [إضافة الإشارات المرجعية وإعدادها وإزالتها](#إضافة-الإشارات-المرجعية-وإعدادها-وإزالتها-والحصول-عليها-والانتقال-إليها)
  - [للبحث عن أي آية](#للبحث-عن-أي-آية)
- [Fonts Download - تحميل الخطوط](#لتحميل-خطوط-المصحف-لديك-خيارين)
- [Tafsir - التفسير](#tafsir---التفسير)
- [Audio Playback - التشغيل الصوتي](#audio-playback---التشغيل-الصوتي)

#

## Getting started - بدء الإستخدام

### Permissions - الصلاحيات

#### Android - أندرويد
The required permissions for audio playback (`WAKE_LOCK`, `FOREGROUND_SERVICE`, and `FOREGROUND_SERVICE_MEDIA_PLAYBACK`) are automatically added by the package. You don't need to manually edit your AndroidManifest.xml.

الصلاحيات المطلوبة للتشغيل الصوتي (`WAKE_LOCK`, `FOREGROUND_SERVICE`, و `FOREGROUND_SERVICE_MEDIA_PLAYBACK`) يتم إضافتها تلقائياً بواسطة المكتبة. لا تحتاج لتعديل ملف AndroidManifest.xml يدوياً.

#### iOS - آي أو إس
For background audio playback, you must add the following to your app's `Info.plist`:

للتشغيل الصوتي في الخلفية، يجب إضافة التالي إلى ملف `Info.plist` الخاص بتطبيقك:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

This allows audio playback to continue when the app is in the background.

هذا يسمح باستمرار التشغيل الصوتي عندما يكون التطبيق في الخلفية.

In the `pubspec.yaml` of your flutter project, add the following dependency:

```yaml
dependencies:
  ...
  quran_library: ^2.0.9+7
```


Import it:

```dart
import 'package:quran_library/quran_library.dart';
```

Initialize it - تهيئة المكتبة:

```dart
QuranLibrary.init();
```

## Usage Example - مثال الإستخدام

### Basic Quran Screen

```dart
/// You can just add it to your code like this:
/// يمكنك فقط إضافته إلى الكود الخاص بك هكذا:
class MyQuranPage extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return QuranLibraryScreen(
      parentContext: context, // مطلوب - Required
    );
  }
}
```


#### or give it some options:
#### أو يمكنك تمرير بعض الخيارات:

```dart
QuranLibraryScreen(
    /// **مطلوب** - تمرير السياق من الويدجت الأب [parentContext]
    /// **Required** - Pass context from parent widget [parentContext]
    parentContext: context,
    
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

### Individual Surah Display - عرض السورة المنفصلة

```dart
/// For displaying a single surah with custom pagination
/// لعرض سورة واحدة مع تقسيم مخصص للصفحات
SurahDisplayScreen(
    /// رقم السورة المراد عرضها [surahNumber]
    /// [surahNumber] The surah number to display
    surahNumber: 1, // For Al-Fatihah - للفاتحة
    /// إذا تم توفيره فسيتم استدعاؤه عند تغيير صفحة السورة [onPageChanged]
    /// [onPageChanged] if provided it will be called when a surah page changed
    onPageChanged: (int pageIndex) => print("Surah page changed: $pageIndex"),
    /// تمكين أو تعطيل النمط المظلم [isDark]
    /// [isDark] enable or disable dark mode
    isDark: false,
    /// تغيير نمط البسملة [basmalaStyle]
    /// [basmalaStyle] Change the style of Basmala
    basmalaStyle: BasmalaStyle(
        basmalaColor: Colors.black,
        basmalaWidth: 160.0,
        basmalaHeight: 30.0,
    ),
    /// تغيير نمط الشعار [bannerStyle]
    /// [bannerStyle] Change the style of banner
    bannerStyle: BannerStyle(
        isImage: false,
        bannerSvgHeight: 40.0,
        bannerSvgWidth: 150.0,
    ),
    /// and more options...
),
```


## Utils - الأدوات

### توفر الحزمة الكثير من الأدوات مثل:
### The package provides a lot of utils like:

* ### الحصول على جميع أجزاء القرآن والأحزاب والسور
* ### Getting all Quran's Jozzs, Hizbs, and Surahs

```dart
final jozzs = QuranLibrary.allJoz;
final hizbs = QuranLibrary.allHizb;
final surahs = QuranLibrary.getAllSurahs();
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

## Fonts Download - تحميل الخطوط

## لتحميل خطوط المصحف لديك خيارين:
* ### أما استخدام نافذة الحوار الافتراضية ويمكنك تعديل الخصائص التي فيها.
* ### أو يمكنك عمل تصميم خاص بك مع استخدام جميع الدوال الخاصة بتحميل الخطوط.
## To download Quran fonts, you have two options:
* ### As for using the default dialog, you can modify the style in it.
* ### Or you can create your own design using all the functions for downloading fonts.

## تحتاج MACOS إلى طلب استحقاق محدد للوصول إلى الشبكة.
### للقيام بذلك: افتح MacOS/Runner/DebugProfile.Entitlements وأضف زوج القيمة والمفتاح التالي.
## macOS needs you to request a specific entitlement in order to access the network. 
### To do that: open macos/Runner/DebugProfile.entitlements and add the following key-value pair.

```xml
<key>com.apple.security.network.client</key>
<true/>
```

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


* ### Usage Example - مثال الإستخدام

```dart
// get current list


final all = TafsirController.instance.items; // includes defaults + customs

// add a custom sql file (File is from file picker)

final added = await TafsirController.instance.addCustomFromFile(

  sourceFile: pickedFile,

  displayName: 'My Custom Tafsir',

  bookName: 'My Book',

  type: TafsirFileType.sqlite,

);
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

## Audio Playback - التشغيل الصوتي

### يوفر هذا القسم إمكانيات شاملة لتشغيل القرآن الكريم صوتياً مع دعم التشغيل في الخلفية وإدارة متقدمة للملفات الصوتية.
### This section provides comprehensive capabilities for audio playback of the Holy Quran with background playback support and advanced audio file management.

* ### Verse Audio Playback - تشغيل الآيات صوتياً

```dart
/// تشغيل آية أو مجموعة من الآيات بدءًا من آية محددة
/// Play a verse or group of verses starting from a specific verse
await QuranLibrary().playAyah(
  context: context,
  currentAyahUniqueNumber: 1, // رقم الآية الفريد
  playSingleAyah: true, // true لآية واحدة، false للاستمرار
);

/// الانتقال للآية التالية وتشغيلها
/// Move to next verse and play it
await QuranLibrary().seekNextAyah(
  context: context,
  currentAyahUniqueNumber: 5,
);

/// الانتقال للآية السابقة وتشغيلها
/// Move to previous verse and play it
await QuranLibrary().seekPreviousAyah(
  context: context,
  currentAyahUniqueNumber: 10,
);
```

* ### Surah Audio Playback - تشغيل السور صوتياً

```dart
/// تشغيل سورة كاملة من البداية حتى النهاية
/// Play a complete surah from beginning to end
await QuranLibrary().playSurah(surahNumber: 1); // الفاتحة
await QuranLibrary().playSurah(surahNumber: 2); // البقرة

/// الانتقال للسورة التالية وتشغيلها
/// Move to next surah and play it
await QuranLibrary().seekToNextSurah();

/// الانتقال للسورة السابقة وتشغيلها
/// Move to previous surah and play it
await QuranLibrary().seekToPreviousSurah();
```

* ### Download Management - إدارة التحميل

```dart
/// بدء تحميل سورة للتشغيل دون اتصال
/// Start downloading a surah for offline playback
await QuranLibrary().startDownloadSurah(surahNumber: 1);

/// إلغاء التحميل الجاري
/// Cancel ongoing download
QuranLibrary().cancelDownloadSurah();
```

* ### Position Control & Resume - التحكم في الموضع والاستئناف

```dart
/// الحصول على رقم السورة الحالية/الأخيرة
/// Get current/last surah number
int currentSurah = QuranLibrary().currentAndLastSurahNumber;

/// الحصول على الموضع الأخير كنص منسق (مثل "05:23")
/// Get last position as formatted text (like "05:23")
String lastTimeText = QuranLibrary().formatLastPositionToTime;

/// الحصول على الموضع الأخير كمدة زمنية للعمليات البرمجية
/// Get last position as Duration object for programming operations
Duration lastDuration = QuranLibrary().formatLastPositionToDuration;

/// تشغيل من الموضع الأخير الذي توقف عنده المستخدم
/// Play from the last position where user stopped
await QuranLibrary().playLastPosition();
```

* ### Complete Audio Example - مثال شامل للتشغيل الصوتي

```dart
class AudioControlExample extends StatefulWidget {
  @override
  _AudioControlExampleState createState() => _AudioControlExampleState();
}

class _AudioControlExampleState extends State<AudioControlExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مشغل القرآن الصوتي')),
      body: Column(
        children: [
          // عرض السورة الحالية
          Text('السورة الحالية: ${QuranLibrary().currentAndLastSurahNumber}'),
          
          // عرض الموضع الأخير
          Text('الموضع الأخير: ${QuranLibrary().formatLastPositionToTime}'),
          
          // أزرار التحكم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // تشغيل من الموضع الأخير
              ElevatedButton(
                onPressed: () => QuranLibrary().playLastPosition(),
                child: Text('متابعة من حيث توقفت'),
              ),
              
              // تشغيل سورة الفاتحة
              ElevatedButton(
                onPressed: () => QuranLibrary().playSurah(surahNumber: 1),
                child: Text('سورة الفاتحة'),
              ),
            ],
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // السورة السابقة
              IconButton(
                onPressed: () => QuranLibrary().seekToPreviousSurah(),
                icon: Icon(Icons.skip_previous),
              ),
              
              // الآية السابقة
              IconButton(
                onPressed: () => QuranLibrary().seekPreviousAyah(
                  context: context,
                  currentAyahUniqueNumber: 10,
                ),
                icon: Icon(Icons.fast_rewind),
              ),
              
              // الآية التالية
              IconButton(
                onPressed: () => QuranLibrary().seekNextAyah(
                  context: context,
                  currentAyahUniqueNumber: 5,
                ),
                icon: Icon(Icons.fast_forward),
              ),
              
              // السورة التالية
              IconButton(
                onPressed: () => QuranLibrary().seekToNextSurah(),
                icon: Icon(Icons.skip_next),
              ),
            ],
          ),
          
          // أزرار التحميل
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => QuranLibrary().startDownloadSurah(surahNumber: 2),
                child: Text('تحميل سورة البقرة'),
              ),
              
              ElevatedButton(
                onPressed: () => QuranLibrary().cancelDownloadSurah(),
                child: Text('إلغاء التحميل'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Audio Features Summary - ملخص الميزات الصوتية:
- ✅ **Verse Playback** - تشغيل الآيات المنفردة أو المتسلسلة
- ✅ **Complete Surah Playback** - تشغيل السور كاملة
- ✅ **Navigation Controls** - أدوات التنقل بين الآيات والسور
- ✅ **Offline Download** - تحميل للتشغيل دون اتصال
- ✅ **Resume Functionality** - استئناف التشغيل من آخر موضع
- ✅ **Background Playback** - التشغيل في الخلفية
- ✅ **Position Tracking** - تتبع موضع التشغيل
- ✅ **Download Management** - إدارة شاملة للتحميل والإلغاء

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
