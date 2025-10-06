part of '../../audio.dart';

class SurahSeekBar extends StatelessWidget {
  final String? languageCode;
  const SurahSeekBar({super.key, this.languageCode});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AudioCtrl>(
        id: 'seekBar_id',
        builder: (c) => c.state.isDownloading.value
            ? GetX<AudioCtrl>(builder: (c) {
                return PackageSliderWidget.downloading(
                    currentPosition: c.state.downloadProgress.value.toInt(),
                    filesCount: c.state.fileSize.value,
                    horizontalPadding: 32.0);
              })
            : StreamBuilder<PackagePositionData>(
                stream: c.positionDataStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    c.state.positionData?.value = snapshot.data!;
                    final positionData = snapshot.data;

                    c.updateControllerValues(positionData!);
                    return PackageSliderWidget.player(
                      horizontalPadding: 32.0,
                      duration: positionData.duration,
                      position: c.state.lastPosition.value != 0
                          ? Duration(
                              seconds: c.state.lastPosition.value.toInt())
                          : positionData.position,
                      // bufferedPosition: positionData.bufferedPosition,
                      onChangeEnd: (newPosition) {
                        c.state.audioPlayer.seek(newPosition);
                        c.saveLastSurahListen();
                        c.state.seekNextSeconds.value =
                            positionData.position.inSeconds;
                        c.updateControllerValues(positionData);
                      },
                      activeTrackColor: Colors.teal,
                      textColor: Colors.white,
                      timeShow: true,
                      languageCode: languageCode,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ));
  }
}
