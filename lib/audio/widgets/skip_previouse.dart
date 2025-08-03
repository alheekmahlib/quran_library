import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '../surah_audio/controller/surah_audio_controller.dart';

class SkipToPrevious extends StatelessWidget {
  const SkipToPrevious({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SequenceState?>(
      stream:
          SurahAudioController.instance.state.audioPlayer.sequenceStateStream,
      builder: (context, snapshot) => IconButton(
        icon: Semantics(
          button: true,
          enabled: true,
          label: 'skipToPrevious'.tr,
          child: Icon(
            Icons.skip_next,
            color: Theme.of(context).colorScheme.primary,
            size: 30,
          ),
        ),
        onPressed: SurahAudioController
                    .instance.state.currentAudioListSurahNum.value ==
                1
            ? null
            : () {
                SurahAudioController.instance.playPreviousSurah();
              },
      ),
    );
  }
}
