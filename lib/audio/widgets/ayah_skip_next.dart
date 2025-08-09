part of '../audio.dart';

class AyahSkipToNext extends StatelessWidget {
  final AyahAudioStyle? style;
  AyahSkipToNext({super.key, this.style});
  final audioCtrl = AudioCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SequenceState?>(
      stream: audioCtrl.state.audioPlayer.sequenceStateStream,
      builder: (context, snapshot) => GestureDetector(
        child: Semantics(
          button: true,
          enabled: true,
          label: 'next'.tr,
          child: Icon(
            Icons.skip_previous,
            color: style!.playIconColor ?? Colors.blue,
            size: style!.nextIconHeight ?? 38,
          ),
        ),
        onTap: () async => await audioCtrl.skipNextAyah(
            context, audioCtrl.state.currentAyahUniqueNumber),
      ),
    );
  }
}
