part of '../audio.dart';

/// BottomSheet احترافي لإدارة تحميل/حذف آيات السور حسب القارئ الحالي
class AyahDownloadManagerSheet extends StatelessWidget {
  final Future<void> Function(int surahNumber) onRequestDownload;
  final Future<void> Function(int surahNumber) onRequestDelete;
  final Future<bool> Function(int surahNumber) isSurahDownloadedChecker;
  final int? initialSurahToFocus;
  final AyahDownloadManagerStyle? style;
  final bool? isDark;
  final String? language;
  final AyahAudioStyle? ayahStyle;

  const AyahDownloadManagerSheet({
    super.key,
    required this.onRequestDownload,
    required this.onRequestDelete,
    required this.isSurahDownloadedChecker,
    this.initialSurahToFocus,
    this.style,
    this.isDark = false,
    this.language,
    this.ayahStyle,
  });

  @override
  Widget build(BuildContext context) {
    final audioCtrl = AudioCtrl.instance;
    final surahs = QuranCtrl.instance.surahs;
    final controller = ScrollController();

    // مفاتيح لكل عنصر لضمان تمرير scroll دقيق للعنصر المطلوب
    final Map<int, GlobalKey> itemKeys = {
      for (final s in surahs) s.surahNumber: GlobalKey()
    };

    // تنفيذ التمرير إلى السورة المطلوبة بعد أول frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (initialSurahToFocus != null) {
        final key = itemKeys[initialSurahToFocus!];
        final ctx = key?.currentContext;
        if (ctx != null) {
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            alignment: 0.2,
            curve: Curves.easeInOut,
          );
        } else if (controller.hasClients) {
          final index =
              surahs.indexWhere((s) => s.surahNumber == initialSurahToFocus);
          if (index >= 0) {
            await controller.animateTo(
              (index * 78).toDouble(),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        }
      }
    });

    return SizedBox(
      height: context.height * 0.8,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: style?.handleColor ?? Colors.grey.shade300,
              borderRadius: BorderRadius.circular(style?.handleRadius ?? 8),
            ),
          ),
          const SizedBox(height: 12),
          HeaderBuild(style: style, isDark: isDark, ayahStyle: ayahStyle),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              final isBusy = audioCtrl.state.isDownloading.value;
              return ListView.separated(
                controller: controller,
                padding: const EdgeInsets.only(
                    bottom: 16, top: 8, left: 16, right: 16),
                itemCount: surahs.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: style?.separatorColor,
                ),
                itemBuilder: (context, index) {
                  final s = surahs[index];
                  final itemKey = itemKeys[s.surahNumber]!;

                  return KeyedSubtree(
                    key: itemKey,
                    child: GetBuilder<AudioCtrl>(
                      id: 'ayahDownloadManager',
                      builder: (audioCtrl) {
                        // حساب عدد الآيات المحمّلة لهذه السورة
                        int downloaded = 0;
                        for (final ayah in s.ayahs) {
                          if (audioCtrl.state
                                  .ayahsDownloadStatus[ayah.ayahUQNumber] ==
                              true) {
                            downloaded++;
                          }
                        }
                        final total = s.ayahs.length;
                        final progress = total == 0 ? 0.0 : downloaded / total;
                        final fullyDownloaded =
                            total > 0 && downloaded == total;

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            ProgressIndicatorWidget(
                                style: style,
                                progress: progress,
                                fullyDownloaded: fullyDownloaded),
                            ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: style?.itemHorizontalPadding ?? 16,
                                vertical: style?.itemVerticalPadding ?? 8,
                              ),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: fullyDownloaded
                                    ? (style?.avatarDownloadedColor ??
                                        Colors.teal)
                                    : (style?.avatarUndownloadedColor ??
                                            Colors.teal)
                                        .withValues(alpha: .4),
                                child: Text(
                                  s.surahNumber
                                      .toString()
                                      .convertNumbersAccordingToLang(
                                          languageCode: language ?? 'ar'),
                                  style: style?.avatarTextStyle ??
                                      const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    s.surahNumber.toString(),
                                    style: style?.surahTitleStyle ??
                                        TextStyle(
                                          color: AppColors.getTextColor(
                                              isDark ?? false),
                                          fontFamily: "surahName",
                                          fontSize: style?.surahNameSize ?? 30,
                                          height: 1.2,
                                          package: "quran_library",
                                        ),
                                  ),
                                  DownloadedTextWidget(
                                    style: style,
                                    downloaded: downloaded,
                                    total: total,
                                    language: language,
                                  ),
                                ],
                              ),
                              trailing: DownloadedAndDeleteWidget(
                                fullyDownloaded: fullyDownloaded,
                                style: style,
                                isBusy: isBusy,
                                onRequestDelete: onRequestDelete,
                                s: s,
                                onRequestDownload: onRequestDownload,
                                audioCtrl: audioCtrl,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class DownloadedAndDeleteWidget extends StatelessWidget {
  const DownloadedAndDeleteWidget({
    super.key,
    required this.fullyDownloaded,
    required this.style,
    required this.isBusy,
    required this.onRequestDelete,
    required this.s,
    required this.onRequestDownload,
    required this.audioCtrl,
  });

  final bool fullyDownloaded;
  final AyahDownloadManagerStyle? style;
  final bool isBusy;
  final Future<void> Function(int surahNumber) onRequestDelete;
  final SurahModel s;
  final Future<void> Function(int surahNumber) onRequestDownload;
  final AudioCtrl audioCtrl;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AudioCtrl>(
      id: 'ayahDownloadManager',
      builder: (audioCtrl) => Wrap(
        spacing: 8,
        children: [
          if (fullyDownloaded)
            IconButton(
              tooltip: style?.deleteTooltipText ?? 'حذف السورة',
              icon: Icon(
                style?.deleteIcon ?? Icons.delete_outline,
                color: style?.deleteIconColor ?? Colors.red,
              ),
              onPressed: isBusy ? null : () => onRequestDelete(s.surahNumber),
            ),
          Obx(() {
            final isDownloading = audioCtrl.state.isDownloading.value;
            final currentDownloadingSurah =
                audioCtrl.state.currentDownloadingAyahSurahNumber.value;
            final isThisItemDownloading =
                isDownloading && currentDownloadingSurah == s.surahNumber;

            if (isThisItemDownloading) {
              // زر الإيقاف يظهر فقط للسورة الجاري تحميلها الآن
              return FilledButton.icon(
                onPressed: () {
                  audioCtrl.state.cancelRequested.value = true;
                  AudioCtrl.instance.cancelDownload();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                      style?.stopButtonBackground ?? Colors.teal),
                  foregroundColor: WidgetStatePropertyAll(
                      style?.stopButtonForeground ?? Colors.white),
                ),
                icon: Icon(style?.stopButtonIcon ?? Icons.stop_circle_outlined),
                label: Text(style?.stopButtonText ?? 'إيقاف التحميل'),
              );
            }

            // إذا لم يكن هذا العنصر هو الجاري تحميله حاليًا، أظهر زر تحميل/إعادة
            return FilledButton.icon(
              onPressed:
                  isDownloading ? null : () => onRequestDownload(s.surahNumber),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                    style?.downloadBackground ?? Colors.teal),
                foregroundColor: WidgetStatePropertyAll(
                    style?.downloadForeground ?? Colors.teal),
              ),
              icon: Icon(
                fullyDownloaded
                    ? (style?.redownloadIcon ?? Icons.refresh)
                    : (style?.downloadIcon ?? Icons.download),
                color: Colors.white,
              ),
              label: Text(
                fullyDownloaded
                    ? (style?.redownloadText ?? 'إعادة')
                    : (style?.downloadText ?? 'تحميل'),
                style: QuranLibrary().cairoStyle.copyWith(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class DownloadedTextWidget extends StatelessWidget {
  const DownloadedTextWidget({
    super.key,
    required this.style,
    required this.downloaded,
    required this.total,
    required this.language,
  });

  final AyahDownloadManagerStyle? style;
  final int downloaded;
  final int total;
  final String? language;

  @override
  Widget build(BuildContext context) {
    return Text(
      style?.countTextBuilder?.call(downloaded, total) ??
          'تم تحميل $downloaded/$total آية'
              .convertNumbersAccordingToLang(languageCode: language ?? 'ar'),
      style: style?.surahSubtitleStyle ??
          QuranLibrary().cairoStyle.copyWith(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.2,
              ),
    );
  }
}

class ProgressIndicatorWidget extends StatelessWidget {
  const ProgressIndicatorWidget({
    super.key,
    required this.style,
    required this.progress,
    required this.fullyDownloaded,
  });

  final AyahDownloadManagerStyle? style;
  final double progress;
  final bool fullyDownloaded;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(style?.progressRadius ?? 8),
      child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0.0,
            end: progress,
          ),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.fastEaseInToSlowEaseOut,
          builder: (context, value, child) => LinearProgressIndicator(
                minHeight: style?.progressHeight ?? 70,
                // Use the animated value provided by TweenAnimationBuilder
                value: value,
                backgroundColor:
                    style?.progressBackgroundColor ?? Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                    (style?.progressColor ?? Colors.teal)
                        .withValues(alpha: .25)),
              )),
    );
  }
}

class HeaderBuild extends StatelessWidget {
  const HeaderBuild({
    super.key,
    required this.style,
    this.isDark = false,
    required this.ayahStyle,
  });

  final AyahDownloadManagerStyle? style;
  final AyahAudioStyle? ayahStyle;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        style?.headerIcon ??
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                style?.titleText ?? 'إدارة تحميل آيات السور',
                style: style?.titleTextStyle ??
                    QuranLibrary().cairoStyle.copyWith(
                          fontSize: 18,
                          color: AppColors.getTextColor(isDark ?? false),
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
              ),
            ),
        AyahChangeReader(style: ayahStyle ?? AyahAudioStyle()),
      ],
    );
  }
}
