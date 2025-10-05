part of '../../audio.dart';

class SurahDownloadPlayButton extends StatelessWidget {
  final SurahAudioStyle? style;
  const SurahDownloadPlayButton({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final surahAudioCtrl = AudioCtrl.instance;
    return Obx(
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
                  return SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ));
                } else {
                  return IconButton(
                    icon: Semantics(
                        button: true,
                        enabled: true,
                        label: 'download'.tr,
                        child: const Icon(Icons.cloud_download_outlined)),
                    iconSize: 24.0,
                    color: style?.iconColor ?? Colors.cyan,
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
    );
  }
}
