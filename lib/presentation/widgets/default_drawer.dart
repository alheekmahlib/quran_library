part of '../../quran.dart';

class _DefaultDrawer extends StatelessWidget {
  final String languageCode;
  const _DefaultDrawer(this.languageCode);

  @override
  Widget build(BuildContext context) {
    final jozzList = QuranLibrary().allJoz;
    final hizbList = QuranLibrary().allHizb;
    final surahs = QuranLibrary().getAllSurahs();
    return Drawer(
      backgroundColor: const Color(0xfffaf7f3),
      child: ListView(
        children: [
          Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
                color: const Color(0xfff6d09d).withValues(alpha: .3),
                border: Border.all(width: 1, color: const Color(0xfff6d09d)),
                borderRadius: BorderRadius.all(Radius.circular(8))),
            child: ListTile(
              trailing: const Icon(Icons.search_outlined),
              title: Text('بحث', style: QuranLibrary().naskhStyle),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (ctx) => const QuranLibrarySearchScreen()));
              },
            ),
          ),
          const SizedBox(height: 32),
          ExpansionTile(
            title: Text('الفهرس', style: QuranLibrary().naskhStyle),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            backgroundColor: const Color(0xfff6d09d).withValues(alpha: .1),
            collapsedBackgroundColor:
                const Color(0xfff6d09d).withValues(alpha: .3),
            children: [
              ExpansionTile(
                title: Text('الجزء', style: QuranLibrary().naskhStyle),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                    jozzList.length,
                    (jozzIndex) => Container(
                          width: MediaQuery.sizeOf(context).width,
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          color: jozzIndex.isEven
                              ? const Color(0xfff6d09d).withValues(alpha: .1)
                              : Colors.transparent,
                          child: ExpansionTile(
                            title: Text(
                              jozzList[jozzIndex],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
                                  width: MediaQuery.sizeOf(context).width,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  color: index.isEven
                                      ? const Color(0xfff6d09d)
                                          .withValues(alpha: .1)
                                      : Colors.transparent,
                                  child: Text(
                                    hizbList[hizbIndex],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            }),
                          ),
                        )
                    //    )
                    ),
              ),
              ExpansionTile(
                title: Text('السورة', style: QuranLibrary().naskhStyle),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                    surahs.length,
                    (index) => GestureDetector(
                        onTap: () => QuranLibrary().jumpToSurah(index + 1),
                        child: Container(
                          width: MediaQuery.sizeOf(context).width,
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
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
                                        AssetsPath().suraNum,
                                        width: 50,
                                        height: 50,
                                        colorFilter: ColorFilter.mode(
                                            Colors.black, BlendMode.srcIn),
                                      ),
                                      Text(
                                          '${index + 1}'
                                              .convertNumbersAccordingToLang(
                                                  languageCode: languageCode),
                                          style: QuranLibrary()
                                              .naskhStyle
                                              .copyWith(fontSize: 18)),
                                    ],
                                  ),
                                ),
                              ),
                              // SizedBox(width: 46),
                              Expanded(
                                flex: 8,
                                child: SvgPicture.asset(
                                  'packages/quran_library/lib/assets/svg/surah_name/00${index + 1}.svg',
                                  width: 200,
                                  height: 40,
                                  colorFilter: ColorFilter.mode(
                                      Colors.black, BlendMode.srcIn),
                                ),
                              ),
                            ],
                          ),
                        ))),
              ),
            ],
          ),
          SizedBox(height: 8),
          ExpansionTile(
            title: Text('العلامات', style: QuranLibrary().naskhStyle),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            backgroundColor: const Color(0xfff6d09d).withValues(alpha: .1),
            collapsedBackgroundColor:
                const Color(0xfff6d09d).withValues(alpha: .3),
            children: [
              ...BookmarksCtrl.instance.bookmarks.entries.map((entry) {
                final colorCode = entry.key; // اللون
                final bookmarks = entry.value; // قائمة العلامات لهذا اللون

                return ExpansionTile(
                  title: Text(
                    colorCode == 0xAAFFD354
                        ? 'العلامات الصفراء'
                        : colorCode == 0xAAF36077
                            ? 'العلامات الحمراء'
                            : 'العلامات الخضراء',
                    style: QuranLibrary().naskhStyle,
                  ),
                  leading: Icon(
                    Icons.bookmark,
                    color: Color(colorCode),
                  ),
                  children: bookmarks.map((bookmark) {
                    return ListTile(
                      leading: Container(
                        padding: EdgeInsets.symmetric(horizontal: 1.0),
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
                        style: QuranLibrary().naskhStyle,
                      ),
                      onTap: () => QuranLibrary()
                          .jumpToBookmark(bookmark), // التنقل إلى العلامة
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
