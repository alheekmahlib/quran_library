part of '../audio.dart';

class SurahAudioScreen extends StatelessWidget {
  final SurahAudioStyle? style;
  final bool? isDark;
  final String? languageCode;

  const SurahAudioScreen(
      {super.key, this.style, this.isDark, this.languageCode = 'ar'});

  @override
  Widget build(BuildContext context) {
    final surahCtrl = AudioCtrl.instance;
    final bool dark = isDark ?? Theme.of(context).brightness == Brightness.dark;

    final background =
        style?.backgroundColor ?? AppColors.getBackgroundColor(dark);
    final textColor = style?.textColor ?? AppColors.getTextColor(dark);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          'الإستماع للسور',
          style: QuranLibrary().cairoStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
        ),
        backgroundColor: background,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor, size: 22),
      ),
      body: SafeArea(
        child: SlidingPanel(
          controller: surahCtrl.state.panelController,
          config: SlidingPanelConfig(
            anchorPosition: 100,
            expandPosition: MediaQuery.sizeOf(context).height * .6,
          ),
          pageContent: SurahBackDropWidget(
              style: style, isDark: dark, languageCode: languageCode),
          //! FIXME: Adjust the panel position in horizontal orientation when the interface language is set to Arabic
          panelContent: Obx(
            () => !surahCtrl.state.isSheetOpen.value
                ? SurahCollapsedPlayWidget(
                    style: style, isDark: dark, languageCode: languageCode)
                : PlaySurahsWidget(
                    style: style, isDark: dark, languageCode: languageCode),
          ),
        ),
      ),
    );
  }
}
