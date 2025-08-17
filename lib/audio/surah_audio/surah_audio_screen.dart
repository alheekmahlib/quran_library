part of '../audio.dart';

class SurahAudioScreen extends StatelessWidget {
  final SurahAudioStyle? style;
  final bool? isDark;

  const SurahAudioScreen({super.key, this.style, this.isDark});

  @override
  Widget build(BuildContext context) {
    final surahCtrl = AudioCtrl.instance;
    surahCtrl.sheetState();
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
            expandPosition: MediaQuery.sizeOf(context).height * .6,
          ),
          pageContent: SurahBackDropWidget(style: style, isDark: isDark),
          panelContent: Obx(() => !surahCtrl.state.isSheetOpen.value
              ? SurahCollapsedPlayWidget(style: style)
              : PlaySurahsWidget(style: style)),
        ),
      ),
    );
  }

  // @override
  bool get wantKeepAlive => true;
}
