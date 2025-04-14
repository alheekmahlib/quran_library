part of '../../quran.dart';

/// A dialog displayed on long click of an Ayah to provide options like bookmarking and copying text.
///
/// This widget shows a dialog at a specified position with options to bookmark the Ayah in different colors
/// or copy the Ayah text to the clipboard. The appearance and behavior are influenced by the state of QuranCtrl.
class AyahLongClickDialog extends StatelessWidget {
  /// Creates a dialog displayed on long click of an Ayah to provide options like bookmarking and copying text.
  ///
  /// This widget shows a dialog at a specified position with options to bookmark the Ayah in different colors
  /// or copy the Ayah text to the clipboard. The appearance and behavior are influenced by the state of QuranCtrl.
  const AyahLongClickDialog({
    super.key,
    this.ayah,
    this.ayahFonts,
    required this.position,
    required this.context,
    required this.index,
    required this.pageIndex,
  });

  /// The AyahModel that is the target of the long click event.
  ///
  /// This is for the original fonts.
  final AyahModel? ayah;

  /// The AyahFontsModel that is the target of the long click event.
  ///
  /// This is for the downloaded fonts.
  final AyahFontsModel? ayahFonts;

  /// The position where the dialog should appear on the screen.
  ///
  /// This is typically the position of the long click event.
  final Offset position;
  final BuildContext context;
  final int index;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: position.dy - 70,
      left: position.dx - 100,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
            color: const Color(0xfffff5ee),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 5,
                offset: const Offset(0, 5),
              )
            ]),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          margin: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(6.0)),
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
                        if (QuranCtrl.instance.state.fontsSelected2.value == 1 ||
                            QuranCtrl.instance.state.fontsSelected2.value ==
                                2 ||
                            QuranCtrl.instance.state.scaleFactor.value > 1.3) {
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
                            surahName: ayah!.arabicName,
                            ayahNumber: ayah!.ayahNumber,
                            ayahId: ayah!.ayahUQNumber,
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
              context.verticalDivider(
                  height: 30, color: const Color(0xffe8decb)),
              GestureDetector(
                onTap: () {
                  if (QuranCtrl.instance.state.fontsSelected2.value == 1) {
                    Clipboard.setData(ClipboardData(text: ayahFonts!.text));
                    _ToastUtils().showToast(context, "تم النسخ الى الحافظة");
                  } else {
                    Clipboard.setData(ClipboardData(
                        text: QuranCtrl
                            .instance.staticPages[ayah!.page - 1].ayahs
                            .firstWhere((element) =>
                                element.ayahUQNumber == ayah!.ayahUQNumber)
                            .text));
                    _ToastUtils().showToast(context, "تم النسخ الى الحافظة");
                  }
                  QuranCtrl.instance.state.overlayEntry?.remove();
                  QuranCtrl.instance.state.overlayEntry = null;
                },
                child: const Icon(
                  Icons.copy_rounded,
                  color: Colors.grey,
                ),
              ),
              // context.verticalDivider(
              //     height: 30, color: const Color(0xffe8decb)),
              // GestureDetector(
              //   onTap: () {
              //     if (QuranCtrl.instance.state.fontsSelected2.value == 1 ||
              //         QuranCtrl.instance.state.fontsSelected2.value == 2 ||
              //         QuranCtrl.instance.state.scaleFactor.value > 1.3) {
              //       // TafsirCtrl.instance.showTafsirOnTap2(
              //       //   context: context,
              //       //   surahNum: QuranCtrl.instance
              //       //       .getSurahDataByAyah(ayahFonts!)
              //       //       .surahNumber,
              //       //   ayahNum: ayahFonts!.ayahNumber,
              //       //   ayahText: ayahFonts!.text,
              //       //   pageIndex: pageIndex,
              //       //   ayahTextN: ayahFonts!.ayaTextEmlaey,
              //       //   ayahUQNum: ayahFonts!.ayahUQNumber,
              //       //   index: ayahFonts!.ayahNumber,
              //       // );
              //     } else {
              //       // TafsirCtrl.instance.showTafsirOnTap2(
              //       //     context: context,
              //       //     surahNum: ayah!.surahNumber,
              //       //     ayahNum: ayah!.ayahNumber,
              //       //     ayahText: ayah!.text,
              //       //     pageIndex: pageIndex,
              //       //     ayahTextN: ayah!.ayaTextEmlaey,
              //       //     ayahUQNum: ayah!.ayahUQNumber,
              //       //     index: ayah!.ayahNumber);
              //     }
              //     QuranCtrl.instance.state.overlayEntry?.remove();
              //     QuranCtrl.instance.state.overlayEntry = null;
              //   },
              //   child: const Icon(
              //     Icons.insert_page_break_outlined,
              //     color: Colors.grey,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
