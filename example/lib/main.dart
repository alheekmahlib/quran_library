// import 'package:device_preview/device_preview.dart';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      locale: const Locale('ar'),
      // useInheritedMediaQuery: true,
      // locale: DevicePreview.locale(context),
      // builder: DevicePreview.appBuilder,
      theme: ThemeData(
        primaryColor: Colors.teal,
        useMaterial3: false,
      ),
      home: const Scaffold(
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
      // ayahIconColor: Colors.teal,
      // backgroundColor: Colors.white,
      // textColor: Colors.black,
      isFontsLocal: false,
      anotherMenuChild:
          const Icon(Icons.play_arrow_outlined, size: 28, color: Colors.teal),
      anotherMenuChildOnTap: (ayah) {
        // SurahAudioController.instance.state.currentAyahUnequeNumber =
        //     ayah.ayahUQNumber;
        AudioCtrl.instance
            .playAyah(context, ayah.ayahUQNumber, playSingleAyah: true);
        log('Another Menu Child Tapped: ${ayah.ayahUQNumber}');
      },
      secondMenuChild:
          const Icon(Icons.playlist_play, size: 28, color: Colors.teal),
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
          const Icon(Icons.play_arrow_outlined, size: 28, color: Colors.grey),
      anotherMenuChildOnTap: (ayah) {
        // SurahAudioController.instance.state.currentAyahUnequeNumber =
        //     ayah.ayahUQNumber;
        AudioCtrl.instance
            .playAyah(context, ayah.ayahUQNumber, playSingleAyah: true);
        log('Another Menu Child Tapped: ${ayah.ayahUQNumber}');
      },
      secondMenuChild:
          const Icon(Icons.playlist_play, size: 28, color: Colors.grey),
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
    return const Center(
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
        highlightedRanges: const [
          (startSurah: 2, startAyah: 30, endSurah: 2, endAyah: 35)
        ],
        withPageView: true, // تمكين/تعطيل السحب بين الصفحات
        anotherMenuChild:
            const Icon(Icons.play_arrow_outlined, size: 28, color: Colors.teal),
        anotherMenuChildOnTap: (ayah) {
          // SurahAudioController.instance.state.currentAyahUnequeNumber =
          //     ayah.ayahUQNumber;
          AudioCtrl.instance
              .playAyah(context, ayah.ayahUQNumber, playSingleAyah: true);
          log('Another Menu Child Tapped: ${ayah.ayahUQNumber}');
        },
        secondMenuChild:
            const Icon(Icons.playlist_play, size: 28, color: Colors.teal),
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
