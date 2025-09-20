## Quran Library
<p align="center">
<img src="https://raw.githubusercontent.com/alheekmahlib/thegarlanded/refs/heads/master/Photos/quran_library.svg" width="150"/>
</p>

<p align="center"><strong>Choose your language for the documentation:</strong></p>

<p align="center">
  <a href="https://alheekmahlib.github.io/quran_library_web/#/ar" style="display: inline-block; padding: 6px 24px; margin: 8px; background: linear-gradient(135deg, #FCFBF8, #E0CCB0); color: black; text-decoration: none; border-radius: 8px; box-shadow: 0 4px 15px rgba(238, 186, 32, 0.11); font-weight: bold; font-size: 14px; transition: all 0.3s ease; text-transform: uppercase;">العربية</a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/en" style="display: inline-block; padding: 6px 24px; margin: 8px; background: linear-gradient(135deg, #FCFBF8, #E0CCB0); color: black; text-decoration: none; border-radius: 8px; box-shadow: 0 4px 15px rgba(238, 186, 32, 0.11); font-weight: bold; font-size: 14px; transition: all 0.3s ease; text-transform: uppercase;">English</a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/bn" style="display: inline-block; padding: 6px 24px; margin: 8px; background: linear-gradient(135deg, #FCFBF8, #E0CCB0); color: black; text-decoration: none; border-radius: 8px; box-shadow: 0 4px 15px rgba(238, 186, 32, 0.11); font-weight: bold; font-size: 14px; transition: all 0.3s ease; text-transform: uppercase;">বাংলা</a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/id" style="display: inline-block; padding: 6px 24px; margin: 8px; background: linear-gradient(135deg, #FCFBF8, #E0CCB0); color: black; text-decoration: none; border-radius: 8px; box-shadow: 0 4px 15px rgba(238, 186, 32, 0.11); font-weight: bold; font-size: 14px; transition: all 0.3s ease; text-transform: uppercase;">Bahasa Indonesia</a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/ur" style="display: inline-block; padding: 6px 24px; margin: 8px; background: linear-gradient(135deg, #FCFBF8, #E0CCB0); color: black; text-decoration: none; border-radius: 8px; box-shadow: 0 4px 15px rgba(238, 186, 32, 0.11); font-weight: bold; font-size: 14px; transition: all 0.3s ease; text-transform: uppercase;">اردو</a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/tr" style="display: inline-block; padding: 6px 24px; margin: 8px; background: linear-gradient(135deg, #FCFBF8, #E0CCB0); color: black; text-decoration: none; border-radius: 8px; box-shadow: 0 4px 15px rgba(238, 186, 32, 0.11); font-weight: bold; font-size: 14px; transition: all 0.3s ease; text-transform: uppercase;">Türkçe</a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/ku" style="display: inline-block; padding: 6px 24px; margin: 8px; background: linear-gradient(135deg, #FCFBF8, #E0CCB0); color: black; text-decoration: none; border-radius: 8px; box-shadow: 0 4px 15px rgba(238, 186, 32, 0.11); font-weight: bold; font-size: 14px; transition: all 0.3s ease; text-transform: uppercase;">کوردی</a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/ms" style="display: inline-block; padding: 6px 24px; margin: 8px; background: linear-gradient(135deg, #FCFBF8, #E0CCB0); color: black; text-decoration: none; border-radius: 8px; box-shadow: 0 4px 15px rgba(238, 186, 32, 0.11); font-weight: bold; font-size: 14px; transition: all 0.3s ease; text-transform: uppercase;">Bahasa Malaysia</a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/es" style="display: inline-block; padding: 6px 24px; margin: 8px; background: linear-gradient(135deg, #FCFBF8, #E0CCB0); color: black; text-decoration: none; border-radius: 8px; box-shadow: 0 4px 15px rgba(238, 186, 32, 0.11); font-weight: bold; font-size: 14px; transition: all 0.3s ease; text-transform: uppercase;">Español</a>
</p>

### This package is a continuation of [flutter_quran](https://pub.dev/packages/flutter_quran) by [Hesham Erfan](https://www.linkedin.com/in/hesham-erfan-876b83105/) with many new features.

<p align="center">
<img src="https://github.com/alheekmahlib/thegarlanded/blob/master/Photos/quran_package_banner.png?raw=true" width="500"/>
</p>

### Important note before starting to use: Please make:
```dart
  useMaterial3: false,
```
### In order not to cause any formation problems

#

## Table of Contents

- [Getting started](#getting-started)
- [Usage Example](#usage-example)
  - [Basic Quran Screen](#basic-quran-screen)
  - [Individual Surah Display](#individual-surah-display)
  - [Single Ayah Display](#single-ayah-display)
- [Utils](#utils)
  - [Getting all Quran's Jozzs, Hizbs, and Surahs](#getting-all-qurans-jozzs-hizbs-and-surahs)
  - [to jump between pages, Surahs or Hizbs you can use](#to-jump-between-pages-surahs-or-hizbs-you-can-use)
  - [Adding, setting, removing, getting and navigating to bookmarks](#adding-setting-removing-getting-and-navigating-to-bookmarks)
  - [searching for any Ayah](#searching-for-any-ayah)
- [Fonts Download](#fonts-download)
- [Tafsir](#tafsir)
- [Audio Playback](#audio-playback)

#

## Getting started

#### Android
The required permissions for audio playback (`WAKE_LOCK`, `FOREGROUND_SERVICE`, and `FOREGROUND_SERVICE_MEDIA_PLAYBACK`) are automatically added by the package. You don't need to manually edit your AndroidManifest.xml.

#### iOS
For background audio playback, you must add the following to your app's `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

This allows audio playback to continue when the app is in the background.

In the `pubspec.yaml` of your flutter project, add the following dependency:

```yaml
dependencies:
  ...
  quran_library: ^2.0.16
```

Import it:

```dart
import 'package:quran_library/quran_library.dart';
```

Initialize it:

```dart
QuranLibrary.init();
```

## Usage Example

### Basic Quran Screen

```dart
/// You can just add it to your code like this:
class MyQuranPage extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return QuranLibraryScreen(
      parentContext: context, // Required
    );
  }
}
```


#### or give it some options:

```dart
QuranLibraryScreen(
    /// **Required** - Pass context from parent widget [parentContext]
    parentContext: context,
    
    /// [appBar] if provided it will replace the default app bar
    appBar: ...,
    /// [useDefaultAppBar] is a bool to disable or enable the default app bar widget
    useDefaultAppBar: // true or false,
    /// [onPageChanged] if provided it will be called when a quran page changed
    onPageChanged: (int pageIndex) => print("Page changed: $pageIndex"),
    /// [BasmalaStyle] Change the style of Basmala by BasmalaStyle class
    basmalaStyle: // BasmalaStyle(),
    /// [BannerStyle] Change the style of banner by BannerStyle class
    bannerStyle: // BannerStyle(),
    /// [SurahNameStyle] Change the style of surah name by SurahNameStyle class
    surahNameStyle: // SurahNameStyle(),
    /// [SurahInfoStyle] Change the style of surah information by SurahInfoStyle class
    surahInfoStyle: // SurahInfoStyle(),
    /// [DownloadFontsDialogStyle] Change the style of Download fonts dialog by DownloadFontsDialogStyle class
    downloadFontsDialogStyle: // DownloadFontsDialogStyle(),
    
    /// and more ................
),
```

### Individual Surah Display

```dart
/// For displaying a single surah with custom pagination
SurahDisplayScreen(
    /// [surahNumber] The surah number to display
    surahNumber: 1, // For Al-Fatihah
    /// [onPageChanged] if provided it will be called when a surah page changed
    onPageChanged: (int pageIndex) => print("Surah page changed: $pageIndex"),
    /// [isDark] enable or disable dark mode
    isDark: false,
    /// [basmalaStyle] Change the style of Basmala
    basmalaStyle: BasmalaStyle(
        basmalaColor: Colors.black,
        basmalaWidth: 160.0,
        basmalaHeight: 30.0,
    ),
    /// [bannerStyle] Change the style of banner
    bannerStyle: BannerStyle(
        isImage: false,
        bannerSvgHeight: 40.0,
        bannerSvgWidth: 150.0,
    ),
    /// and more options...
),
```

### Single Ayah Display

```dart
/// For displaying a single ayah from any surah
GetSingleAyah(
    /// [surahNumber] - must be between 1 and 114
    surahNumber: 1, // Surah number
    
    /// [ayahNumber] - ayah number within the surah
    ayahNumber: 2, // Ayah number
    
    /// [textColor] - optional text color
    textColor: Colors.black,
    
    /// [isDark] - optional, default is false
    isDark: false,
    
    /// [fontSize] - optional, default is 22
    fontSize: 24.0,
    
    /// [isBold] - optional, default is true
    isBold: true,
),
```

#### Using GetSingleAyah in a list:

```dart
class SingleAyahExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display Single Ayahs')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Ayat al-Kursi
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Ayat al-Kursi', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  GetSingleAyah(
                    surahNumber: 2, // Al-Baqarah
                    ayahNumber: 255, // Ayat al-Kursi
                    fontSize: 20,
                    textColor: Colors.brown,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Complete Al-Fatihah
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Surah Al-Fatihah', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  // Display all ayahs of Al-Fatihah
                  ...List.generate(7, (index) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: GetSingleAyah(
                      surahNumber: 1,
                      ayahNumber: index + 1,
                      fontSize: 18,
                      isDark: false,
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Utils

### The package provides a lot of utils like:

* ### Getting all Quran's Jozzs, Hizbs, and Surahs

```dart
final jozzs = QuranLibrary.allJoz;
final hizbs = QuranLibrary.allHizb;
final surahs = QuranLibrary.getAllSurahs();
final ayahsOnPage = QuranLibrary().getAyahsByPage();

/// [getSurahInfo] let's you get a Surah with all its data when you pass Surah number
final surah = QuranLibrary().getSurahInfo(1);
```

* ### to jump between pages, Surahs or Hizbs you can use:
```dart
/// [jumpToAyah] let's you navigate to any ayah..
/// It's better to call this method while Quran screen is displayed
/// and if it's called and the Quran screen is not displayed, the next time you
/// open quran screen it will start from this ayah's page
QuranLibrary().jumpToAyah(AyahModel ayah);
/// or you can use:
/// jumpToPage, jumpToJoz, jumpToHizb, jumpToBookmark and jumpToSurah.
```

<img src="https://github.com/alheekmahlib/thegarlanded/blob/master/Photos/Quran_package_jumpTo.png?raw=true" width="320"/>

* ### Adding, setting, removing, getting and navigating to bookmarks:

```dart
// In init function
QuranLibrary().init(userBookmarks: [Bookmark(id: 0, colorCode: Colors.red.value, name: "Red Bookmark")]);
final usedBookmarks = QuranLibrary().getUsedBookmarks();
QuranLibrary().setBookmark(surahName: 'Al-Fatihah', ayahNumber: 5, ayahId: 5, page: 1, bookmarkId: 0);
QuranLibrary().removeBookmark(bookmarkId: 0);
QuranLibrary().jumpToBookmark(BookmarkModel bookmark);
```

<img src="https://github.com/alheekmahlib/thegarlanded/blob/master/Photos/Quran_package_bookmark.png?raw=true" width="320"/> <img src="https://github.com/alheekmahlib/thegarlanded/blob/master/Photos/Quran_package_bookmark2.png?raw=true" width="320"/>

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
    hintText: 'Search',
  ),
),
```
<img src="https://github.com/alheekmahlib/thegarlanded/blob/master/Photos/Quran_package_search.png?raw=true" width="320"/>

## Fonts Download

## To download Quran fonts, you have two options:
* ### As for using the default dialog, you can modify the style in it.
* ### Or you can create your own design using all the functions for downloading fonts.

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
QuranLibrary().getFontsDownloadDialog(downloadFontsDialogStyle, languageCode);

/// to get the fonts download widget just call [getFontsDownloadWidget]
Widget getFontsDownloadWidget(context, {downloadFontsDialogStyle, languageCode});

/// to get the fonts download method just call [fontsDownloadMethod]
QuranLibrary().fontsDownloadMethod;

/// to prepare the fonts was downloaded before just call [getFontsPrepareMethod]
/// required to pass [pageIndex]
QuranLibrary().getFontsPrepareMethod(pageIndex);

/// to delete the fonts just call [deleteFontsMethod]
QuranLibrary().deleteFontsMethod;

/// to get fonts download progress just call [fontsDownloadProgress]
QuranLibrary().fontsDownloadProgress;

/// To find out whether fonts are downloaded or not, just call [isFontsDownloaded]
QuranLibrary().isFontsDownloaded;
```

<img src="https://github.com/alheekmahlib/thegarlanded/blob/master/Photos/Quran_package_fontes.png?raw=true" width="320"/>

## Tafsir

### Important note before starting to use: Please add this library to your pubspec.yaml file only for Android:
```yaml
 dependencies:
 ...
  drift_flutter: ^0.2.4
 ...
```
# to avoid any problems when showing the tafsir


* ### Usage Example

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
QuranLibrary().changeTafsirPopupMenu(TafsirStyle tafsirStyle, {int? pageNumber});

/// Close and re-initialize the database (usually when changing the tafsir).
QuranLibrary().closeAndInitializeDatabase({int? pageNumber});

/// Fetch tafsir for a specific page by its page number.
QuranLibrary().fetchTafsir({required int pageNumber});

/// Check if the tafsir is already downloaded.
QuranLibrary().getTafsirDownloaded(int index);

/// Get the list of tafsir and translation names.
QuranLibrary().tafsirAndTraslationCollection;

/// Change the selected tafsir when the switch button is pressed.
QuranLibrary().changeTafsirSwitch(int index, {int? pageNumber});

/// Get the list of available tafsir data.
QuranLibrary().tafsirList;

/// Get the list of available translations.
QuranLibrary().translationList;

/// Fetch translations from the source.
QuranLibrary().fetchTranslation();

/// Download the tafsir by the given index.
QuranLibrary().tafsirDownload(int i);
```

## Audio Playback

### This section provides comprehensive capabilities for audio playback of the Holy Quran with background playback support and advanced audio file management.

* ### Verse Audio Playback

```dart
/// Play a verse or group of verses starting from a specific verse
await QuranLibrary().playAyah(
  context: context,
  currentAyahUniqueNumber: 1, // Unique ayah number
  playSingleAyah: true, // true for single ayah, false to continue
);

/// Move to next verse and play it
await QuranLibrary().seekNextAyah(
  context: context,
  currentAyahUniqueNumber: 5,
);

/// Move to previous verse and play it
await QuranLibrary().seekPreviousAyah(
  context: context,
  currentAyahUniqueNumber: 10,
);
```

* ### Surah Audio Playback

```dart
/// Play a complete surah from beginning to end
await QuranLibrary().playSurah(surahNumber: 1); // Al-Fatihah
await QuranLibrary().playSurah(surahNumber: 2); // Al-Baqarah

/// Move to next surah and play it
await QuranLibrary().seekToNextSurah();

/// Move to previous surah and play it
await QuranLibrary().seekToPreviousSurah();
```

* ### Download Management

```dart
/// Start downloading a surah for offline playback
await QuranLibrary().startDownloadSurah(surahNumber: 1);

/// Cancel ongoing download
QuranLibrary().cancelDownloadSurah();
```

* ### Position Control & Resume

```dart
/// Get current/last surah number
int currentSurah = QuranLibrary().currentAndLastSurahNumber;

/// Get last position as formatted text (like "05:23")
String lastTimeText = QuranLibrary().formatLastPositionToTime;

/// Get last position as Duration object for programming operations
Duration lastDuration = QuranLibrary().formatLastPositionToDuration;

/// Play from the last position where user stopped
await QuranLibrary().playLastPosition();
```

* ### Complete Audio Example

```dart
class AudioControlExample extends StatefulWidget {
  @override
  _AudioControlExampleState createState() => _AudioControlExampleState();
}

class _AudioControlExampleState extends State<AudioControlExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quran Audio Player')),
      body: Column(
        children: [
          // Display current surah
          Text('Current Surah: ${QuranLibrary().currentAndLastSurahNumber}'),
          
          // Display last position
          Text('Last Position: ${QuranLibrary().formatLastPositionToTime}'),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Play from last position
              ElevatedButton(
                onPressed: () => QuranLibrary().playLastPosition(),
                child: Text('Resume from where you left'),
              ),
              
              // Play Al-Fatihah
              ElevatedButton(
                onPressed: () => QuranLibrary().playSurah(surahNumber: 1),
                child: Text('Surah Al-Fatihah'),
              ),
            ],
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous surah
              IconButton(
                onPressed: () => QuranLibrary().seekToPreviousSurah(),
                icon: Icon(Icons.skip_previous),
              ),
              
              // Previous ayah
              IconButton(
                onPressed: () => QuranLibrary().seekPreviousAyah(
                  context: context,
                  currentAyahUniqueNumber: 10,
                ),
                icon: Icon(Icons.fast_rewind),
              ),
              
              // Next ayah
              IconButton(
                onPressed: () => QuranLibrary().seekNextAyah(
                  context: context,
                  currentAyahUniqueNumber: 5,
                ),
                icon: Icon(Icons.fast_forward),
              ),
              
              // Next surah
              IconButton(
                onPressed: () => QuranLibrary().seekToNextSurah(),
                icon: Icon(Icons.skip_next),
              ),
            ],
          ),
          
          // Download buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => QuranLibrary().startDownloadSurah(surahNumber: 2),
                child: Text('Download Surah Al-Baqarah'),
              ),
              
              ElevatedButton(
                onPressed: () => QuranLibrary().cancelDownloadSurah(),
                child: Text('Cancel Download'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Audio Features Summary:
- ✅ **Verse Playback** - Play individual or sequential verses
- ✅ **Complete Surah Playback** - Play complete surahs
- ✅ **Navigation Controls** - Navigation tools between verses and surahs
- ✅ **Offline Download** - Download for offline playback
- ✅ **Resume Functionality** - Resume playback from last position
- ✅ **Background Playback** - Playback in the background
- ✅ **Position Tracking** - Track playback position
- ✅ **Download Management** - Comprehensive download and cancel management

* ### You can also use the default Quran font or Naskh font
```dart
/// [hafsStyle] is the default style for Quran so all special characters will be rendered correctly
QuranLibrary().hafsStyle;

/// [naskhStyle] is the default style for other text.
QuranLibrary().naskhStyle;
```
