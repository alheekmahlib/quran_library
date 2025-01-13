part of '../flutter_quran_screen.dart';

class AyahLongClickDialog extends StatelessWidget {
  const AyahLongClickDialog({super.key, this.ayah, this.ayahFonts});

  final AyahModel? ayah;
  final AyahFontsModel? ayahFonts;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        elevation: 3,
        backgroundColor: const Color(0xFFF7EFE0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أضف علامة',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...[0xAAFFD354, 0xAAF36077, 0xAA00CD00].map((colorCode) {
                  // أزرار لإضافة العلامة بناءً على اللون
                  return ListTile(
                    leading: Icon(
                      Icons.bookmark,
                      color: Color(colorCode),
                    ),
                    title: Text(
                      colorCode == 0xAAFFD354
                          ? 'العلامة الصفراء'
                          : colorCode == 0xAAF36077
                              ? 'العلامة الحمراء'
                              : 'العلامة الخضراء',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      if (QuranCtrl.instance.state.isDownloadedV2Fonts.value) {
                        // إضافة العلامة الجديدة
                        BookmarksCtrl.instance.saveBookmark(
                          surahName: QuranCtrl.instance
                              .getSurahDataByAyah(ayahFonts!)
                              .arabicName,
                          ayahNumber: ayahFonts!.ayahNumber,
                          ayahId: ayahFonts!.ayahUQNumber,
                          page: ayahFonts!.page,
                          colorCode: colorCode,
                        );
                      } else {
                        BookmarksCtrl.instance.saveBookmark(
                          surahName: ayah!.surahNameAr,
                          ayahNumber: ayah!.ayahNumber,
                          ayahId: ayah!.id,
                          page: ayah!.page,
                          colorCode: colorCode,
                        );
                      }
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
                const Divider(),
                InkWell(
                  onTap: () {
                    if (QuranCtrl.instance.state.isDownloadedV2Fonts.value) {
                      Clipboard.setData(ClipboardData(text: ayahFonts!.text))
                          .then((value) =>
                              ToastUtils().showToast("تم النسخ الى الحافظة"));
                    } else {
                      Clipboard.setData(ClipboardData(
                              text: QuranCtrl
                                  .instance.staticPages[ayah!.page - 1].ayahs
                                  .firstWhere(
                                      (element) => element.id == ayah!.id)
                                  .ayah))
                          .then((value) =>
                              ToastUtils().showToast("تم النسخ الى الحافظة"));
                    }

                    Navigator.of(context).pop();
                  },
                  child: const ListTile(
                      title: Text("نسخ الى الحافظة"),
                      leading: Icon(
                        Icons.copy_rounded,
                        color: Color(0xFF798FAB),
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
