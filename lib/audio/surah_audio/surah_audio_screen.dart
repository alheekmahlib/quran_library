part of '../audio.dart';

class SurahAudioScreen extends StatelessWidget {
  final SurahAudioStyle? style;
  final bool? isDark;

  const SurahAudioScreen({super.key, this.style, this.isDark});

  @override
  Widget build(BuildContext context) {
    final surahCtrl = AudioCtrl.instance;
    surahCtrl.loadSurahReader();
    surahCtrl.loadLastSurahListen;
    return Scaffold(
      backgroundColor: const Color(0xfffaf7f3),
      appBar: AppBar(
        title: Text('الإستماع للسور',
            style: TextStyle(color: style?.textColor ?? Colors.black)),
        backgroundColor: style?.backgroundColor ?? const Color(0xfffaf7f3),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SlidingPanel(
          controller: surahCtrl.state.panelController,
          config: SlidingPanelConfig(
            anchorPosition: 100,
            expandPosition: MediaQuery.sizeOf(context).height * .5,
          ),
          pageContent: BackDropWidget(style: style, isDark: isDark),
          panelContent: Obx(() => !surahCtrl.state.isSheetOpen.value
              ? CollapsedPlayWidget(style: style)
              : PlayWidget(style: style)),
        ),
      ),
    );
  }

  // @override
  bool get wantKeepAlive => true;
}
