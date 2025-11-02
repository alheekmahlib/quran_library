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
    // استخدام نمط موحد افتراضي إذا لم يُمرر
    final s = style ?? SurahAudioStyle.defaults(isDark: dark, context: context);

    final background = s.backgroundColor ?? AppColors.getBackgroundColor(dark);
    final textColor = s.textColor ?? AppColors.getTextColor(dark);
    final size = MediaQuery.sizeOf(context);

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
        child: UiHelper.currentOrientation(
            PortraitWidget(
                surahCtrl: surahCtrl,
                size: size,
                style: s,
                dark: dark,
                languageCode: languageCode),
            SurahBackDropWidget(
                style: s, isDark: dark, languageCode: languageCode),
            context),
      ),
    );
  }
}

class PortraitWidget extends StatelessWidget {
  const PortraitWidget({
    super.key,
    required this.surahCtrl,
    required this.size,
    required this.style,
    required this.dark,
    required this.languageCode,
  });

  final AudioCtrl surahCtrl;
  final Size size;
  final SurahAudioStyle? style;
  final bool dark;
  final String? languageCode;

  @override
  Widget build(BuildContext context) {
    return SlidingPanel(
      controller: surahCtrl.state.panelController,
      config: SlidingPanelConfig(
        anchorPosition: 100,
        expandPosition: UiHelper.currentOrientation(
            size.height * .7, size.height * .8, context),
      ),
      pageContent: SurahBackDropWidget(
          style: style, isDark: dark, languageCode: languageCode),
      panelContent: Obx(
        () => !surahCtrl.state.isSheetOpen.value
            ? SurahCollapsedPlayWidget(
                style: style, isDark: dark, languageCode: languageCode)
            : PlaySurahsWidget(
                style: style, isDark: dark, languageCode: languageCode),
      ),
    );
  }
}
