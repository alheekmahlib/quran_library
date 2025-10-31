part of '/quran.dart';

class _BookmarksTab extends StatelessWidget {
  final bool isDark;
  final String languageCode;
  const _BookmarksTab({required this.isDark, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppColors.getTextColor(isDark);

    return SingleChildScrollView(
      child: Column(
        children: [
          ...BookmarksCtrl.instance.bookmarks.entries.map((entry) {
            final int colorCode = entry.key;
            final groupColor = Color(colorCode);
            final bookmarks = entry.value;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: groupColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: groupColor.withValues(alpha: 0.25), width: 1),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Icon(Icons.bookmark, color: groupColor),
                  title: Text(
                    colorCode == 0xAAFFD354
                        ? 'الفواصل الصفراء'
                        : colorCode == 0xAAF36077
                            ? 'الفواصل الحمراء'
                            : 'الفواصل الخضراء',
                    style: QuranLibrary().cairoStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor),
                  ),
                  subtitle: Text(
                    'عدد: ${bookmarks.length}'.convertNumbersAccordingToLang(
                        languageCode: languageCode),
                    style: QuranLibrary().cairoStyle.copyWith(
                        color: textColor.withValues(alpha: 0.7), fontSize: 12),
                  ),
                  childrenPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  children: bookmarks.map((bookmark) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 4.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.pop(context);
                            QuranLibrary().jumpToBookmark(bookmark);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: groupColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: groupColor.withValues(alpha: 0.2),
                                  width: 1),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Leading visual
                                Container(
                                  height: 36,
                                  width: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        Border.all(color: groupColor, width: 1),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(Icons.bookmark,
                                          color: Color(bookmark.colorCode),
                                          size: 26),
                                      Text(
                                        bookmark.ayahNumber
                                            .toString()
                                            .convertNumbersAccordingToLang(
                                                languageCode: languageCode),
                                        style: QuranLibrary()
                                            .cairoStyle
                                            .copyWith(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Title and chips
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bookmark.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: QuranLibrary()
                                            .cairoStyle
                                            .copyWith(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: textColor),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: -6,
                                        children: [
                                          _chip(
                                            context,
                                            label: 'آية ${bookmark.ayahNumber}'
                                                .convertNumbersAccordingToLang(
                                                    languageCode: languageCode),
                                            bg: groupColor.withValues(
                                                alpha: 0.12),
                                            fg: textColor,
                                          ),
                                          if (bookmark.page > 0)
                                            _chip(
                                              context,
                                              label: 'صفحة ${bookmark.page}'
                                                  .convertNumbersAccordingToLang(
                                                      languageCode:
                                                          languageCode),
                                              bg: groupColor.withValues(
                                                  alpha: 0.12),
                                              fg: textColor,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_left, color: textColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
          if (BookmarksCtrl.instance.bookmarks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 48,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد فواصل محفوظة',
                    style: QuranLibrary().cairoStyle.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context,
      {required String label, required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: QuranLibrary().cairoStyle.copyWith(fontSize: 12, color: fg),
      ),
    );
  }
}
