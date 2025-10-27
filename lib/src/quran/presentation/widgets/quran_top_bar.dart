part of '/quran.dart';

class _QuranTopBar extends StatelessWidget {
  final String languageCode;
  final bool isDark;
  final SurahAudioStyle? style;
  final bool? isFontsLocal;
  final DownloadFontsDialogStyle? downloadFontsDialogStyle;
  final Color? backgroundColor;
  final QuranTopBarStyle? topBarStyle;

  const _QuranTopBar(
    this.languageCode,
    this.isDark, {
    this.style,
    this.isFontsLocal,
    this.downloadFontsDialogStyle,
    this.backgroundColor,
    this.topBarStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Centralized theming
    final QuranTopBarStyle defaults =
        topBarStyle ?? QuranTopBarStyle.defaults(isDark: isDark);
    final Color textColor =
        (defaults.textColor ?? AppColors.getTextColor(isDark));
    final Color bgColor = backgroundColor ??
        (defaults.backgroundColor ?? AppColors.getBackgroundColor(isDark));
    final Color accentColor = defaults.accentColor ?? Colors.teal;
    final Color linearBg = accentColor is MaterialColor
        ? accentColor.shade100
        : accentColor.withValues(alpha: 0.15);

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: defaults.height ?? 55,
        padding:
            defaults.padding ?? const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(defaults.borderRadius ?? 12),
          boxShadow: [
            BoxShadow(
              color:
                  (defaults.shadowColor ?? Colors.black.withValues(alpha: .2)),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 5), // changes position of shadow
            ),
          ],
        ),
        child: Row(
          children: [
            if (defaults.showBackButton ?? false)
              IconButton(
                icon: SvgPicture.asset(
                    defaults.backIconPath ?? AssetsPath.assets.backArrow,
                    height: defaults.iconSize,
                    colorFilter: ColorFilter.mode(
                        defaults.iconColor ?? Colors.teal, BlendMode.srcIn)),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            if (defaults.showMenuButton ?? true)
              IconButton(
                icon: SvgPicture.asset(
                    defaults.menuIconPath ?? AssetsPath.assets.buttomSheet,
                    height: defaults.iconSize,
                    colorFilter: ColorFilter.mode(
                        defaults.iconColor ?? Colors.teal, BlendMode.srcIn)),
                onPressed: () {
                  _showMenuBottomSheet(context, defaults);
                },
              ),
            const Spacer(),
            Row(
              children: [
                if (defaults.showAudioButton ?? true)
                  IconButton(
                    icon: SvgPicture.asset(
                        defaults.audioIconPath ?? AssetsPath.assets.surahsAudio,
                        height: defaults.iconSize,
                        colorFilter: ColorFilter.mode(
                            defaults.iconColor ?? Colors.teal,
                            BlendMode.srcIn)),
                    onPressed: () async {
                      await AudioCtrl.instance.state.audioPlayer.stop();
                      await AudioCtrl.instance.lastAudioSource();
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SurahAudioScreen(
                              isDark: isDark,
                              style: style,
                              languageCode: languageCode,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                if (defaults.showFontsButton ?? true)
                  FontsDownloadDialog(
                    downloadFontsDialogStyle: downloadFontsDialogStyle ??
                        DownloadFontsDialogStyle(
                          title: defaults.fontsDialogTitle ?? 'الخطوط',
                          titleColor: textColor,
                          notes: defaults.fontsDialogNotes ??
                              'لجعل مظهر المصحف مشابه لمصحف المدينة يمكنك تحميل خطوط المصحف',
                          notesColor: textColor,
                          linearProgressBackgroundColor: linearBg,
                          linearProgressColor: accentColor,
                          downloadButtonBackgroundColor: accentColor,
                          downloadingText:
                              defaults.fontsDialogDownloadingText ??
                                  'جارِ التحميل',
                          backgroundColor: isDark
                              ? const Color(0xff1E1E1E)
                              : const Color(0xFFF7EFE0),
                        ),
                    languageCode: languageCode,
                    isFontsLocal: isFontsLocal,
                    isDark: isDark,
                  )
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showMenuBottomSheet(BuildContext context, QuranTopBarStyle defaults) {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor ??
          defaults.backgroundColor ??
          AppColors.getBackgroundColor(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(defaults.borderRadius ?? 20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => _MenuBottomSheet(
        isDark: isDark,
        languageCode: languageCode,
        backgroundColor: backgroundColor,
        style: defaults,
      ),
    );
  }
}

// BottomSheet container with main TabBar
class _MenuBottomSheet extends StatelessWidget {
  final bool isDark;
  final String languageCode;
  final Color? backgroundColor;
  final QuranTopBarStyle style;

  const _MenuBottomSheet({
    required this.isDark,
    required this.languageCode,
    this.backgroundColor,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = style.textColor ?? AppColors.getTextColor(isDark);
    final Color accentColor = style.accentColor ?? Colors.teal;

    return DefaultTabController(
      length: 3,
      child: SafeArea(
        top: false,
        child: Container(
          height: UiHelper.currentOrientation(
              MediaQuery.of(context).size.height * 0.8,
              MediaQuery.of(context).size.height * .9,
              context),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Drag handle + header
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color:
                      (style.handleColor ?? textColor.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  padding: EdgeInsets.zero,
                  labelColor: Colors.white,
                  unselectedLabelColor: textColor.withValues(alpha: 0.6),
                  indicatorColor: accentColor,
                  indicatorWeight: .5,
                  labelStyle: QuranLibrary().cairoStyle.copyWith(
                      fontSize: 15, fontWeight: FontWeight.w700, height: 1.3),
                  unselectedLabelStyle:
                      QuranLibrary().cairoStyle.copyWith(fontSize: 15),
                  tabs: [
                    Tab(text: style.tabIndexLabel ?? 'الفهرس'),
                    Tab(text: style.tabSearchLabel ?? 'البحث'),
                    Tab(text: style.tabBookmarksLabel ?? 'الفواصل'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: TabBarView(
                  children: [
                    _IndexTab(
                        isDark: isDark,
                        languageCode: languageCode,
                        style: style),
                    _SearchTab(isDark: isDark, languageCode: languageCode),
                    _BookmarksTab(isDark: isDark, languageCode: languageCode),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndexTab extends StatelessWidget {
  final bool isDark;
  final String languageCode;
  final QuranTopBarStyle style;
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
            height: 35,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              padding: EdgeInsets.zero,
              labelColor: Colors.white,
              unselectedLabelColor: textColor.withValues(alpha: 0.6),
              indicatorColor: accentColor,
              indicatorWeight: .5,
              labelStyle: QuranLibrary().cairoStyle.copyWith(
                  fontSize: 13, fontWeight: FontWeight.w700, height: 1.3),
              unselectedLabelStyle:
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
                    isDark: isDark, languageCode: languageCode, surahs: surahs),
                _JozzList(
                    isDark: isDark, jozzList: jozzList, hizbList: hizbList),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SearchTab extends StatelessWidget {
  final bool isDark;
  final String languageCode;
  const _SearchTab({required this.isDark, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppColors.getTextColor(isDark);
    const Color accentColor = Colors.teal;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Search TextField
            GetBuilder<QuranCtrl>(
              builder: (quranCtrl) => TextField(
                onChanged: (txt) {
                  if (txt.isEmpty) {
                    quranCtrl.searchResultAyahs.value = [];
                    quranCtrl.searchResultSurahs.value = [];
                    return;
                  }
                  final ayahResults = QuranLibrary().search(txt);
                  quranCtrl.searchResultAyahs.value = [...ayahResults];
                  final surahResults = QuranLibrary().surahSearch(txt);
                  quranCtrl.searchResultSurahs.value = [...surahResults];
                },
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  fillColor: accentColor.withValues(alpha: 0.1),
                  filled: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  suffixIcon: Icon(Icons.search,
                      color: textColor.withValues(alpha: 0.6)),
                  hintText: 'بحث في القرآن',
                  hintStyle: QuranLibrary().cairoStyle.copyWith(
                      color: textColor.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: textColor.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: textColor.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: textColor.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Surah chips row
            Obx(() {
              final quranCtrl = QuranCtrl.instance;
              if (quranCtrl.searchResultSurahs.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 64,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: quranCtrl.searchResultSurahs.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final search = quranCtrl.searchResultSurahs[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          Navigator.pop(context);
                          quranCtrl.searchResultSurahs.value = [];
                          // if (quranCtrl.isDownloadFonts) {
                          //   await quranCtrl.prepareFonts(search.startPage!);
                          // }
                          QuranLibrary().jumpToSurah(search.surahNumber);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4.0, vertical: 10.0),
                          decoration: const BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Text(
                            search.surahNumber.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'surahName',
                              fontSize: 28,
                              package: 'quran_library',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 8),
            // Ayah results list
            Expanded(
              child: GetX<QuranCtrl>(
                builder: (quranCtrl) => ListView.separated(
                  itemCount: quranCtrl.searchResultAyahs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.grey, thickness: 1),
                  itemBuilder: (context, i) {
                    final ayah = quranCtrl.searchResultAyahs[i];
                    return ListTile(
                      title: GetSingleAyah(
                        surahNumber: ayah.surahNumber!,
                        ayahNumber: ayah.ayahNumber,
                        isBold: false,
                        fontSize: 20,
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            ayah.arabicName ?? '',
                            style: TextStyle(
                                color: textColor.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'صفحة: ${ayah.page.toString().convertNumbersAccordingToLang(languageCode: languageCode)}',
                            style: TextStyle(
                                color: textColor.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      onTap: () async {
                        Navigator.pop(context);
                        quranCtrl.searchResultAyahs.value = [];
                        // if (quranCtrl.isDownloadFonts) {
                        //   await quranCtrl.prepareFonts(ayah.page);
                        // }
                        QuranLibrary().jumpToAyah(ayah.page, ayah.ayahUQNumber);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _SurahsList extends StatelessWidget {
  final bool isDark;
  final String languageCode;
  final List<String> surahs;
  const _SurahsList(
      {required this.isDark, required this.languageCode, required this.surahs});

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppColors.getTextColor(isDark);
    const Color accentColor = Colors.teal;
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
                  ? accentColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
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
  const _JozzList(
      {required this.isDark, required this.jozzList, required this.hizbList});

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppColors.getTextColor(isDark);
    const Color accentColor = Colors.teal;
    return ListView.builder(
      itemCount: jozzList.length,
      itemBuilder: (context, jozzIndex) => Container(
        margin: const EdgeInsets.symmetric(vertical: 2.0),
        decoration: BoxDecoration(
          color: jozzIndex.isEven
              ? accentColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ExpansionTile(
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: textColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
                        ? accentColor.withValues(alpha: 0.05)
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
