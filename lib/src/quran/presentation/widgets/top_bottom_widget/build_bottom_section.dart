part of '/quran.dart';

class BuildBottomSection extends StatelessWidget {
  BuildBottomSection({
    super.key,
    required this.pageIndex,
    required this.sajdaName,
    required this.isRight,
    required this.languageCode,
  });

  final bool isRight;
  final int pageIndex;
  final String? sajdaName;
  final String languageCode;
  final quranCtrl = QuranCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return isRight
        ? Stack(
            alignment: Alignment.center,
            children: [
              // شرح: ربع الحزب (يمين)
              // Explanation: Hizb quarter (right)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    quranCtrl
                        .getHizbQuarterDisplayByPage(pageIndex + 1)
                        .convertNumbersAccordingToLang(
                            languageCode: languageCode),
                    style: _getTextStyle(context),
                  ),
                ),
              ),

              // شرح: رقم الصفحة (وسط)
              // Explanation: Page number (center)
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  '${pageIndex + 1}'.convertNumbersAccordingToLang(
                      languageCode: languageCode),
                  style: _getPageNumberStyle(context),
                ),
              ),

              // شرح: السجدة (يسار)
              // Explanation: Sajda (left)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: showSajda(context, pageIndex, sajdaName ?? 'سجدة'),
                ),
              ),
            ],
          )
        : Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: showSajda(context, pageIndex, sajdaName ?? 'سجدة'),
                ),
              ),

              // شرح: رقم الصفحة (وسط)
              // Explanation: Page number (center)
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  '${pageIndex + 1}'.convertNumbersAccordingToLang(
                      languageCode: languageCode),
                  style: _getPageNumberStyle(context),
                ),
              ),

              // شرح: ربع الحزب (يسار)
              // Explanation: Hizb quarter (left)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    quranCtrl
                        .getHizbQuarterDisplayByPage(pageIndex + 1)
                        .convertNumbersAccordingToLang(
                            languageCode: languageCode),
                    style: _getTextStyle(context),
                  ),
                ),
              ),
            ],
          );
  }

  /// الحصول على نمط رقم الصفحة
  /// Get page number style
  TextStyle _getPageNumberStyle(BuildContext context) {
    return TextStyle(
      fontSize: UiHelper.currentOrientation(20.0, 22.0, context),
      fontFamily: 'naskh',
      color: const Color(0xff77554B),
      package: 'quran_library',
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
