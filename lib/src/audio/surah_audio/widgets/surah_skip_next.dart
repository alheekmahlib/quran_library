part of '../../audio.dart';

class SurahSkipToNext extends StatelessWidget {
  final SurahAudioStyle? style;
  SurahSkipToNext({super.key, this.style});
  final audioCtrl = AudioCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 50,
      child: StreamBuilder<SequenceState?>(
        stream: audioCtrl.state.audioPlayer.sequenceStateStream,
        builder: (context, snapshot) => IconButton(
          icon: Semantics(
            button: true,
            enabled: true,
            label: 'next'.tr,
            child: Icon(
              Icons.skip_next,
              color: style!.playIconColor ?? Colors.teal,
              size: style!.nextIconHeight ?? 38,
            ),
          ),
          onPressed: () async => await audioCtrl.playNextSurah(),
        ),
      ),
    );
  }
}
