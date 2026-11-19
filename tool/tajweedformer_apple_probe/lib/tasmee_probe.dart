import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quran_library/quran_library.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuranLibrary.init();
  QuranLibrary.initWordAudio();
  runApp(const _TasmeeProbe());
}

class _TasmeeProbe extends StatelessWidget {
  const _TasmeeProbe();

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: QuranLibraryScreen(
              parentContext: context,
              isDark: false,
              isShowTabBar: true,
              isFontsLocal: false,
              useDefaultAppBar: true,
              enableWordSelection: true,
              isShowDisplayModeBar: true,
              showAyahBookmarkedIcon: true,
              appLanguageCode: 'ar',
            ),
          ),
        ),
      );
}
