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
    required this.language,
  });

  final bool isDark;
  final TafsirStyle tafsirStyle;
  final BuildContext context;
  final int ayahIndex;
  final TafsirTableData tafsir;
  final AyahModel ayahs;
  final bool isTafsir;
  final List<TranslationModel> translationList;
  final double fontSizeArabic;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text.rich(
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
                color:
                    tafsirStyle.textColor ?? Colors.grey.withValues(alpha: 0.8),
                height: 1.5,
              )),
            ],
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
        ),
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              isTafsir
                  ? TextSpan(
                      children: tafsir.tafsirText.customTextSpans(),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          height: 1.5,
                          fontSize: fontSizeArabic),
                    )
                  : TextSpan(
                      children: _buildTranslationSpans(),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          height: 1.5,
                          fontSize: fontSizeArabic),
                    ),
            ],
          ),
          textDirection: context.alignmentLayoutWPassLang(
              language, TextDirection.rtl, TextDirection.ltr),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  // بناء spans للترجمة مع الحواشي
  List<InlineSpan> _buildTranslationSpans() {
    if (translationList.isEmpty ||
        ayahIndex <= 0 ||
        ayahIndex > translationList.length) {
      return [const TextSpan(text: '')];
    }

    final translation = translationList[ayahIndex - 1];
    final spans = <InlineSpan>[
      // النص الأساسي بدون HTML tags
      TextSpan(text: translation.cleanText),
    ];

    // إضافة الحواشي إذا وجدت
    final footnotes = translation.orderedFootnotesWithNumbers;
    if (footnotes.isNotEmpty) {
      spans.add(const TextSpan(text: '\n\n'));

      // إضافة خط فاصل
      spans.add(WidgetSpan(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: 1,
          color: (isDark ? Colors.white30 : Colors.black26),
        ),
      ));
      spans.add(const TextSpan(text: '\n'));

      spans.add(TextSpan(
        text: 'الحواشي:\n',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: fontSizeArabic * 0.95,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ));

      for (final footnoteEntry in footnotes) {
        final number = footnoteEntry.key;
        final footnoteData = footnoteEntry.value;

        spans.add(TextSpan(
          children: [
            TextSpan(
              text: '($number) ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSizeArabic * 0.9,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            TextSpan(
              text: '${footnoteData.value}\n\n',
              style: TextStyle(
                fontSize: fontSizeArabic * 0.85,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ));
      }
    }

    return spans;
  }
}
