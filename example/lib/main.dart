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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          const QuranLibraryScreen(
            isDark: false,
            fFamily: 'p603',
            pageIndex: 602,
            withPageView: false,
            // backgroundColor: Colors.black,
            // textColor: Colors.white,
          ),
          Text(
            'ﱅﱆﱇﱈﱉ',
            style: TextStyle(fontFamily: 'p603', color: Colors.black),
          ),
        ],
      ),
    );
  }
}
