part of '../../quran.dart';

/// A widget that displays the Quran library search screen.
///
/// This screen is used to search for specific parts of the Quran.
/// It contains a text field where the user can enter the text to search for,
/// and a list of results that match the search.
class QuranLibrarySearchScreen extends StatelessWidget {
  /// Creates a [QuranLibrarySearchScreen].
  ///
  /// The [isDark] parameter allows you to set the screen's color scheme.
  /// If [isDark] is `true`, the screen will be dark. If it is `false` or null,
  /// the screen will be light.
  const QuranLibrarySearchScreen(
      {super.key, this.isDark = false, this.textController});

  /// Whether the screen should be dark or not.
  ///
  /// If [isDark] is `true`, the screen will be dark. If it is `false` or null,
  /// the screen will be light.
  final bool isDark;
  final TextEditingController? textController;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xff202020) : const Color(0xfffaf7f3),
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black,
              )),
          title: Text(
            'بحث',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          centerTitle: true,
          backgroundColor:
              isDark ? const Color(0xff202020) : const Color(0xfffaf7f3),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                GetBuilder<QuranCtrl>(
                  builder: (quranCtrl) => TextField(
                    // onSubmitted: (txt) async {
                    //   if (txt.isNotEmpty) {
                    //     final searchResult =
                    //         await quranCtrl.quranSearch.search(txt);
                    //     quranCtrl.ayahsList.value = [...searchResult];
                    //   } else {
                    //     quranCtrl.ayahsList.value = [];
                    //   }
                    // },

                    onChanged: (txt) {
                      final searchResult = QuranLibrary().search(txt);
                      quranCtrl.ayahsList.value = [...searchResult];
                    },
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: 'بحث',
                      hintStyle: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
                Expanded(
                  child: GetX<QuranCtrl>(
                    builder: (quranCtrl) => ListView(
                      children: quranCtrl.ayahsList
                          .map(
                            (ayah) => Column(
                              children: [
                                ListTile(
                                  title: Text(
                                    ayah.text.replaceAll('\n', ' '),
                                    style: QuranLibrary().hafsStyle.copyWith(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                  ),
                                  subtitle: Text(
                                    ayah.arabicName,
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    quranCtrl.ayahsList.value = [];
                                    quranCtrl.isDownloadFonts
                                        ? await quranCtrl
                                            .prepareFonts(ayah.page)
                                        : null;
                                    QuranLibrary().jumpToAyah(
                                        ayah.page, ayah.ayahUQNumber);
                                  },
                                ),
                                const Divider(
                                  color: Colors.grey,
                                  thickness: 1,
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
