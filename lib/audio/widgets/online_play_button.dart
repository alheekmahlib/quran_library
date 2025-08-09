part of '../audio.dart';

class OnlinePlayButton extends StatelessWidget {
  const OnlinePlayButton({super.key});

  @override
  Widget build(BuildContext context) {
    final surahAudioCtrl = AudioCtrl.instance;
    return SizedBox(
      height: 50,
      child: Align(
        alignment: Alignment.center,
        child: StreamBuilder<PlayerState>(
          stream: surahAudioCtrl.state.audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            if (processingState == ProcessingState.buffering) {
              return CustomWidgets.customLottie(
                  LottieConstants.get(LottieConstants.assetsLottiePlayButton),
                  width: 20.0,
                  height: 20.0);
            } else if (playerState != null && !playerState.playing) {
              return GestureDetector(
                child: CustomWidgets.customSvgWithColor(
                  AssetsPath.assets.playArrow,
                  height: 30,
                  ctx: context,
                  color: Colors.blue,
                ),
                onTap: () async {
                  surahAudioCtrl.cancelDownload();
                  surahAudioCtrl.state.isPlaying.value = true;
                  // await surahAudioCtrl.state.audioPlayer.pause();
                  surahAudioCtrl.state.surahDownloadStatus.value[surahAudioCtrl
                              .state.currentAudioListSurahNum.value] ??
                          false
                      ? await surahAudioCtrl.startDownload()
                      : await surahAudioCtrl.state.audioPlayer.play();
                },
              );
            } else if (processingState != ProcessingState.completed ||
                !playerState!.playing) {
              return GestureDetector(
                child: CustomWidgets.customSvgWithColor(
                  AssetsPath.assets.pauseArrow,
                  height: 30,
                  ctx: context,
                  color: Colors.blue,
                ),
                onTap: () {
                  surahAudioCtrl.state.isPlaying.value = false;
                  surahAudioCtrl.state.audioPlayer.pause();
                },
              );
            } else {
              return IconButton(
                icon: Semantics(
                    button: true,
                    enabled: true,
                    label: 'replaySurah'.tr,
                    child: Icon(
                      Icons.replay,
                      color: Colors.blue,
                    )),
                iconSize: 24.0,
                color: Theme.of(context).canvasColor,
                onPressed: () => surahAudioCtrl.state.audioPlayer.seek(
                    Duration.zero,
                    index: surahAudioCtrl
                        .state.audioPlayer.effectiveIndices.first),
              );
            }
          },
        ),
      ),
    );
  }
}
