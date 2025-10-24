part of '../../audio.dart';

/// ويدجت آخر استماع مع دعم تمرير الألوان والأنماط
/// Last listen widget with color and style passing support
class SurahLastListen extends StatelessWidget {
  final SurahAudioStyle? style;
  final bool isDark;
  final String? languageCode;

  SurahLastListen(
      {super.key, this.style, this.isDark = false, this.languageCode});

  final surahAudioCtrl = AudioCtrl.instance;

  @override
  Widget build(BuildContext context) {
    final bool dark = isDark;
    final bg = style?.backgroundColor ?? AppColors.getBackgroundColor(dark);
    final textColor = style?.textColor ?? AppColors.getTextColor(dark);
    final primary = style?.primaryColor ?? Colors.teal;
    final numberColor = style?.surahNameColor ?? textColor;

    return Semantics(
      button: true,
      enabled: true,
      label: 'lastListen'.tr,
      child: GestureDetector(
        onTap: () {
          surahAudioCtrl.lastAudioSource().then((_) {
            surahAudioCtrl.state.audioPlayer.play();
            surahAudioCtrl.state.panelController.expand();
          });
        },
        child: Container(
          // اجعل العرض مرنًا ليناسب الحاوية الأب
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.06),
            borderRadius:
                BorderRadius.all(Radius.circular(style?.borderRadius ?? 12.0)),
            border: Border.all(color: bg.withValues(alpha: 0.16), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _GradientCircleIcon(color: primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'آخر إستماع'.tr,
                      style: QuranLibrary().cairoStyle.copyWith(
                            fontSize: 16,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // وقت التشغيل يتحدث لحظيًا عبر positionDataStream
                    Obx(
                      () => Text(
                        surahAudioCtrl.textDurationFormatted
                            .convertNumbersAccordingToLang(
                                languageCode: languageCode ?? 'ar'),
                        style: QuranLibrary().cairoStyle.copyWith(
                              fontSize: 14,
                              height: 1.3,
                              color: textColor.withValues(alpha: 0.75),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // رقم السورة بتصميم متدرج وخلفية شفافة
              Obx(
                () => Text(
                  surahAudioCtrl.state.currentAudioListSurahNum.value
                      .toString(),
                  style: TextStyle(
                    color: numberColor,
                    fontFamily: 'surahName',
                    fontSize: 32.sp.clamp(32, 40),
                    package: 'quran_library',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientCircleIcon extends StatelessWidget {
  final Color color;
  const _GradientCircleIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.10),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: color,
        size: 26,
      ),
    );
  }
}
