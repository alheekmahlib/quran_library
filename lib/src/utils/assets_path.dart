part of '../flutter_quran_screen.dart';

class AssetsPath {
  final surahSvgBanner =
      'packages/quran_library/lib/assets/svg/surah_banner.svg';
  final besmAllah2 = 'packages/quran_library/lib/assets/svg/besmAllah2.svg';
  final besmAllah = 'packages/quran_library/lib/assets/svg/besmAllah.svg';
  final ayahBookmarked =
      'packages/quran_library/lib/assets/svg/ayah_bookmarked.svg';

  ///Singleton factory
  static final AssetsPath _instance = AssetsPath._internal();

  factory AssetsPath() {
    return _instance;
  }

  AssetsPath._internal();
}
