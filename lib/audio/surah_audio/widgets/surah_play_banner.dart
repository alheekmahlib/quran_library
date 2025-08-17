part of '../../audio.dart';

class SurahPlayBanner extends StatelessWidget {
  const SurahPlayBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      label: 'Play Banner',
      child: GestureDetector(
        child: Container(
          width: 150,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: .2),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          margin: UiHelper.currentOrientation(
              const EdgeInsets.only(top: 75.0, right: 16.0),
              const EdgeInsets.only(bottom: 16.0, left: 32.0),
              context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              CustomWidgets.surahNameWidget(
                  AudioCtrl.instance.state.currentAudioListSurahNum.value,
                  width: 100,
                  Theme.of(context).hintColor),
              // MiniMusicVisualizer(
              //   color: Theme.of(context).colorScheme.surface,
              //   width: 4,
              //   height: 15,
              //   animate: true,
              // ),
              Container(
                height: 80,
                width: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          // SurahAudioController.instance.jumpToSurah(SurahAudioController
          //         .instance.state.currentAudioListSurahNum.value -
          //     1);
        },
      ),
    );
  }
}
