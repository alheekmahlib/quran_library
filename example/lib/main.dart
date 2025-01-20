import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';

void main() => runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Colors.blue,
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const QuranLibraryScreen();
  }
}
