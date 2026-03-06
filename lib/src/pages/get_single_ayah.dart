part of '../../quran.dart';

class GetSingleAyah extends StatelessWidget {
  final int surahNumber;
  final int ayahNumber;
  final Color? textColor;
  final bool? isDark;
  final bool? isBold;
  final double? fontSize;
  final AyahModel? ayahs;
  final bool? isSingleAyah;
  final bool? islocalFont;
  final String? fontsName;
  final int? pageIndex;
  final Function(LongPressStartDetails details, AyahModel ayah)?
      onAyahLongPress;
  final Color? ayahIconColor;
  final bool showAyahBookmarkedIcon;
  final Color? bookmarksColor;
  final Color? ayahSelectedBackgroundColor;
  final TextAlign? textAlign;
  final bool? enabledTajweed;

  /// تفعيل خاصية تحديد الكلمة بضغطة واحدة (يعمل مع خط QPC فقط).
  /// عند التفعيل، تُحدّد أول كلمة افتراضياً.
  final bool enableWordSelection;

  /// callback يُستدعى عند الضغط على كلمة، يعيد [WordRef] يحتوي
  /// (surahNumber, ayahNumber, wordNumber).
  final Function(WordRef wordRef)? onWordTap;

  /// لون خلفية الكلمة المحدّدة. الافتراضي: لون primary بشفافية 0.25.
  final Color? selectedWordColor;

  /// لتحديد كلمة برمجياً من الخارج. عند تمريره يُتجاهل التحديد المحلي.
  final WordRef? externalSelectedWordRef;

  /// لإظهار أيقونة بجانب الآية.
  final bool? showAyahNumber;

  final double? textHeight;

  GetSingleAyah({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    this.textColor,
    this.isDark = false,
    this.fontSize,
    this.isBold = true,
    this.ayahs,
    this.isSingleAyah = true,
    this.islocalFont = false,
    this.fontsName,
    this.pageIndex,
    this.onAyahLongPress,
    this.ayahIconColor,
    this.showAyahBookmarkedIcon = false,
    this.bookmarksColor,
    this.ayahSelectedBackgroundColor,
    this.textAlign,
    this.enabledTajweed,
    this.enableWordSelection = false,
    this.onWordTap,
    this.selectedWordColor,
    this.externalSelectedWordRef,
    this.showAyahNumber = true,
    this.textHeight,
  });

  final QuranCtrl quranCtrl = QuranCtrl.instance;

  /// حالة الكلمة المحدّدة — محلية لهذا الويدجت فقط ولا تؤثر على الحالة العامّة.
  final Rx<WordRef?> _localSelectedWord = Rx<WordRef?>(null);

  @override
  Widget build(BuildContext context) {
    QuranCtrl.instance.state.isTajweedEnabled.value = enabledTajweed ?? false;
    GetStorage().write(_StorageConstants().isTajweed,
        QuranCtrl.instance.state.isTajweedEnabled.value);
    if (surahNumber < 1 || surahNumber > 114) {
      return Text(
        'رقم السورة غير صحيح',
        style: TextStyle(
          fontSize: fontSize ?? 22,
          color: textColor ?? AppColors.getTextColor(isDark!),
        ),
        textAlign: textAlign,
      );
    }
    final ayah = ayahs ??
        QuranCtrl.instance
            .getSingleAyahByAyahAndSurahNumber(ayahNumber, surahNumber);
    final pageNumber = pageIndex ??
        QuranCtrl.instance
            .getPageNumberByAyahAndSurahNumber(ayahNumber, surahNumber);
    QuranFontsService.ensurePagesLoaded(pageNumber, radius: 0).then((_) {
      // update();
      // update(['_pageViewBuild']);
      // تحميل بقية الصفحات في الخلفية
      // QuranFontsService.loadRemainingInBackground(
      //   startNearPage: pageNumber,
      //   progress: QuranCtrl.instance.state.fontsLoadProgress,
      //   ready: QuranCtrl.instance.state.fontsReady,
      // ).then((_) {
      //   // update();
      QuranCtrl.instance.update(['single_ayah_$surahNumber-$ayahNumber']);
      // });
    });
    log('surahNumber: $surahNumber, ayahNumber: $ayahNumber, pageNumber: $pageNumber');

    if (ayah.text.isEmpty) {
      return Text(
        'الآية غير موجودة',
        style: TextStyle(
          fontSize: fontSize ?? 22,
          color: textColor ?? AppColors.getTextColor(isDark!),
        ),
        textAlign: textAlign,
      );
    }

    // استخدام نفس طريقة عرض PageBuild إذا كان QPC Layout مفعل
    if (quranCtrl.isQpcLayoutEnabled) {
      return GetBuilder<QuranCtrl>(
          id: 'single_ayah_$surahNumber-$ayahNumber',
          builder: (_) {
            return _buildQpcLayout(context, pageNumber, ayah);
          });
    }

    // العرض التقليدي للخطوط الأخرى
    return _buildTraditionalLayout(context, pageNumber, ayah);
  }

  /// بناء الآية باستخدام نفس طريقة PageBuild (QPC Layout)
  Widget _buildQpcLayout(BuildContext context, int pageNumber, AyahModel ayah) {
    final blocks = quranCtrl.getQpcLayoutBlocksForPageSync(pageNumber);
    if (blocks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }
    final ayahUq = ayah.ayahUQNumber;

    // استخراج segments الخاصة بالآية المطلوبة فقط
    final List<QpcV4WordSegment> ayahSegments = [];
    for (final block in blocks) {
      if (block is QpcV4AyahLineBlock) {
        for (final seg in block.segments) {
          if (seg.surahNumber == surahNumber && seg.ayahNumber == ayahNumber) {
            ayahSegments.add(seg);
          }
        }
      }
    }

    if (ayahSegments.isEmpty) {
      // fallback للعرض التقليدي إذا لم يتم العثور على segments
      return _buildTraditionalLayout(context, pageNumber, ayah);
    }

    // عرض مع تحديد الكلمات
    if (enableWordSelection) {
      return _buildSelectableQpcWidget(context, pageNumber, ayahSegments);
    }

    // العرض الأصلي بدون تحديد الكلمات
    return GetBuilder<QuranCtrl>(
      id: 'single_ayah_$ayahUq',
      builder: (_) => LayoutBuilder(
        builder: (ctx, constraints) {
          final fs =
              (fontSize ?? PageFontSizeHelper.getFontSize(pageNumber - 1, ctx));

          return _buildRichTextFromSegments(
            context: context,
            segments: ayahSegments,
            fontSize: fs,
            ayahUq: ayahUq,
            pageNumber: pageNumber,
            showAyahNumber: showAyahNumber,
          );
        },
      ),
    );
  }

  /// بناء RichText من segments
  Widget _buildRichTextFromSegments({
    required BuildContext context,
    required List<QpcV4WordSegment> segments,
    required double fontSize,
    required int ayahUq,
    required int pageNumber,
    bool? showAyahNumber,
  }) {
    final wordInfoCtrl = WordInfoCtrl.instance;
    final bookmarksCtrl = BookmarksCtrl.instance;
    final bookmarks = bookmarksCtrl.bookmarks;
    final bookmarksAyahs = bookmarksCtrl.bookmarksAyahs;
    final ayahBookmarked = bookmarksAyahs.toList();
    final allBookmarksList = bookmarks.values.expand((list) => list).toList();

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: textAlign ?? TextAlign.right,
      softWrap: true,
      overflow: TextOverflow.visible,
      maxLines: null,
      text: TextSpan(
        children: List.generate(segments.length, (segmentIndex) {
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

          return _qpcV4SpanSegment(
            context: context,
            pageIndex: pageNumber - 1,
            isSelected: isSelectedCombined,
            showAyahBookmarkedIcon: showAyahBookmarkedIcon,
            fontSize: fontSize,
            ayahUQNum: uq,
            ayahNumber: seg.ayahNumber,
            glyphs: seg.glyphs,
            showAyahNumber: (showAyahNumber ?? true) && seg.isAyahEnd,
            wordRef: ref,
            isWordKhilaf: hasKhilaf,
            textColor: textColor ?? AppColors.getTextColor(isDark ?? false),
            ayahIconColor: ayahIconColor,
            allBookmarksList: allBookmarksList,
            bookmarksAyahs: bookmarksAyahs,
            bookmarksColor: bookmarksColor,
            ayahSelectedBackgroundColor: ayahSelectedBackgroundColor,
            isFontsLocal: islocalFont ?? false,
            fontsName: fontsName ?? '',
            fontFamilyOverride: null,
            fontPackageOverride: null,
            usePaintColoring: true,
            ayahBookmarked: ayahBookmarked,
            isDark: isDark ?? false,
          );
        }),
      ),
    );
  }

  /// بناء ويدجت QPC مع دعم تحديد الكلمات — معزول تماماً
  Widget _buildSelectableQpcWidget(
    BuildContext context,
    int pageNumber,
    List<QpcV4WordSegment> segments,
  ) {
    // تهيئة الكلمة المحدّدة
    if (externalSelectedWordRef != null) {
      _localSelectedWord.value = externalSelectedWordRef;
    } else if (_localSelectedWord.value == null && segments.isNotEmpty) {
      final first = segments.first;
      final firstWord = WordRef(
        surahNumber: first.surahNumber,
        ayahNumber: first.ayahNumber,
        wordNumber: first.wordNumber,
      );
      _localSelectedWord.value = firstWord;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onWordTap?.call(firstWord);
      });
    }

    return Obx(() {
      final currentWord = _localSelectedWord.value;
      return LayoutBuilder(
        builder: (ctx, constraints) {
          final fs =
              fontSize ?? PageFontSizeHelper.getFontSize(pageNumber - 1, ctx);
          return _buildSelectableRichText(
            context: context,
            segments: segments,
            fontSize: fs,
            pageNumber: pageNumber,
            selectedWord: currentWord,
          );
        },
      );
    });
  }

  /// بناء RichText مع دعم تحديد الكلمات — معزول عن [_buildRichTextFromSegments]
  Widget _buildSelectableRichText({
    required BuildContext context,
    required List<QpcV4WordSegment> segments,
    required double fontSize,
    required int pageNumber,
    required WordRef? selectedWord,
  }) {
    final effectiveColor = selectedWordColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.25);

    // حساب نطاق أحرف الكلمة المحدّدة لرسم التظليل عبر CustomPaint
    TextSelection? wordSelectionRange;
    int charOffset = 0;

    final spans = List.generate(segments.length, (i) {
      final seg = segments[i];
      final ref = WordRef(
        surahNumber: seg.surahNumber,
        ayahNumber: seg.ayahNumber,
        wordNumber: seg.wordNumber,
      );

      final span = _buildWordSelectableSpan(
        context: context,
        seg: seg,
        wordRef: ref,
        fontSize: fontSize,
        pageNumber: pageNumber,
      );

      // حساب عدد أحرف هذا الـ span لتحديد نطاق الكلمة المحدّدة
      final spanCharCount = _countCharsInSpan(span);
      if (selectedWord == ref) {
        // نطاق الـ glyphs فقط (بدون tail)
        wordSelectionRange = TextSelection(
          baseOffset: charOffset,
          extentOffset: charOffset + seg.glyphs.length,
        );
      }
      charOffset += spanCharCount;

      return span;
    });

    final richText = RichText(
      textDirection: TextDirection.rtl,
      textAlign: textAlign ?? TextAlign.right,
      softWrap: true,
      overflow: TextOverflow.visible,
      maxLines: null,
      text: TextSpan(children: spans),
    );

    // لف بـ _AyahSelectionWidget لرسم تظليل الكلمة المحدّدة بـ CustomPaint
    if (wordSelectionRange != null) {
      return _SingleAyahWordHighlight(
        wordSelectionRange: wordSelectionRange!,
        highlightColor: effectiveColor,
        child: richText,
      );
    }

    return richText;
  }

  /// بناء TextSpan لكلمة واحدة مع دعم الضغط للتحديد — معزول عن [_qpcV4SpanSegment]
  TextSpan _buildWordSelectableSpan({
    required BuildContext context,
    required QpcV4WordSegment seg,
    required WordRef wordRef,
    required double fontSize,
    required int pageNumber,
  }) {
    final pageIndex = pageNumber - 1;
    final withTajweed = QuranCtrl.instance.state.isTajweedEnabled.value;
    final isTenRecitations = WordInfoCtrl.instance.isTenRecitations;

    final info = WordInfoCtrl.instance.getRecitationsInfoSync(wordRef);
    final hasKhilaf = info?.hasKhilaf ?? false;
    final bool forceRed = hasKhilaf && !withTajweed && isTenRecitations;

    final String fontFamily;
    if (islocalFont == true) {
      fontFamily = fontsName ?? '';
    } else if (forceRed) {
      fontFamily = quranCtrl.getRedFontPath(pageIndex);
    } else {
      fontFamily = quranCtrl.getFontPath(pageIndex, isDark: isDark ?? false);
    }

    final baseTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: textHeight ?? 1.2,
      wordSpacing: -2,
      color: textColor ?? AppColors.getTextColor(isDark ?? false),
    );

    InlineSpan? tail;
    if (seg.isAyahEnd) {
      final hasBookmark =
          BookmarksCtrl.instance.bookmarksAyahs.contains(seg.ayahUq);

      if (hasBookmark && showAyahBookmarkedIcon && !kIsWeb) {
        tail = WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: SvgPicture.asset(
              AssetsPath.assets.ayahBookmarked,
              height: 30,
              width: 30,
            ),
          ),
        );
      } else {
        tail = TextSpan(
          text:
              '${' ${seg.ayahNumber}'.convertEnglishNumbersToArabic('${seg.ayahNumber}')}\u202F\u202F',
          style: TextStyle(
            fontFamily: 'ayahNumber',
            fontSize: fontSize + 5,
            height: 1.5,
            package: 'quran_library',
            color: ayahIconColor ?? Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }

    return TextSpan(
      children: <InlineSpan>[
        TextSpan(
          text: seg.glyphs,
          style: baseTextStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              _localSelectedWord.value = wordRef;
              onWordTap?.call(wordRef);
            },
        ),
        if (tail != null) tail,
      ],
    );
  }
}

/// ويدجت رسم محلي لتظليل الكلمة المحدّدة — معزول عن [_AyahSelectionWidget]
class _SingleAyahWordHighlight extends SingleChildRenderObjectWidget {
  final TextSelection wordSelectionRange;
  final Color highlightColor;

  const _SingleAyahWordHighlight({
    required this.wordSelectionRange,
    required this.highlightColor,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _SingleAyahWordHighlightRenderBox(
      wordRange: wordSelectionRange,
      highlightColor: highlightColor,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _SingleAyahWordHighlightRenderBox renderObject) {
    renderObject
      ..wordRange = wordSelectionRange
      ..highlightColor = highlightColor;
  }
}

class _SingleAyahWordHighlightRenderBox extends RenderProxyBox {
  _SingleAyahWordHighlightRenderBox({
    required TextSelection wordRange,
    required Color highlightColor,
  })  : _wordRange = wordRange,
        _highlightColor = highlightColor;

  TextSelection _wordRange;
  set wordRange(TextSelection value) {
    if (_wordRange == value) return;
    _wordRange = value;
    markNeedsPaint();
  }

  Color _highlightColor;
  set highlightColor(Color value) {
    if (_highlightColor == value) return;
    _highlightColor = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child is RenderParagraph) {
      final paragraph = child! as RenderParagraph;
      final boxes = paragraph.getBoxesForSelection(
        _wordRange,
        boxHeightStyle: BoxHeightStyle.max,
      );
      if (boxes.isNotEmpty) {
        final paint = Paint()..color = _highlightColor;
        const padding = EdgeInsets.only(left: 4, right: 4, top: 0, bottom: -6);

        // دمج المستطيلات على نفس السطر
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
            paint,
          );
        }
      }
    }
    super.paint(context, offset);
  }
}

/// العرض التقليدي للخطوط غير QPC — يظل داخل [GetSingleAyah]
extension _GetSingleAyahTraditional on GetSingleAyah {
  Widget _buildTraditionalLayout(
      BuildContext context, int pageNumber, AyahModel ayah) {
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      softWrap: true,
      overflow: TextOverflow.visible,
      maxLines: null,
      text: TextSpan(
        style: TextStyle(
          fontFamily: islocalFont == true
              ? fontsName
              : QuranCtrl.instance
                  .getFontPath(pageNumber - 1, isDark: isDark ?? false),
          package: 'quran_library',
          fontSize: fontSize ?? 22,
          height: 2.0,
          fontWeight: isBold! ? FontWeight.bold : FontWeight.normal,
          color: textColor ?? AppColors.getTextColor(isDark!),
        ),
        children: [
          TextSpan(
            text: '${ayah.text.replaceAll('\n', '').split(' ').join(' ')} ',
          ),
          TextSpan(
            text: '${ayah.ayahNumber}'
                .convertEnglishNumbersToArabic('${ayah.ayahNumber}'),
            style: TextStyle(
              fontFamily: 'ayahNumber',
              package: 'quran_library',
              color: ayahIconColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
