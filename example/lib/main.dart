import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_library/quran_library.dart';

void main() => runApp(
      GetMaterialApp(
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
    return const QuranLibraryScreen(
      withPageView: true,
      textColor: Colors.black,
      backgroundColor: Color(0xfffaf7f3),
      languageCode: 'ar',
      bookmarkList: [],
    );
  }
}
