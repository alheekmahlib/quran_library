part of '../pages/quran_library_screen.dart';

class AyahLongClickDialog extends StatelessWidget {
  const AyahLongClickDialog(
      {super.key, this.ayah, this.ayahFonts, required this.position});

  final AyahModel? ayah;
  final AyahFontsModel? ayahFonts;
  final Offset position;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: position.dy - 70,
      left: position.dx - 100,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            color: const Color(0xfffff5ee),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: .3),
                blurRadius: 10,
                spreadRadius: 5,
                offset: Offset(0, 5),
              )
            ]),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          margin: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(6.0)),
              border: Border.all(width: 2, color: const Color(0xffe8decb))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ...[
                0xAAFFD354,
                0xAAF36077,
                0xAA00CD00
              ].map((colorCode) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        if (QuranCtrl.instance.state.fontsSelected.value ||
                            QuranCtrl.instance.state.scaleFactor.value > 1.3) {
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
                        QuranCtrl.instance.state.overlayEntry?.remove();
                        QuranCtrl.instance.state.overlayEntry = null;
                      },
                      child: Icon(
                        Icons.bookmark,
                        color: Color(colorCode),
                      ),
                    ),
                  )),
              context.vDivider(height: 30, color: const Color(0xffe8decb)),
              GestureDetector(
                onTap: () {
                  if (QuranCtrl.instance.state.fontsSelected.value) {
                    Clipboard.setData(ClipboardData(text: ayahFonts!.text));
                    ToastUtils().showToast(context, "تم النسخ الى الحافظة");
                  } else {
                    Clipboard.setData(ClipboardData(
                        text: QuranCtrl
                            .instance.staticPages[ayah!.page - 1].ayahs
                            .firstWhere((element) => element.id == ayah!.id)
                            .ayah));
                    ToastUtils().showToast(context, "تم النسخ الى الحافظة");
                  }
                  QuranCtrl.instance.state.overlayEntry?.remove();
                  QuranCtrl.instance.state.overlayEntry = null;
                },
                child: Icon(
                  Icons.copy_rounded,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
