part of '../../audio.dart';

class SurahCollapsedPlayWidget extends StatelessWidget {
  final SurahAudioStyle? style;
  final bool isDark;
  final String? languageCode;

  const SurahCollapsedPlayWidget(
      {super.key, this.style, this.isDark = false, this.languageCode});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bg = style?.audioSliderBackgroundColor ?? const Color(0xfffaf7f3);
    final handleColor = Colors.grey.withValues(alpha: .6);
    final borderColor =
        (style?.backgroundColor ?? AppColors.getBackgroundColor(isDark))
            .withValues(alpha: 0.15);
    final textColor = style?.surahNameColor ?? AppColors.getTextColor(isDark);
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        height: size.height,
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
        child: Column(
          children: [
            const SizedBox(height: 8.0),
            _PanelHandle(color: handleColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    textDirection: TextDirection.rtl,
                    children: [
                      SurahSkipToPrevious(style: style),
                      SurahOnlinePlayButton(style: style),
                      SurahSkipToNext(style: style),
                    ].reversed.toList(),
                  ),
                  Obx(
                    () => Text(
                      AudioCtrl.instance.state.currentAudioListSurahNum.value
                          .toString(),
                      style: TextStyle(
                        color: textColor,
                        fontFamily: "surahName",
                        fontSize: 42,
                        package: "quran_library",
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelHandle extends StatelessWidget {
  final Color color;
  const _PanelHandle({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
