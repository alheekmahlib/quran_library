part of '/quran.dart';

class QpcV4RichTextLine extends StatefulWidget {
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
  final List<int> ayahBookmarked;
  final bool isCentered;

  @override
  State<QpcV4RichTextLine> createState() => _QpcV4RichTextLineState();
}

class _QpcV4RichTextLineState extends State<QpcV4RichTextLine> {
  /// كاش الويدجت المبني — يُعاد بناؤه فقط عند تغيّر selection/bookmarks/word_info
  Widget? _cachedWidget;

  /// بصمة البيانات المؤثرة على البناء — عند تغيّرها يُبطل الكاش
  int _lastFingerprint = 0;

  /// حساب بصمة سريعة للبيانات التي تؤثر فعلياً على شكل الويدجت
  int _computeFingerprint() {
    final quranCtrl = widget.quranCtrl;
    // الآيات المحددة + الآيات المظللة برمجياً
    final selHash = Object.hashAll(quranCtrl.selectedAyahsByUnequeNumber);
    final extHash = Object.hashAll(quranCtrl.externallyHighlightedAyahs);
    // bookmarks المؤثرة على هذا السطر
    final bmHash = Object.hashAll(widget.bookmarksAyahs);
    final abHash = Object.hashAll(widget.ayahBookmarked);
    // إعدادات العرض
    final isDarkHash = widget.isDark.hashCode;
    final tajweedHash =
        QuranCtrl.instance.state.isTajweedEnabled.value.hashCode;
    final wordSelectedHash =
        WordInfoCtrl.instance.selectedWordRef.value.hashCode;
    // حالة تبويب القراءات العشر
    final tenRecHash = WordInfoCtrl.instance.tabController.index.hashCode;

    return Object.hash(selHash, extHash, bmHash, abHash, isDarkHash,
        tajweedHash, wordSelectedHash, tenRecHash);
  }

  @override
  Widget build(BuildContext context) {
    final wordInfoCtrl = WordInfoCtrl.instance;

    // GetBuilder بمعرّف خاص بالصفحة — لا يُعاد بناؤه من update() بدون id
    return GetBuilder<QuranCtrl>(
      id: 'selection_page_${widget.pageIndex}',
      builder: (_) => GetBuilder<WordInfoCtrl>(
        id: 'word_info_data',
        builder: (_) {
          // قراءة القيم داخل الـ builder حتى تعكس آخر حالة عند كل rebuild
          final withTajweed = QuranCtrl.instance.state.isTajweedEnabled.value;
          final isTenRecitations = wordInfoCtrl.isTenRecitations;

          // prewarm القراءات في خلفية
          if (wordInfoCtrl.isKindAvailable(WordInfoKind.recitations) &&
              wordInfoCtrl.tabController.index == 1) {
            final surahs = widget.segments.map((s) => s.surahNumber);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              wordInfoCtrl.prewarmRecitationsSurahs(surahs);
            });
          }

          // فحص البصمة: إذا لم تتغيّر البيانات الفعلية → أعد الكاش
          final fp = _computeFingerprint();
          if (_cachedWidget != null && fp == _lastFingerprint) {
            return _cachedWidget!;
          }
          _lastFingerprint = fp;

          _cachedWidget = LayoutBuilder(
            builder: (ctx, constraints) {
              final fs = PageFontSizeHelper.getFontSize(
                widget.pageIndex,
                ctx,
              );

              Paint? redQTextPaint;
              if (!withTajweed && isTenRecitations) {
                redQTextPaint = Paint()
                  ..colorFilter =
                      const ColorFilter.mode(Colors.red, BlendMode.srcATop);
              }

              return _buildRichText(
                wordInfoCtrl,
                context,
                fs,
                redQTextPaint: redQTextPaint,
                withTajweed: withTajweed,
                isTenRecitations: isTenRecitations,
              );
            },
          );
          return _cachedWidget!;
        },
      ),
    );
  }

  Widget _buildRichText(
    WordInfoCtrl wordInfoCtrl,
    BuildContext context,
    double fs, {
    Paint? redQTextPaint,
    required bool withTajweed,
    required bool isTenRecitations,
  }) {
    final bookmarksSet = widget.bookmarksAyahs.toSet();
    final ayahCharRanges = <int, TextSelection>{};
    int charOffset = 0;

    final bookmarksAyahsList = bookmarksSet.toList();
    final allBookmarksList =
        widget.bookmarks.values.expand((list) => list).toList();

    final spans =
        List<InlineSpan>.generate(widget.segments.length, (segmentIndex) {
      final seg = widget.segments[segmentIndex];
      final uq = seg.ayahUq;
      final isSelectedCombined =
          widget.quranCtrl.selectedAyahsByUnequeNumber.contains(uq) ||
              widget.quranCtrl.externallyHighlightedAyahs.contains(uq);

      final ref = WordRef(
        surahNumber: seg.surahNumber,
        ayahNumber: seg.ayahNumber,
        wordNumber: seg.wordNumber,
      );

      final info = wordInfoCtrl.getRecitationsInfoSync(ref);
      final hasKhilaf = info?.hasKhilaf ?? false;

      final bool wouldForceRed = hasKhilaf && !withTajweed && isTenRecitations;
      final Paint? qTextPaint = wouldForceRed ? redQTextPaint : null;

      final span = _qpcV4SpanSegment(
        context: context,
        pageIndex: widget.pageIndex,
        isSelected: isSelectedCombined,
        showAyahBookmarkedIcon: widget.showAyahBookmarkedIcon,
        fontSize: fs,
        ayahUQNum: uq,
        ayahNumber: seg.ayahNumber,
        glyphs: seg.glyphs,
        showAyahNumber: seg.isAyahEnd,
        wordRef: ref,
        isWordKhilaf: hasKhilaf,
        onLongPressStart: (details) {
          final ayahModel = widget.quranCtrl.getAyahByUq(uq);

          if (widget.onAyahLongPress != null) {
            widget.onAyahLongPress!(details, ayahModel);
            widget.quranCtrl.toggleAyahSelection(uq);
            widget.quranCtrl.state.isShowMenu.value = false;
            return;
          }

          int? bookmarkId;
          for (final b in allBookmarksList) {
            if (b.ayahId == uq) {
              bookmarkId = b.id;
              break;
            }
          }

          if (bookmarkId != null) {
            BookmarksCtrl.instance.removeBookmark(bookmarkId);
            return;
          }

          if (widget.quranCtrl.isMultiSelectMode.value) {
            widget.quranCtrl.toggleAyahSelectionMulti(uq);
          } else {
            widget.quranCtrl.toggleAyahSelection(uq);
          }
          widget.quranCtrl.state.isShowMenu.value = false;

          final themedTafsirStyle = TafsirTheme.of(context)?.style;
          showAyahMenuDialog(
            context: context,
            isDark: widget.isDark,
            ayah: ayahModel,
            position: details.globalPosition,
            index: segmentIndex,
            pageIndex: widget.pageIndex,
            externalTafsirStyle: themedTafsirStyle,
          );
        },
        textColor: widget.textColor ?? (AppColors.getTextColor(widget.isDark)),
        ayahIconColor: widget.ayahIconColor,
        allBookmarksList: allBookmarksList,
        bookmarksAyahs: bookmarksAyahsList,
        bookmarksColor: widget.bookmarksColor,
        ayahSelectedBackgroundColor: widget.ayahSelectedBackgroundColor,
        isFontsLocal: widget.isFontsLocal,
        fontsName: widget.fontsName,
        fontFamilyOverride: widget.fontFamilyOverride,
        fontPackageOverride: widget.fontPackageOverride,
        usePaintColoring: widget.usePaintColoring,
        ayahBookmarked: widget.ayahBookmarked,
        quranTextForeground: qTextPaint,
        isDark: widget.isDark,
      );

      final spanStart = charOffset;
      charOffset += _countCharsInSpan(span);

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
      textAlign: widget.isCentered ? TextAlign.center : TextAlign.justify,
      softWrap: true,
      overflow: TextOverflow.visible,
      maxLines: null,
      text: TextSpan(children: spans),
    );

    final needsRenderWidget = ayahCharRanges.isNotEmpty;

    if (!needsRenderWidget) {
      return richText;
    }

    return _AyahSelectionWidget(
      selectedRanges: ayahCharRanges.values.toList(),
      selectionColor: widget.ayahSelectedBackgroundColor ??
          const Color(0xffCDAD80).withValues(alpha: 0.25),
      child: richText,
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

  const _AyahSelectionWidget({
    required this.selectedRanges,
    required this.selectionColor,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _AyahSelectionRenderBox(
      selectedRanges: selectedRanges,
      selectionColor: selectionColor,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _AyahSelectionRenderBox renderObject) {
    renderObject
      ..selectedRanges = selectedRanges
      ..selectionColor = selectionColor;
  }
}

/// [RenderProxyBox] يرسم مستطيلات مستديرة خلف نطاقات الآيات المحددة
/// باستخدام [RenderParagraph.getBoxesForSelection].
class _AyahSelectionRenderBox extends RenderProxyBox {
  _AyahSelectionRenderBox({
    required List<TextSelection> selectedRanges,
    required Color selectionColor,
  })  : _selectedRanges = selectedRanges,
        _selectionColor = selectionColor;

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

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child is RenderParagraph && _selectedRanges.isNotEmpty) {
      _paintSelectionBackgrounds(context, offset);
    }
    super.paint(context, offset);
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
}
