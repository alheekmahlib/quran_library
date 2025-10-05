part of '../audio.dart';

class PlayAyahWidget extends StatelessWidget {
  final AyahAudioStyle? style;
  const PlayAyahWidget({super.key, this.style});

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
            return SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ));
          } else if (playerState != null && !playerState.playing) {
            return GestureDetector(
              child: CustomWidgets.customSvgWithColor(
                style?.playIconPath ?? AssetsPath.assets.playArrow,
                height: style?.playIconHeight ?? 25,
                ctx: context,
                color: style?.playIconColor ?? (Colors.cyan),
              ),
              onTap: () async {
                // اضبط وضع التشغيل للآيات فقط
                audioCtrl.state.isPlayingSurahsMode = false;
                // تجنّب استدعاءات مزدوجة
                if (!audioCtrl.state.audioPlayer.playing) {
                  await audioCtrl.playAyah(
                    context,
                    audioCtrl.state.currentAyahUniqueNumber,
                    playSingleAyah: audioCtrl.state.playSingleAyahOnly,
                  );
                }
              },
            );
          }
          return GestureDetector(
            child: CustomWidgets.customSvgWithColor(
              style?.pauseIconPath ?? AssetsPath.assets.pauseArrow,
              height: style?.pauseIconHeight ?? 25,
              ctx: context,
              color: style?.playIconColor ?? (Colors.cyan),
            ),
            onTap: () async {
              // Pause only, don't auto-toggle play again
              await audioCtrl.pausePlayer();
            },
          );
        },
      ),
    );
  }
}
