import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '/core/constants/lottie_constants.dart';
import '/core/constants/svg_paths.dart';
import '/core/utils/custom_widgets.dart';
import '/quran.dart';

class PlayAyah extends StatelessWidget {
  const PlayAyah({super.key});

  @override
  Widget build(BuildContext context) {
    final audioCtrl = SurahAudioController.instance;
    return SizedBox(
      width: 28,
      height: 28,
      child: StreamBuilder<PlayerState>(
        stream: audioCtrl.state.audioPlayer.playerStateStream,
        builder: (context, snapshot) {
          final playerState = snapshot.data;
          final processingState = playerState?.processingState;
          if (processingState == ProcessingState.loading ||
              processingState == ProcessingState.buffering ||
              (audioCtrl.state.isDownloading.value &&
                  audioCtrl.state.progress.value == 0)) {
            return CustomWidgets.customLottie(
                LottieConstants.assetsLottiePlayButton,
                width: 20.0,
                height: 20.0);
          } else if (playerState != null && !playerState.playing) {
            return GestureDetector(
              child: CustomWidgets.customSvgWithColor(
                SvgPath.svgPlayArrow,
                height: 25,
                ctx: context,
              ),
              onTap: () async {
                QuranCtrl.instance.selectedAyahsByUnequeNumber.isNotEmpty
                    ? audioCtrl.state.isDirectPlaying.value = false
                    : audioCtrl.state.isDirectPlaying.value = true;
                QuranCtrl.instance.state.isPlayExpanded.value = true;
                audioCtrl.playAyah(context);
              },
            );
          }
          return GestureDetector(
            child: CustomWidgets.customSvgWithColor(
              SvgPath.svgPauseArrow,
              height: 25,
              ctx: context,
            ),
            onTap: () {
              QuranCtrl.instance.state.isPlayExpanded.value = true;
              audioCtrl.playAyah(context);
            },
          );
        },
      ),
    );
  }
}
