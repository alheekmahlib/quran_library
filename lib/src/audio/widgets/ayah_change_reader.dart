part of '../audio.dart';

class AyahChangeReader extends StatelessWidget {
  final AyahAudioStyle? style;
  final AyahDownloadManagerStyle? downloadManagerStyle;
  final bool? isDark;
  const AyahChangeReader(
      {super.key, this.style, this.downloadManagerStyle, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final AyahAudioStyle effectiveStyle = style ?? AyahAudioStyle();
    final bool dark = isDark ?? false;

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: effectiveStyle.dialogBackgroundColor ??
              AppColors.getBackgroundColor(dark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                effectiveStyle.dialogBorderRadius ?? 12.0),
          ),
          alignment: Alignment.center,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          constraints: BoxConstraints(
            maxHeight: effectiveStyle.dialogHeight ??
                MediaQuery.of(context).size.height * 0.7,
            maxWidth:
                effectiveStyle.dialogWidth ?? MediaQuery.of(context).size.width,
          ),
          child: _buildDialog(context, effectiveStyle, dark),
        ),
      ),
      child: _buildTitle(effectiveStyle, dark),
    );
  }

  Widget _buildDialog(
      BuildContext context, AyahAudioStyle effectiveStyle, bool dark) {
    final Color activeColor = effectiveStyle.dialogSelectedReaderColor ??
        Colors.teal.withValues(alpha: 0.05);
    final Color inactiveColor = effectiveStyle.dialogUnSelectedReaderColor ??
        AppColors.getTextColor(dark);
    final double itemFontSize = effectiveStyle.readerNameInItemFontSize ?? 14;
    final Color textColor =
        effectiveStyle.dialogReaderTextColor ?? AppColors.getTextColor(dark);

    final int selectedIndex = AudioCtrl.instance.state.ayahReaderIndex.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: HeaderDialogWidget(
            title: 'تغيير القارئ',
            isDark: dark,
            backgroundGradient: effectiveStyle.dialogHeaderBackgroundGradient,
            closeIconColor: effectiveStyle.dialogCloseIconColor,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),
        // List
        Flexible(
          child: DefaultTabController(
            length: !kIsWeb ? 2 : 1,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TabBar(
                    indicatorColor:
                        effectiveStyle.dialogSelectedReaderColor ?? Colors.teal,
                    labelColor:
                        effectiveStyle.dialogSelectedReaderColor ?? Colors.teal,
                    unselectedLabelColor:
                        effectiveStyle.dialogUnSelectedReaderColor ??
                            AppColors.getTextColor(dark),
                    labelStyle: QuranLibrary().cairoStyle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                    tabs: const [
                      Tab(text: 'القراء'),
                      if (!kIsWeb) Tab(text: 'السور المحملة'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ReaderListBuild(
                        selectedIndex: selectedIndex,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        textColor: textColor,
                        itemFontSize: itemFontSize,
                        dark: dark,
                        effectiveStyle: effectiveStyle,
                      ),
                      if (!kIsWeb)
                        AyahDownloadManagerSheet(
                          isInChangeReaderDialog: true,
                          onRequestDownload: (surahNum) async {
                            if (AudioCtrl.instance.state.isDownloading.value) {
                              return;
                            }
                            await AudioCtrl.instance.startDownloadAyahSurah(
                                surahNum,
                                context: context);
                          },
                          onRequestDelete: (surahNum) async {
                            await AudioCtrl.instance
                                .deleteAyahSurahDownloads(surahNum);
                          },
                          isSurahDownloadedChecker: (surahNum) => AudioCtrl
                              .instance
                              .isAyahSurahFullyDownloaded(surahNum),
                          initialSurahToFocus:
                              AudioCtrl.instance.currentSurahNumber,
                          style: downloadManagerStyle ??
                              AyahDownloadManagerStyle.defaults(
                                  isDark: dark, context: context),
                          isDark: isDark,
                          ayahStyle: style,
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(AyahAudioStyle effectiveStyle, bool dark) {
    final Color textColor =
        effectiveStyle.textColor ?? AppColors.getTextColor(dark);
    final double fontSize = effectiveStyle.readerNameFontSize ?? 16;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(
          () => Text(
            '${ReadersConstants.ayahReaderInfo[AudioCtrl.instance.state.ayahReaderIndex.value]['name']}'
                .tr,
            style: QuranLibrary().cairoStyle.copyWith(
                  color: textColor,
                  fontSize: fontSize,
                ),
          ),
        ),
        const SizedBox(width: 4),
        Semantics(
          button: true,
          enabled: true,
          label: 'Change Reader'.tr,
          child: Icon(
            Icons.keyboard_arrow_down_outlined,
            size: fontSize.clamp(16, 20),
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class ReaderListBuild extends StatelessWidget {
  const ReaderListBuild({
    super.key,
    required this.selectedIndex,
    required this.activeColor,
    required this.inactiveColor,
    required this.textColor,
    required this.itemFontSize,
    required this.dark,
    required this.effectiveStyle,
  });

  final int selectedIndex;
  final Color activeColor;
  final Color inactiveColor;
  final Color textColor;
  final double itemFontSize;
  final bool dark;
  final AyahAudioStyle effectiveStyle;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: ReadersConstants.ayahReaderInfo.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: AppColors.getTextColor(dark).withValues(alpha: 0.08),
      ),
      itemBuilder: (context, index) {
        final info = ReadersConstants.ayahReaderInfo[index];
        final bool isSelected = selectedIndex == info['index'];
        final Color itemColor = isSelected ? activeColor : inactiveColor;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0),
          child: ListTile(
            minTileHeight: 44,
            dense: true,
            focusColor: itemColor.withValues(alpha: 0.12),
            splashColor: itemColor.withValues(alpha: 0.12),
            selectedColor: itemColor,
            selectedTileColor: itemColor.withValues(alpha: 0.12),
            tileColor: itemColor.withValues(alpha: 0.07),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text(
              '${info['name']}'.tr,
              style: QuranLibrary().cairoStyle.copyWith(
                    color: textColor,
                    fontSize: itemFontSize,
                  ),
            ),
            trailing: _SelectionIndicator(
                isSelected: isSelected,
                color: effectiveStyle.dialogSelectedReaderColor ?? Colors.teal),
            onTap: () async =>
                await AudioCtrl.instance.changeAyahReadersOnTap(context, index),
          ),
        );
      },
    );
  }
}
