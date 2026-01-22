part of '/quran.dart';

TextSpan _buildMarkedContentSpan({
  required String content,
  required TextStyle baseStyle,
  required TextStyle markedStyle,
}) {
  if (content.isEmpty) return TextSpan(text: '', style: baseStyle);

  final spans = <InlineSpan>[];
  int i = 0;
  while (i < content.length) {
    final start = content.indexOf('@', i);
    if (start == -1) {
      spans.add(TextSpan(text: content.substring(i), style: baseStyle));
      break;
    }

    if (start > i) {
      spans.add(TextSpan(text: content.substring(i, start), style: baseStyle));
    }

    final end = content.indexOf('/', start + 1);
    if (end == -1) {
      spans.add(TextSpan(text: content.substring(start), style: baseStyle));
      break;
    }

    if (end > start + 1) {
      spans.add(
        TextSpan(
          text: content.substring(start + 1, end),
          style: markedStyle,
        ),
      );
    }

    // نستبدل '/' بمسافة واحدة (بدون مضاعفة المسافات إن كان بعدها فراغ).
    final nextIndex = end + 1;
    final hasNext = nextIndex < content.length;
    final nextIsWhitespace =
        hasNext ? RegExp(r'\s').hasMatch(content[nextIndex]) : false;
    if (!nextIsWhitespace) {
      spans.add(TextSpan(text: ' ', style: baseStyle));
    }

    i = end + 1;
  }

  return TextSpan(children: spans, style: baseStyle);
}

Future<void> showWordInfoDialog({
  required BuildContext context,
  required WordRef ref,
  WordInfoKind initialKind = WordInfoKind.recitations,
  required bool isDark,
}) async {
  final ctrl = WordInfoCtrl.instance;
  ctrl.setSelectedKind(initialKind);

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: WordInfoDialog(
        ref: ref,
        initialKind: initialKind,
        ctrl: ctrl,
        isDark: isDark,
      ),
    ),
  );
}

class WordInfoDialog extends StatelessWidget {
  const WordInfoDialog({
    super.key,
    required this.ref,
    required this.initialKind,
    required this.ctrl,
    required this.isDark,
  });

  final WordRef ref;
  final WordInfoKind initialKind;
  final WordInfoCtrl ctrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      Tab(text: 'القراءات'),
      Tab(text: 'التصريف'),
      Tab(text: 'الإعراب'),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
      child: Container(
        height: 450,
        width: 350,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: AppColors.getBackgroundColor(isDark),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: HeaderDialogWidget(
                isDark: isDark,
                title: 'عن الكلمة',
                // titleColor: defaults.headerTitleColor,
                // closeIconColor: defaults.headerCloseIconColor,
                // backgroundGradient: defaults.headerBackgroundGradient,
              ),
            ),
            Expanded(
              child: GetBuilder<WordInfoCtrl>(
                id: 'word_info_kind',
                builder: (_) {
                  return DefaultTabController(
                    length: tabs.length,
                    initialIndex: initialKind.index,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TabBar(
                          onTap: (index) {
                            ctrl.setSelectedKind(WordInfoKind.values[index]);
                          },
                          labelStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextColor(isDark),
                            fontFamily: 'cairo',
                            package: 'quran_library',
                          ),
                          tabs: tabs,
                        ),
                        const Divider(height: 1),
                        Flexible(
                          child: TabBarView(
                            children: [
                              _WordInfoKindTab(
                                kind: WordInfoKind.recitations,
                                kindLabelAr: 'القراءات',
                                ref: ref,
                                ctrl: ctrl,
                                isDark: isDark,
                              ),
                              _WordInfoKindTab(
                                kind: WordInfoKind.tasreef,
                                kindLabelAr: 'التصريف',
                                ref: ref,
                                ctrl: ctrl,
                                isDark: isDark,
                              ),
                              _WordInfoKindTab(
                                kind: WordInfoKind.eerab,
                                kindLabelAr: 'الإعراب',
                                ref: ref,
                                ctrl: ctrl,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordInfoKindTab extends StatelessWidget {
  const _WordInfoKindTab({
    required this.kind,
    required this.kindLabelAr,
    required this.ref,
    required this.ctrl,
    required this.isDark,
  });

  final WordInfoKind kind;
  final String kindLabelAr;
  final WordRef ref;
  final WordInfoCtrl ctrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WordInfoCtrl>(
      id: 'word_info_download',
      builder: (_) {
        final isAvailable = ctrl.isKindAvailable(kind);
        final isDownloading =
            ctrl.isDownloading.value && ctrl.downloadingKind.value == kind;

        if (!isAvailable) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بيانات $kindLabelAr غير محمّلة على الجهاز.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getTextColor(isDark),
                    fontFamily: 'cairo',
                    package: 'quran_library',
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isDownloading
                        ? null
                        : () async {
                            await ctrl.downloadKind(kind);
                          },
                    child: isDownloading
                        ? Text(
                            'جاري التحميل...',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.getTextColor(isDark),
                              fontFamily: 'cairo',
                              package: 'quran_library',
                            ),
                          )
                        : Text(
                            'تحميل',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.getTextColor(isDark),
                              fontFamily: 'cairo',
                              package: 'quran_library',
                            ),
                          ),
                  ),
                ),
                if (isDownloading || ctrl.isPreparingDownload.value) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: ctrl.downloadProgress.value > 0
                        ? (ctrl.downloadProgress.value / 100).clamp(0, 1)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${ctrl.downloadProgress.value.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getTextColor(isDark),
                      fontFamily: 'cairo',
                      package: 'quran_library',
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return GetBuilder<WordInfoCtrl>(
          id: 'word_info_data',
          builder: (_) {
            final f = ctrl.getWordInfo(kind: kind, ref: ref);
            return FutureBuilder<QiraatWordInfo?>(
              future: f,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                }

                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'تعذّر تحميل بيانات هذه الكلمة.\n${snap.error}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextColor(isDark),
                        fontFamily: 'cairo',
                        package: 'quran_library',
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  );
                }

                final data = snap.data;
                if (data == null) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'لا توجد بيانات لهذه الكلمة.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextColor(isDark),
                        fontFamily: 'cairo',
                        package: 'quran_library',
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  );
                }

                final wordColor =
                    (kind == WordInfoKind.recitations && data.hasKhilaf)
                        ? Colors.red
                        : AppColors.getTextColor(isDark);
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        data.word,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: wordColor,
                          fontFamily: 'cairo',
                          package: 'quran_library',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText.rich(
                        _buildMarkedContentSpan(
                          content: data.content,
                          baseStyle: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppColors.getTextColor(isDark),
                            fontFamily: 'cairo',
                            package: 'quran_library',
                          ),
                          markedStyle: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
