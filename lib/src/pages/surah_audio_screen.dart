part of '../audio/audio.dart';

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

    surahCtrl.loadLastSurahAndPosition();
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            if (s.withAppBar ?? true)
              AppBarWidget(background: background, s: s, textColor: textColor),
            Expanded(
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
          ],
        ),
      ),
    );
  }
}

class AppBarWidget extends StatelessWidget {
  const AppBarWidget({
    super.key,
    required this.background,
    required this.s,
    required this.textColor,
  });

  final Color background;
  final SurahAudioStyle s;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(s.borderRadius ?? 16),
          bottomRight: Radius.circular(s.borderRadius ?? 16),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional.bottomStart,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_outlined,
                color: s.backIconColor,
              ),
              color: s.backIconColor ?? textColor,
              iconSize: 24,
            ),
          ),
          Text(
            'الإستماع للسور',
            style: QuranLibrary().cairoStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.7,
                ),
          ),
        ],
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
