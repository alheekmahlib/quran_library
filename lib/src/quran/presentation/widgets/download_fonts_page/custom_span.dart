part of '/quran.dart';

TextSpan _qpcV4SpanSegment({
  required BuildContext context,
  required int pageIndex,
  required bool isSelected,
  required bool showAyahBookmarkedIcon,
  required double fontSize,
  required int ayahUQNum,
  required int ayahNumber,
  required WordRef wordRef,
  required bool isWordKhilaf,
  required String glyphs,
  required bool showAyahNumber,
  _LongPressStartDetailsFunction? onLongPressStart,
  required Color? textColor,
  required Color? ayahIconColor,
  required List<int> bookmarksAyahs,
  required List<int> ayahBookmarked,
  required List<BookmarkModel> allBookmarksList,
  Color? bookmarksColor,
  Color? Function(AyahModel)? customBookmarksColor,
  Color? ayahSelectedBackgroundColor,
  bool Function(AyahModel ayah)? isAyahBookmarked,
  required bool isFontsLocal,
  required String fontsName,
  String? fontFamilyOverride,
  String? fontPackageOverride,
  bool usePaintColoring = true,
  required bool isDark,
  VoidCallback? onPagePress,
  bool hideGlyphs = false,
  Color? hiddenGlyphColor,
  Color? tasmeeUnderlineColor,
}) {
  final quranCtrl = QuranCtrl.instance;
  final wordInfoCtrl = WordInfoCtrl.instance;
  final AyahModel ayahModel = quranCtrl.getAyahByUq(ayahUQNum);

  final withTajweed = QuranCtrl.instance.state.isTajweedEnabled.value;
  final isTenRecitations = WordInfoCtrl.instance.isTenRecitations;
  final bool forceRed = isWordKhilaf && !withTajweed && isTenRecitations;

  // اختيار الخط: كلمات الخلاف تستخدم خط CPAL أحمر بدلاً من foreground Paint
  final bool transparentHidden =
      hideGlyphs && !isFontsLocal && GetInstance().isRegistered<TasmeeCtrl>()
          ? TasmeeCtrl.instance.state.transparentFontsReady.value
          : false;
  final String fontFamily;
  if (transparentHidden) {
    // كلمات التسميع المخفية: متغير CPAL شفاف بالكامل — تختفي بصريًا
    // مع بقاء المقاييس فتظل أرقام الآيات في مواضعها.
    fontFamily = quranCtrl.getTransparentFontPath(pageIndex);
  } else if (fontFamilyOverride != null) {
    fontFamily = fontFamilyOverride;
  } else if (isFontsLocal) {
    fontFamily = fontsName;
  } else if (forceRed) {
    fontFamily = quranCtrl.getRedFontPath(pageIndex);
  } else {
    fontFamily = quranCtrl.getFontPath(pageIndex, isDark: isDark);
  }

  // وضع التسميع: الكلمة غير المُتَلَّاة تُلوَّن بلون خلفية الصفحة (لا تُحذف)
  // فيبقى التخطيط وتظل أرقام الآيات في مواضعها الصحيحة.
  final effectiveGlyphColor = hideGlyphs
      ? (hiddenGlyphColor ?? AppColors.getBackgroundColor(isDark))
      : (textColor ?? AppColors.getTextColor(isDark));

  final baseTextStyle = TextStyle(
    fontFamily: fontFamily,
    package: fontPackageOverride,
    fontSize: fontSize,
    height: 2,
    // wordSpacing: 50,
    color: effectiveGlyphColor,
    // وضع التسميع: الخط السفلي يرسمه محرك النص (لا الخط الملوّن COLR)
    // فيعمل حتمًا — أخضر للسليمة ولون نوع الخطأ للخاطئة.
    decoration: tasmeeUnderlineColor == null ? null : TextDecoration.underline,
    decorationColor: tasmeeUnderlineColor,
    decorationThickness: 2,
  );

  InlineSpan? tail;
  final hasBookmark = isAyahBookmarked != null
      ? isAyahBookmarked(ayahModel)
      : (ayahBookmarked.contains(ayahUQNum) ||
          bookmarksAyahs.contains(ayahUQNum));
  if (showAyahNumber) {
    tail = hasBookmark && showAyahBookmarkedIcon && !kIsWeb
        ? WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: quranCtrl.isQpcV4Enabled
                  ? const EdgeInsets.symmetric(horizontal: 4.0)
                  : const EdgeInsets.only(right: 4.0, left: 4.0, bottom: 16.0),
              child: SvgPicture.asset(
                AssetsPath.assets.ayahBookmarked,
                height: UiHelper.currentOrientation(30.0.h, 130.0.h, context),
                width: UiHelper.currentOrientation(30.0.w, 130.0.w, context),
              ),
            ),
          )
        : TextSpan(
            text: usePaintColoring
                ? '${'$ayahNumber'.convertEnglishNumbersToArabic(ayahNumber.toString())}\u202F\u202F'
                : '\u202F${'$ayahNumber'.convertEnglishNumbersToArabic(ayahNumber.toString())}\u202F',
            style: TextStyle(
              fontFamily: 'ayahNumber',
              fontSize: usePaintColoring ? (fontSize + 5) : (fontSize + 5),
              height: 1.5,
              package: 'quran_library',
              color: ayahIconColor ?? Theme.of(context).colorScheme.primary,
            ),
            recognizer: LongPressGestureRecognizer(
                duration: const Duration(milliseconds: 500))
              ..onLongPressStart = onLongPressStart,
          );
  }

  final GestureRecognizer recognizer;
  if (!wordInfoCtrl.isWordSelectionEnabled) {
    // تحديد الكلمة معطّل: الضغط القصير لا يفعل شيئاً، الضغط المطوّل يفتح قائمة الآية
    recognizer = TapLongPressRecognizer(
      shortHoldDuration: const Duration(milliseconds: 150),
      longHoldDuration: const Duration(milliseconds: 500),
    )
      ..onQuickTapCallback = onPagePress
      ..onShortHoldStartCallback = () {
        // فارغ عمداً — لإبقاء الحدث حياً حتى يصل للضغط المطوّل
      }
      ..onShortHoldCompleteCallback = null
      ..onLongHoldStartCallback = (details) {
        onLongPressStart?.call(details);
      };
  } else {
    recognizer = TapLongPressRecognizer(
      shortHoldDuration: const Duration(milliseconds: 150),
      longHoldDuration: const Duration(milliseconds: 500),
    )
      ..onQuickTapCallback = onPagePress
      ..onShortHoldStartCallback = () {
        wordInfoCtrl.setSelectedWord(wordRef);
      }
      ..onShortHoldCompleteCallback = () {
        () async {
          if (!context.mounted) return;
          await showWordInfoBottomSheet(
              context: context, ref: wordRef, isDark: isDark);
          if (!context.mounted) return;
          wordInfoCtrl.clearSelectedWord();
        }();
      }
      ..onLongHoldStartCallback = (details) {
        wordInfoCtrl.clearSelectedWord();
        onLongPressStart?.call(details);
      };
  }

  return TextSpan(
    children: <InlineSpan>[
      // كلمة التسميع المخفية: بالخط الشفاف تبقى في التخطيط (فتظل أرقام
      // الآيات في مواضعها)، وإن لم يكن جاهزًا تُحذف حروفها احتياطًا —
      // وبلا مستمع لمس في الحالتين.
      if (!hideGlyphs || transparentHidden)
        TextSpan(
          text: glyphs,
          style: baseTextStyle,
          recognizer: hideGlyphs ? null : recognizer,
        ),
      if (tail != null) tail,
    ],
  );
}

typedef _LongPressStartDetailsFunction = void Function(LongPressStartDetails)?;

// ── وضع التسميع — مساعدات العرض / Tasmee display helpers ─────────────

/// حالة كلمة في وضع التسميع (null = الوضع غير مفعّل لهذه الصفحة).
///
/// [pageIndex] فهرس الصفحة (0-based) — الإخفاء يخص صفحة النطاق فقط.
TasmeeWordStatus? tasmeeStatusOfSegment(QpcV4WordSegment seg, int pageIndex) {
  final TasmeeCtrl tasmeeCtrl;
  if (!GetInstance().isRegistered<TasmeeCtrl>()) return null;
  tasmeeCtrl = TasmeeCtrl.instance;
  if (!tasmeeCtrl.state.isTasmeeMode.value) return null;
  // زر إظهار الكلام: عرض طبيعي مؤقت لكل كلمات الصفحة.
  if (tasmeeCtrl.state.showAllWords.value) return null;
  if (tasmeeCtrl.state.currentRangePage != pageIndex + 1) return null;
  return tasmeeCtrl.wordStatusOf('${seg.ayahUq}:${seg.wordNumber}');
}

/// نوع خطأ كلمة تسميع (null = غير خاطئة/الوضع غير مفعّل).
TasmeeErrorKind? tasmeeErrorKindOfSegment(QpcV4WordSegment seg, int pageIndex) {
  final TasmeeCtrl tasmeeCtrl;
  if (!GetInstance().isRegistered<TasmeeCtrl>()) return null;
  tasmeeCtrl = TasmeeCtrl.instance;
  if (!tasmeeCtrl.state.isTasmeeMode.value) return null;
  if (tasmeeCtrl.state.showAllWords.value) return null;
  if (tasmeeCtrl.state.currentRangePage != pageIndex + 1) return null;
  return tasmeeCtrl.tasmeeErrorKindOf('${seg.ayahUq}:${seg.wordNumber}');
}

/// يحدّد لون الخط السفلي لكلمة تسميع من حالتها ونوع خطأها
/// (null = بلا خط: المخفية والجارية والوضع غير المفعّل).
///
/// [style] النمط المحلول مسبقًا في نطاق بناء السطر — بلا سياق Get
/// (استدعاء أثناء الـ layout قد يسبق جاهزية Get.context).
Color? tasmeeUnderlineColorFor({
  required TasmeeWordStatus? status,
  required TasmeeErrorKind? kind,
  required TasmeeStyle style,
}) {
  if (status == null || status == TasmeeWordStatus.hidden) return null;
  if (status == TasmeeWordStatus.current) return null; // لها تظليل مرسوم.
  return switch (status) {
    TasmeeWordStatus.correct => style.correctColor,
    TasmeeWordStatus.incorrect => switch (kind) {
        TasmeeErrorKind.tajweed => style.tajweedErrorColor,
        TasmeeErrorKind.tashkeel => style.tashkeelErrorColor,
        TasmeeErrorKind.normal => style.normalErrorColor,
        _ => style.incorrectColor,
      },
    TasmeeWordStatus.current => null,
    TasmeeWordStatus.hidden => null,
  };
}

/// بصمة حالة التسميع المؤثرة على بناء السطر (تُدمج في _computeFingerprint).
int tasmeeFingerprint() {
  if (!GetInstance().isRegistered<TasmeeCtrl>()) return 0;
  final t = TasmeeCtrl.instance;
  return Object.hash(
    t.state.isTasmeeMode.value.hashCode,
    t.state.currentRangePage.hashCode,
    t.state.showAllWords.value.hashCode,
    t.state.transparentFontsReady.value.hashCode,
    t.state.currentWordKey.value.hashCode,
    Object.hashAll(t.state.wordStatuses.entries
        .map((e) => Object.hash(e.key, e.value.index))),
    Object.hashAll(t.state.wordErrorKinds.entries
        .map((e) => Object.hash(e.key, e.value.index))),
  );
}
