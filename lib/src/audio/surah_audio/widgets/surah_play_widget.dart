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
    final accent =
        style?.playIconColor ?? Theme.of(context).colorScheme.primary;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        width:
            UiHelper.currentOrientation(size.width, size.width * .5, context),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8.0),
              _PanelHandle(color: handleColor),
              const SizedBox(height: 24),
              UiHelper.currentOrientation(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AudioSurahNameWidget(
                          numberColor: numberColor, size: size),
                      SurahChangeSurahReader(style: style, isDark: isDark),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AudioSurahNameWidget(
                            numberColor: numberColor, size: size),
                        SurahChangeSurahReader(style: style, isDark: isDark),
                      ],
                    ),
                  ),
                  context),
              // const SizedBox(height: 16),
              SurahSeekBar(style: style),
              // const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  kIsWeb
                      ? const SizedBox.shrink()
                      : Obx(
                          () => surahCtrl.state
                                  .isSurahDownloadedByNumber(surahCtrl
                                      .state.currentAudioListSurahNum.value)
                                  .value
                              ? const SizedBox.shrink()
                              : SurahDownloadPlayButton(style: style),
                        ),
                  const SizedBox(width: 8),
                  SurahRepeatWidget(style: style)
                ],
              ),
              // const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        SurahSkipToNext(
                            style: style, languageCode: languageCode ?? 'ar'),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 25,
                          width: 25,
                          child: GestureDetector(
                            onTap: () => surahCtrl.state.audioPlayer.seek(
                                Duration(
                                    seconds: surahCtrl
                                        .state.seekNextSeconds.value += 5)),
                            child: SvgPicture.asset(
                              AssetsPath.assets.rewind,
                              colorFilter:
                                  ColorFilter.mode(accent, BlendMode.srcIn),
                              height: 30,
                              width: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SurahOnlinePlayButton(style: style),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        SizedBox(
                          height: 25,
                          width: 25,
                          child: GestureDetector(
                            onTap: () {
                              surahCtrl.state.audioPlayer.seek(Duration(
                                  seconds: surahCtrl
                                      .state.seekNextSeconds.value -= 5));
                            },
                            child: SvgPicture.asset(
                              AssetsPath.assets.backward,
                              colorFilter:
                                  ColorFilter.mode(accent, BlendMode.srcIn),
                              height: 30,
                              width: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SurahSkipToPrevious(
                            style: style, languageCode: languageCode ?? 'ar'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AudioSurahNameWidget extends StatelessWidget {
  const AudioSurahNameWidget({
    super.key,
    required this.numberColor,
    required this.size,
  });

  final Color numberColor;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        alignment: Alignment.center,
        children: [
          UiHelper.currentOrientation(
              Opacity(
                opacity: .1,
                child: Text(
                  AudioCtrl.instance.state.currentAudioListSurahNum.value
                      .toString(),
                  style: TextStyle(
                    color: numberColor,
                    fontFamily: "surahName",
                    fontSize: size.height * 0.18,
                    package: "quran_library",
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox.shrink(),
              context),
          Text(
            AudioCtrl.instance.state.currentAudioListSurahNum.value.toString(),
            style: TextStyle(
              color: numberColor,
              fontFamily: "surahName",
              fontSize: size.height * 0.1,
              package: "quran_library",
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
