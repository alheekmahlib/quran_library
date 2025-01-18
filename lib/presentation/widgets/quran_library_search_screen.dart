part of '../pages/quran_library_screen.dart';

class QuranLibrarySearchScreen extends StatelessWidget {
  const QuranLibrarySearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بحث'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                GetBuilder<QuranCtrl>(
                    builder: (quranCtrl) => TextField(
                          onChanged: (txt) {
                            final searchResult = QuranLibrary().search(txt);
                            quranCtrl.ayahsList.value = [...searchResult];
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            hintText: 'بحث',
                          ),
                        )),
                Expanded(
                  child: GetX<QuranCtrl>(
                    builder: (quranCtrl) => ListView(
                      children: quranCtrl.ayahsList
                          .map((ayah) => Column(
                                children: [
                                  ListTile(
                                    title: Text(ayah.ayah.replaceAll('\n', ' '),
                                        style: QuranLibrary().hafsStyle),
                                    subtitle: Text(ayah.surahNameAr),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      QuranLibrary().jumpToAyah(ayah);
                                    },
                                  ),
                                  const Divider(
                                    color: Colors.grey,
                                    thickness: 1,
                                  ),
                                ],
                              ))
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
