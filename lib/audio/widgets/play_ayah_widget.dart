part of '../audio.dart';

class PlayAyah extends StatelessWidget {
  final AyahAudioStyle? style;
  const PlayAyah({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final audioCtrl = AudioCtrl.instance;
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
                LottieConstants.get(LottieConstants.assetsLottiePlayButton),
                width: 20.0,
                height: 20.0);
          } else if (playerState != null && !playerState.playing) {
            return GestureDetector(
              child: CustomWidgets.customSvgWithColor(
                style?.playIconPath ?? AssetsPath.assets.playArrow,
                height: style?.playIconHeight ?? 25,
                ctx: context,
                color: style?.playIconColor ?? (Colors.blue),
              ),
              onTap: () async {
                QuranCtrl.instance.selectedAyahsByUnequeNumber.isNotEmpty
                    ? audioCtrl.state.isDirectPlaying.value = false
                    : audioCtrl.state.isDirectPlaying.value = true;
                QuranCtrl.instance.state.isPlayExpanded.value = true;
                audioCtrl.playAyah(
                    context, audioCtrl.state.currentAyahUniqueNumber,
                    playSingleAyah: true);
              },
            );
          }
          return GestureDetector(
            child: CustomWidgets.customSvgWithColor(
              style?.pauseIconPath ?? AssetsPath.assets.pauseArrow,
              height: style?.pauseIconHeight ?? 25,
              ctx: context,
              color: style?.playIconColor ?? (Colors.blue),
            ),
            onTap: () {
              QuranCtrl.instance.state.isPlayExpanded.value = true;
              audioCtrl.pausePlayer();
            },
          );
        },
      ),
    );
  }
}
