part of '../../quran.dart';

class FontsDownloadDialog extends StatelessWidget {
  final DownloadFontsDialogStyle? downloadFontsDialogStyle;
  final String? languageCode;
  final bool isDark;
  final bool? isFontsLocal;

  FontsDownloadDialog(
      {super.key,
      this.downloadFontsDialogStyle,
      this.languageCode,
      this.isFontsLocal,
      this.isDark = false});

  final quranCtrl = QuranCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(useMaterial3: true),
      child: IconButton(
        onPressed: () => showDialog(
            context: context, builder: (ctx) => _fontsDownloadDialog(ctx)),
        icon: Stack(
          alignment: Alignment.center,
          children: [
            downloadFontsDialogStyle?.iconWidget ??
                Icon(
                  quranCtrl.state.isDownloadedV2Fonts.value
                      ? Icons.settings
                      : Icons.downloading_outlined,
                  size: 24,
                  color: isDark ? Colors.white : Colors.black,
                ),
            GetX<QuranCtrl>(
              builder: (quranCtrl) => CircularProgressIndicator(
                strokeWidth: 2,
                value: (quranCtrl.state.fontsDownloadProgress.value / 100),
                color: downloadFontsDialogStyle?.linearProgressColor,
                backgroundColor:
                    downloadFontsDialogStyle?.linearProgressBackgroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fontsDownloadDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 3,
      backgroundColor: downloadFontsDialogStyle?.backgroundColor,
      child: Stack(
        children: [
          quranCtrl.fontsDownloadWidget(context,
              downloadFontsDialogStyle: downloadFontsDialogStyle!,
              languageCode: languageCode,
              isDark: isDark,
              isFontsLocal: isFontsLocal),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: Icon(Icons.close),
              color: isDark
                  ? Colors.grey[400]
                  : Colors.grey[
                      800], // Light grey for dark theme, dark grey for light theme
              padding: EdgeInsets.all(4),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
