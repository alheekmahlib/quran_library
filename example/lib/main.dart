import 'package:floating_draggable_widget/floating_draggable_widget.dart';
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
    return FloatingDraggableWidget(
      mainScreenWidget: const QuranLibraryScreen(
        isDark: false,
        // backgroundColor: Colors.black,
        // textColor: Colors.white,
      ),
      floatingWidget: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
            onPressed: () => showDialog<String>(
                context: context,
                builder: (BuildContext context) => Dialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Wrap(
                              children: List.generate(
                                  QuranLibrary()
                                      .getTajweedRules(languageCode: 'ar')
                                      .length,
                                  (i) => Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              height: 30,
                                              width: 30,
                                              margin: EdgeInsets.symmetric(
                                                  horizontal: 8.0),
                                              decoration: BoxDecoration(
                                                color: Color(QuranLibrary()
                                                    .getTajweedRules(
                                                        languageCode: 'ar')[i]
                                                    .color),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            Text(
                                              QuranLibrary()
                                                  .getTajweedRules(
                                                      languageCode: 'ar')[i]
                                                  .text,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                            ),
                          ),
                        ],
                      ),
                    )),
            icon: Icon(
              Icons.format_color_text_outlined,
              color: Colors.white,
            )),
      ),
      autoAlign: true,
      screenWidth: MediaQuery.sizeOf(context).width,
      disableBounceAnimation: true,
      deleteWidgetPadding: EdgeInsets.symmetric(horizontal: 32),
      floatingWidgetWidth: 50,
      floatingWidgetHeight: 50,
    );
  }
}
