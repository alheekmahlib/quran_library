part of '../audio.dart';

class AyahsAudioWidget extends StatelessWidget {
  final AyahAudioStyle? style;
  final AyahDownloadManagerStyle? downloadManagerStyle;
  final bool? isDark;
  final String? languageCode;

  AyahsAudioWidget(
      {super.key,
      this.style,
      this.downloadManagerStyle,
      this.isDark = false,
      this.languageCode});
  final quranCtrl = QuranCtrl.instance;
  final audioCtrl = AudioCtrl.instance;

  @override
  Widget build(BuildContext context) {
    final bool dark = isDark ?? false;
    final AyahAudioStyle effectiveStyle =
        style ?? AyahAudioStyle.defaults(isDark: dark, context: context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: effectiveStyle.backgroundColor!,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Obx(() => AnimatedCrossFade(
                // مطابقة مدة الأنيميشن مع السلايدر لتجنب overflow
                // Match animation duration with slider to avoid overflow
                duration: const Duration(milliseconds: 10),
                reverseDuration: const Duration(milliseconds: 0),
                secondCurve: Curves.linear,
                firstChild: Container(
                  height: 50,
                  width: MediaQuery.sizeOf(context).width,
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      PlayAyahWidget(style: effectiveStyle),
                      AyahChangeReader(
                          style: effectiveStyle,
                          isDark: isDark,
                          downloadManagerStyle: downloadManagerStyle),
                    ],
                  ),
                ),
                secondChild: GetBuilder<AudioCtrl>(
                    id: 'audio_seekBar_id',
                    builder: (c) {
                      return LayoutBuilder(builder: (context, constraints) {
                        // تحديد الارتفاع بناءً على المساحة المتاحة مع حد أدنى وأقصى
                        // Determine height based on available space with min/max limits
                        final availableHeight = constraints.maxHeight;
                        final targetHeight = availableHeight.clamp(80.0, 175.0);

                        return SizedBox(
                            height: targetHeight.h,
                            width: MediaQuery.sizeOf(context).width,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // تقليل المسافات عند المساحة المحدودة
                                // Reduce spacing when space is limited
                                SizedBox(height: targetHeight > 120 ? 4 : 2),
                                AyahChangeReader(
                                    style: effectiveStyle,
                                    isDark: isDark,
                                    downloadManagerStyle: downloadManagerStyle),
                                // SizedBox(height: 4),
                                // جعل الـ Slider مرن ليأخذ المساحة المتبقية
                                // Make slider flexible to take remaining space
                                Flexible(
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: SingleChildScrollView(
                                      child: c.state.isDownloading.value
                                          ? GetX<AudioCtrl>(builder: (c) {
                                              final data = c.state
                                                  .tmpDownloadedAyahsCount;
                                              log('$data => REBUILDING  ${audioCtrl.state.tmpDownloadedAyahsCount}');
                                              return PackageSliderWidget
                                                  .downloading(
                                                currentPosition: data,
                                                filesCount: audioCtrl
                                                    .currentAyahFileName.length,
                                                activeTrackColor: effectiveStyle
                                                    .seekBarActiveTrackColor!,
                                                inactiveTrackColor: effectiveStyle
                                                    .seekBarInactiveTrackColor!,
                                                thumbColor: effectiveStyle
                                                    .seekBarThumbColor!,
                                                horizontalPadding: effectiveStyle
                                                    .seekBarHorizontalPadding!,
                                                timeContainerColor: effectiveStyle
                                                    .seekBarTimeContainerColor!,
                                              );
                                            })
                                          : StreamBuilder<PackagePositionData>(
                                              stream:
                                                  audioCtrl.positionDataStream,
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  final positionData =
                                                      snapshot.data;
                                                  return PackageSliderWidget
                                                      .player(
                                                    horizontalPadding:
                                                        effectiveStyle
                                                            .seekBarHorizontalPadding!,
                                                    duration: positionData
                                                            ?.duration ??
                                                        Duration.zero,
                                                    position: positionData
                                                            ?.position ??
                                                        Duration.zero,
                                                    activeTrackColor: effectiveStyle
                                                        .seekBarActiveTrackColor!,
                                                    inactiveTrackColor:
                                                        effectiveStyle
                                                            .seekBarInactiveTrackColor!,
                                                    thumbColor: effectiveStyle
                                                        .seekBarThumbColor!,
                                                    onChangeEnd: audioCtrl
                                                        .state.audioPlayer.seek,
                                                    timeContainerColor:
                                                        effectiveStyle
                                                            .seekBarTimeContainerColor!,
                                                    languageCode:
                                                        languageCode ?? 'ar',
                                                    sliderHeight: 20,
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              },
                                            ),
                                    ),
                                  ),
                                ),
                                // إضافة أزرار التحكم فقط إذا كان هناك مساحة كافية
                                // Add control buttons only if there's enough space
                                if (targetHeight > 120)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        AyahSkipToPrevious(
                                            style: effectiveStyle),
                                        PlayAyahWidget(style: effectiveStyle),
                                        AyahSkipToNext(style: effectiveStyle),
                                      ],
                                    ),
                                  ),
                              ],
                            ));
                      });
                    }),
                crossFadeState: quranCtrl.state.isPlayExpanded.value
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ))),
    );
  }
}
