part of '/quran.dart';

class QpcV4RichTextLine extends StatelessWidget {
  const QpcV4RichTextLine({
    super.key,
    required this.pageIndex,
    required this.textColor,
    required this.isDark,
    required this.bookmarks,
    required this.onAyahLongPress,
    required this.bookmarkList,
    required this.ayahIconColor,
    required this.showAyahBookmarkedIcon,
    required this.bookmarksAyahs,
    required this.bookmarksColor,
    required this.ayahSelectedBackgroundColor,
    required this.context,
    required this.quranCtrl,
    required this.segments,
    required this.isFontsLocal,
    required this.fontsName,
    this.fontFamilyOverride,
    this.fontPackageOverride,
    this.usePaintColoring = true,
    this.useHafsSizing = false,
    required this.ayahBookmarked,
    required this.isCentered,
  });

  final int pageIndex;
  final Color? textColor;
  final bool isDark;
  final Map<int, List<BookmarkModel>> bookmarks;
  final Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;
  final List? bookmarkList;
  final Color? ayahIconColor;
  final bool showAyahBookmarkedIcon;
  final List<int> bookmarksAyahs;
  final Color? bookmarksColor;
  final Color? ayahSelectedBackgroundColor;
  final BuildContext context;
  final QuranCtrl quranCtrl;
  final List<QpcV4WordSegment> segments;
  final bool isFontsLocal;
  final String fontsName;
  final String? fontFamilyOverride;
  final String? fontPackageOverride;
  final bool usePaintColoring;
  final bool useHafsSizing;
  final List<int> ayahBookmarked;
  final bool isCentered;

  @override
  Widget build(BuildContext context) {
    final bookmarksSet = bookmarksAyahs.toSet();
    final wordInfoCtrl = WordInfoCtrl.instance;
    final withTajweed = QuranCtrl.instance.state.isTajweedEnabled.value;
    final isTenRecitations = WordInfoCtrl.instance.isTenRecitations;

    // بعد تحميل بيانات القراءات، نحاول تهيئة سور هذه السطر بالخلفية.
    // ملاحظة: استخدمنا prewarm مجمّع + حارس لتجنب تكرار الاستدعاءات أثناء build.
    if (wordInfoCtrl.isKindAvailable(WordInfoKind.recitations)) {
      final surahs = segments.map((s) => s.surahNumber);
      Future(() => wordInfoCtrl.prewarmRecitationsSurahs(surahs));
    }

    return GetBuilder<QuranCtrl>(
      id: 'selection_page_',
      builder: (_) => LayoutBuilder(
        builder: (ctx, constraints) {
          final fs = useHafsSizing
                  ? 100.0
                  //  PageFontSizeHelper.getFontSize(
                  //       pageIndex,
                  //       ctx,
                  //     ) -
                  //     4
                  : PageFontSizeHelper.getFontSize(
                      pageIndex,
                      ctx,
                    )
              //     :
              //     PageFontSizeHelper.qcfFontSize(
              //   context: ctx,
              //   pageIndex: pageIndex,
              //   maxWidth: constraints.maxWidth,
              // )
              ;
          // ---------- تحديد أسلوب التلوين ----------
          final Color resolvedTextColor =
              textColor ?? AppColors.getTextColor(isDark);

          // ColorFilter يُطبَّق انتقائياً عبر الـ RenderBox
          // (يُصفّي النص القرآني فقط ولا يؤثر على أرقام الآيات)
          ColorFilter? quranColorFilter;
          if (!withTajweed && !isTenRecitations) {
            // بدون تجويد بدون عشر قراءات → لون موحّد
            quranColorFilter =
                ColorFilter.mode(resolvedTextColor, BlendMode.srcATop);
          } else if (withTajweed && isDark) {
            // تجويد + وضع داكن → عكس الألوان
            quranColorFilter = const ColorFilter.matrix([
              -1, 0, 0, 0, 255, //
              0, -1, 0, 0, 255, //
              0, 0, -1, 0, 255, //
              0, 0, 0, 1, 0, //
            ]);
          }

          // foreground Paint فقط للقراءات العشر بدون تجويد
          // (لدعم تلوين كلمات الخلاف بالأحمر لكل كلمة)
          Paint? normalQTextPaint;
          Paint? redQTextPaint;
          if (!withTajweed && isTenRecitations) {
            normalQTextPaint = Paint()
              ..colorFilter =
                  ColorFilter.mode(resolvedTextColor, BlendMode.srcATop);
            redQTextPaint = Paint()
              ..colorFilter =
                  const ColorFilter.mode(Colors.red, BlendMode.srcATop);
          }

          return _richTextBuild(
            wordInfoCtrl,
            context,
            fs,
            bookmarksSet,
            normalQTextPaint: normalQTextPaint,
            redQTextPaint: redQTextPaint,
            quranColorFilter: quranColorFilter,
            withTajweed: withTajweed,
            isTenRecitations: isTenRecitations,
          );
        },
      ),
    );
  }

  Widget _richTextBuild(
    WordInfoCtrl wordInfoCtrl,
    BuildContext context,
    double fs,
    Set<int> bookmarksSet, {
    Paint? normalQTextPaint,
    Paint? redQTextPaint,
    ColorFilter? quranColorFilter,
    required bool withTajweed,
    required bool isTenRecitations,
  }) {
    return GetBuilder<WordInfoCtrl>(
      id: 'word_info_data',
      builder: (_) {
        final ayahCharRanges = <int, TextSelection>{};
        final ayahNumberRanges = <TextSelection>[];
        int charOffset = 0;

        final spans =
            List<InlineSpan>.generate(segments.length, (segmentIndex) {
          final seg = segments[segmentIndex];
          final uq = seg.ayahUq;
          final isSelectedCombined =
              quranCtrl.selectedAyahsByUnequeNumber.contains(uq) ||
                  quranCtrl.externallyHighlightedAyahs.contains(uq);

          final ref = WordRef(
            surahNumber: seg.surahNumber,
            ayahNumber: seg.ayahNumber,
            wordNumber: seg.wordNumber,
          );

          final info = wordInfoCtrl.getRecitationsInfoSync(ref);
          final hasKhilaf = info?.hasKhilaf ?? false;

          // تحديد Paint المناسب: أحمر للخلاف، عادي لغيره
          final bool wouldForceRed =
              hasKhilaf && !withTajweed && isTenRecitations;
          final Paint? qTextPaint = withTajweed
              ? null
              : (wouldForceRed
                  ? (redQTextPaint ?? normalQTextPaint)
                  : normalQTextPaint);

          final span = _qpcV4SpanSegment(
            context: context,
            pageIndex: pageIndex,
            isSelected: isSelectedCombined,
            showAyahBookmarkedIcon: showAyahBookmarkedIcon,
            fontSize: fs,
            ayahUQNum: uq,
            ayahNumber: seg.ayahNumber,
            glyphs: seg.glyphs,
            showAyahNumber: seg.isAyahEnd,
            wordRef: ref,
            isWordKhilaf: hasKhilaf,
            onLongPressStart: (details) {
              final ayahModel = quranCtrl.getAyahByUq(uq);

              if (onAyahLongPress != null) {
                onAyahLongPress!(details, ayahModel);
                quranCtrl.toggleAyahSelection(uq);
                quranCtrl.state.isShowMenu.value = false;
                return;
              }

              int? bookmarkId;
              for (final b in bookmarks.values.expand((list) => list)) {
                if (b.ayahId == uq) {
                  bookmarkId = b.id;
                  break;
                }
              }

              if (bookmarkId != null) {
                BookmarksCtrl.instance.removeBookmark(bookmarkId);
                return;
              }

              if (quranCtrl.isMultiSelectMode.value) {
                quranCtrl.toggleAyahSelectionMulti(uq);
              } else {
                quranCtrl.toggleAyahSelection(uq);
              }
              quranCtrl.state.isShowMenu.value = false;

              final themedTafsirStyle = TafsirTheme.of(context)?.style;
              showAyahMenuDialog(
                context: context,
                isDark: isDark,
                ayah: ayahModel,
                position: details.globalPosition,
                index: segmentIndex,
                pageIndex: pageIndex,
                externalTafsirStyle: themedTafsirStyle,
              );
            },
            textColor: textColor ?? (AppColors.getTextColor(isDark)),
            ayahIconColor: ayahIconColor,
            bookmarks: bookmarks,
            bookmarksAyahs: bookmarksSet.toList(),
            bookmarksColor: bookmarksColor,
            ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
            isFontsLocal: isFontsLocal,
            fontsName: fontsName,
            fontFamilyOverride: fontFamilyOverride,
            fontPackageOverride: fontPackageOverride,
            usePaintColoring: usePaintColoring,
            ayahBookmarked: ayahBookmarked,
            quranTextForeground: qTextPaint,
            isDark: isDark,
          );

          final spanStart = charOffset;
          charOffset += _countCharsInSpan(span);

          // تتبّع نطاقات أحرف أرقام الآيات للتصفية الانتقائية
          if (seg.isAyahEnd) {
            final ayahNumStart = spanStart + seg.glyphs.length;
            if (ayahNumStart < charOffset) {
              ayahNumberRanges.add(TextSelection(
                baseOffset: ayahNumStart,
                extentOffset: charOffset,
              ));
            }
          }

          if (isSelectedCombined) {
            if (ayahCharRanges.containsKey(uq)) {
              ayahCharRanges[uq] = TextSelection(
                baseOffset: ayahCharRanges[uq]!.baseOffset,
                extentOffset: charOffset,
              );
            } else {
              ayahCharRanges[uq] = TextSelection(
                baseOffset: spanStart,
                extentOffset: charOffset,
              );
            }
          }

          return span;
        });

        final richText = RichText(
          textDirection: TextDirection.rtl,
          textAlign: isCentered ? TextAlign.center : TextAlign.justify,
          softWrap: true,
          overflow: TextOverflow.visible,
          maxLines: null,
          text: TextSpan(children: spans),
        );

        final needsRenderWidget =
            ayahCharRanges.isNotEmpty || quranColorFilter != null;

        if (!needsRenderWidget) {
          return richText;
        }

        return _AyahSelectionWidget(
          selectedRanges: ayahCharRanges.values.toList(),
          selectionColor: ayahSelectedBackgroundColor ??
              const Color(0xffCDAD80).withValues(alpha: 0.25),
          colorFilter: quranColorFilter,
          ayahNumberRanges: ayahNumberRanges,
          child: richText,
        );
      },
    );
  }
}

/// يعدّ عدد الأحرف في [InlineSpan] بشكل تسلسلي (بما في ذلك [WidgetSpan] كحرف واحد).
int _countCharsInSpan(InlineSpan span) {
  if (span is TextSpan) {
    int count = span.text?.length ?? 0;
    if (span.children != null) {
      for (final child in span.children!) {
        count += _countCharsInSpan(child);
      }
    }
    return count;
  }
  if (span is WidgetSpan) {
    return 1;
  }
  return 0;
}

/// ويدجت يرسم خلفية التحديد خلف النص القرآني لكل آية على حدة.
class _AyahSelectionWidget extends SingleChildRenderObjectWidget {
  final List<TextSelection> selectedRanges;
  final Color selectionColor;
  final ColorFilter? colorFilter;
  final List<TextSelection> ayahNumberRanges;

  const _AyahSelectionWidget({
    required this.selectedRanges,
    required this.selectionColor,
    this.colorFilter,
    this.ayahNumberRanges = const [],
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _AyahSelectionRenderBox(
      selectedRanges: selectedRanges,
      selectionColor: selectionColor,
      colorFilter: colorFilter,
      ayahNumberRanges: ayahNumberRanges,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _AyahSelectionRenderBox renderObject) {
    renderObject
      ..selectedRanges = selectedRanges
      ..selectionColor = selectionColor
      ..colorFilter = colorFilter
      ..ayahNumberRanges = ayahNumberRanges;
  }
}

/// [RenderProxyBox] يرسم مستطيلات مستديرة خلف نطاقات الآيات المحددة
/// باستخدام [RenderParagraph.getBoxesForSelection].
class _AyahSelectionRenderBox extends RenderProxyBox {
  _AyahSelectionRenderBox({
    required List<TextSelection> selectedRanges,
    required Color selectionColor,
    ColorFilter? colorFilter,
    List<TextSelection> ayahNumberRanges = const [],
  })  : _selectedRanges = selectedRanges,
        _selectionColor = selectionColor,
        _colorFilter = colorFilter,
        _ayahNumberRanges = ayahNumberRanges;

  List<TextSelection> _selectedRanges;
  set selectedRanges(List<TextSelection> value) {
    if (listEquals(_selectedRanges, value)) return;
    _selectedRanges = value;
    markNeedsPaint();
  }

  Color _selectionColor;
  set selectionColor(Color value) {
    if (_selectionColor == value) return;
    _selectionColor = value;
    markNeedsPaint();
  }

  ColorFilter? _colorFilter;
  set colorFilter(ColorFilter? value) {
    if (_colorFilter == value) return;
    _colorFilter = value;
    markNeedsPaint();
  }

  List<TextSelection> _ayahNumberRanges;
  set ayahNumberRanges(List<TextSelection> value) {
    if (listEquals(_ayahNumberRanges, value)) return;
    _ayahNumberRanges = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // الخطوة 1: رسم خلفيات التحديد
    if (child is RenderParagraph && _selectedRanges.isNotEmpty) {
      _paintSelectionBackgrounds(context, offset);
    }

    // الخطوة 2: رسم المحتوى مع فلتر لوني انتقائي
    if (_colorFilter != null) {
      _paintWithSelectiveFilter(context, offset);
    } else {
      super.paint(context, offset);
    }
  }

  /// رسم خلفيات التحديد خلف الآيات المحدّدة.
  void _paintSelectionBackgrounds(PaintingContext context, Offset offset) {
    final paragraph = child! as RenderParagraph;
    final bgPaint = Paint()..color = _selectionColor;
    const padding = EdgeInsets.only(left: 4, right: 4, top: 0, bottom: -6);

    for (final range in _selectedRanges) {
      final boxes = paragraph.getBoxesForSelection(
        range,
        boxHeightStyle: BoxHeightStyle.max,
      );
      if (boxes.isEmpty) continue;

      final mergedRects = <Rect>[];
      Rect? current;
      double? currentTop;
      const lineTolerance = 2.0;

      for (final box in boxes) {
        final rect = box.toRect();
        if (current == null) {
          current = rect;
          currentTop = rect.top;
        } else if ((rect.top - currentTop!).abs() < lineTolerance) {
          current = Rect.fromLTRB(
            math.min(current.left, rect.left),
            math.min(current.top, rect.top),
            math.max(current.right, rect.right),
            math.max(current.bottom, rect.bottom),
          );
        } else {
          mergedRects.add(current);
          current = rect;
          currentTop = rect.top;
        }
      }
      if (current != null) mergedRects.add(current);

      for (final rect in mergedRects) {
        final padded = padding.inflateRect(rect).shift(offset);
        context.canvas.drawRRect(
          RRect.fromRectAndRadius(padded, const Radius.circular(16)),
          bgPaint,
        );
      }
    }
  }

  /// رسم المحتوى مع تطبيق الفلتر اللوني على النص القرآني فقط
  /// مع استثناء مناطق أرقام الآيات (تُرسم بدون فلتر).
  void _paintWithSelectiveFilter(PaintingContext context, Offset offset) {
    final bounds = offset & size;

    // إذا لا توجد أرقام آيات للحماية → فلترة كاملة
    if (_ayahNumberRanges.isEmpty || child is! RenderParagraph) {
      context.canvas.saveLayer(bounds, Paint()..colorFilter = _colorFilter);
      super.paint(context, offset);
      context.canvas.restore();
      return;
    }

    final paragraph = child! as RenderParagraph;

    // جمع مستطيلات أرقام الآيات
    final ayahRects = <Rect>[];
    for (final range in _ayahNumberRanges) {
      final boxes = paragraph.getBoxesForSelection(
        range,
        boxHeightStyle: BoxHeightStyle.max,
      );
      for (final box in boxes) {
        ayahRects.add(box.toRect().shift(offset));
      }
    }

    if (ayahRects.isEmpty) {
      context.canvas.saveLayer(bounds, Paint()..colorFilter = _colorFilter);
      super.paint(context, offset);
      context.canvas.restore();
      return;
    }

    // بناء مسار استثناء: كل شيء ما عدا مناطق أرقام الآيات
    final exclusionPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(bounds);
    for (final rect in ayahRects) {
      exclusionPath.addRect(rect);
    }

    // رسم النص القرآني مع الفلتر (المنطقة المقطوعة تستثني أرقام الآيات)
    context.canvas.save();
    context.canvas.clipPath(exclusionPath);
    context.canvas.saveLayer(bounds, Paint()..colorFilter = _colorFilter);
    super.paint(context, offset);
    context.canvas.restore(); // إنهاء saveLayer
    context.canvas.restore(); // إنهاء clip

    // رسم مناطق أرقام الآيات بدون فلتر
    final ayahPath = Path();
    for (final rect in ayahRects) {
      ayahPath.addRect(rect);
    }
    context.canvas.save();
    context.canvas.clipPath(ayahPath);
    context.paintChild(child!, offset);
    context.canvas.restore();
  }
}
