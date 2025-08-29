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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: isRight
          ? Row(
              children: [
                topTitleChild ?? const SizedBox.shrink(),
                const SizedBox(width: 16),
                Text(
                  '${juzName ?? 'الجزء'}: ${quranCtrl.getJuzByPage(pageIndex).juz}'
                      .convertNumbersAccordingToLang(
                          languageCode: languageCode),
                  style: _getTextStyle(context),
                ),
                const Spacer(),
                surahName != null
                    ? Text(
                        surahName!,
                        style: _getTextStyle(context),
                      )
                    : quranCtrl.getSurahsByPageNumber(pageIndex + 1).isNotEmpty
                        ? Row(
                            children: List.generate(
                                quranCtrl
                                    .getSurahsByPageNumber(pageIndex + 1)
                                    .length,
                                (i) => Text(
                                      ' ${quranCtrl.getSurahsByPageNumber(pageIndex + 1)[i].arabicName.replaceAll('سُورَةُ ', '')} ',
                                      style: TextStyle(
                                          fontSize: UiHelper.currentOrientation(
                                              18.0, 22.0, context),
                                          // fontWeight: FontWeight.bold,
                                          fontFamily: 'naskh',
                                          color: const Color(0xff77554B)),
                                    )),
                          )
                        : const SizedBox.shrink(),
              ],
            )
          : Row(
              children: [
                surahName != null
                    ? Text(
                        surahName!,
                        style: _getTextStyle(context),
                      )
                    : quranCtrl.getSurahsByPageNumber(pageIndex + 1).isNotEmpty
                        ? Row(
                            children: List.generate(
                                quranCtrl
                                    .getSurahsByPageNumber(pageIndex + 1)
                                    .length,
                                (i) => Text(
                                      ' ${quranCtrl.getSurahsByPageNumber(pageIndex + 1)[i].arabicName.replaceAll('سُورَةُ ', '')} ',
                                      style: TextStyle(
                                          fontSize: UiHelper.currentOrientation(
                                              18.0, 22.0, context),
                                          // fontWeight: FontWeight.bold,
                                          fontFamily: 'naskh',
                                          color: const Color(0xff77554B)),
                                    )),
                          )
                        : const SizedBox.shrink(),
                const Spacer(),
                Text(
                  '${juzName ?? 'الجزء'}: ${quranCtrl.getJuzByPage(pageIndex).juz}'
                      .convertNumbersAccordingToLang(
                          languageCode: languageCode),
                  style: _getTextStyle(context),
                ),
                const SizedBox(width: 16),
                topTitleChild ?? const SizedBox.shrink(),
              ],
            ),
    );
  }

  /// الحصول على نمط النص
  /// Get text style
  TextStyle _getTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: UiHelper.currentOrientation(18.0, 22.0, context),
      fontFamily: 'naskh',
      color: const Color(0xff77554B),
      package: 'quran_library',
    );
  }
}
