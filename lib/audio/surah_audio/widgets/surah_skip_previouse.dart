part of '../../audio.dart';

class SurahSkipToPrevious extends StatelessWidget {
  final SurahAudioStyle? style;
  const SurahSkipToPrevious({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SequenceState?>(
      stream: AudioCtrl.instance.state.audioPlayer.sequenceStateStream,
      builder: (context, snapshot) => IconButton(
        icon: Semantics(
          button: true,
          enabled: true,
          label: 'skipToPrevious'.tr,
          child: Icon(
            Icons.skip_next,
            color: style?.textColor ?? Colors.blue,
            size: style?.previousIconHeight ?? 38,
          ),
        ),
        onPressed: () async => await AudioCtrl.instance.playPreviousSurah(),
      ),
    );
  }
}
