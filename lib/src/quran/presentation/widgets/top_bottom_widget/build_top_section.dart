part of '/quran.dart';

class BuildTopSection extends StatelessWidget {
  final bool isRight;
  final Widget? topTitleChild;
  final String? surahName;
  final String? juzName;
  final String? languageCode;
  final bool isSurah;
  final int pageIndex;

  BuildTopSection({
    super.key,
    required this.isRight,
    this.topTitleChild,
    this.surahName,
    this.juzName,
    this.languageCode,
    this.isSurah = false,
    required this.pageIndex,
  });

  final surahCtrl = SurahCtrl.instance;
  final quranCtrl = QuranCtrl.instance;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final topBottomStyle = TopBottomTheme.of(context)?.style ??
        TopBottomQuranStyle.defaults(isDark: isDark, context: context);
    final Color juzColor =
        topBottomStyle.juzTextColor ?? const Color(0xff77554B);
    final Color surahColor =
        topBottomStyle.surahNameColor ?? const Color(0xff77554B);

    final Widget? effectiveTopTitleChild =
        topTitleChild ?? topBottomStyle.customChild;
    final String effectiveJuzName =
        (juzName ?? topBottomStyle.juzName) ?? 'الجزء';
    final String? effectiveSurahName = surahName ?? topBottomStyle.surahName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: isRight
          ? Row(
              children: [
                effectiveTopTitleChild ?? const SizedBox.shrink(),
                effectiveTopTitleChild != null
                    ? const SizedBox(width: 16)
                    : const SizedBox.shrink(),
                Text(
                  '$effectiveJuzName: ${quranCtrl.getJuzByPage(pageIndex).juz}'
                      .convertNumbersAccordingToLang(
                          languageCode: languageCode),
                  style: _getTextStyle(context, juzColor),
                ),
                const Spacer(),
                effectiveSurahName != null
                    ? Text(
                        effectiveSurahName,
                        style: _getTextStyle(context, surahColor),
                      )
                    : quranCtrl.getSurahsByPageNumber(pageIndex + 1).isNotEmpty
                        ? Row(
                            children: List.generate(
                                quranCtrl
                                    .getSurahsByPageNumber(pageIndex + 1)
                                    .length,
                                (i) => Text(
                                      ' ${quranCtrl.getSurahsByPageNumber(pageIndex + 1)[i].arabicName.replaceAll('سُورَةُ ', '')} ',
                                      style: _getTextStyle(context, surahColor),
                                    )),
                          )
                        : const SizedBox.shrink(),
              ],
            )
          : Row(
              children: [
                effectiveSurahName != null
                    ? Text(
                        effectiveSurahName,
                        style: _getTextStyle(context, surahColor),
                      )
                    : quranCtrl.getSurahsByPageNumber(pageIndex + 1).isNotEmpty
                        ? Row(
                            children: List.generate(
                              quranCtrl
                                  .getSurahsByPageNumber(pageIndex + 1)
                                  .length,
                              (i) => Text(
                                ' ${quranCtrl.getSurahsByPageNumber(pageIndex + 1)[i].arabicName.replaceAll('سُورَةُ ', '')} ',
                                style: _getTextStyle(context, surahColor),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                const Spacer(),
                Text(
                  '$effectiveJuzName: ${quranCtrl.getJuzByPage(pageIndex).juz}'
                      .convertNumbersAccordingToLang(
                          languageCode: languageCode),
                  style: _getTextStyle(context, juzColor),
                ),
                effectiveTopTitleChild != null
                    ? const SizedBox(width: 16)
                    : const SizedBox.shrink(),
                effectiveTopTitleChild ?? const SizedBox.shrink(),
              ],
            ),
    );
  }

  /// الحصول على نمط النص
  /// Get text style
  TextStyle _getTextStyle(BuildContext context, Color color) {
    return TextStyle(
      fontSize: UiHelper.currentOrientation(18.0, 22.0, context),
      fontFamily: 'naskh',
      color: color,
      package: 'quran_library',
    );
  }
}
