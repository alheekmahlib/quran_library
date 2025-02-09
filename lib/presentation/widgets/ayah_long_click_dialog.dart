part of '../../quran.dart';

class AyahLongClickDialog extends StatelessWidget {
  const AyahLongClickDialog(
      {super.key, this.ayahFonts, required this.position});

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
              ...[0xAAFFD354, 0xAAF36077, 0xAA00CD00]
                  .map((colorCode) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: GestureDetector(
                          onTap: () {
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

                            QuranCtrl.instance.state.overlayEntry?.remove();
                            QuranCtrl.instance.state.overlayEntry = null;
                          },
                          child: Icon(
                            Icons.bookmark,
                            color: Color(colorCode),
                          ),
                        ),
                      )),
              context.verticalDivider(
                  height: 30, color: const Color(0xffe8decb)),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: ayahFonts!.text));
                  ToastUtils().showToast(context, "تم النسخ الى الحافظة");

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
