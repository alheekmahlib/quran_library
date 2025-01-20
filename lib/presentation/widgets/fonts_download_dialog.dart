import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_library/core/extensions/fonts_download_widget.dart';

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
          downloadFontsDialogStyle!.iconWidget ??
              Icon(
                quranCtrl.state.isDownloadedV2Fonts.value
                    ? Icons.settings
                    : Icons.downloading_outlined,
                size: 24,
                color: Colors.black,
              ),
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
      child: quranCtrl.fontsDownloadWidget(context,
          downloadFontsDialogStyle: downloadFontsDialogStyle!,
          languageCode: languageCode),
    );
  }
}
