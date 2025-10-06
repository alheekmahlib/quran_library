part of '../../audio.dart';

class SurahOnlinePlayButton extends StatelessWidget {
  final SurahAudioStyle? style;
  const SurahOnlinePlayButton({super.key, this.style});

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
              return SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ));
            } else if (playerState != null && !playerState.playing) {
              return IconButton(
                icon: CustomWidgets.customSvgWithColor(
                  style?.playIconPath ?? AssetsPath.assets.playArrow,
                  height: style?.playIconHeight ?? 30,
                  ctx: context,
                  color: style?.playIconColor ?? Colors.teal,
                ),
                onPressed: () async {
                  surahAudioCtrl.cancelDownload();
                  surahAudioCtrl.state.isPlaying.value = true;
                  // await surahAudioCtrl.state.audioPlayer.pause();
                  surahAudioCtrl.state
                          .isSurahDownloadedByNumber(surahAudioCtrl
                              .state.currentAudioListSurahNum.value)
                          .value
                      ? await surahAudioCtrl.startDownload()
                      : await surahAudioCtrl.state.audioPlayer.play();
                },
              );
            } else if (processingState != ProcessingState.completed ||
                !playerState!.playing) {
              return IconButton(
                icon: CustomWidgets.customSvgWithColor(
                  style?.pauseIconPath ?? AssetsPath.assets.pauseArrow,
                  height: style?.pauseIconHeight ?? 30,
                  ctx: context,
                  color: style?.playIconColor ?? Colors.teal,
                ),
                onPressed: () {
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
                      color: style?.playIconColor ?? Colors.teal,
                    )),
                iconSize: style?.playIconHeight ?? 24.0,
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
