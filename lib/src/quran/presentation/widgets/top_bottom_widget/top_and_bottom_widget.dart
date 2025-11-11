part of '/quran.dart';

/// ويدجت لعرض محتوى السورة المخصصة مع المعلومات المطلوبة
/// Widget for displaying custom surah content with required information
class TopAndBottomWidget extends StatelessWidget {
  final int pageIndex;
  final bool isRight;
  final bool? isSurah;
  final int? surahNumber;
  final String? languageCode;
  @Deprecated(
      'In versions after 2.2.5 this parameter will be removed. Please use juzName in TopBottomQuranStyle instead.')
  final String? juzName;
  @Deprecated(
      'In versions after 2.2.5 this parameter will be removed. Please use sajdaName in TopBottomQuranStyle instead.')
  final String? sajdaName;
  @Deprecated(
      'In versions after 2.2.5 this parameter will be removed. Please use surahName in TopBottomQuranStyle instead.')
  final String? surahName;
  final Widget child;
  @Deprecated(
      'In versions after 2.2.5 this parameter will be removed. Please use topTitleChild in TopBottomQuranStyle instead.')
  final Widget? topTitleChild;

  TopAndBottomWidget({
    super.key,
    required this.pageIndex,
    required this.isRight,
    required this.child,
    this.languageCode,
    @Deprecated(
        'In versions after 2.2.5 this parameter will be removed. Please use juzName in TopBottomQuranStyle instead.')
    this.juzName,
    @Deprecated(
        'In versions after 2.2.5 this parameter will be removed. Please use sajdaName in TopBottomQuranStyle instead.')
    this.sajdaName,
    @Deprecated(
        'In versions after 2.2.5 this parameter will be removed. Please use topTitleChild in TopBottomQuranStyle instead.')
    this.topTitleChild,
    @Deprecated(
        'In versions after 2.2.5 this parameter will be removed. Please use surahName in TopBottomQuranStyle instead.')
    this.surahName,
    this.isSurah = false,
    this.surahNumber,
  });

  final surahCtrl = SurahCtrl.instance;
  final quranCtrl = QuranCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return UiHelper.currentOrientation(
      // شرح: التخطيط العمودي (Portrait)
      // Explanation: Portrait layout
      Stack(
        children: [
          // شرح: العنوان العلوي
          // Explanation: Top title
          Align(
            alignment: Alignment.topCenter,
            child: BuildTopSection(
              isRight: isRight,
              languageCode: languageCode,
              juzName: juzName,
              surahName: surahName,
              pageIndex: pageIndex,
              topTitleChild: topTitleChild,
              isSurah: isSurah!,
            ),
          ),

          // شرح: المحتوى الرئيسي
          // Explanation: Main content
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: child,
            ),
          ),

          // شرح: القسم السفلي
          // Explanation: Bottom section
          Align(
            alignment: Alignment.bottomCenter,
            child: BuildBottomSection(
                pageIndex: pageIndex,
                sajdaName: sajdaName,
                isRight: isRight,
                languageCode: languageCode!),
          ),
        ],
      ),

      // شرح: التخطيط الأفقي (Landscape)
      // Explanation: Landscape layout
      Responsive.isMobile(context) ||
              Responsive.isMobileLarge(context) ||
              Responsive.isDesktop(context)
          ? Column(
              children: [
                BuildTopSection(
                  isRight: isRight,
                  languageCode: languageCode,
                  juzName: juzName,
                  surahName: surahName,
                  pageIndex: pageIndex,
                  topTitleChild: topTitleChild,
                  isSurah: isSurah!,
                ),
                Flexible(
                  child: child,
                ),
                BuildBottomSection(
                    pageIndex: pageIndex,
                    sajdaName: sajdaName,
                    isRight: isRight,
                    languageCode: languageCode!),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  BuildTopSection(
                    isRight: isRight,
                    languageCode: languageCode,
                    juzName: juzName,
                    surahName: surahName,
                    pageIndex: pageIndex,
                    topTitleChild: topTitleChild,
                    isSurah: isSurah!,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: child,
                  ),
                  BuildBottomSection(
                      pageIndex: pageIndex,
                      sajdaName: sajdaName,
                      isRight: isRight,
                      languageCode: languageCode!),
                ],
              ),
            ),
      context,
    );
  }
}
