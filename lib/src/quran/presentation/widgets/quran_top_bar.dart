part of '/quran.dart';

class _QuranTopBar extends StatelessWidget {
  final String languageCode;
  final bool isDark;
  final SurahAudioStyle? style;
  final bool? isFontsLocal;
  final DownloadFontsDialogStyle? downloadFontsDialogStyle;
  final Color? backgroundColor;
  final QuranTopBarStyle? topBarStyle;
  final IndexTabStyle? indexTabStyle;
  final SearchTabStyle? searchTabStyle;

  const _QuranTopBar(
    this.languageCode,
    this.isDark, {
    this.style,
    this.isFontsLocal,
    this.downloadFontsDialogStyle,
    this.backgroundColor,
    this.topBarStyle,
    this.indexTabStyle,
    this.searchTabStyle,
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
                  QuranCtrl.instance.searchFocusNode.requestFocus();
                  _showMenuBottomSheet(
                      context, defaults, indexTabStyle, searchTabStyle);
                },
              ),
            const Spacer(),
            if (defaults.customTopBarWidgets != null)
              ...defaults.customTopBarWidgets!,
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
                      // await AudioCtrl.instance.lastAudioSource();
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

  void _showMenuBottomSheet(BuildContext context, QuranTopBarStyle defaults,
      IndexTabStyle? indexTabStyle, SearchTabStyle? searchTabStyle) {
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
      constraints: BoxConstraints(
        maxWidth: UiHelper.currentOrientation(
            double.infinity, MediaQuery.sizeOf(context).width * 0.5, context),
      ),
      builder: (ctx) => _MenuBottomSheet(
        isDark: isDark,
        languageCode: languageCode,
        backgroundColor: backgroundColor,
        style: defaults,
        indexTabStyle: indexTabStyle,
        searchTabStyle: searchTabStyle,
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
  final IndexTabStyle? indexTabStyle;
  final SearchTabStyle? searchTabStyle;

  const _MenuBottomSheet({
    required this.isDark,
    required this.languageCode,
    this.backgroundColor,
    required this.style,
    required this.indexTabStyle,
    this.searchTabStyle,
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
                        style: indexTabStyle ??
                            IndexTabStyle.defaults(
                              isDark: isDark,
                              context: context,
                            )),
                    _SearchTab(
                      isDark: isDark,
                      languageCode: languageCode,
                      style: searchTabStyle ??
                          SearchTabStyle.defaults(
                            isDark: isDark,
                            context: context,
                          ),
                    ),
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
