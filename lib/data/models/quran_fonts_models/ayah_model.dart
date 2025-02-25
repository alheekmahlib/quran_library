part of '../../../quran.dart';

/// A model class representing an Ayah (verse) for downloaded fonts in the Quran library.
/// This class is used to store and manage data related to a specific Ayah when using quran fonts.
class AyahFontsModel {
  /// The unique number assigned to the Ayah in the Quran text.
  ///
  /// This number is used to identify the Ayah within the Quran.
  ///
  /// Example: 1 for the first Ayah of the Quran.
  final int ayahUQNumber;

  /// The number of the Ayah (verse) in the Quran.
  ///
  /// This is a unique identifier for each Ayah within a Surah (chapter).
  final int ayahNumber;

  /// The text of the Ayah (verse) in the Quran.
  final String text;

  /// Custom text color for the Ayah.
  Color? singleAyahTextColor;

  /// The text of the Ayah in Emlaey script.
  final String ayaTextEmlaey;

  /// The code for the Ayah in version 2 format.
  final String codeV2;

  /// The Juz (part) number in which the Ayah (verse) is located.
  final int juz;

  /// Represents the page number of the Ayah in the Quran.
  ///
  /// This field holds the integer value of the page where the Ayah is located.
  final int page;

  /// Represents the Hizb number of the Ayah.
  ///
  /// A Hizb is a part of the Quran, and there are 60 Hizbs in total.
  /// This field indicates which Hizb the Ayah belongs to.
  final int hizb;

  /// Represents the sajda (prostration) information for an Ayah (verse).
  /// This can be of any type, hence the use of `dynamic`.
  dynamic sajda;

  /// A model class representing an Ayah (verse) for downloaded fonts.
  ///
  /// This class is used to store and manage data related to an Ayah,
  /// specifically for the purpose of handling downloaded fonts.
  ///
  /// Example usage:
  /// ```dart
  /// AyahFontsModel ayah = AyahFontsModel(
  ///   // initialization parameters
  /// );
  /// ```
  AyahFontsModel({
    required this.ayahUQNumber,
    required this.ayahNumber,
    required this.text,
    required this.singleAyahTextColor,
    required this.ayaTextEmlaey,
    required this.codeV2,
    required this.juz,
    required this.page,
    required this.hizb,
    required this.sajda,
  });

  factory AyahFontsModel._fromJson(Map<String, dynamic> json) {
    return AyahFontsModel(
      ayahUQNumber: json['number'],
      ayahNumber: json['numberInSurah'],
      text: json['text'],
      singleAyahTextColor: json['singleAyahTextColor'],
      ayaTextEmlaey: json['aya_text_emlaey'],
      codeV2: json['code_v2'],
      juz: json['juz'],
      page: json['page'],
      hizb: json['hizbQuarter'],
      sajda: json['sajda'],
    );
  }

  factory AyahFontsModel._empty() {
    return AyahFontsModel(
      ayahUQNumber: 0,
      ayahNumber: 0,
      text: '',
      singleAyahTextColor: null,
      ayaTextEmlaey: '',
      codeV2: '',
      juz: 0,
      page: 0,
      hizb: 0,
      sajda: dynamic,
    );
  }
}
