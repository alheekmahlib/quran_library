part of '../flutter_quran_screen.dart';

class _DefaultDrawer extends StatelessWidget {
  const _DefaultDrawer();

  @override
  Widget build(BuildContext context) {
    final jozzList = FlutterQuran().allJozz;
    final hizbList = FlutterQuran().allHizb;
    final surahs = FlutterQuran().getAllSurahs();
    return Drawer(
      child: ListView(
        children: [
          ListTile(
            trailing: const Icon(Icons.search_outlined),
            title: const Text('بحث'),
            onTap: () async {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => const FlutterQuranSearchScreen()));
            },
          ),
          ExpansionTile(
            title: const Text('الفهرس'),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExpansionTile(
                title: const Text('الجزء'),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                    jozzList.length,
                    (jozzIndex) => ExpansionTile(
                          title: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              jozzList[jozzIndex],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          children: List.generate(2, (index) {
                            final hizbIndex = (index == 0 && jozzIndex == 0)
                                ? 0
                                : ((jozzIndex * 2 + index));
                            return InkWell(
                              onTap: () {
                                FlutterQuran().jumpToHizb(hizbIndex + 1);
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  hizbList[hizbIndex],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }),
                        )
                    //    )
                    ),
              ),
              ExpansionTile(
                title: const Text('السورة'),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                    surahs.length,
                    (index) => GestureDetector(
                        onTap: () => FlutterQuran().jumpToSurah(index + 1),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            surahs[index],
                            textAlign: TextAlign.start,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ))),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('العلامات'),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
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
                              bookmark.ayahNumber.toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      title: Text(
                        bookmark.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onTap: () => FlutterQuran()
                          .jumpToBookmark(bookmark), // التنقل إلى العلامة
                    );
                  }).toList(),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}
