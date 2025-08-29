part of '../tafsir.dart';

class ActualTafsirWidget extends StatelessWidget {
  const ActualTafsirWidget({
    super.key,
    required this.isDark,
    required this.tafsirStyle,
    required this.context,
    required this.ayahIndex,
    required this.tafsir,
    required this.ayahs,
    required this.isTafsir,
    required this.translationList,
    required this.fontSizeArabic,
  });

  final bool isDark;
  final TafsirStyle tafsirStyle;
  final BuildContext context;
  final int ayahIndex;
  final TafsirTableData tafsir;
  final AyahModel ayahs;
  final bool isTafsir;
  final List translationList;
  final double fontSizeArabic;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '﴿${ayahs.text}﴾\n',
            style: TextStyle(
              fontFamily: 'uthmanic2',
              fontSize: 24,
              height: 1.9,
              color: (isDark ? Colors.white : Colors.black),
            ),
          ),
          WidgetSpan(
              child: context.horizontalDivider(
            color: tafsirStyle.textColor ?? Colors.grey.withValues(alpha: 0.8),
            height: 1.5,
          )),
          isTafsir
              ? TextSpan(
                  children: tafsir.tafsirText.customTextSpans(),
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.5,
                      fontSize: fontSizeArabic),
                )
              : TextSpan(
                  text: (translationList.length > (ayahIndex - 1) &&
                          (ayahIndex - 1) >= 0)
                      ? translationList[ayahIndex - 1].text
                      : '',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.5,
                      fontSize: fontSizeArabic),
                ),
        ],
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );
  }
}
