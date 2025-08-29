part of '../../audio.dart';

class SurahCollapsedPlayWidget extends StatelessWidget {
  final SurahAudioStyle? style;
  const SurahCollapsedPlayWidget({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: MediaQuery.sizeOf(context).height,
        width: UiHelper.currentOrientation(MediaQuery.sizeOf(context).width,
            MediaQuery.sizeOf(context).width * .5, context),
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
            SizedBox(height: 8.0),
            Container(
              width: 70,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                        color: style?.surahNameColor ?? Colors.black,
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
