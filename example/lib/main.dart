import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';

void main() => runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Colors.blue,
          useMaterial3: false,
        ),
        home: const MyApp(),
      ),
    );

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    QuranLibrary().init();
    QuranLibrary().initTafsir();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return QuranLibraryScreen(
      isDark: false,
      showAyahBookmarkedIcon: true,
      ayahIconColor: Color(0xffcdad80),
      backgroundColor: Colors.white,
      textColor: Colors.black,
      isFontsLocal: false,
    );
  }
}
