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
    final atIndex = content.indexOf('@', i);
    final curlyIndex = content.indexOf('{', i);
    final parenIndex = content.indexOf('(', i);

    int next = content.length;
    String? marker;
    if (atIndex != -1 && atIndex < next) {
      next = atIndex;
      marker = '@';
    }
    if (curlyIndex != -1 && curlyIndex < next) {
      next = curlyIndex;
      marker = '{';
    }
    if (parenIndex != -1 && parenIndex < next) {
      next = parenIndex;
      marker = '(';
    }

    if (marker == null) {
      spans.add(TextSpan(text: content.substring(i), style: baseStyle));
      break;
    }

    if (next > i) {
      spans.add(TextSpan(text: content.substring(i, next), style: baseStyle));
    }

    if (marker == '@') {
      final end = content.indexOf('/', next + 1);
      if (end == -1) {
        spans.add(TextSpan(text: content.substring(next), style: baseStyle));
        break;
      }

      if (end > next + 1) {
        spans.add(
          TextSpan(
            text: content.substring(next + 1, end),
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
      continue;
    }

    if (marker == '{') {
      final end = content.indexOf('}', next + 1);
      if (end == -1) {
        spans.add(TextSpan(text: content.substring(next), style: baseStyle));
        break;
      }

      spans.add(TextSpan(text: '{', style: baseStyle));
      if (end > next + 1) {
        spans.add(
          TextSpan(
            text: content.substring(next + 1, end),
            style: markedStyle,
          ),
        );
      }
      spans.add(TextSpan(text: '}', style: baseStyle));
      i = end + 1;
      continue;
    }

    // marker == '('
    final end = content.indexOf(')', next + 1);
    if (end == -1) {
      spans.add(TextSpan(text: content.substring(next), style: baseStyle));
      break;
    }

    spans.add(TextSpan(text: '(', style: baseStyle));
    if (end > next + 1) {
      spans.add(
        TextSpan(
          text: content.substring(next + 1, end),
          style: markedStyle,
        ),
      );
    }
    spans.add(TextSpan(text: ')', style: baseStyle));
    i = end + 1;
  }

  return TextSpan(children: spans, style: baseStyle);
}

Future<void> showWordInfoBottomSheet({
  required BuildContext context,
  required WordRef ref,
  WordInfoKind initialKind = WordInfoKind.recitations,
  required bool isDark,
}) async {
  final ctrl = WordInfoCtrl.instance;
  ctrl.setSelectedKind(initialKind);

  final WordInfoBottomSheetStyle defaults =
      WordInfoDialogTheme.of(context)?.style ??
          WordInfoBottomSheetStyle.defaults(isDark: isDark, context: context);
  final size = MediaQuery.sizeOf(context);
  final maxHFactor = (defaults.maxHeightFactor ?? 0.9).clamp(0.0, 1.0);
  final maxWFactor = (defaults.maxWidthFactor ?? 1.0).clamp(0.0, 1.0);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    constraints: BoxConstraints(
      maxHeight: size.height * maxHFactor,
      maxWidth: size.width * maxWFactor,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext modalContext) {
      return WordInfoDialog(
        ref: ref,
        initialKind: initialKind,
        ctrl: ctrl,
        isDark: isDark,
      );
    },
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

    final WordInfoBottomSheetStyle defaults =
        WordInfoDialogTheme.of(context)?.style ??
            WordInfoBottomSheetStyle.defaults(isDark: isDark, context: context);

    return Container(
      padding: defaults.padding ?? const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: defaults.backgroundColor ?? AppColors.getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(defaults.borderRadius ?? 12),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // خط فاصل جمالي
          Container(
            width: defaults.handleWidth ?? 60,
            height: defaults.handleHeight ?? 5,
            margin: defaults.handleMargin ?? const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: defaults.handleColor ?? Colors.grey.shade500,
              borderRadius:
                  BorderRadius.circular(defaults.handleBorderRadius ?? 3),
            ),
          ),
          Text(
            defaults.titleText ?? 'عن الكلمة',
            style: defaults.titleTextStyle ??
                TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDark),
                  fontFamily: 'cairo',
                  package: 'quran_library',
                ),
          ),
          const SizedBox(height: 8),
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
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: defaults.horizontalMargin ?? 8,
                        ),
                        decoration: BoxDecoration(
                          color: defaults.tabIndicatorColor!
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          onTap: (index) {
                            ctrl.setSelectedKind(WordInfoKind.values[index]);
                          },
                          labelStyle: defaults.tabLabelStyle ??
                              TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextColor(isDark),
                                fontFamily: 'cairo',
                                package: 'quran_library',
                              ),
                          indicator: BoxDecoration(
                            color: defaults.tabIndicatorColor ??
                                (Theme.of(context).colorScheme.primary)
                                    .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                                defaults.tabIndicatorRadius ?? 10),
                          ),
                          indicatorPadding: defaults.tabIndicatorPadding ??
                              const EdgeInsets.all(4),
                          tabs: tabs,
                        ),
                      ),
                      Flexible(
                        child: TabBarView(
                          children: [
                            _WordInfoKindTab(
                              kind: WordInfoKind.recitations,
                              kindLabelAr: 'القراءات',
                              ref: ref,
                              ctrl: ctrl,
                              isDark: isDark,
                              style: defaults,
                            ),
                            _WordInfoKindTab(
                              kind: WordInfoKind.tasreef,
                              kindLabelAr: 'التصريف',
                              ref: ref,
                              ctrl: ctrl,
                              isDark: isDark,
                              style: defaults,
                            ),
                            _WordInfoKindTab(
                              kind: WordInfoKind.eerab,
                              kindLabelAr: 'الإعراب',
                              ref: ref,
                              ctrl: ctrl,
                              isDark: isDark,
                              style: defaults,
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
    required this.style,
  });

  final WordInfoKind kind;
  final String kindLabelAr;
  final WordRef ref;
  final WordInfoCtrl ctrl;
  final bool isDark;
  final WordInfoBottomSheetStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: style.verticalMargin ?? 8,
        horizontal: style.horizontalMargin ?? 8,
      ),
      padding: style.innerContainerPadding ?? const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: style.textBackgroundColor ??
            style.backgroundColor ??
            AppColors.getBackgroundColor(isDark),
        borderRadius:
            BorderRadius.circular(style.innerContainerBorderRadius ?? 16),
        boxShadow: [
          BoxShadow(
            color: style.innerShadowColor ?? Colors.grey.withValues(alpha: 0.1),
            blurRadius: style.innerShadowBlurRadius ?? 8,
            offset: style.innerShadowOffset ?? const Offset(0, 0),
          ),
        ],
        border: Border.symmetric(
          horizontal: BorderSide(
            color:
                style.tabIndicatorColor ?? Colors.grey.withValues(alpha: 0.3),
            width: style.innerBorderWidth ?? 1.2,
          ),
        ),
      ),
      child: GetBuilder<WordInfoCtrl>(
        id: 'word_info_download',
        builder: (_) {
          final isAvailable = ctrl.isKindAvailable(kind);
          final isDownloading =
              ctrl.isDownloading.value && ctrl.downloadingKind.value == kind;

          if (!isAvailable) {
            return Padding(
              padding: style.contentPadding ?? const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'بيانات $kindLabelAr غير محمّلة على الجهاز.',
                    style: style.bodyTextStyle ??
                        TextStyle(
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
                              style: style.buttonTextStyle ??
                                  TextStyle(
                                    fontSize: 14,
                                    color: AppColors.getTextColor(isDark),
                                    fontFamily: 'cairo',
                                    package: 'quran_library',
                                  ),
                            )
                          : Text(
                              'تحميل',
                              style: style.buttonTextStyle ??
                                  TextStyle(
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
                      style: style.progressTextStyle ??
                          TextStyle(
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
                      padding: style.contentPadding ?? const EdgeInsets.all(16),
                      child: Text(
                        'تعذّر تحميل بيانات هذه الكلمة.\n${snap.error}',
                        style: style.bodyTextStyle ??
                            TextStyle(
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
                      padding: style.contentPadding ?? const EdgeInsets.all(16),
                      child: Text(
                        'لا توجد بيانات لهذه الكلمة.',
                        style: style.bodyTextStyle ??
                            TextStyle(
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
                    padding: style.contentPadding ?? const EdgeInsets.all(16),
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
      ),
    );
  }
}
