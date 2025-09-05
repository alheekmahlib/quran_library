part of '../../audio.dart';

class PlaySurahsWidget extends StatelessWidget {
  final SurahAudioStyle? style;
  PlaySurahsWidget({super.key, this.style});

  final surahCtrl = AudioCtrl.instance;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      width: UiHelper.currentOrientation(size.width, size.width * .5, context),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: style?.audioSliderBackgroundColor ?? const Color(0xfffaf7f3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: .3),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8.0),
          Container(
            width: 70,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 32),
          Obx(
            () => Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: .1,
                  child: Text(
                    AudioCtrl.instance.state.currentAudioListSurahNum.value
                        .toString(),
                    style: TextStyle(
                      color: style?.surahNameColor ?? Colors.black,
                      fontFamily: "surahName",
                      fontSize: 120.sp,
                      package: "quran_library",
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  AudioCtrl.instance.state.currentAudioListSurahNum.value
                      .toString(),
                  style: TextStyle(
                    color: style?.surahNameColor ?? Colors.black,
                    fontFamily: "surahName",
                    fontSize: 72.sp,
                    package: "quran_library",
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SurahChangeSurahReader(style: style),
          const SizedBox(height: 16),
          const SurahSeekBar(),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => surahCtrl.state
                        .isSurahDownloadedByNumber(
                            surahCtrl.state.currentAudioListSurahNum.value)
                        .value
                    ? const SizedBox.shrink()
                    : SurahDownloadPlayButton(style: style),
              ),
              SurahRepeatWidget()
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    SurahSkipToNext(style: style),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => surahCtrl.state.audioPlayer.seek(Duration(
                          seconds: surahCtrl.state.seekNextSeconds.value += 5)),
                      child: SvgPicture.asset(
                        AssetsPath.assets.rewind,
                        colorFilter: ColorFilter.mode(
                            style!.playIconColor ?? Colors.blue,
                            BlendMode.srcIn),
                        height: 30,
                        width: 30,
                      ),
                    ),
                  ],
                ),
                SurahOnlinePlayButton(),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        surahCtrl.state.audioPlayer.seek(Duration(
                            seconds: surahCtrl.state.seekNextSeconds.value -=
                                5));
                      },
                      child: SvgPicture.asset(
                        AssetsPath.assets.backward,
                        colorFilter: ColorFilter.mode(
                            style!.playIconColor ?? Colors.blue,
                            BlendMode.srcIn),
                        height: 30,
                        width: 30,
                      ),
                    ),
                    SizedBox(width: 8),
                    SurahSkipToPrevious(style: style),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
