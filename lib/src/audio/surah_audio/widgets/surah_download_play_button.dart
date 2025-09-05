part of '../../audio.dart';

class SurahDownloadPlayButton extends StatelessWidget {
  final SurahAudioStyle? style;
  const SurahDownloadPlayButton({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final surahAudioCtrl = AudioCtrl.instance;
    return SizedBox(
      width: 40,
      child: Obx(
        () => surahAudioCtrl.state.isDownloading.value
            ? IconButton(
                icon: Icon(
                  Icons.close,
                  color: style?.iconColor ?? Colors.black,
                  size: 28,
                ),
                onPressed: () => surahAudioCtrl.cancelDownload(),
              )
            : StreamBuilder<PlayerState>(
                stream: surahAudioCtrl.state.audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return CustomWidgets.customLottie(
                        LottieConstants.get(
                            LottieConstants.assetsLottiePlayButton),
                        width: 20.0,
                        height: 20.0);
                  } else {
                    return IconButton(
                      icon: Semantics(
                          button: true,
                          enabled: true,
                          label: 'download'.tr,
                          child: const Icon(Icons.cloud_download_outlined)),
                      iconSize: 24.0,
                      color: style?.iconColor ?? Colors.blue,
                      onPressed: () async {
                        surahAudioCtrl.state.isPlayingSurahsMode = true;
                        if (surahAudioCtrl.state.isDownloading.value) {
                          surahAudioCtrl.cancelDownload();
                        } else if (surahAudioCtrl.state
                            .isSurahDownloadedByNumber(surahAudioCtrl
                                .state.currentAudioListSurahNum.value)
                            .value) {
                          surahAudioCtrl.state.isPlaying.value = true;
                        } else {
                          await surahAudioCtrl.startDownload();
                        }
                      },
                    );
                  }
                },
              ),
      ),
    );
  }
}
