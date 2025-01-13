import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/src/controllers/quran_ctrl.dart';
import '/src/extensions/convert_number_extension.dart';
import '/src/extensions/extensions.dart';
import '/src/extensions/fonts_extension.dart';
import '../models/quran_fonts_model/download_fonts_dialog_style.dart';

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
        height: 250,
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
            Obx(() => quranCtrl.state.fontsDownloadProgress.value != 0.0
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
                ? SizedBox.shrink()
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
