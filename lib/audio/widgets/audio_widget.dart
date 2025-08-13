part of '../audio.dart';

class AudioWidget extends StatelessWidget {
  final AyahAudioStyle? style;
  final bool? isDark;
  AudioWidget({super.key, this.style, this.isDark});
  final quranCtrl = QuranCtrl.instance;
  final audioCtrl = AudioCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Obx(() => AnimatedCrossFade(
                // مطابقة مدة الأنيميشن مع السلايدر لتجنب overflow
                // Match animation duration with slider to avoid overflow
                duration: const Duration(milliseconds: 650),
                reverseDuration: const Duration(milliseconds: 600),
                secondCurve: Curves.easeOutBack,
                firstChild: Container(
                  height: 50,
                  width: MediaQuery.sizeOf(context).width,
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      PlayAyah(style: style!),
                      ChangeReader(style: style!),
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
                        final targetHeight = availableHeight.clamp(80.0, 165.0);

                        return SizedBox(
                            height: targetHeight,
                            width: MediaQuery.sizeOf(context).width,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // تقليل المسافات عند المساحة المحدودة
                                // Reduce spacing when space is limited
                                SizedBox(height: targetHeight > 120 ? 4 : 2),
                                ChangeReader(style: style!),
                                // SizedBox(height: 4),
                                // جعل الـ Slider مرن ليأخذ المساحة المتبقية
                                // Make slider flexible to take remaining space
                                Expanded(
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: c.state.isDownloading.value
                                          ? GetX<AudioCtrl>(builder: (c) {
                                              final data = c.state
                                                  .tmpDownloadedAyahsCount;
                                              log('$data => REBUILDING  ${audioCtrl.state.tmpDownloadedAyahsCount}');
                                              return SliderWidget.downloading(
                                                  currentPosition: data,
                                                  filesCount: audioCtrl
                                                      .currentAyahFileName
                                                      .length,
                                                  activeTrackColor: style!
                                                          .seekBarActiveTrackColor ??
                                                      Colors.blue,
                                                  inactiveTrackColor: style!
                                                          .seekBarInactiveTrackColor ??
                                                      Colors.grey,
                                                  thumbColor: style!
                                                          .seekBarThumbColor ??
                                                      Colors.blue,
                                                  horizontalPadding: style!
                                                          .seekBarHorizontalPadding ??
                                                      0);
                                            })
                                          : StreamBuilder<PositionData>(
                                              stream:
                                                  audioCtrl.positionDataStream,
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  final positionData =
                                                      snapshot.data;
                                                  return SliderWidget.player(
                                                    horizontalPadding: style!
                                                            .seekBarHorizontalPadding ??
                                                        0.0,
                                                    duration: positionData
                                                            ?.duration ??
                                                        Duration.zero,
                                                    position: positionData
                                                            ?.position ??
                                                        Duration.zero,
                                                    activeTrackColor: style!
                                                            .seekBarActiveTrackColor ??
                                                        Colors.blue,
                                                    inactiveTrackColor: style!
                                                            .seekBarInactiveTrackColor ??
                                                        Colors.grey,
                                                    thumbColor: style!
                                                            .seekBarThumbColor ??
                                                        Colors.blue,
                                                    onChangeEnd: audioCtrl
                                                        .state.audioPlayer.seek,
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
                                        AyahSkipToPrevious(style: style),
                                        PlayAyah(style: style),
                                        AyahSkipToNext(style: style),
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
