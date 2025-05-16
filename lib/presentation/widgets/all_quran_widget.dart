part of '../../quran.dart';

class AllQuranWidget extends StatelessWidget {
  final int pageIndex;
  final bool isRight;
  final String? languageCode;
  final String? juzName;
  final String? sajdaName;
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
  });

  final quranCtrl = QuranCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return context.currentOrientation(
        Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
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
                            style: TextStyle(
                                fontSize:
                                    context.currentOrientation(18.0, 22.0),
                                // fontWeight: FontWeight.bold,
                                fontFamily: 'naskh',
                                color: const Color(0xff77554B)),
                          ),
                          const Spacer(),
                          quranCtrl.getSurahsByPage(pageIndex).isNotEmpty
                              ? Row(
                                  children: List.generate(
                                      quranCtrl
                                          .getSurahsByPage(pageIndex)
                                          .length,
                                      (i) => Text(
                                            ' ${quranCtrl.getSurahsByPage(pageIndex)[i].arabicName.replaceAll('سُورَةُ ', '')} ',
                                            style: TextStyle(
                                                fontSize:
                                                    context.currentOrientation(
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
                          quranCtrl.getSurahsByPage(pageIndex).isNotEmpty
                              ? Row(
                                  children: List.generate(
                                      quranCtrl
                                          .getSurahsByPage(pageIndex)
                                          .length,
                                      (i) => Text(
                                            ' ${quranCtrl.getSurahsByPage(pageIndex)[i].arabicName.replaceAll('سُورَةُ ', '')} ',
                                            style: TextStyle(
                                                fontSize:
                                                    context.currentOrientation(
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
                            style: TextStyle(
                                fontSize:
                                    context.currentOrientation(18.0, 22.0),
                                // fontWeight: FontWeight.bold,
                                fontFamily: 'naskh',
                                color: const Color(0xff77554B)),
                          ),
                          const SizedBox(width: 16),
                          topTitleChild ?? const SizedBox.shrink(),
                        ],
                      ),
              ),
            ),
            Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: child,
                )),
            Align(
              alignment: Alignment.bottomCenter,
              child: isRight
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              quranCtrl
                                  .getHizbQuarterDisplayByPage(pageIndex + 1)
                                  .convertNumbersAccordingToLang(
                                      languageCode: languageCode),
                              style: TextStyle(
                                fontSize:
                                    context.currentOrientation(18.0, 22.0),
                                fontFamily: 'naskh',
                                color: const Color(0xff77554B),
                                package: 'quran_library',
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            '${pageIndex + 1}'.convertNumbersAccordingToLang(
                                languageCode: languageCode),
                            style: TextStyle(
                              fontSize: context.currentOrientation(20.0, 22.0),
                              fontFamily: 'naskh',
                              color: const Color(0xff77554B),
                              package: 'quran_library',
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: showSajda(
                                  context, pageIndex, sajdaName ?? 'سجدة')),
                        ),
                      ],
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: showSajda(
                                  context, pageIndex, sajdaName ?? 'سجدة')),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            '${pageIndex + 1}'.convertNumbersAccordingToLang(
                                languageCode: languageCode),
                            style: TextStyle(
                              fontSize: context.currentOrientation(20.0, 22.0),
                              fontFamily: 'naskh',
                              color: const Color(0xff77554B),
                              package: 'quran_library',
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              quranCtrl
                                  .getHizbQuarterDisplayByPage(pageIndex + 1)
                                  .convertNumbersAccordingToLang(
                                      languageCode: languageCode),
                              style: TextStyle(
                                fontSize:
                                    context.currentOrientation(18.0, 22.0),
                                fontFamily: 'naskh',
                                color: const Color(0xff77554B),
                                package: 'quran_library',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            )
          ],
        ),
        SingleChildScrollView(
          child: Column(
            children: [
              Padding(
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
                            style: TextStyle(
                                fontSize:
                                    context.currentOrientation(18.0, 22.0),
                                // fontWeight: FontWeight.bold,
                                fontFamily: 'naskh',
                                color: const Color(0xff77554B)),
                          ),
                          const Spacer(),
                          Row(
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
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Row(
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
                          ),
                          const Spacer(),
                          Text(
                            '${juzName ?? 'الجزء'}: ${quranCtrl.getJuzByPage(pageIndex).juz}'
                                .convertNumbersAccordingToLang(
                                    languageCode: languageCode),
                            style: TextStyle(
                                fontSize:
                                    context.currentOrientation(18.0, 22.0),
                                // fontWeight: FontWeight.bold,
                                fontFamily: 'naskh',
                                color: const Color(0xff77554B)),
                          ),
                          const SizedBox(width: 16),
                          topTitleChild ?? const SizedBox.shrink(),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: child,
              ),
              isRight
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              quranCtrl
                                  .getHizbQuarterDisplayByPage(pageIndex + 1)
                                  .convertNumbersAccordingToLang(
                                      languageCode: languageCode),
                              style: TextStyle(
                                fontSize:
                                    context.currentOrientation(18.0, 22.0),
                                fontFamily: 'naskh',
                                color: const Color(0xff77554B),
                                package: 'quran_library',
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            '${pageIndex + 1}'.convertNumbersAccordingToLang(
                                languageCode: languageCode),
                            style: TextStyle(
                              fontSize: context.currentOrientation(20.0, 22.0),
                              fontFamily: 'naskh',
                              color: const Color(0xff77554B),
                              package: 'quran_library',
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: showSajda(
                                  context, pageIndex, sajdaName ?? 'سجدة')),
                        ),
                      ],
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: showSajda(
                                  context, pageIndex, sajdaName ?? 'سجدة')),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            '${pageIndex + 1}'.convertNumbersAccordingToLang(
                                languageCode: languageCode),
                            style: TextStyle(
                              fontSize: context.currentOrientation(20.0, 22.0),
                              fontFamily: 'naskh',
                              color: const Color(0xff77554B),
                              package: 'quran_library',
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              quranCtrl
                                  .getHizbQuarterDisplayByPage(pageIndex + 1)
                                  .convertNumbersAccordingToLang(
                                      languageCode: languageCode),
                              style: TextStyle(
                                fontSize:
                                    context.currentOrientation(18.0, 22.0),
                                fontFamily: 'naskh',
                                color: const Color(0xff77554B),
                                package: 'quran_library',
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
            ],
          ),
        ));
  }
}
