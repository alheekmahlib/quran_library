part of '/quran.dart';

/// ويدجت لعرض محتوى السورة المخصصة مع المعلومات المطلوبة
/// Widget for displaying custom surah content with required information
class TopAndBottomWidget extends StatelessWidget {
  final int pageIndex;
  final bool isRight;
  final bool? isSurah;
  final int? surahNumber;
  final String? languageCode;
  final String? juzName;
  final String? sajdaName;
  final String? surahName;
  final Widget child;
  final Widget? topTitleChild;

  TopAndBottomWidget({
    super.key,
    required this.pageIndex,
    required this.isRight,
    required this.child,
    this.languageCode,
    this.juzName,
    this.sajdaName,
    this.topTitleChild,
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
