part of '../../audio.dart';

/// ويدجت آخر استماع مع دعم تمرير الألوان والأنماط
/// Last listen widget with color and style passing support
class SurahLastListen extends StatelessWidget {
  final SurahAudioStyle? style;

  SurahLastListen({super.key, this.style});

  final surahAudioCtrl = AudioCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      label: 'lastListen'.tr,
      child: GestureDetector(
        onTap: () {
          surahAudioCtrl
              .lastAudioSource()
              .then((_) => surahAudioCtrl.state.audioPlayer.play());
          // surahAudioCtrl.jumpToSurah(
          //     (surahAudioCtrl.state.currentAudioListSurahNum.value - 1));
        },
        child: Container(
          width: 250,
          decoration: BoxDecoration(
              // شرح: استخدام لون الخلفية من الستايل أو الافتراضي
              // Explanation: Use background color from style or default
              color: style?.backgroundColor?.withValues(alpha: 0.1) ??
                  const Color(0xfffaf7f3).withValues(alpha: .1),
              borderRadius:
                  BorderRadius.all(Radius.circular(style?.borderRadius ?? 8.0)),
              border: Border.all(
                  color: style?.backgroundColor?.withValues(alpha: 0.2) ??
                      Colors.blue.withValues(alpha: .2),
                  width: 1)),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 3.0),
                decoration: BoxDecoration(
                  // شرح: استخدام لون الخلفية الأساسي من الستايل
                  // Explanation: Use primary background color from style
                  color: style?.backgroundColor ?? Colors.blue,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: Radius.circular(style?.borderRadius ?? 8.0),
                    bottomStart: Radius.circular(style?.borderRadius ?? 8.0),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      'آخر قراءة',
                      style: QuranLibrary().naskhStyle.copyWith(
                            fontSize: 18,
                            // شرح: استخدام لون النص من الستايل أو الأبيض
                            // Explanation: Use text color from style or white
                            color: style?.textColor ?? Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: .2,
                      child: Obx(
                        () => Text(
                          AudioCtrl
                              .instance.state.currentAudioListSurahNum.value
                              .toString(),
                          style: TextStyle(
                            color: style?.surahNameColor ?? Colors.black,
                            fontFamily: "surahName",
                            fontSize: 48.sp,
                            package: "quran_library",
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (context.mounted)
                      GetX<AudioCtrl>(
                        builder: (surahSurahAudioController) => Text(
                          surahAudioCtrl.formatDuration(Duration(
                              seconds:
                                  surahAudioCtrl.state.lastPosition.value)),
                          style: QuranLibrary().naskhStyle.copyWith(
                                fontSize: 26,
                                // شرح: استخدام لون النص من الستايل أو الأزرق
                                // Explanation: Use text color from style or blue
                                color: style?.textColor ?? Colors.blue,
                              ),
                        ),
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
