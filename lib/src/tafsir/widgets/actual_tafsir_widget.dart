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
    required this.surahs,
    this.islocalFont,
    this.fontsName,
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
  final SurahModel surahs;
  final bool? islocalFont;
  final String? fontsName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GetSingleAyah(
          surahNumber: surahs.surahNumber,
          ayahNumber: ayahs.ayahNumber,
          fontSize: 24,
          isBold: false,
          ayahs: ayahs,
          isSingleAyah: false,
          islocalFont: islocalFont,
          fontsName: fontsName,
          isDark: isDark,
          textColor:
              tafsirStyle.textColor ?? (isDark ? Colors.white : Colors.black),
        ),
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
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
                          color: tafsirStyle.textColor ??
                              (isDark ? Colors.white : Colors.black),
                          height: 1.5,
                          fontSize: tafsirStyle.fontSize ?? fontSizeArabic),
                    )
                  : TextSpan(
                      children: _buildTranslationSpans(),
                      style: TextStyle(
                          color: tafsirStyle.textColor ??
                              (isDark ? Colors.white : Colors.black),
                          height: 1.5,
                          fontSize: tafsirStyle.fontSize ?? fontSizeArabic),
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
    if (translationList.isEmpty || ayahIndex <= 0) {
      return [const TextSpan(text: '')];
    }

    // استخدام دالة helper من TafsirCtrl للحصول على الترجمة
    final translation =
        TafsirCtrl.instance.getTranslationForAyahModel(ayahs, ayahIndex);

    if (translation == null) {
      if (kDebugMode) {
        print(
            'No translation found for Surah: ${ayahs.surahNumber}, Ayah: ${ayahs.ayahNumber}, Index: $ayahIndex, Total translations: ${translationList.length}');
      }
      return [
        const TextSpan(
            text:
                'لا توجد ترجمة لهذه الآية / No translation available for this verse')
      ];
    }
    final spans = <InlineSpan>[
      // النص الأساسي بدون HTML tags
      TextSpan(children: translation.cleanText.customTextSpans()),
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
          color: tafsirStyle.dividerColor ??
              (isDark ? Colors.white30 : Colors.black26),
        ),
      ));
      spans.add(const TextSpan(text: '\n'));

      spans.add(TextSpan(
        text: '${tafsirStyle.footnotesName ?? 'الحواشي:'}\n',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: fontSizeArabic * 0.95,
          color: tafsirStyle.textColor ??
              (isDark ? Colors.white70 : Colors.black87),
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
                color: tafsirStyle.textColor ??
                    (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            TextSpan(
              text: '${footnoteData.value}\n\n',
              style: TextStyle(
                fontSize: fontSizeArabic * 0.85,
                color: tafsirStyle.textColor ??
                    (isDark ? Colors.white60 : Colors.black54),
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
