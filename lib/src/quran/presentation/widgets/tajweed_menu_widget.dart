part of '/quran.dart';

class TajweedMenuWidget extends StatelessWidget {
  final String languageCode;
  final bool isDark;
  TajweedMenuWidget(
      {super.key, required this.languageCode, required this.isDark});
  final quranCtrl = QuranCtrl.instance;

  @override
  Widget build(BuildContext context) {
    final rule =
        quranCtrl.getTajweedRulesListForLanguage(languageCode: languageCode);
    return GetBuilder<QuranCtrl>(
        id: 'isShowControl',
        builder: (quranCtrl) {
          final visible = quranCtrl.isShowControl.value;
          return visible && QuranCtrl.instance.state.fontsSelected.value == 2
              ? FloatingMenuExpendable(
                  controller: quranCtrl.state.floatingController,
                  panelWidth: 460,
                  panelHeight: 360,
                  handleWidth: 65,
                  handleHeight: 65,
                  expandPanelFromHandle: true,
                  initialPosition: const Offset(12, 60),
                  openMode: FloatingMenuExpendableOpenMode.vertical,
                  style: FloatingMenuExpendableStyle(
                    barrierColor: AppColors.getBackgroundColor(isDark)
                        .withValues(alpha: 0.35),
                    barrierBlurSigmaX: 10,
                    barrierBlurSigmaY: 10,
                    panelBorderRadius:
                        const BorderRadius.all(Radius.circular(8)),
                    panelDecoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      border: Border.all(
                        color: Colors.teal.withValues(alpha: 0.60),
                      ),
                    ),
                    handleInkBorderRadius: BorderRadius.circular(8),
                  ),
                  handleChild: Container(
                    height: 65,
                    width: 65,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ArabicJustifiedText(
                      'أحكام التجويد',
                      style: TextStyle(
                        color: AppColors.getTextColor(isDark),
                        fontSize: 16,
                        height: 1.3,
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                        package: 'quran_library',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  panelChild: Container(
                    color: Colors.teal,
                    child: Container(
                      margin: const EdgeInsets.all(4.0),
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      decoration: BoxDecoration(
                        color: AppColors.getBackgroundColor(isDark),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView(
                        children: List.generate(
                          rule.length,
                          (i) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 2.0, horizontal: 8.0),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 6.0),
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Color(isDark
                                            ? rule[i].darkColor
                                            : rule[i].color)
                                        .withValues(alpha: 0.1),
                                    Colors.transparent,
                                  ]),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.teal.withValues(alpha: .2),
                                    width: 1,
                                  )),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: Color(isDark
                                          ? rule[i].darkColor
                                          : rule[i].color),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      rule[i].text[languageCode] ??
                                          rule[i].text['ar']!,
                                      style: TextStyle(
                                        color: AppColors.getTextColor(isDark),
                                        fontSize: 16,
                                        fontFamily: 'cairo',
                                        fontWeight: FontWeight.w500,
                                        package: 'quran_library',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink();
        });
  }
}
