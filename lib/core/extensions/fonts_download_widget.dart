part of '../../quran.dart';

extension FontsDownloadWidgetExtension on QuranCtrl {
  Widget fontsDownloadWidget(BuildContext context,
      {DownloadFontsDialogStyle? downloadFontsDialogStyle,
      String? languageCode}) {
    final quranCtrl = QuranCtrl.instance;
    List<String> titleList = [
      // downloadFontsDialogStyle?.defaultFontText ??
      'الخطوط الأساسية',
      // downloadFontsDialogStyle?.downloadedFontsText ??
      'خطوط المصحف',
      // downloadFontsDialogStyle?.downloadedFontsTajweedText ??
      'خطوط المصحف ٢',
    ];
    return Container(
      height: 380,
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Column(
        children: [
          Text(
            downloadFontsDialogStyle?.title ?? 'الخطوط',
            style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'kufi',
                color: downloadFontsDialogStyle?.titleColor ?? Colors.black,
                package: 'quran_library'),
          ),
          SizedBox(height: 8.0),
          context.horizontalDivider(
              width: MediaQuery.sizeOf(context).width * .5, color: Colors.blue),
          SizedBox(height: 8.0),
          Text(
            downloadFontsDialogStyle?.notes ??
                'لجعل مظهر المصحف مشابه لمصحف المدينة يمكنك تحميل خطوط المصحف',
            style: TextStyle(
                fontSize: 16.0,
                fontFamily: 'naskh',
                color: downloadFontsDialogStyle?.notesColor ?? Colors.black,
                package: 'quran_library'),
          ),
          Spacer(),
          Column(
            children: List.generate(
              3,
              (i) => CheckboxListTile(
                  value: (quranCtrl.state.fontsSelected2.value == i)
                      ? true
                      : false,
                  activeColor: downloadFontsDialogStyle?.linearProgressColor ??
                      Colors.blue,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        downloadFontsDialogStyle?.defaultFontText ??
                            'الخطوط الأساسية', //titleList[i],
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'naskh',
                          color: downloadFontsDialogStyle?.titleColor ??
                              Colors.black,
                          package: 'quran_library',
                        ),
                      ),
                      i == 0
                          ? SizedBox.shrink()
                          : IconButton(
                              onPressed: () async {
                                quranCtrl.state.fontsDownloadedList.contains(i)
                                    ? await quranCtrl.deleteFonts(i)
                                    : await quranCtrl
                                        .downloadAllFontsZipFile(i);
                                log('fontIndex: $i');
                              },
                              icon: Icon(
                                quranCtrl.state.fontsDownloadedList.contains(i)
                                    ? Icons.delete_forever
                                    : Icons.downloading_outlined,
                                color: Colors.blue,
                              ))
                    ],
                  ),
                  onChanged: !quranCtrl.state.isDownloadedV2Fonts.value
                      ? null
                      : (value) {
                          quranCtrl.state.fontsSelected2.value = i;
                          GetStorage()
                              .write(StorageConstants().fontsSelected, i);
                          log('fontsSelected: $i');
                          Get.forceAppUpdate();
                        }),
            ),
          ),
          Obx(() => quranCtrl.state.fontsDownloadProgress.value != 0.0 &&
                  quranCtrl.state.isDownloadingFonts.value
              ? Text(
                  '${downloadFontsDialogStyle?.downloadingText} ${quranCtrl.state.fontsDownloadProgress.value.toStringAsFixed(1)}%'
                      .convertNumbersAccordingToLang(
                          languageCode: languageCode ?? 'ar'),
                  style: TextStyle(
                    color: downloadFontsDialogStyle?.notesColor ?? Colors.black,
                    fontSize: 16,
                    fontFamily: 'naskh',
                    package: 'quran_library',
                  ),
                )
              : const SizedBox.shrink()),
          Obx(() => quranCtrl.state.isDownloadedV2Fonts.value
              ? const SizedBox.shrink()
              : LinearProgressIndicator(
                  backgroundColor:
                      downloadFontsDialogStyle?.linearProgressBackgroundColor ??
                          Colors.blue.shade100,
                  value: (quranCtrl.state.fontsDownloadProgress.value / 100),
                  color: downloadFontsDialogStyle?.linearProgressColor ??
                      Colors.blue,
                )),
          SizedBox(height: 8.0),
        ],
      ),
    );
  }
}
