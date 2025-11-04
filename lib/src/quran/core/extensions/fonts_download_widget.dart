part of '/quran.dart';

/// Extension on `QuranCtrl` to provide additional functionality related to fonts download widget.
///
/// This extension adds methods and properties to the `QuranCtrl` class that are
/// specifically related to handling the fonts download widget in the application.
extension FontsDownloadWidgetExtension on QuranCtrl {
  /// A widget that displays the fonts download option.
  ///
  /// This widget provides a UI element for downloading fonts.
  ///
  /// [context] is the BuildContext in which the widget is built.
  ///
  /// Returns a Widget that represents the fonts download option.
  Widget fontsDownloadWidget(BuildContext context,
      {DownloadFontsDialogStyle? downloadFontsDialogStyle,
      String? languageCode,
      bool isDark = false,
      bool? isFontsLocal = false}) {
    final ctrl = QuranCtrl.instance;
    final fontsLocal = isFontsLocal ?? false;

    final List<String> titleList = [
      downloadFontsDialogStyle?.defaultFontText ?? 'الخط الأساسي',
      downloadFontsDialogStyle?.downloadedFontsText ?? 'خط المصحف',
    ];

    // Theming fallbacks
    final Color accent = downloadFontsDialogStyle?.linearProgressColor ??
        Theme.of(context).colorScheme.primary;
    final Color background = downloadFontsDialogStyle?.linearProgressColor ??
        AppColors.getBackgroundColor(isDark);
    final Color textColor =
        downloadFontsDialogStyle?.titleColor ?? AppColors.getTextColor(isDark);
    final Color notesColor =
        downloadFontsDialogStyle?.notesColor ?? AppColors.getTextColor(isDark);
    final Color dividerColor = downloadFontsDialogStyle?.dividerColor ?? accent;
    final Color outlineColor =
        (downloadFontsDialogStyle?.downloadButtonBackgroundColor != null)
            ? downloadFontsDialogStyle!.downloadButtonBackgroundColor!
                .withValues(alpha: .2)
            : isDark
                ? accent.withValues(alpha: .35)
                : accent.withValues(alpha: .2);

    Widget buildTile({
      required int index,
    }) {
      final bool isSelected = ctrl.state.fontsSelected.value == index;
      final bool isDownloadOption = index == 1;

      Widget trailingForDownload() {
        if (!isDownloadOption) return const SizedBox.shrink();
        if (fontsLocal || kIsWeb) return const SizedBox.shrink();
        return Obx(() {
          final preparing = ctrl.state.isPreparingDownload.value;
          final downloading = ctrl.state.isDownloadingFonts.value;
          final downloaded = ctrl.state.isFontDownloaded.value;
          // Keep a consistent button area size
          const double buttonHeight = 55;

          return SizedBox(
            width: 40,
            height: isSelected ? 65 : buttonHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (preparing || downloading)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: accent,
                    ),
                  )
                else
                  IconButton(
                    tooltip: downloaded ? 'حذف الخطوط' : 'تحميل الخطوط',
                    onPressed: () async {
                      if (downloaded) {
                        await ctrl.deleteFonts();
                      } else if (!ctrl.state.isDownloadingFonts.value &&
                          !ctrl.state.isPreparingDownload.value) {
                        await ctrl.downloadAllFontsZipFile(index);
                      }
                      log('fontIndex: $index');
                    },
                    icon: downloadFontsDialogStyle?.iconWidget ??
                        Icon(
                          downloaded
                              ? Icons.delete_forever
                              : Icons.download_outlined,
                          color: downloadFontsDialogStyle?.iconColor ?? accent,
                          size: downloadFontsDialogStyle?.iconSize,
                        ),
                  ),
              ],
            ),
          );
        });
      }

      Widget progressIndicatorForDownload() {
        if (!isDownloadOption) return const SizedBox.shrink();
        if (fontsLocal || kIsWeb) return const SizedBox.shrink();
        return Obx(() {
          final preparing = ctrl.state.isPreparingDownload.value;
          final downloading = ctrl.state.isDownloadingFonts.value;
          final progress = ctrl.state.fontsDownloadProgress.value;

          // Keep a consistent button area size
          const double buttonHeight = 55;
          const double radius = 8;

          final Widget backgroundProgress = ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: TweenAnimationBuilder(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: progress,
                  ),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.fastEaseInToSlowEaseOut,
                  builder: (context, value, child) => LinearProgressIndicator(
                        minHeight: buttonHeight,
                        value: downloading
                            ? (progress / 100).clamp(0.0, 1.0)
                            : null,
                        backgroundColor: (downloadFontsDialogStyle
                                    ?.linearProgressBackgroundColor ??
                                background)
                            .withValues(alpha: .05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          (downloadFontsDialogStyle?.linearProgressColor ??
                                  accent)
                              .withValues(alpha: .25),
                        ),
                      )),
            ),
          );

          return SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (preparing || downloading) backgroundProgress,
              ],
            ),
          );
        });
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: AnimatedContainer(
          height: isSelected ? 65 : 55,
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          decoration: BoxDecoration(
            color:
                isSelected ? accent.withValues(alpha: .05) : Colors.transparent,
            border: Border.all(color: outlineColor, width: 1),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Obx(() {
            final downloading = ctrl.state.isDownloadingFonts.value;
            final progress = ctrl.state.fontsDownloadProgress.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                progressIndicatorForDownload(),
                ListTile(
                  minTileHeight: isSelected ? 65 : 55,
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 12, vertical: 0),
                  onTap: (fontsLocal ||
                          ctrl.state.isFontDownloaded.value ||
                          kIsWeb)
                      ? () {
                          ctrl.state.fontsSelected.value = index;
                          GetStorage()
                              .write(_StorageConstants().fontsSelected, index);
                          log('fontsSelected: ');
                          Get.forceAppUpdate().then((_) =>
                              prepareFonts(state.currentPageNumber.value - 1));
                        }
                      : null,
                  leading: trailingForDownload(),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        downloading && isDownloadOption
                            ? '${downloadFontsDialogStyle?.downloadingText ?? 'جاري التحميل'} ${progress.toStringAsFixed(1)}%'
                                .convertNumbersAccordingToLang(
                                    languageCode: languageCode ?? 'ar')
                            : titleList[index],
                        style: downloadFontsDialogStyle?.fontNameStyle ??
                            TextStyle(
                              fontSize: 16,
                              fontFamily: 'cairo',
                              color: textColor,
                              package: 'quran_library',
                            ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: accent,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          HeaderDialogWidget(
              isDark: isDark,
              title: downloadFontsDialogStyle?.title ?? 'الخطوط'),
          const SizedBox(height: 8.0),
          context.horizontalDivider(
            width: MediaQuery.sizeOf(context).width * .5,
            color: dividerColor,
          ),
          const SizedBox(height: 10.0),
          Text(
            downloadFontsDialogStyle?.notes ??
                'لجعل مظهر المصحف مشابه لمصحف المدينة يمكنك تحميل خطوط المصحف',
            style: downloadFontsDialogStyle?.notesStyle ??
                TextStyle(
                    fontSize: 14.0,
                    fontFamily: 'cairo',
                    color: notesColor,
                    height: 1.5,
                    package: 'quran_library'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Options
          buildTile(index: 0),
          buildTile(index: 1),
        ],
      ),
    );
  }
}
