part of '/quran.dart';

class _DefaultDrawer extends StatelessWidget {
  final String languageCode;
  final bool isDark;
  final SurahAudioStyle? style;

  const _DefaultDrawer(this.languageCode, this.isDark, {this.style});

  @override
  Widget build(BuildContext context) {
    final jozzList = QuranLibrary.allJoz;
    final hizbList = QuranLibrary.allHizb;
    final surahs = QuranLibrary.getAllSurahs();
    return Drawer(
      backgroundColor:
          isDark ? const Color(0xff1E1E1E) : const Color(0xfffaf7f3),
      child: ListView(
        children: [
          _buildSearchTile(context),
          const SizedBox(height: 32),
          _buildIndexSection(context, jozzList, hizbList, surahs),
          const SizedBox(height: 8),
          _buildBookmarksSection(),
          const SizedBox(height: 8),
          _buildAudioPlayer(context),
        ],
      ),
    );
  }

  // شرح: بلاطة البحث
  // Explanation: Search tile
  Widget _buildSearchTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xfff6d09d).withValues(alpha: isDark ? .5 : .3),
        border: Border.all(width: 1, color: const Color(0xfff6d09d)),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: ListTile(
        trailing: const Icon(Icons.search_outlined),
        title: Text('البحث', style: QuranLibrary().naskhStyle),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => QuranLibrarySearchScreen(isDark: isDark),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAudioPlayer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xfff6d09d).withValues(alpha: isDark ? .5 : .3),
        border: Border.all(width: 1, color: const Color(0xfff6d09d)),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: ListTile(
        trailing: const Icon(Icons.record_voice_over),
        title: Text('الإستماع للقرآن', style: QuranLibrary().naskhStyle),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SurahAudioScreen(style: style, isDark: isDark),
            ),
          );
        },
      ),
    );
  }

  // شرح: قسم الفهرس (الأجزاء والسور)
  // Explanation: Index section (Jozz & Surahs)
  Widget _buildIndexSection(BuildContext context, List<String> jozzList,
      List<String> hizbList, List<String> surahs) {
    return ExpansionTile(
      title: Text('الفهرس', style: QuranLibrary().naskhStyle),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      backgroundColor:
          const Color(0xfff6d09d).withValues(alpha: isDark ? .6 : .1),
      collapsedBackgroundColor:
          const Color(0xfff6d09d).withValues(alpha: isDark ? .8 : .3),
      children: [
        _buildJozzSection(context, jozzList, hizbList),
        _buildSurahSection(context, surahs),
      ],
    );
  }

  // شرح: قسم الأجزاء
  // Explanation: Jozz section
  Widget _buildJozzSection(
      BuildContext context, List<String> jozzList, List<String> hizbList) {
    return ExpansionTile(
      title: Text('الأجزاء', style: QuranLibrary().naskhStyle),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      iconColor: Colors.black,
      children: List.generate(
        jozzList.length,
        (jozzIndex) => Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          color: jozzIndex.isEven
              ? const Color(0xfff6d09d).withValues(alpha: .1)
              : Colors.transparent,
          child: ExpansionTile(
            title: Text(
              jozzList[jozzIndex],
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
            children: List.generate(2, (index) {
              final hizbIndex = (index == 0 && jozzIndex == 0)
                  ? 0
                  : ((jozzIndex * 2 + index));
              return InkWell(
                onTap: () {
                  QuranLibrary().jumpToHizb(hizbIndex + 1);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  color: index.isEven
                      ? const Color(0xfff6d09d).withValues(alpha: .1)
                      : Colors.transparent,
                  child: Text(
                    hizbList[hizbIndex],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // شرح: قسم السور
  // Explanation: Surah section
  Widget _buildSurahSection(BuildContext context, List<String> surahs) {
    return ExpansionTile(
      title: Text('السور', style: QuranLibrary().naskhStyle),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        surahs.length,
        (index) => GestureDetector(
          onTap: () => QuranLibrary().jumpToSurah(index + 1),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            color: index.isEven
                ? const Color(0xfff6d09d).withValues(alpha: .1)
                : Colors.transparent,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SvgPicture.asset(
                          AssetsPath.assets.suraNum,
                          width: 50,
                          height: 50,
                          colorFilter:
                              ColorFilter.mode(Colors.black, BlendMode.srcIn),
                        ),
                        Text(
                          '${index + 1}'.convertNumbersAccordingToLang(
                              languageCode: languageCode),
                          style:
                              QuranLibrary().naskhStyle.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Text(
                    (index + 1).toString(),
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black),
                      fontFamily: "surahName",
                      fontSize: 38,
                      package: "quran_library",
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // شرح: قسم العلامات
  // Explanation: Bookmarks section
  Widget _buildBookmarksSection() {
    return ExpansionTile(
      title: Text('العلامات', style: QuranLibrary().naskhStyle),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      backgroundColor:
          const Color(0xfff6d09d).withValues(alpha: isDark ? .6 : .1),
      collapsedBackgroundColor:
          const Color(0xfff6d09d).withValues(alpha: isDark ? .8 : .3),
      children: [
        ...BookmarksCtrl.instance.bookmarks.entries.map((entry) {
          final colorCode = entry.key;
          final bookmarks = entry.value;
          return ExpansionTile(
            title: Text(
              colorCode == 0xAAFFD354
                  ? 'العلامات الصفراء'
                  : colorCode == 0xAAF36077
                      ? 'العلامات الحمراء'
                      : 'العلامات الخضراء',
              style: QuranLibrary().naskhStyle.copyWith(fontSize: 18),
            ),
            leading: Icon(
              Icons.bookmark,
              color: Color(colorCode),
            ),
            children: bookmarks.map((bookmark) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Color(colorCode)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.bookmark,
                        color: Color(bookmark.colorCode),
                        size: 34,
                      ),
                      Text(
                        bookmark.ayahNumber
                            .toString()
                            .convertNumbersAccordingToLang(
                                languageCode: languageCode),
                        style: QuranLibrary().naskhStyle,
                      ),
                    ],
                  ),
                ),
                title: Text(
                  bookmark.name,
                  style: QuranLibrary().naskhStyle.copyWith(fontSize: 17),
                ),
                onTap: () => QuranLibrary().jumpToBookmark(bookmark),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}
