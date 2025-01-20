import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_library/core/extensions/convert_number_extension.dart';
import 'package:quran_library/core/extensions/fonts_extension.dart';

import '/core/extensions/extensions.dart';
import '/data/models/quran_fonts_models/download_fonts_dialog_style.dart';
import '../../presentation/controllers/quran/quran_ctrl.dart';
import '../../presentation/pages/quran_library_screen.dart';
import '../utils/storage_constants.dart';

extension FontsDownloadWidgetExtension on QuranCtrl {
  Widget fontsDownloadWidget(BuildContext context,
      {DownloadFontsDialogStyle? downloadFontsDialogStyle,
      String? languageCode}) {
    final quranCtrl = QuranCtrl.instance;
    return Container(
      height: 340,
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Column(
        children: [
          Text(
            downloadFontsDialogStyle!.title ?? 'الخطوط',
            style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'kufi',
                color: downloadFontsDialogStyle.titleColor ?? Colors.black,
                package: 'quran_library'),
          ),
          SizedBox(height: 8.0),
          context.hDivider(
              width: MediaQuery.sizeOf(context).width * .5, color: Colors.blue),
          SizedBox(height: 8.0),
          Text(
            downloadFontsDialogStyle.notes ??
                'لجعل مظهر المصحف مشابه لمصحف المدينة يمكنك تحميل خطوط المصحف',
            style: TextStyle(
                fontSize: 16.0,
                fontFamily: 'naskh',
                color: downloadFontsDialogStyle.notesColor ?? Colors.black,
                package: 'quran_library'),
          ),
          Spacer(),
          Column(
            children: [
              CheckboxListTile(
                  value: !quranCtrl.state.fontsSelected.value,
                  activeColor: downloadFontsDialogStyle.linearProgressColor ??
                      Colors.blue,
                  title: Text(
                    downloadFontsDialogStyle.defaultFontText ??
                        'الخطوط الأساسية',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'naskh',
                      color:
                          downloadFontsDialogStyle.titleColor ?? Colors.black,
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
                  activeColor: downloadFontsDialogStyle.linearProgressColor ??
                      Colors.blue,
                  title: Text(
                    downloadFontsDialogStyle.downloadedFontsText ??
                        'خطوط المصحف',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'naskh',
                      color:
                          downloadFontsDialogStyle.titleColor ?? Colors.black,
                      package: 'quran_library',
                    ),
                  ),
                  onChanged: !quranCtrl.state.isDownloadedV2Fonts.value
                      ? (_) => ToastUtils().showToast(context,
                          '${downloadFontsDialogStyle.downloadedNotesTitle ?? 'ملاحظة:'}\n${downloadFontsDialogStyle.downloadedNotesBody ?? 'يرجى تحميل الخطوط أولًا!'}')
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
                  '${downloadFontsDialogStyle.downloadingText} ${quranCtrl.state.fontsDownloadProgress.value.toStringAsFixed(1)}%'
                      .convertNumbers(languageCode: languageCode ?? 'ar'),
                  style: TextStyle(
                    color: downloadFontsDialogStyle.notesColor ?? Colors.black,
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
                      downloadFontsDialogStyle.linearProgressBackgroundColor ??
                          Colors.blue.shade100,
                  value: (quranCtrl.state.fontsDownloadProgress.value / 100),
                  color: downloadFontsDialogStyle.linearProgressColor ??
                      Colors.blue,
                )),
          SizedBox(height: 8.0),
          Align(
            alignment: quranCtrl.state.isDownloadedV2Fonts.value
                ? Alignment.center
                : AlignmentDirectional.bottomEnd,
            child: SizedBox(
              height: 30,
              child: ElevatedButton(
                onPressed: () async => quranCtrl.state.isDownloadedV2Fonts.value
                    ? await quranCtrl.deleteFonts()
                    : await quranCtrl.downloadAllFontsZipFile(),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                      downloadFontsDialogStyle.downloadButtonBackgroundColor ??
                          Colors.blue),
                  elevation: WidgetStatePropertyAll(0),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  )),
                ),
                child: Text(
                  quranCtrl.state.isDownloadedV2Fonts.value
                      ? downloadFontsDialogStyle.deleteButtonText ??
                          'حذف الخطوط'
                      : downloadFontsDialogStyle.downloadButtonText ?? 'تحميل',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: downloadFontsDialogStyle.downloadButtonTextColor ??
                        Colors.white,
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
    );
  }
}
