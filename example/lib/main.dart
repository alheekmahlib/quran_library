import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';

Future<void> main() async {
  runApp(const MyApp());
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
        ),
      ),
    );
  }
}
