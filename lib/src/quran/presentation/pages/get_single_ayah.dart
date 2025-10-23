part of '../../../../quran.dart';

class GetSingleAyah extends StatelessWidget {
  final int surahNumber;
  final int ayahNumber;
  final Color? textColor;
  final bool? isDark;
  final bool? isBold;
  final double? fontSize;
  final AyahModel? ayahs;
  final bool? isSingleAyah;
  final bool? islocalFont;
  final String? fontsName;
  final int? pageIndex;

  const GetSingleAyah({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    this.textColor,
    this.isDark = false,
    this.fontSize,
    this.isBold = true,
    this.ayahs,
    this.isSingleAyah = true,
    this.islocalFont = false,
    this.fontsName,
    this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (surahNumber < 1 || surahNumber > 114) {
      return Text(
        'رقم السورة غير صحيح',
        style: TextStyle(
          fontSize: fontSize ?? 22,
          color: textColor ?? AppColors.getTextColor(isDark!),
        ),
      );
    }
    final ayah = ayahs ??
        QuranCtrl.instance
            .getSingleAyahByAyahAndSurahNumber(ayahNumber, surahNumber);
    final pageNumber = pageIndex ??
        QuranCtrl.instance
            .getPageNumberByAyahAndSurahNumber(ayahNumber, surahNumber);
    log('surahNumber: $surahNumber, ayahNumber: $ayahNumber, pageNumber: $pageNumber');
    final bool currentFontsSelected = QuranLibrary().currentFontsSelected == 1;
    if (ayah.text.isEmpty) {
      return Text(
        'الآية غير موجودة',
        style: TextStyle(
          fontSize: fontSize ?? 22,
          color: textColor ?? AppColors.getTextColor(isDark!),
        ),
      );
    }
    // if (currentFontsSelected) {
    //   QuranLibrary().getFontsPrepareMethod(
    //       pageIndex: pageNumber - 1, isFontsLocal: islocalFont ?? false);
    // }
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      softWrap: true,
      overflow: TextOverflow.visible,
      maxLines: null,
      text: TextSpan(
        style: TextStyle(
          fontFamily: islocalFont == true
              ? fontsName
              : (currentFontsSelected
                  ? 'p${((pageNumber - 1) + 2001)}'
                  : 'hafs'),
          package: currentFontsSelected ? null : 'quran_library',
          fontSize: fontSize ?? 22,
          height: 1.7,
          letterSpacing: currentFontsSelected ? 3 : null,
          color: textColor ?? AppColors.getTextColor(isDark!),
          shadows: [
            Shadow(
              blurRadius: 0.5,
              color: isBold!
                  ? textColor ?? AppColors.getTextColor(isDark!)
                  : Colors.transparent,
              offset: const Offset(0.5, 0.5),
            ),
          ],
        ),
        children: [
          TextSpan(
            text: currentFontsSelected
                ? '${ayah.codeV2!.replaceAll('\n', '').split(' ').join(' ')} '
                : '${ayah.text} ',
            style: TextStyle(
              fontFamily: islocalFont == true
                  ? fontsName
                  : (currentFontsSelected
                      ? 'p${((pageNumber - 1) + 2001)}'
                      : 'hafs'),
              package: currentFontsSelected ? null : 'quran_library',
              fontSize: fontSize ?? 22,
              height: 1.7,
              letterSpacing: currentFontsSelected ? 3 : null,
              color: textColor ?? AppColors.getTextColor(isDark!),
              shadows: [
                Shadow(
                  blurRadius: 0.5,
                  color: isBold!
                      ? textColor ?? AppColors.getTextColor(isDark!)
                      : Colors.transparent,
                  offset: const Offset(0.5, 0.5),
                ),
              ],
            ),
          ),
          currentFontsSelected
              ? TextSpan()
              : TextSpan(
                  text: '${ayah.ayahNumber}'
                      .convertEnglishNumbersToArabic('${ayah.ayahNumber}'),
                  style: TextStyle(
                    fontFamily: 'hafs',
                    package: 'quran_library',
                    fontSize: fontSize ?? 22,
                    height: 1.7,
                    color: textColor ?? AppColors.getTextColor(isDark!),
                    shadows: [
                      Shadow(
                        blurRadius: 0.5,
                        color: isBold!
                            ? textColor ?? AppColors.getTextColor(isDark!)
                            : Colors.transparent,
                        offset: const Offset(0.5, 0.5),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
