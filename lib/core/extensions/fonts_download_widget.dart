part of '../../quran.dart';

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
    final quranCtrl = QuranCtrl.instance;

    List<String> titleList = [
      downloadFontsDialogStyle?.defaultFontText ?? 'الخط الأساسي',
      downloadFontsDialogStyle?.downloadedFontsText ?? 'خط المصحف',
    ];
    // List<String> tajweedList = [
    //   downloadFontsDialogStyle?.withTajweedText ?? 'مع التجويد',
    //   downloadFontsDialogStyle?.withoutTajweedText ?? 'بدون تجويد',
    // ];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            downloadFontsDialogStyle?.title ?? 'الخطوط',
            style: downloadFontsDialogStyle?.titleStyle ??
                TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'kufi',
                  color: downloadFontsDialogStyle?.titleColor ??
                      (isDark ? Colors.white : Colors.black),
                  package: 'quran_library',
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          context.horizontalDivider(
            width: MediaQuery.sizeOf(context).width * .5,
            color: downloadFontsDialogStyle?.dividerColor ?? Colors.blue,
          ),
          const SizedBox(height: 8.0),
          Text(
            downloadFontsDialogStyle?.notes ??
                'لجعل مظهر المصحف مشابه لمصحف المدينة يمكنك تحميل خطوط المصحف',
            style: downloadFontsDialogStyle?.notesStyle ??
                TextStyle(
                    fontSize: 16.0,
                    fontFamily: 'naskh',
                    color: downloadFontsDialogStyle?.notesColor ??
                        (isDark ? Colors.white : Colors.black),
                    package: 'quran_library'),
          ),
          const SizedBox(
            height: 100,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              titleList.length,
              (i) => Container(
                margin: EdgeInsets.symmetric(vertical: 2.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: downloadFontsDialogStyle
                                ?.downloadButtonBackgroundColor !=
                            null
                        ? downloadFontsDialogStyle!
                            .downloadButtonBackgroundColor!
                            .withValues(alpha: .2)
                        : isDark
                            ? Colors.blue.withValues(alpha: .4)
                            : Colors.blue.withValues(alpha: .2),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Container(
                  height: 50,
                  margin: EdgeInsets.symmetric(vertical: 4.0),
                  color: quranCtrl.state.fontsSelected2.value == i
                      ? downloadFontsDialogStyle?.linearProgressColor != null
                          ? downloadFontsDialogStyle?.linearProgressColor!
                              .withValues(alpha: .05)
                          : Colors.blue.withValues(alpha: .05)
                      : null,
                  child: CheckboxListTile(
                    value: (quranCtrl.state.fontsSelected2.value == i)
                        ? true
                        : false,
                    activeColor:
                        downloadFontsDialogStyle?.linearProgressColor ??
                            Colors.blue,
                    secondary: i == 0
                        ? const SizedBox.shrink()
                        : isFontsLocal!
                            ? const SizedBox.shrink()
                            : IconButton(
                                onPressed: () async {
                                  quranCtrl.state.isDownloadedV2Fonts.value
                                      ? await quranCtrl.deleteFonts()
                                      : quranCtrl.state.isDownloadingFonts.value
                                          ? null
                                          : await quranCtrl
                                              .downloadAllFontsZipFile(i);
                                  log('fontIndex: $i');
                                },
                                icon: downloadFontsDialogStyle?.iconWidget ??
                                    Icon(
                                      quranCtrl.state.isDownloadedV2Fonts.value
                                          ? Icons.delete_forever
                                          : Icons.downloading_outlined,
                                      color:
                                          downloadFontsDialogStyle?.iconColor ??
                                              Colors.blue,
                                      size: downloadFontsDialogStyle?.iconSize,
                                    ),
                              ),
                    title: Text(
                      titleList[i],
                      style: downloadFontsDialogStyle?.fontNameStyle ??
                          TextStyle(
                            fontSize: 16,
                            fontFamily: 'naskh',
                            color: downloadFontsDialogStyle?.titleColor ??
                                (isDark ? Colors.white : Colors.black),
                            package: 'quran_library',
                          ),
                    ),
                    onChanged: isFontsLocal! ||
                            quranCtrl.state.isDownloadedV2Fonts.value
                        ? (_) {
                            quranCtrl.state.fontsSelected2.value = i;
                            GetStorage()
                                .write(_StorageConstants().fontsSelected, i);
                            log('fontsSelected: $i');
                            Get.forceAppUpdate();
                          }
                        : null,
                  ),
                ),
              ),
            ),
          ),
          Obx(
            () => quranCtrl.state.isDownloadingFonts.value
                ? Text(
                    '${downloadFontsDialogStyle?.downloadingText ?? 'جاري التحميل'} ${quranCtrl.state.fontsDownloadProgress.value.toStringAsFixed(1)}%'
                        .convertNumbersAccordingToLang(
                            languageCode: languageCode ?? 'ar'),
                    style: downloadFontsDialogStyle?.downloadingStyle ??
                        TextStyle(
                          color: downloadFontsDialogStyle?.notesColor ??
                              (isDark ? Colors.white : Colors.black),
                          fontSize: 16,
                          fontFamily: 'naskh',
                          package: 'quran_library',
                        ),
                  )
                : const SizedBox.shrink(),
          ),
          Obx(
            () => quranCtrl.state.isDownloadedV2Fonts.value
                ? const SizedBox.shrink()
                : LinearProgressIndicator(
                    backgroundColor: downloadFontsDialogStyle
                            ?.linearProgressBackgroundColor ??
                        Colors.blue.shade100,
                    value: (quranCtrl.state.fontsDownloadProgress.value / 100),
                    color: downloadFontsDialogStyle?.linearProgressColor ??
                        Colors.blue,
                  ),
          ),
        ],
      ),
    );
  }
}
