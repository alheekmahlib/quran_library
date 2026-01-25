part of '/quran.dart';

class QuranOrTenRecitationsTabBar extends StatelessWidget {
  const QuranOrTenRecitationsTabBar({
    super.key,
    required this.bgColor,
    required this.defaults,
    required this.isDark,
  });

  final Color bgColor;
  final QuranTopBarStyle defaults;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return !QuranCtrl.instance.state.isTajweedEnabled.value &&
            (QuranCtrl.instance.state.fontsSelected.value == 1)
        ? DefaultTabController(
            length: 2,
            child: Container(
              height: 45,
              width: 250,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius:
                    BorderRadius.circular(defaults.borderRadius ?? 12),
                boxShadow: [
                  BoxShadow(
                    color: (defaults.shadowColor ??
                        Colors.black.withValues(alpha: .1)),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TabBar(
                controller: WordInfoCtrl.instance.tabController,
                onTap: (index) async {
                  // عند اختيار "القراءات العشر" تأكد من أن البيانات محمّلة.
                  if (index == 1 &&
                      !WordInfoCtrl.instance
                          .isKindAvailable(WordInfoKind.recitations)) {
                    // امنع الانتقال للتبويب قبل التحميل.
                    Future.microtask(() {
                      if (WordInfoCtrl.instance.tabController.index != 0) {
                        WordInfoCtrl.instance.tabController.index = 0;
                      }
                    });

                    final fallbackRef =
                        WordInfoCtrl.instance.selectedWordRef.value ??
                            const WordRef(
                              surahNumber: 1,
                              ayahNumber: 1,
                              wordNumber: 1,
                            );

                    await showWordInfoBottomSheet(
                      context: context,
                      ref: fallbackRef,
                      initialKind: WordInfoKind.recitations,
                      isDark: isDark,
                    );

                    if (WordInfoCtrl.instance
                        .isKindAvailable(WordInfoKind.recitations)) {
                      WordInfoCtrl.instance.tabController.index = 1;
                    }
                  }

                  WordInfoCtrl.instance.update(['word_info_data']);
                  log('تم اختيار التبويب: $index');
                },
                indicator: BoxDecoration(
                  color: (defaults.accentColor ??
                          Theme.of(context).colorScheme.primary)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelStyle: defaults.tabLabelStyle,
                tabs: [
                  Tab(text: defaults.quranTabText),
                  Tab(text: defaults.tenRecitationsTabText),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}
