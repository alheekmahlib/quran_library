part of '../../audio.dart';

class SurahRepeatWidget extends StatelessWidget {
  SurahRepeatWidget({super.key});

  final surahAudioCtrl = AudioCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LoopMode>(
      stream: surahAudioCtrl.state.audioPlayer.loopModeStream,
      builder: (context, snapshot) {
        final loopMode = snapshot.data ?? LoopMode.off;
        List<IconData> icons = [
          Icons.repeat,
          Icons.repeat,
        ];
        const cycleModes = [
          LoopMode.off,
          LoopMode.all,
        ];
        final index = cycleModes.indexOf(loopMode);
        return IconButton(
          iconSize: 30,
          icon: Icon(icons[index]),
          color: index == 0
              ? context.theme.colorScheme.primary.withValues(alpha: .4)
              : context.theme.colorScheme.primary,
          onPressed: () {
            surahAudioCtrl.state.audioPlayer.setLoopMode(cycleModes[
                (cycleModes.indexOf(loopMode) + 1) % cycleModes.length]);
          },
        );
      },
    );
  }
}
