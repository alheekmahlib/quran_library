// import 'package:device_preview/device_preview.dart';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';
import 'package:quran_library/src/audio/audio.dart';

Future<void> main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  await QuranLibrary.init();
  runApp(
    // DevicePreview(
    //   builder: (context) => const MyApp(),
    // ),
    const MyApp(),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // useInheritedMediaQuery: true,
      // locale: DevicePreview.locale(context),
      // builder: DevicePreview.appBuilder,
      theme: ThemeData(
        primaryColor: Colors.blue,
        useMaterial3: false,
      ),
      home: Scaffold(
        // body: SingleAyah(),
        // body: SingleSurah(),
        // body: QuranPages(),
        body: FullQuran(),
      ),
    );
  }
}

class FullQuran extends StatelessWidget {
  const FullQuran({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return QuranLibraryScreen(
      parentContext: context,
      isDark: false,
      showAyahBookmarkedIcon: true,
      ayahIconColor: Color(0xffcdad80),
      // backgroundColor: Colors.white,
      // textColor: Colors.black,
      isFontsLocal: false,
      anotherMenuChild:
          Icon(Icons.play_arrow_outlined, size: 28, color: Colors.teal),
      anotherMenuChildOnTap: (ayah) {
        // SurahAudioController.instance.state.currentAyahUnequeNumber =
        //     ayah.ayahUQNumber;
        AudioCtrl.instance
            .playAyah(context, ayah.ayahUQNumber, playSingleAyah: true);
        log('Another Menu Child Tapped: ${ayah.ayahUQNumber}');
      },
      secondMenuChild: Icon(Icons.playlist_play, size: 28, color: Colors.teal),
      secondMenuChildOnTap: (ayah) {
        // SurahAudioController.instance.state.currentAyahUnequeNumber =
        //     ayah.ayahUQNumber;
        AudioCtrl.instance
            .playAyah(context, ayah.ayahUQNumber, playSingleAyah: false);
        log('Second Menu Child Tapped: ${ayah.ayahUQNumber}');
      },
    );
  }
}

class SingleSurah extends StatelessWidget {
  const SingleSurah({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SurahDisplayScreen(
      parentContext: context,
      surahNumber: 18,
      isDark: false,
      languageCode: 'ar',
      useDefaultAppBar: false,
      anotherMenuChild:
          Icon(Icons.play_arrow_outlined, size: 28, color: Colors.grey),
      anotherMenuChildOnTap: (ayah) {
        // SurahAudioController.instance.state.currentAyahUnequeNumber =
        //     ayah.ayahUQNumber;
        AudioCtrl.instance
            .playAyah(context, ayah.ayahUQNumber, playSingleAyah: true);
        log('Another Menu Child Tapped: ${ayah.ayahUQNumber}');
      },
      secondMenuChild: Icon(Icons.playlist_play, size: 28, color: Colors.grey),
      secondMenuChildOnTap: (ayah) {
        // SurahAudioController.instance.state.currentAyahUnequeNumber =
        //     ayah.ayahUQNumber;
        AudioCtrl.instance
            .playAyah(context, ayah.ayahUQNumber, playSingleAyah: false);
        log('Second Menu Child Tapped: ${ayah.ayahUQNumber}');
      },
    );
  }
}

class SingleAyah extends StatelessWidget {
  const SingleAyah({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GetSingleAyah(
        surahNumber: 114,
        ayahNumber: 4,
        fontSize: 30,
        isBold: false,
      ),
    );
  }
}

class QuranPages extends StatelessWidget {
  const QuranPages({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: QuranPagesScreen(
        parentContext: context,
        enableMultiSelect: true,
        // highlightedAyahNumbersBySurah: {
        //   2: [7, 8, 9, 10, 11, 12],
        // },
        // page: 6,
        startPage: 6,
        endPage: 11, // النطاق شامل
        // highlightedAyahNumbersInPages: [
        //   (
        //     start: 3,
        //     end: 5,
        //     ayahs: [7, 8, 9, 10, 11, 12],
        //   )
        // ],
        highlightedRanges: [
          (startSurah: 2, startAyah: 30, endSurah: 2, endAyah: 35)
        ],
        withPageView: true, // تمكين/تعطيل السحب بين الصفحات
        anotherMenuChild:
            Icon(Icons.play_arrow_outlined, size: 28, color: Colors.teal),
        anotherMenuChildOnTap: (ayah) {
          // SurahAudioController.instance.state.currentAyahUnequeNumber =
          //     ayah.ayahUQNumber;
          AudioCtrl.instance
              .playAyah(context, ayah.ayahUQNumber, playSingleAyah: true);
          log('Another Menu Child Tapped: ${ayah.ayahUQNumber}');
        },
        secondMenuChild:
            Icon(Icons.playlist_play, size: 28, color: Colors.teal),
        secondMenuChildOnTap: (ayah) {
          // SurahAudioController.instance.state.currentAyahUnequeNumber =
          //     ayah.ayahUQNumber;
          AudioCtrl.instance
              .playAyah(context, ayah.ayahUQNumber, playSingleAyah: false);
          log('Second Menu Child Tapped: ${ayah.ayahUQNumber}');
        },
      ),
    );
  }
}
