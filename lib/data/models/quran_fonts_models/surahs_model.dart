part of '../../../quran.dart';

/// This class is used for downloaded fonts.
///
/// It represents the Surahs model which contains information about the Surahs
/// in the Quran.
class SurahFontsModel {
  /// The number of the Surah (chapter) in the Quran.
  ///
  /// This is an integer value representing the position of the Surah
  /// within the Quran, starting from 1 for Al-Fatiha to 114 for An-Nas.
  final int surahNumber;

  /// The Arabic name of the Surah.
  final String arabicName;

  /// The English name of the Surah.
  final String englishName;

  /// The type of revelation for the Surah (e.g., Meccan or Medinan).
  final String revelationType;

  /// A list of AyahFontsModel objects representing the ayahs (verses) in the surah.
  final List<AyahFontsModel> ayahs;

  /// Represents a model for downloaded fonts of a Surah in the Quran.
  SurahFontsModel(
      {required this.surahNumber,
      required this.arabicName,
      required this.englishName,
      required this.revelationType,
      required this.ayahs});

  factory SurahFontsModel._fromJson(Map<String, dynamic> json) {
    var ayahsFromJson = json['ayahs'] as List;
    List<AyahFontsModel> ayahsList =
        ayahsFromJson.map((i) => AyahFontsModel._fromJson(i)).toList();

    return SurahFontsModel(
      surahNumber: json['number'],
      arabicName: json['name'],
      englishName: json['englishName'],
      revelationType: json['revelationType'],
      ayahs: ayahsList,
    );
  }
}
