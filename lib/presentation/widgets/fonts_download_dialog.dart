import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/extensions/convert_number_extension.dart';
import '../../core/extensions/extensions.dart';
import '../../core/extensions/fonts_extension.dart';
import '../../core/utils/storage_constants.dart';
import '../../data/models/quran_fonts_models/download_fonts_dialog_style.dart';
import '../controllers/quran/quran_ctrl.dart';

class FontsDownloadDialog extends StatelessWidget {
  final DownloadFontsDialogStyle? downloadFontsDialogStyle;
  final String? languageCode;

  FontsDownloadDialog(
      {super.key, this.downloadFontsDialogStyle, this.languageCode});

  final quranCtrl = QuranCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showDialog(
          context: context, builder: (ctx) => _fontsDownloadDialog(ctx)),
      icon: Stack(
        alignment: Alignment.center,
        children: [
          downloadFontsDialogStyle!.iconWidget!,
          GetX<QuranCtrl>(
              builder: (quranCtrl) => CircularProgressIndicator(
                    strokeWidth: 2,
                    value: (quranCtrl.state.fontsDownloadProgress.value / 100),
                    color: downloadFontsDialogStyle!.linearProgressColor,
                    backgroundColor:
                        downloadFontsDialogStyle!.linearProgressBackgroundColor,
                  )),
        ],
      ),
    );
  }

  Widget _fontsDownloadDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 3,
      backgroundColor: downloadFontsDialogStyle!.backgroundColor,
      child: Container(
        height: 320,
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Column(
          children: [
            Text(
              downloadFontsDialogStyle!.title!,
              style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'kufi',
                  color: downloadFontsDialogStyle!.titleColor,
                  package: 'quran_library'),
            ),
            SizedBox(height: 8.0),
            context.hDivider(width: Get.width * .5, color: Colors.blue),
            SizedBox(height: 8.0),
            Text(
              downloadFontsDialogStyle!.notes!,
              style: TextStyle(
                  fontSize: 16.0,
                  fontFamily: 'naskh',
                  color: downloadFontsDialogStyle!.notesColor,
                  package: 'quran_library'),
            ),
            SizedBox(height: 8.0),
            Spacer(),
            Column(
              children: [
                CheckboxListTile(
                    value: !quranCtrl.state.fontsSelected.value,
                    activeColor: downloadFontsDialogStyle!.linearProgressColor,
                    title: Text(
                      downloadFontsDialogStyle!.defaultFontText!,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'naskh',
                        color: downloadFontsDialogStyle!.titleColor,
                        package: 'quran_library',
                      ),
                    ),
                    onChanged: (value) {
                      quranCtrl.state.fontsSelected.value = !value!;
                      GetStorage()
                          .write(StorageConstants().fontsSelected, !value);
                      Get.forceAppUpdate();
                    }),
                CheckboxListTile(
                    value: quranCtrl.state.fontsSelected.value,
                    activeColor: downloadFontsDialogStyle!.linearProgressColor,
                    title: Text(
                      downloadFontsDialogStyle!.downloadedFontsText!,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'naskh',
                        color: downloadFontsDialogStyle!.titleColor,
                        package: 'quran_library',
                      ),
                    ),
                    onChanged: !quranCtrl.state.isDownloadedV2Fonts.value
                        ? (_) => Get.snackbar(
                              downloadFontsDialogStyle!.downloadedNotesTitle!,
                              downloadFontsDialogStyle!.downloadedNotesBody!,
                              backgroundColor:
                                  downloadFontsDialogStyle!.backgroundColor,
                            )
                        : (value) {
                            quranCtrl.state.fontsSelected.value = value!;
                            GetStorage()
                                .write(StorageConstants().fontsSelected, value);
                            Get.forceAppUpdate();
                          }),
              ],
            ),
            Obx(() => quranCtrl.state.fontsDownloadProgress.value != 0.0 &&
                    quranCtrl.state.isDownloadingFonts.value
                ? Text(
                    '${downloadFontsDialogStyle!.downloadingText} ${quranCtrl.state.fontsDownloadProgress.value.toStringAsFixed(1)}%'
                        .convertNumbers(languageCode: languageCode ?? 'ar'),
                    style: TextStyle(
                      color:
                          downloadFontsDialogStyle!.notesColor ?? Colors.black,
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
                        downloadFontsDialogStyle!.linearProgressBackgroundColor,
                    value: (quranCtrl.state.fontsDownloadProgress.value / 100),
                    color: downloadFontsDialogStyle!.linearProgressColor,
                  )),
            SizedBox(height: 8.0),
            Align(
              alignment: quranCtrl.state.isDownloadedV2Fonts.value
                  ? Alignment.center
                  : AlignmentDirectional.bottomEnd,
              child: SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: () async =>
                      quranCtrl.state.isDownloadedV2Fonts.value
                          ? await quranCtrl.deleteFonts()
                          : await quranCtrl.downloadAllFontsZipFile(),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                        downloadFontsDialogStyle!
                            .downloadButtonBackgroundColor),
                    elevation: WidgetStatePropertyAll(0),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    )),
                  ),
                  child: Text(
                    quranCtrl.state.isDownloadedV2Fonts.value
                        ? downloadFontsDialogStyle!.deleteButtonText!
                        : downloadFontsDialogStyle!.downloadButtonText!,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: downloadFontsDialogStyle!.downloadButtonTextColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'kufi',
                      package: 'quran_library',
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
