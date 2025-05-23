import 'dart:developer';

// import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';

Future<void> main() async {
  runApp(
    // DevicePreview(
    //   builder: (context) => const MyApp(),
    // ),
    const MyApp(),
  );

  await QuranLibrary().init();
  await QuranLibrary().initTafsir();
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
        body: QuranLibraryScreen(
          isDark: false,
          showAyahBookmarkedIcon: true,
          ayahIconColor: Color(0xffcdad80),
          // backgroundColor: Colors.white,
          // textColor: Colors.black,
          isFontsLocal: false,
          anotherMenuChild:
              Icon(Icons.play_arrow_outlined, size: 28, color: Colors.grey),
          anotherMenuChildOnTap: (ayah) {
            log('Another Menu Child Tapped: ${ayah.ayahNumber}');
          },
        ),
      ),
    );
  }
}
