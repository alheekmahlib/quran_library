part of '../../audio.dart';

class PlaySurahsWidget extends StatelessWidget {
  final SurahAudioStyle? style;
  final bool isDark;
  final String? languageCode;

  PlaySurahsWidget(
      {super.key, this.style, this.isDark = false, this.languageCode});

  final surahCtrl = AudioCtrl.instance;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bg = style?.audioSliderBackgroundColor ??
        AppColors.getBackgroundColor(isDark);
    final borderColor =
        (style?.backgroundColor ?? AppColors.getBackgroundColor(isDark))
            .withValues(alpha: 0.15);
    final handleColor = Colors.grey.withValues(alpha: .6);
    final numberColor = style?.surahNameColor ?? AppColors.getTextColor(isDark);
    final accent = style?.playIconColor ?? Colors.teal;
    return Container(
      width: UiHelper.currentOrientation(size.width, size.width * .5, context),
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: .2),
            spreadRadius: 1,
            blurRadius: 9,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8.0),
          _PanelHandle(color: handleColor),
          const SizedBox(height: 24),
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
                      color: numberColor,
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
                    color: numberColor,
                    fontFamily: "surahName",
                    fontSize: 72.sp,
                    package: "quran_library",
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SurahChangeSurahReader(style: style, isDark: isDark),
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
              const SizedBox(width: 8),
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
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => surahCtrl.state.audioPlayer.seek(Duration(
                          seconds: surahCtrl.state.seekNextSeconds.value += 5)),
                      child: SvgPicture.asset(
                        AssetsPath.assets.rewind,
                        colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                        height: 30,
                        width: 30,
                      ),
                    ),
                  ],
                ),
                SurahOnlinePlayButton(style: style),
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
                        colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                        height: 30,
                        width: 30,
                      ),
                    ),
                    const SizedBox(width: 8),
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
