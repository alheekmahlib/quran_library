import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/ayah.dart';
import '../../../data/models/quran_fonts_models/surahs_model.dart';
import '../../../data/models/quran_page.dart';
import '../../../data/models/styles_models/surah_names_model.dart';
import '../../../data/models/surah.dart';
import '../../../data/repositories/quran_repository.dart';
import 'quran_state.dart';

class QuranCtrl extends GetxController {
  static QuranCtrl get instance => Get.isRegistered<QuranCtrl>()
      ? Get.find<QuranCtrl>()
      : Get.put<QuranCtrl>(QuranCtrl());
  QuranCtrl({QuranRepository? quranRepository})
      : _quranRepository = quranRepository ?? QuranRepository(),
        super();

  final QuranRepository _quranRepository;

  RxList<QuranPage> staticPages = <QuranPage>[].obs;
  RxList<int> quranStops = <int>[].obs;
  RxList<int> surahsStart = <int>[].obs;
  RxList<Surah> surahs = <Surah>[].obs;
  final RxList<AyahModel> ayahs = <AyahModel>[].obs;
  int lastPage = 1;
  int? initialPage;
  RxList<AyahModel> ayahsList = <AyahModel>[].obs;
  var selectedAyahIndexes = <int>[].obs;
  bool isAyahSelected = false;
  RxDouble scaleFactor = 1.0.obs;
  RxDouble baseScaleFactor = 1.0.obs;
  var isLoading = true.obs;
  RxList<SurahNamesModel> surahsList = <SurahNamesModel>[].obs;

  PageController _pageController = PageController();

  QuranState state = QuranState();

  @override
  void onClose() {
    state.quranPageController.dispose();
    state.overlayEntry!.remove();
    super.onClose();
  }

  /// -------- [Methods] ----------

  Future<void> loadFontsQuran() async {
    lastPage = _quranRepository.getLastPage() ?? 1;
    if (lastPage != 0) {
      jumpToPage(lastPage - 1);
    }
    if (state.surahs.isEmpty) {
      List<dynamic> surahsJson = await _quranRepository.getFontsQuran();
      state.surahs =
          surahsJson.map((s) => SurahFontsModel.fromJson(s)).toList();

      for (final surah in state.surahs) {
        state.allAyahs.addAll(surah.ayahs);
        // log('Added ${surah.arabicName} ayahs');
        update();
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

  Future<void> loadQuran({quranPages = QuranRepository.hafsPagesNumber}) async {
    lastPage = _quranRepository.getLastPage() ?? 1;
    if (lastPage != 0) {
      jumpToPage(lastPage - 1);
    }
    if (staticPages.isEmpty || quranPages != staticPages.length) {
      staticPages.value = List.generate(quranPages,
          (index) => QuranPage(pageNumber: index + 1, ayahs: [], lines: []));
      final quranJson = await _quranRepository.getQuran();
      int hizb = 1;
      int surahsIndex = 1;
      List<AyahModel> thisSurahAyahs = [];
      for (int i = 0; i < quranJson.length; i++) {
        final ayah = AyahModel.fromJson(quranJson[i]);
        if (ayah.surahNumber != surahsIndex) {
          surahs.last.endPage = ayahs.last.page;
          surahs.last.ayahs = thisSurahAyahs;
          surahsIndex = ayah.surahNumber;
          thisSurahAyahs = [];
        }
        ayahs.add(ayah);
        thisSurahAyahs.add(ayah);
        staticPages[ayah.page - 1].ayahs.add(ayah);
        if (ayah.ayah.contains('۞')) {
          staticPages[ayah.page - 1].hizb = hizb++;
          quranStops.add(ayah.page);
        }
        if (ayah.ayah.contains('۩')) {
          staticPages[ayah.page - 1].hasSajda = true;
        }
        if (ayah.ayahNumber == 1) {
          ayah.ayah = ayah.ayah.replaceAll('۞', '');
          staticPages[ayah.page - 1].numberOfNewSurahs++;
          surahs.add(Surah(
              index: ayah.surahNumber,
              startPage: ayah.page,
              endPage: 0,
              nameEn: ayah.surahNameEn,
              nameAr: ayah.surahNameAr,
              ayahs: []));
          surahsStart.add(ayah.page - 1);
        }
      }
      surahs.last.endPage = ayahs.last.page;
      surahs.last.ayahs = thisSurahAyahs;
      for (QuranPage staticPage in staticPages) {
        List<AyahModel> ayas = [];
        for (AyahModel aya in staticPage.ayahs) {
          if (aya.ayahNumber == 1 && ayas.isNotEmpty) {
            ayas.clear();
          }
          if (aya.ayah.contains('\n')) {
            final lines = aya.ayah.split('\n');
            for (int i = 0; i < lines.length; i++) {
              bool centered = false;
              if ((aya.centered && i == lines.length - 2)) {
                centered = true;
              }
              final a = AyahModel.fromAya(
                  ayah: aya,
                  aya: lines[i],
                  ayaText: lines[i],
                  centered: centered);
              ayas.add(a);
              if (i < lines.length - 1) {
                staticPage.lines.add(Line([...ayas]));
                ayas.clear();
              }
            }
          } else {
            ayas.add(aya);
          }
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
      print('Error fetching data: $e');
    } finally {
      isLoading(false);
    }
    update();
  }

  List<AyahModel> search(String searchText) {
    if (searchText.isEmpty) {
      return [];
    } else {
      final filteredAyahs = ayahs
          .where((aya) => aya.ayahText.contains(searchText.trim()))
          .toList();
      return filteredAyahs;
    }
  }

  void saveLastPage(int lastPage) {
    this.lastPage = lastPage;
    _quranRepository.saveLastPage(lastPage);
  }

  void jumpToPage(int page) {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(page);
    } else {
      _pageController = PageController(initialPage: page);
    }
  }

  PageController get pageController => _pageController;

  void toggleAyahSelection(int index) {
    if (selectedAyahIndexes.contains(index)) {
      selectedAyahIndexes.remove(index);
      update();
    } else {
      selectedAyahIndexes.clear();
      selectedAyahIndexes.add(index);
      selectedAyahIndexes.refresh();
      update();
    }
    selectedAyahIndexes.refresh();
    update();
  }

  void clearSelection() {
    selectedAyahIndexes.clear();
    update();
  }

  dynamic textScale(dynamic widget1, dynamic widget2) {
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
    }
    state.scaleFactor.value = newScaleFactor;
    update();
  }
}
