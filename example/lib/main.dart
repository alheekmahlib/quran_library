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
  bool _isDark = false;

  @override
  void initState() {
    QuranLibrary().init();
    super.initState();
  }

  void _toggleDarkMode() {
    setState(() {
      _isDark = !_isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return QuranLibraryScreen(
      isDark: _isDark,
      showAyahBookmarkedIcon: true,
      onThemeToggle: _toggleDarkMode, // Pass the toggle method
      // ayahIconColor: Color(0xffcdad80),
      // backgroundColor: Colors.white,
      // textColor: Colors.black,
    );
  }
}
