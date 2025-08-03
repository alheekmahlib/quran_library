import 'package:flutter/material.dart';
import 'package:flutter_sliding_box/flutter_sliding_box.dart';

import '/core/utils/ui_helper.dart';
import '../surah_audio/controller/extensions/surah_audio_storage_getters.dart';
import '../surah_audio/controller/surah_audio_controller.dart';
import '../surah_audio/widgets/back_drop_widget.dart';
import '../surah_audio/widgets/collapsed_play_widget.dart';
import '../surah_audio/widgets/play_widget.dart';

class SurahAudioScreen extends StatelessWidget {
  const SurahAudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final surahCtrl = SurahAudioController.instance;
    surahCtrl.loadSurahReader();
    surahCtrl.loadLastSurahListen;
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: SlidingBox(
          controller: surahCtrl.state.boxController,
          minHeight: 80,
          maxHeight: 290,
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 250),
          draggableIconVisible: false,
          collapsed: true,
          backdrop: Backdrop(
            fading: false,
            overlay: false,
            color: Theme.of(context).colorScheme.primaryContainer,
            body: const BackDropWidget(),
          ),
          width:
              UiHelper.customOrientation(size.width, size.width * 0.5, context),
          collapsedBody: const CollapsedPlayWidget(),
          body: PlayWidget(),
        ),
      ),
    );
  }

  // @override
  bool get wantKeepAlive => true;
}
