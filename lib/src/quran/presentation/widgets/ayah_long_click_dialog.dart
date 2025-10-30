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
    this.style,
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
  final AyahLongClickStyle? style;

  @override
  Widget build(BuildContext context) {
    final s =
        style ?? AyahLongClickStyle.defaults(isDark: isDark, context: context);
    // الحصول على أبعاد الشاشة والهوامش الآمنة / Get screen dimensions and safe area
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // حساب العرض الفعلي للحوار بناءً على المحتوى / Calculate actual dialog width based on content
    int itemsCount = 0;
    final bookmarkCount = (s.showBookmarkButtons ?? true)
        ? (s.bookmarkColorCodes?.length ?? 3)
        : 0;
    itemsCount += bookmarkCount;
    if (s.showCopyButton ?? true) itemsCount += 1;
    if (s.showTafsirButton ?? true) itemsCount += 1;
    if (anotherMenuChild != null) itemsCount += 1;
    if (secondMenuChild != null) itemsCount += 1;

    final baseWidth = s.itemBaseWidth ?? 40.0;
    final spacing = s.itemSpacing ?? 16.0;
    final extra = s.extraHorizontalSpace ?? 40.0;
    double dialogWidth =
        (itemsCount * baseWidth) + (itemsCount * spacing) + extra;
    double dialogHeight =
        s.dialogHeight ?? 80.0; // ارتفاع الحوار / Dialog height

    // حساب الموضع الأفقي مع التأكد من البقاء داخل الشاشة / Calculate horizontal position ensuring it stays within screen
    double left = position.dx - (dialogWidth / 2);

    // التحقق من الحواف اليسرى واليمنى / Check left and right edges
    final safe = s.edgeSafeMargin ?? 10.0;
    if (left < padding.left + safe) {
      left = padding.left + safe; // هامش من الحافة اليسرى / Left margin
    } else if (left + dialogWidth > screenSize.width - padding.right - safe) {
      left = screenSize.width -
          padding.right -
          dialogWidth -
          safe; // هامش من الحافة اليمنى / Right margin
    }

    // حساب الموضع العمودي مع التأكد من البقاء داخل الشاشة / Calculate vertical position ensuring it stays within screen
    final tapOffset = s.tapOffsetSpacing ?? 10.0;
    double top = position.dy - dialogHeight + tapOffset; // إزاحة موضع النقر

    // التحقق من الحافة العلوية / Check top edge
    if (top < padding.top + safe) {
      top = position.dy + tapOffset; // إظهار الحوار تحت النقر مع مسافة أقل
    }

    // التحقق من الحافة السفلية / Check bottom edge
    if (top + dialogHeight > screenSize.height - padding.bottom - safe) {
      top = screenSize.height -
          padding.bottom -
          dialogHeight -
          safe; // هامش من الحافة السفلى / Bottom margin
    }

    return Positioned(
      top: top,
      left: left,
      child: Container(
        decoration: BoxDecoration(
            borderRadius:
                BorderRadius.all(Radius.circular(s.outerBorderRadius ?? 8.0)),
            color: s.backgroundColor,
            boxShadow: s.boxShadow),
        child: Container(
          padding: s.padding ??
              const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          margin: s.margin ?? const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.all(Radius.circular(s.borderRadius ?? 6.0)),
              border: Border.all(
                  width: s.borderWidth ?? 2.0,
                  color: s.borderColor ?? Colors.teal.shade100)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: () {
              final List<Widget> widgets = [];
              Widget divider() => context.verticalDivider(
                    height: s.dividerHeight ?? 30.0,
                    color: s.dividerColor ?? Colors.teal.shade100,
                  );

              void addDividerIfNeeded() {
                if (widgets.isNotEmpty) widgets.add(divider());
              }

              // عنصر إضافي أول
              if (anotherMenuChild != null) {
                addDividerIfNeeded();
                widgets.add(
                  GestureDetector(
                    onTap: () {
                      if (anotherMenuChildOnTap != null) {
                        anotherMenuChildOnTap!(ayah!);
                      }
                      QuranCtrl.instance.state.overlayEntry?.remove();
                      QuranCtrl.instance.state.overlayEntry = null;
                    },
                    child: anotherMenuChild!,
                  ),
                );
              }

              // عنصر إضافي ثانٍ
              if (secondMenuChild != null) {
                addDividerIfNeeded();
                widgets.add(
                  GestureDetector(
                    onTap: () {
                      if (secondMenuChildOnTap != null) {
                        secondMenuChildOnTap!(ayah!);
                      }
                      QuranCtrl.instance.state.overlayEntry?.remove();
                      QuranCtrl.instance.state.overlayEntry = null;
                    },
                    child: secondMenuChild!,
                  ),
                );
              }

              // زر التفسير
              if (s.showTafsirButton ?? true) {
                addDividerIfNeeded();
                widgets.add(
                  GestureDetector(
                    onTap: () {
                      showTafsirOnTap(
                        context: context,
                        isDark: isDark,
                        ayahNum: (QuranCtrl
                                        .instance.state.fontsSelected.value ==
                                    1 ||
                                QuranCtrl.instance.state.fontsSelected.value ==
                                    2 ||
                                QuranCtrl.instance.state.scaleFactor.value >
                                    1.3)
                            ? ayah!.ayahNumber
                            : ayah!.ayahNumber,
                        pageIndex: pageIndex,
                        ayahUQNum: (QuranCtrl
                                        .instance.state.fontsSelected.value ==
                                    1 ||
                                QuranCtrl.instance.state.fontsSelected.value ==
                                    2 ||
                                QuranCtrl.instance.state.scaleFactor.value >
                                    1.3)
                            ? ayah!.ayahUQNumber
                            : ayah!.ayahUQNumber,
                        ayahNumber:
                            (QuranCtrl.instance.state.fontsSelected.value ==
                                        1 ||
                                    QuranCtrl.instance.state.fontsSelected
                                            .value ==
                                        2 ||
                                    QuranCtrl.instance.state.scaleFactor.value >
                                        1.3)
                                ? ayah!.ayahNumber
                                : ayah!.ayahNumber,
                        tafsirStyle: TafsirStyle(
                          backgroundColor: AppColors.getBackgroundColor(isDark),
                          tafsirNameWidget: Text(
                            'التفسير',
                            style: QuranLibrary().cairoStyle.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                          ),
                          fontSizeWidget: fontSizeDropDown(
                            height: 30.0,
                            isDark: isDark,
                          ),
                        ),
                      );
                      QuranCtrl.instance.state.overlayEntry?.remove();
                      QuranCtrl.instance.state.overlayEntry = null;
                    },
                    child: Icon(
                      s.tafsirIconData ?? Icons.text_snippet_rounded,
                      color: s.tafsirIconColor ?? Colors.teal,
                      size: s.iconSize,
                    ),
                  ),
                );
              }

              // زر النسخ
              if (s.showCopyButton ?? true) {
                addDividerIfNeeded();
                widgets.add(
                  GestureDetector(
                    onTap: () {
                      if (QuranCtrl.instance.state.fontsSelected.value == 1) {
                        Clipboard.setData(ClipboardData(text: ayah!.text));
                        ToastUtils().showToast(
                          context,
                          s.copySuccessMessage ?? 'تم النسخ الى الحافظة',
                        );
                      } else {
                        Clipboard.setData(ClipboardData(
                            text: QuranCtrl
                                .instance.staticPages[ayah!.page - 1].ayahs
                                .firstWhere((element) =>
                                    element.ayahUQNumber == ayah!.ayahUQNumber)
                                .text));
                        ToastUtils().showToast(
                          context,
                          s.copySuccessMessage ?? 'تم النسخ الى الحافظة',
                        );
                      }
                      QuranCtrl.instance.state.overlayEntry?.remove();
                      QuranCtrl.instance.state.overlayEntry = null;
                    },
                    child: Icon(
                      s.copyIconData ?? Icons.copy_rounded,
                      color: s.copyIconColor ?? Colors.teal,
                      size: s.iconSize,
                    ),
                  ),
                );
              }

              // أزرار العلامات المرجعية
              if (s.showBookmarkButtons ?? true) {
                final colors = s.bookmarkColorCodes ??
                    const [
                      0xAAFFD354,
                      0xAAF36077,
                      0xAA00CD00,
                    ];
                for (final colorCode in colors) {
                  widgets.add(
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: s.iconHorizontalPadding ?? 8.0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          if (QuranCtrl.instance.state.fontsSelected.value == 1 ||
                              QuranCtrl.instance.state.fontsSelected.value ==
                                  2 ||
                              QuranCtrl.instance.state.scaleFactor.value >
                                  1.3) {
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
                          s.bookmarkIconData ?? Icons.bookmark,
                          color: Color(colorCode),
                          size: s.iconSize,
                        ),
                      ),
                    ),
                  );
                }
              }

              return widgets;
            }(),
          ),
        ),
      ),
    );
  }
}
