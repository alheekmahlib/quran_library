part of '../../quran.dart';

/// ويدجت لعرض محتوى السورة المخصصة مع المعلومات المطلوبة
/// Widget for displaying custom surah content with required information
class AllQuranWidget extends StatelessWidget {
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

  AllQuranWidget({
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
    return context.currentOrientation(
      // شرح: التخطيط العمودي (Portrait)
      // Explanation: Portrait layout
      Stack(
        children: [
          // شرح: العنوان العلوي
          // Explanation: Top title
          Align(
            alignment: Alignment.topCenter,
            child: _buildTopSection(context),
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
            child: _buildBottomSection(context),
          ),
        ],
      ),

      // شرح: التخطيط الأفقي (Landscape)
      // Explanation: Landscape layout
      SingleChildScrollView(
        child: Column(
          children: [
            _buildTopSection(context),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: child,
            ),
            _buildBottomSection(context),
          ],
        ),
      ),
    );
  }

  /// بناء القسم العلوي
  /// Build top section
  Widget _buildTopSection(BuildContext context) {
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
                    : quranCtrl.getSurahsByPage(pageIndex).isNotEmpty
                        ? Row(
                            children: List.generate(
                                quranCtrl.getSurahsByPage(pageIndex).length,
                                (i) => Text(
                                      ' ${quranCtrl.getSurahsByPage(pageIndex)[i].arabicName.replaceAll('سُورَةُ ', '')} ',
                                      style: TextStyle(
                                          fontSize: context.currentOrientation(
                                              18.0, 22.0),
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
                    : quranCtrl.getSurahsByPage(pageIndex).isNotEmpty
                        ? Row(
                            children: List.generate(
                                quranCtrl.getSurahsByPage(pageIndex).length,
                                (i) => Text(
                                      ' ${quranCtrl.getSurahsByPage(pageIndex)[i].arabicName.replaceAll('سُورَةُ ', '')} ',
                                      style: TextStyle(
                                          fontSize: context.currentOrientation(
                                              18.0, 22.0),
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

  /// بناء القسم السفلي
  /// Build bottom section
  Widget _buildBottomSection(BuildContext context) {
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
                  '${pageIndex + 2}'.convertNumbersAccordingToLang(
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
                  child: showSajda(context, pageIndex, sajdaName ?? 'سجدة',
                      isSurah: isSurah, surahNumber: surahCtrl.surahNumber),
                ),
              ),
            ],
          )
        : Stack(
            alignment: Alignment.center,
            children: [
              // شرح: السجدة (يمين)
              // Explanation: Sajda (right)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: showSajda(context, pageIndex, sajdaName ?? 'سجدة',
                      isSurah: isSurah, surahNumber: surahCtrl.surahNumber),
                ),
              ),

              // شرح: رقم الصفحة (وسط)
              // Explanation: Page number (center)
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  '${pageIndex + 2}'.convertNumbersAccordingToLang(
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

  /// الحصول على نمط النص
  /// Get text style
  TextStyle _getTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: context.currentOrientation(18.0, 22.0),
      fontFamily: 'naskh',
      color: const Color(0xff77554B),
      package: 'quran_library',
    );
  }

  /// الحصول على نمط رقم الصفحة
  /// Get page number style
  TextStyle _getPageNumberStyle(BuildContext context) {
    return TextStyle(
      fontSize: context.currentOrientation(20.0, 22.0),
      fontFamily: 'naskh',
      color: const Color(0xff77554B),
      package: 'quran_library',
    );
  }

  /// الحصول على ربع الحزب
  /// Get Hizb quarter
  // String _getHizbQuarter() {
  //   try {
  //     // شرح: الحصول على ربع الحزب من أول آية في الصفحة
  //     // Explanation: Get Hizb quarter from first ayah in page
  //     if (surahCtrl.surahPages.isNotEmpty &&
  //         pageIndex < surahCtrl.surahPages.length) {
  //       final page = surahCtrl.surahPages[pageIndex];
  //       if (page.lines.isNotEmpty && page.lines.first.ayahs.isNotEmpty) {
  //         final ayah = page.lines.first.ayahs.first;
  //         final hizb = ayah.hizb ?? 1;

  //         int hizbNumber = ((hizb - 1) ~/ 4) + 1;
  //         int quarterPosition = (hizb - 1) % 4;

  //         switch (quarterPosition) {
  //           case 0:
  //             return "الحزب $hizbNumber";
  //           case 1:
  //             return "١/٤ الحزب $hizbNumber";
  //           case 2:
  //             return "١/٢ الحزب $hizbNumber";
  //           case 3:
  //             return "٣/٤ الحزب $hizbNumber";
  //           default:
  //             return "";
  //         }
  //       }
  //     }
  //     return "";
  //   } catch (e) {
  //     log('خطأ في الحصول على ربع الحزب: $e', name: 'AllSurahWidget');
  //     return "";
  //   }
  // }
}
