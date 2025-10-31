part of '/quran.dart';

class _IndexTab extends StatelessWidget {
  final bool isDark;
  final String languageCode;
  final IndexTabStyle style;
  const _IndexTab(
      {required this.isDark, required this.languageCode, required this.style});

  @override
  Widget build(BuildContext context) {
    final jozzList = QuranLibrary.allJoz;
    final hizbList = QuranLibrary.allHizb;
    final surahs = QuranLibrary.getAllSurahs(isArabic: false);

    final Color textColor = style.textColor ?? AppColors.getTextColor(isDark);
    final Color accentColor = style.accentColor ?? Colors.teal;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            height: style.tabBarHeight ?? 35,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: style.tabBarBgAlpha ?? 0.06),
              borderRadius:
                  BorderRadius.circular((style.tabBarRadius ?? 12).toDouble()),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(
                    (style.indicatorRadius ?? 10).toDouble()),
              ),
              indicatorPadding:
                  style.indicatorPadding ?? const EdgeInsets.all(4),
              padding: EdgeInsets.zero,
              labelColor: style.labelColor ?? Colors.white,
              unselectedLabelColor: style.unselectedLabelColor ??
                  textColor.withValues(alpha: 0.6),
              indicatorColor: accentColor,
              indicatorWeight: .5,
              labelStyle: style.labelStyle ??
                  QuranLibrary().cairoStyle.copyWith(
                      fontSize: 13, fontWeight: FontWeight.w700, height: 1.3),
              unselectedLabelStyle: style.unselectedLabelStyle ??
                  QuranLibrary().cairoStyle.copyWith(fontSize: 13),
              tabs: [
                Tab(text: style.tabSurahsLabel ?? 'السور'),
                Tab(text: style.tabJozzLabel ?? 'الأجزاء'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: [
                _SurahsList(
                    isDark: isDark,
                    languageCode: languageCode,
                    surahs: surahs,
                    style: style),
                _JozzList(
                    isDark: isDark,
                    jozzList: jozzList,
                    hizbList: hizbList,
                    style: style),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SurahsList extends StatelessWidget {
  final bool isDark;
  final String languageCode;
  final List<String> surahs;
  final IndexTabStyle style;
  const _SurahsList(
      {required this.isDark,
      required this.languageCode,
      required this.surahs,
      required this.style});

  @override
  Widget build(BuildContext context) {
    final Color textColor = style.textColor ?? AppColors.getTextColor(isDark);
    final Color accentColor = style.accentColor ?? Colors.teal;
    return ListView.builder(
      itemCount: surahs.length,
      itemBuilder: (context, index) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            QuranLibrary().jumpToSurah(index + 1);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            margin: const EdgeInsets.symmetric(vertical: 2.0),
            decoration: BoxDecoration(
              color: index.isEven
                  ? accentColor.withValues(
                      alpha: (style.surahRowAltBgAlpha ?? 0.1))
                  : Colors.transparent,
              borderRadius:
                  BorderRadius.circular((style.listItemRadius ?? 8).toDouble()),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      AssetsPath.assets.suraNum,
                      width: 40,
                      height: 40,
                      colorFilter: ColorFilter.mode(
                        textColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    Text(
                      '${index + 1}'.convertNumbersAccordingToLang(
                          languageCode: languageCode),
                      style: QuranLibrary()
                          .cairoStyle
                          .copyWith(fontSize: 14, color: textColor),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      (index + 1).toString(),
                      style: TextStyle(
                        color: textColor,
                        fontFamily: "surahName",
                        fontSize: 32,
                        package: "quran_library",
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      surahs[index],
                      style: QuranLibrary().cairoStyle.copyWith(
                          fontSize: 14, color: textColor, height: 1.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JozzList extends StatelessWidget {
  final bool isDark;
  final List<String> jozzList;
  final List<String> hizbList;
  final IndexTabStyle style;
  const _JozzList(
      {required this.isDark,
      required this.jozzList,
      required this.hizbList,
      required this.style});

  @override
  Widget build(BuildContext context) {
    final Color textColor = style.textColor ?? AppColors.getTextColor(isDark);
    final Color accentColor = style.accentColor ?? Colors.teal;
    return ListView.builder(
      itemCount: jozzList.length,
      itemBuilder: (context, jozzIndex) => Container(
        margin: const EdgeInsets.symmetric(vertical: 2.0),
        decoration: BoxDecoration(
          color: jozzIndex.isEven
              ? accentColor.withValues(alpha: (style.jozzAltBgAlpha ?? 0.1))
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular((style.listItemRadius ?? 8).toDouble()),
        ),
        child: ExpansionTile(
          collapsedShape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular((style.listItemRadius ?? 8).toDouble()),
            side: BorderSide(
              color: textColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular((style.listItemRadius ?? 8).toDouble()),
            side: BorderSide(
              color: textColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          title: Text(
            jozzList[jozzIndex],
            style: QuranLibrary().cairoStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
          ),
          children: List.generate(2, (index) {
            final hizbIndex =
                (index == 0 && jozzIndex == 0) ? 0 : ((jozzIndex * 2 + index));
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  Navigator.pop(context);
                  QuranLibrary().jumpToHizb(hizbIndex + 1);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? accentColor.withValues(
                            alpha: (style.hizbItemAltBgAlpha ?? 0.05))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    hizbList[hizbIndex],
                    style: QuranLibrary().cairoStyle.copyWith(
                          color: textColor,
                        ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
