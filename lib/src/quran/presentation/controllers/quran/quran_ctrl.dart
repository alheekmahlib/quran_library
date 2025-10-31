part of '/quran.dart';

class QuranCtrl extends GetxController {
  static QuranCtrl get instance => GetInstance().putOrFind(() => QuranCtrl());

  QuranCtrl({QuranRepository? quranRepository})
      : _quranRepository = quranRepository ?? QuranRepository(),
        super();

  final QuranRepository _quranRepository;

  RxList<QuranPageModel> staticPages = <QuranPageModel>[].obs;
  RxList<int> quranStops = <int>[].obs;
  RxList<int> surahsStart = <int>[].obs;
  final List<SurahModel> surahs = [];
  final List<AyahModel> ayahs = [];
  int lastPage = 1;
  int? initialPage;
  final RxList<AyahModel> searchResultAyahs = <AyahModel>[].obs;
  final RxList<SurahModel> searchResultSurahs = <SurahModel>[].obs;

  /// List of selected ayahs by their unique number
  final selectedAyahsByUnequeNumber = <int>[].obs;
  bool isAyahSelected = false;
  RxDouble scaleFactor = 1.0.obs;
  RxDouble baseScaleFactor = 1.0.obs;
  final isLoading = true.obs;
  RxList<SurahNamesModel> surahsList = <SurahNamesModel>[].obs;
  RxBool isShowControl = false.obs;
  // وضع تحديد متعدد للآيات
  final RxBool isMultiSelectMode = false.obs;
  // آيات مظللة برمجياً (لا تعتمد على اختيار المستخدم)
  final RxList<int> externallyHighlightedAyahs = <int>[].obs;
  late FocusNode searchFocusNode;
  late TextEditingController searchTextController;

  late Directory _dir;
  // late QuranSearch quranSearch;

  // شرح: تحسين PageController للحصول على أداء أفضل
  // Explanation: Optimized PageController for better performance
  PageController quranPagesController = PageController(
    keepPage: true,
    viewportFraction: 1.0,
  );

  // final bool _scrollListenerAttached = false;
  // final int _lastPrefetchedForPage = -1;

  QuranState state = QuranState();
  Timer? _savePageDebounce;

  @override
  void onInit() async {
    super.onInit();
    if (!kIsWeb) {
      _dir = await getApplicationDocumentsDirectory();
    }
    searchFocusNode = FocusNode();
    searchTextController = TextEditingController();
  }

  @override
  void onClose() {
    staticPages.close();
    quranStops.close();
    surahsStart.close();
    selectedAyahsByUnequeNumber.close();
    searchResultAyahs.close();
    scaleFactor.close();
    baseScaleFactor.close();
    isLoading.close();
    surahsList.close();
    state.dispose();
    quranPagesController.dispose();
    super.onClose();
    searchFocusNode.dispose();
    searchTextController.dispose();
  }

  /// -------- [Methods] ----------

  // Future<void> _initSearch() async {
  //   quranSearch = QuranSearch(ayahs); // تأكد من أن `ayahs` محملة مسبقًا
  //   await quranSearch.loadModel(); // تحميل نموذج BERT
  // }

  Future<void> loadQuranDataV3() async {
    lastPage = _quranRepository.getLastPage() ?? 1;
    state.currentPageNumber.value = lastPage;
    if (lastPage != 0) {
      jumpToPage(lastPage - 1);
    }
    if (state.surahs.isEmpty) {
      List<dynamic> surahsJson = await _quranRepository.getQuranDataV3();
      state.surahs =
          surahsJson.map((s) => SurahModel.fromDownloadedFontsJson(s)).toList();

      for (final surah in state.surahs) {
        state.allAyahs.addAll(surah.ayahs);
        // log('Added ${surah.arabicName} ayahs');
        // update();
      }
      List.generate(604, (pageIndex) {
        state.pages.add(state.allAyahs
            .where((ayah) => ayah.page == pageIndex + 1)
            .toList());
      });
      state.isQuranLoaded = true;
      // log('Pages Length: ${state.pages.length}', name: 'Quran Controller');
    }
  }

  List<AyahModel> getAyahsByPage(int page) {
    // تصفية القائمة بناءً على رقم الصفحة
    final filteredAyahs = ayahs.where((ayah) => ayah.page == page).toList();

    // فرز القائمة حسب رقم الآية
    filteredAyahs.sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));

    return filteredAyahs;
  }

  Future<void> loadQuranDataV1(
      {int quranPages = QuranRepository.hafsPagesNumber}) async {
    // حفظ آخر صفحة
    // lastPage = _quranRepository.getLastPage() ?? 1;
    // state.currentPageNumber.value = lastPage;
    // if (lastPage != 0) {
    //   jumpToPage(lastPage - 1);
    // }
    // إذا كانت الصفحات لم تُملأ أو العدد غير متطابق
    if (staticPages.isEmpty || quranPages != staticPages.length) {
      // إنشاء صفحات فارغة
      staticPages.value = List.generate(
        quranPages,
        (index) => QuranPageModel(pageNumber: index + 1, ayahs: [], lines: []),
      );
      final quranJson = await _quranRepository.getQuran();
      int hizb = 1;
      int surahsIndex = 1;
      List<AyahModel> thisSurahAyahs = [];
      for (int i = 0; i < quranJson.length; i++) {
        // تحويل كل json إلى AyahModel
        final ayah = AyahModel.fromOriginalJson(quranJson[i]);
        if (ayah.surahNumber != surahsIndex) {
          surahs.last.endPage = ayahs.last.page;
          surahs.last.ayahs = thisSurahAyahs;
          surahsIndex = ayah.surahNumber!;
          thisSurahAyahs = [];
        }
        ayahs.add(ayah);
        thisSurahAyahs.add(ayah);
        staticPages[ayah.page - 1].ayahs.add(ayah);
        if (ayah.text.contains('۞')) {
          staticPages[ayah.page - 1].hizb = hizb++;
          quranStops.add(ayah.page);
        }
        if (ayah.text.contains('۩')) {
          staticPages[ayah.page - 1].hasSajda = true;
        }
        if (ayah.ayahNumber == 1) {
          ayah.text = ayah.text.replaceAll('۞', '');
          staticPages[ayah.page - 1].numberOfNewSurahs++;
          surahs.add(SurahModel(
            surahNumber: ayah.surahNumber!,
            englishName: ayah.englishName!,
            arabicName: ayah.arabicName!,
            ayahs: [],
            isDownloadedFonts: false,
          ));
          surahsStart.add(ayah.page - 1);
        }
      }
      surahs.last.endPage = ayahs.last.page;
      surahs.last.ayahs = thisSurahAyahs;
      // ملء الأسطر (lines) لكل صفحة
      for (QuranPageModel staticPage in staticPages) {
        List<AyahModel> ayas = [];
        for (AyahModel aya in staticPage.ayahs) {
          if (aya.ayahNumber == 1 && ayas.isNotEmpty) {
            ayas.clear();
          }
          if (aya.text.contains('\n')) {
            final lines = aya.text.split('\n');
            for (int i = 0; i < lines.length; i++) {
              bool centered = false;
              if ((aya.centered ?? false) && i == lines.length - 2) {
                centered = true;
              }
              final a = AyahModel.fromAya(
                ayah: aya,
                aya: lines[i],
                ayaText: lines[i],
                centered: centered,
              );
              ayas.add(a);
              if (i < lines.length - 1) {
                staticPage.lines.add(LineModel([...ayas]));
                ayas.clear();
              }
            }
          } else {
            ayas.add(aya);
          }
        }
        // إذا بقيت آيات في ayas بعد آخر سطر
        if (ayas.isNotEmpty) {
          staticPage.lines.add(LineModel([...ayas]));
        }
        ayas.clear();
      }
      update();
    }
  }

  Future<void> fetchSurahs() async {
    try {
      isLoading(true);
      final jsonResponse = await _quranRepository.getSurahs();
      final response = SurahResponseModel.fromJson(jsonResponse);
      surahsList.assignAll(response.surahs);
    } catch (e) {
      log('Error fetching data: $e');
    } finally {
      isLoading(false);
    }
    update();
  }

  List<AyahModel> search(String searchText) {
    if (searchText.isEmpty) {
      return [];
    } else {
      // تطبيع النصوص المدخلة
      final normalizedSearchText =
          normalizeText(searchText.toLowerCase().trim());

      final filteredAyahs = ayahs.where((aya) {
        // تطبيع نص الآية واسم السورة
        final normalizedAyahText =
            normalizeText(aya.ayaTextEmlaey.toLowerCase());
        final normalizedSurahNameAr =
            normalizeText(aya.arabicName!.toLowerCase());
        final normalizedSurahNameEn =
            normalizeText(aya.englishName!.toLowerCase());

        // التحقق من تطابق نص الآية
        final containsWord = normalizedAyahText.contains(normalizedSearchText);

        // التحقق من تطابق رقم الصفحة
        final matchesPage = aya.page.toString() ==
            normalizedSearchText
                .convertArabicNumbersToEnglish(normalizedSearchText);

        // التحقق من تطابق اسم السورة بالعربية أو الإنجليزية
        final matchesSurahName =
            normalizedSurahNameAr == normalizedSearchText ||
                normalizedSurahNameEn == normalizedSearchText;

        // التحقق من رقم الآية
        final matchesAyahNumber = aya.ayahNumber.toString() ==
            normalizedSearchText
                .convertArabicNumbersToEnglish(normalizedSearchText);

        // إذا تحقق أي شرط من الشروط أعلاه باستثناء رقم السورة
        return containsWord ||
            matchesPage ||
            matchesSurahName ||
            matchesAyahNumber;
      }).toList();

      return filteredAyahs;
    }
  }

// دالة تطبيع النصوص لتحويل الأحرف
  String normalizeText(String text) {
    return text
        .replaceAll('ة', 'ه')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ئ', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll(RegExp(r'\s+'), ' '); // إزالة الفراغات الزائدة
  }

  List<SurahModel> searchSurah(String searchText) {
    if (searchText.isEmpty) {
      return [];
    } else {
      // تحويل الأرقام العربية إلى إنجليزية في النص المدخل
      // Convert Arabic numbers to English in the input text
      final convertedSearchText =
          searchText.convertArabicNumbersToEnglish(searchText);

      // إزالة التشكيل وتطبيع النص المدخل
      // Remove diacritics and normalize the input text
      final cleanedSearchText = removeDiacriticsQuran(convertedSearchText);
      final normalizedSearchText =
          normalizeText(cleanedSearchText.toLowerCase().trim());

      final filteredSurahs = surahs.where((surah) {
        // إزالة التشكيل وتطبيع أسماء السور
        // Remove diacritics and normalize surah names
        final cleanedSurahNameAr = removeDiacriticsQuran(surah.arabicName);
        final normalizedSurahNameAr =
            normalizeText(cleanedSurahNameAr.toLowerCase());
        final normalizedSurahNameEn =
            normalizeText(surah.englishName.toLowerCase());

        // استخدام contains بدلاً من == للسماح بمطابقة جزئية
        // Use contains instead of == to allow partial matching
        final matchesSurahName =
            normalizedSurahNameAr.contains(normalizedSearchText) ||
                normalizedSurahNameEn.contains(normalizedSearchText);

        // تحويل رقم السورة إلى نص مع تحويل الأرقام العربية
        // Convert surah number to text with Arabic number conversion
        final surahNumberText = surah.surahNumber.toString();
        final matchesSurahNumber = surahNumberText == normalizedSearchText;

        return matchesSurahName || matchesSurahNumber;
      }).toList();

      return filteredSurahs;
    }
  }

  void saveLastPage(int lastPage) {
    this.lastPage = lastPage;
    // Debounce الكتابة لتقليل I/O
    _savePageDebounce?.cancel();
    _savePageDebounce = Timer(const Duration(milliseconds: 400), () {
      _quranRepository.saveLastPage(lastPage);
    });
  }

  // شرح: تحسين التنقل للحصول على سكرول أكثر سلاسة
  // Explanation: Improved navigation for smoother scrolling
  void jumpToPage(int page) {
    if (quranPagesController.hasClients) {
      // استخدام animateToPage بدلاً من jumpToPage للحصول على انتقال أكثر سلاسة
      // Use animateToPage instead of jumpToPage for smoother transition
      quranPagesController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      quranPagesController = PageController(
        initialPage: page,
        keepPage: true,
        viewportFraction: 1.0,
      );
    }
  }

  PageController getPageController(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;

    // احسب قيمة الـ viewportFraction الهدف بناءً على حجم/اتجاه الشاشة
    final double targetFraction =
        (Responsive.isDesktop(context) && orientation == Orientation.landscape)
            ? 0.5
            : 1.0;

    // إذا لم يكن لدينا عملاء (أول إنشاء) أو تغيّرت القيمة، أعد إنشاء المتحكم
    final bool needsNewController = !quranPagesController.hasClients ||
        (quranPagesController.viewportFraction != targetFraction);

    if (needsNewController) {
      // حافظ على الفهرس الحالي للصفحة
      int currentIndex = state.currentPageNumber.value - 1;
      if (quranPagesController.hasClients) {
        final double? p = quranPagesController.page;
        if (p != null) currentIndex = p.round();
      }
      currentIndex = currentIndex.clamp(0, 603);

      final oldController = quranPagesController;
      quranPagesController = PageController(
        initialPage: currentIndex,
        keepPage: kIsWeb || GetPlatform.isDesktop,
        viewportFraction: targetFraction,
      );

      // تخلّص من المتحكم القديم بعد الإطار لتجنّب تعارضات التثبيت
      if (oldController != quranPagesController) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            oldController.dispose();
          } catch (_) {
            // تجاهل أي أخطاء تصريف إن كان قد صُرّف سابقًا
          }
        });
      }
    }

    // إضافة مستمع تمرير لمرة واحدة
    // if (!_scrollListenerAttached) {
    //   _scrollListenerAttached = true;
    //   quranPagesController.addListener(() {
    //     final metrics = quranPagesController.positions.isNotEmpty
    //         ? quranPagesController.position
    //         : null;
    //     if (metrics == null) return;
    //     final viewport = metrics.viewportDimension;
    //     if (viewport == 0) return;

    //     final page = metrics.pixels / viewport;

    //     // تحديد الصفحة الحالية والاتجاه
    //     final currentIndex = page.floor().clamp(0, 603);
    //     final delta = page - currentIndex;

    //     // اقتراب من الحافة اليمنى/اليسرى لبدء تحميل مبكر
    //     const threshold = 0.82; // بدء التهيئة قبل السنيب
    //     int? targetNeighbor;
    //     if (delta > threshold && currentIndex + 1 < 604) {
    //       targetNeighbor = currentIndex + 1; // يسار -> الصفحة التالية (RTL)
    //     } else if (delta < (1 - threshold) && currentIndex - 1 >= 0) {
    //       // عند بداية الصفحة، حضّر السابقة
    //       targetNeighbor = currentIndex - 1;
    //     }

    //     if (targetNeighbor != null &&
    //         targetNeighbor != _lastPrefetchedForPage) {
    //       _lastPrefetchedForPage = targetNeighbor;
    //       // اختيار عدد الجيران بحسب الجهاز: هواتف ±1، غيرها ±2
    //       final isWeak =
    //           Platform.isAndroid || Platform.isIOS || Platform.isFuchsia;
    //       final neighborOffsets =
    //           isWeak ? const [0, 1, -1] : const [0, 1, -1, 2, -2];
    //       final targets = neighborOffsets
    //           .map((o) => targetNeighbor! + o)
    //           .where((i) => i >= 0 && i < 604)
    //           .toList();

    //       // جدولة بوقت الخمول لضمان عدم حجب UI
    //       SchedulerBinding.instance.scheduleTask(() async {
    //         if (!isDownloadFonts) return;
    //         for (final t in targets) {
    //           try {
    //             await prepareFonts(t, isFontsLocal: false);
    //           } catch (_) {
    //             // تجاهل أخطاء التهيئة المسبقة
    //           }
    //         }
    //       }, Priority.idle);
    //     }
    //   });
    // }

    return quranPagesController;
  }

  /// Toggle the selection of an ayah by its unique number
  void toggleAyahSelection(int ayahUnequeNumber, {bool forceAddition = false}) {
    log('selectedAyahs: ${selectedAyahsByUnequeNumber.join(', ')}');
    if (!forceAddition &&
        selectedAyahsByUnequeNumber.contains(ayahUnequeNumber)) {
      if (selectedAyahsByUnequeNumber.length > 1) {
        selectedAyahsByUnequeNumber.remove(ayahUnequeNumber);
      }
    } else {
      selectedAyahsByUnequeNumber.clear();
      selectedAyahsByUnequeNumber.add(ayahUnequeNumber);
    }
    selectedAyahsByUnequeNumber.refresh();
    // إعادة بناء محدودة للصفحة الحالية فقط
    update(['selection_page_']);
    log('selectedAyahs: ${selectedAyahsByUnequeNumber.join(', ')}');
  }

  /// إضافة/إزالة آية من التحديد بدون مسح بقية التحديد (للوضع المتعدد)
  void toggleAyahSelectionMulti(int ayahUniqueNumber) {
    if (selectedAyahsByUnequeNumber.contains(ayahUniqueNumber)) {
      selectedAyahsByUnequeNumber.remove(ayahUniqueNumber);
    } else {
      selectedAyahsByUnequeNumber.add(ayahUniqueNumber);
    }
    selectedAyahsByUnequeNumber.refresh();
    update(['selection_page_']);
  }

  void setMultiSelectMode(bool enabled) {
    isMultiSelectMode.value = enabled;
  }

  // إدارة التظليل البرمجي
  void setExternalHighlights(List<int> ayahUQNumbers) {
    externallyHighlightedAyahs
        .assignAll(ayahUQNumbers.toSet().toList()..sort());
  }

  void addExternalHighlight(int ayahUQNumber) {
    if (!externallyHighlightedAyahs.contains(ayahUQNumber)) {
      externallyHighlightedAyahs.add(ayahUQNumber);
    }
  }

  void removeExternalHighlight(int ayahUQNumber) {
    externallyHighlightedAyahs.remove(ayahUQNumber);
  }

  void clearExternalHighlights() {
    externallyHighlightedAyahs.clear();
  }

  /// تحويل (رقم السورة، رقم الآية) إلى الرقم الفريد للآية
  int? getAyahUQBySurahAndAyah(int surahNumber, int ayahNumber) {
    try {
      final surah = surahs.firstWhere((s) => s.surahNumber == surahNumber);
      final ayah = surah.ayahs.firstWhere((a) => a.ayahNumber == ayahNumber);
      return ayah.ayahUQNumber;
    } catch (_) {
      return null;
    }
  }

  /// إرجاع أرقام UQ لكل الآيات ذات أرقام ayahNumber المحددة داخل نطاق صفحات
  List<int> getAyahUQsForPagesByAyahNumbers(
      {required int startPage,
      required int endPage,
      required List<int> ayahNumbers}) {
    final result = <int>{};
    final sp = startPage.clamp(1, 604);
    final ep = endPage.clamp(1, 604);
    for (int p = sp; p <= ep; p++) {
      final pageAyahs = staticPages.isNotEmpty
          ? staticPages[p - 1].ayahs
          : ayahs.where((a) => a.page == p).toList();
      for (final a in pageAyahs) {
        if (ayahNumbers.contains(a.ayahNumber)) {
          result.add(a.ayahUQNumber);
        }
      }
    }
    return result.toList();
  }

  /// إرجاع أرقام UQ لكل الآيات ضمن نطاق عبر السور، مثل 2:15-3:25 (شامل)
  List<int> getAyahUQsForSurahAyahRange({
    required int startSurah,
    required int startAyah,
    required int endSurah,
    required int endAyah,
  }) {
    // تصحيح الترتيب إذا كان البداية بعد النهاية
    bool swapNeeded = (startSurah > endSurah) ||
        (startSurah == endSurah && startAyah > endAyah);
    int sSurah = swapNeeded ? endSurah : startSurah;
    int sAyah = swapNeeded ? endAyah : startAyah;
    int eSurah = swapNeeded ? startSurah : endSurah;
    int eAyah = swapNeeded ? startAyah : endAyah;

    // ضبط الحدود ضمن المدى الصحيح للسور
    sSurah = sSurah.clamp(1, surahs.isEmpty ? 114 : surahs.length);
    eSurah = eSurah.clamp(1, surahs.isEmpty ? 114 : surahs.length);

    final result = <int>{};
    for (int s = sSurah; s <= eSurah; s++) {
      SurahModel? surah;
      try {
        surah = surahs.firstWhere((x) => x.surahNumber == s);
      } catch (_) {
        surah = null;
      }
      if (surah == null || surah.ayahs.isEmpty) continue;
      final int firstAyah = (s == sSurah) ? sAyah : 1;
      final int lastAyah = (s == eSurah)
          ? eAyah
          : surah.ayahs.last.ayahNumber; // آخر آية في السورة

      final int from = firstAyah.clamp(1, surah.ayahs.last.ayahNumber);
      final int to = lastAyah.clamp(1, surah.ayahs.last.ayahNumber);
      for (final a in surah.ayahs) {
        if (a.ayahNumber >= from && a.ayahNumber <= to) {
          result.add(a.ayahUQNumber);
        }
      }
    }
    return result.toList();
  }

  /// يحلل نص نطاق على شكل "2:15-3:25" إلى (startSurah,startAyah,endSurah,endAyah)
  /// يدعم الأرقام العربية والإنجليزية والمسافات.
  (int startSurah, int startAyah, int endSurah, int endAyah)?
      parseSurahAyahRangeString(String input) {
    final normalized = input.convertArabicNumbersToEnglish(input).trim();
    final reg = RegExp(r"^\s*(\d+)\s*:\s*(\d+)\s*-\s*(\d+)\s*:\s*(\d+)\s*$");
    final m = reg.firstMatch(normalized);
    if (m == null) return null;
    try {
      final ss = int.parse(m.group(1)!);
      final sa = int.parse(m.group(2)!);
      final es = int.parse(m.group(3)!);
      final ea = int.parse(m.group(4)!);
      return (ss, sa, es, ea);
    } catch (_) {
      return null;
    }
  }

  void clearSelection() {
    selectedAyahsByUnequeNumber.clear();
    update(['selection_page_']);
  }

  Widget textScale(dynamic widget1, dynamic widget2) {
    if (state.scaleFactor.value <= 1.3) {
      return widget1;
    } else {
      return widget2;
    }
  }

  void updateTextScale(ScaleUpdateDetails details) {
    double newScaleFactor = state.baseScaleFactor.value * details.scale;
    if (newScaleFactor < 1.0) {
      newScaleFactor = 1.0;
    } else if (newScaleFactor < 4) {
      state.scaleFactor.value = newScaleFactor;
    }

    update(['_pageViewBuild']);
  }

  String removeDiacriticsQuran(String input) {
    final diacriticsMap = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'إٔ': 'ا',
      'إٕ': 'ا',
      'إٓ': 'ا',
      'أَ': 'ا',
      'إَ': 'ا',
      'آَ': 'ا',
      'إُ': 'ا',
      'إٌ': 'ا',
      'إً': 'ا',
      'ة': 'ه',
      'ً': '',
      'ٌ': '',
      'ٍ': '',
      'َ': '',
      'ُ': '',
      'ِ': '',
      'ّ': '',
      'ْ': '',
      'ـ': '',
      'ٰ': '',
      'ٖ': '',
      'ٗ': '',
      'ٕ': '',
      'ٓ': '',
      'ۖ': '',
      'ۗ': '',
      'ۘ': '',
      'ۙ': '',
      'ۚ': '',
      'ۛ': '',
      'ۜ': '',
      '۝': '',
      '۞': '',
      '۟': '',
      '۠': '',
      'ۡ': '',
      'ۢ': '',
    };

    StringBuffer buffer = StringBuffer();
    Map<int, int> indexMapping =
        {}; // Ensure indexMapping is declared if not already globally declared
    for (int i = 0; i < input.length; i++) {
      String char = input[i];
      String? mappedChar = diacriticsMap[char];
      if (mappedChar != null) {
        buffer.write(mappedChar);
        if (mappedChar.isNotEmpty) {
          indexMapping[buffer.length - 1] = i;
        }
      } else {
        buffer.write(char);
        indexMapping[buffer.length - 1] = i;
      }
    }
    return buffer.toString();
  }

  // List<TajweedRuleModel> getTajweedRules({required String languageCode}) {
  //   if (languageCode == "ar") {
  //     return tajweedRulesListAr;
  //   } else if (languageCode == "en") {
  //     return tajweedRulesListEn;
  //   } else if (languageCode == "bn") {
  //     return tajweedRulesListBn;
  //   } else if (languageCode == "id") {
  //     return tajweedRulesListId;
  //   } else if (languageCode == "tr") {
  //     return tajweedRulesListTr;
  //   } else if (languageCode == "ur") {
  //     return tajweedRulesListUr;
  //   }
  //   return tajweedRulesListAr;
  // }

  KeyEventResult controlRLByKeyboard(FocusNode node, KeyEvent event) {
    // على الويب، التقط فقط KeyDown لتجنب التكرارات أو التعارض مع KeyUp
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // تأكد من جاهزية المتحكم قبل التحريك
    if (!quranPagesController.hasClients) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      log('Left Arrow Pressed');
      quranPagesController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      log('Right Arrow Pressed');
      quranPagesController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
