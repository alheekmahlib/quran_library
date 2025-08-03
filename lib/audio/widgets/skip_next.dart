import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' show SequenceState;
import '../surah_audio/controller/surah_audio_controller.dart';

class SkipToNext extends StatelessWidget {
  SkipToNext({super.key});
  final audioCtrl = SurahAudioController.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SequenceState?>(
      stream: audioCtrl.state.audioPlayer.sequenceStateStream,
      builder: (context, snapshot) => GestureDetector(
        child: Semantics(
          button: true,
          enabled: true,
          label: 'next'.tr,
          child: Icon(
            Icons.skip_previous,
            color: Theme.of(context).colorScheme.primary,
            size: 30,
          ),
        ),
        onTap: () async {
          await audioCtrl.skipNextAyah();
        },
      ),
    );
  }
}
