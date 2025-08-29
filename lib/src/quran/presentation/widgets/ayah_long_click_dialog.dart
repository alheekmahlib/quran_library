part of '/quran.dart';

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
    required this.context,
    super.key,
    this.ayah,
    // this.ayahFonts,
    required this.position,
    required this.index,
    required this.pageIndex,
    this.anotherMenuChild,
    this.anotherMenuChildOnTap,
    required this.isDark,
    this.secondMenuChild,
    this.secondMenuChildOnTap,
  });

  /// The AyahModel that is the target of the long click event.
  ///
  /// This is for the original fonts.
  final AyahModel? ayah;

  /// The AyahFontsModel that is the target of the long click event.
  ///
  /// This is for the downloaded fonts.
  // final AyahFontsModel? ayahFonts;

  /// The position where the dialog should appear on the screen.
  ///
  /// This is typically the position of the long click event.
  final Offset position;
  final int index;
  final int pageIndex;
  final Widget? anotherMenuChild;
  final Widget? secondMenuChild;
  final void Function(AyahModel ayah)? anotherMenuChildOnTap;
  final void Function(AyahModel ayah)? secondMenuChildOnTap;
  final BuildContext context;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة والهوامش الآمنة / Get screen dimensions and safe area
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // حساب العرض الفعلي للحوار بناءً على المحتوى / Calculate actual dialog width based on content
    int itemsCount =
        3; // عدد الأيقونات الأساسية (3 ألوان + نسخ + تفسير) / Basic icons count
    if (anotherMenuChild != null) {
      itemsCount += 1; // إضافة عنصر إضافي / Additional item
    }
    if (secondMenuChild != null) {
      itemsCount += 1; // إضافة عنصر إضافي / Additional item
    }
    double dialogWidth = (itemsCount * 40) +
        (itemsCount * 16) +
        40; // عرض كل أيقونة + التباعد + الهوامش / Icon width + spacing + margins
    double dialogHeight = 80; // ارتفاع الحوار / Dialog height

    // حساب الموضع الأفقي مع التأكد من البقاء داخل الشاشة / Calculate horizontal position ensuring it stays within screen
    double left = position.dx - (dialogWidth / 2);

    // التحقق من الحواف اليسرى واليمنى / Check left and right edges
    if (left < padding.left + 10) {
      left = padding.left + 10; // هامش من الحافة اليسرى / Left margin
    } else if (left + dialogWidth > screenSize.width - padding.right - 10) {
      left = screenSize.width -
          padding.right -
          dialogWidth -
          10; // هامش من الحافة اليمنى / Right margin
    }

    // حساب الموضع العمودي مع التأكد من البقاء داخل الشاشة / Calculate vertical position ensuring it stays within screen
    double top = position.dy -
        dialogHeight +
        10; // زيادة المسافة إلى 10 بكسل / Increase distance to 10 pixels

    // التحقق من الحافة العلوية / Check top edge
    if (top < padding.top + 10) {
      top = position.dy +
          10; // إظهار الحوار تحت النقر مع مسافة أقل / Show dialog below tap with less distance
    }

    // التحقق من الحافة السفلية / Check bottom edge
    if (top + dialogHeight > screenSize.height - padding.bottom - 10) {
      top = screenSize.height -
          padding.bottom -
          dialogHeight -
          10; // هامش من الحافة السفلى / Bottom margin
    }

    return Positioned(
      top: top,
      left: left,
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
                        if (QuranCtrl.instance.state.fontsSelected.value == 1 ||
                            QuranCtrl.instance.state.fontsSelected.value == 2 ||
                            QuranCtrl.instance.state.scaleFactor.value > 1.3) {
                          BookmarksCtrl.instance.saveBookmark(
                            surahName: QuranCtrl.instance
                                .getSurahDataByAyah(ayah!)
                                .arabicName,
                            ayahNumber: ayah!.ayahNumber,
                            ayahId: ayah!.ayahUQNumber,
                            page: ayah!.page,
                            colorCode: colorCode,
                          );
                        } else {
                          BookmarksCtrl.instance.saveBookmark(
                            surahName: ayah!.arabicName!,
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
                  if (QuranCtrl.instance.state.fontsSelected.value == 1) {
                    Clipboard.setData(ClipboardData(text: ayah!.text));
                    ToastUtils().showToast(context, "تم النسخ الى الحافظة");
                  } else {
                    Clipboard.setData(ClipboardData(
                        text: QuranCtrl
                            .instance.staticPages[ayah!.page - 1].ayahs
                            .firstWhere((element) =>
                                element.ayahUQNumber == ayah!.ayahUQNumber)
                            .text));
                    ToastUtils().showToast(context, "تم النسخ الى الحافظة");
                  }
                  QuranCtrl.instance.state.overlayEntry?.remove();
                  QuranCtrl.instance.state.overlayEntry = null;
                },
                child: const Icon(
                  Icons.copy_rounded,
                  color: Colors.grey,
                ),
              ),
              context.verticalDivider(
                  height: 30, color: const Color(0xffe8decb)),
              GestureDetector(
                onTap: () {
                  showTafsirOnTap(
                    context: context,
                    isDark: isDark,
                    surahNum: (QuranCtrl.instance.state.fontsSelected.value ==
                                1 ||
                            QuranCtrl.instance.state.fontsSelected.value == 2 ||
                            QuranCtrl.instance.state.scaleFactor.value > 1.3)
                        ? QuranCtrl.instance
                            .getSurahDataByAyah(ayah!)
                            .surahNumber
                        : ayah!.surahNumber!,
                    ayahNum: (QuranCtrl.instance.state.fontsSelected.value ==
                                1 ||
                            QuranCtrl.instance.state.fontsSelected.value == 2 ||
                            QuranCtrl.instance.state.scaleFactor.value > 1.3)
                        ? ayah!.ayahNumber
                        : ayah!.ayahNumber,
                    ayahText: (QuranCtrl.instance.state.fontsSelected.value ==
                                1 ||
                            QuranCtrl.instance.state.fontsSelected.value == 2 ||
                            QuranCtrl.instance.state.scaleFactor.value > 1.3)
                        ? ayah!.text
                        : ayah!.text,
                    pageIndex: pageIndex,
                    ayahTextN: (QuranCtrl.instance.state.fontsSelected.value ==
                                1 ||
                            QuranCtrl.instance.state.fontsSelected.value == 2 ||
                            QuranCtrl.instance.state.scaleFactor.value > 1.3)
                        ? ayah!.ayaTextEmlaey
                        : ayah!.ayaTextEmlaey,
                    ayahUQNum: (QuranCtrl.instance.state.fontsSelected.value ==
                                1 ||
                            QuranCtrl.instance.state.fontsSelected.value == 2 ||
                            QuranCtrl.instance.state.scaleFactor.value > 1.3)
                        ? ayah!.ayahUQNumber
                        : ayah!.ayahUQNumber,
                    ayahNumber: (QuranCtrl.instance.state.fontsSelected.value ==
                                1 ||
                            QuranCtrl.instance.state.fontsSelected.value == 2 ||
                            QuranCtrl.instance.state.scaleFactor.value > 1.3)
                        ? ayah!.ayahNumber
                        : ayah!.ayahNumber,
                  );
                  QuranCtrl.instance.state.overlayEntry?.remove();
                  QuranCtrl.instance.state.overlayEntry = null;
                },
                child: const Icon(
                  Icons.text_snippet_rounded,
                  color: Colors.grey,
                ),
              ),
              anotherMenuChild != null
                  ? context.verticalDivider(
                      height: 30, color: const Color(0xffe8decb))
                  : const SizedBox(),
              anotherMenuChild != null
                  ? GestureDetector(
                      onTap: () {
                        if (anotherMenuChildOnTap != null) {
                          anotherMenuChildOnTap!(ayah!);
                        }
                        QuranCtrl.instance.state.overlayEntry?.remove();
                        QuranCtrl.instance.state.overlayEntry = null;
                      },
                      child: anotherMenuChild ?? const SizedBox(),
                    )
                  : const SizedBox(),
              secondMenuChild != null
                  ? context.verticalDivider(
                      height: 30, color: const Color(0xffe8decb))
                  : const SizedBox(),
              secondMenuChild != null
                  ? GestureDetector(
                      onTap: () {
                        if (secondMenuChildOnTap != null) {
                          secondMenuChildOnTap!(ayah!);
                        }
                        QuranCtrl.instance.state.overlayEntry?.remove();
                        QuranCtrl.instance.state.overlayEntry = null;
                      },
                      child: secondMenuChild ?? const SizedBox(),
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
