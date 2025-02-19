part of '../../quran.dart';

/// A model class representing an Ayah (verse) in the Quran.
///
/// This class contains properties and methods related to an Ayah,
/// which is a single verse in the Quran. It is used to store and
/// manipulate data related to an Ayah.
class AyahModel {
  /// The unique number of the Ayah (verse) in the Quran.
  ///
  /// This number is used to uniquely identify each Ayah within the Quran.
  final int ayahUQNumber;

  /// The Juz (part) number of the Ayah (verse) in the Quran.
  ///
  /// This field represents which Juz the Ayah belongs to, ranging from 1 to 30.
  final int juz;

  /// The number of the Surah (chapter) in the Quran to which this Ayah (verse) belongs.
  final int surahNumber;

  /// The page number where the Ayah (verse) is located in the Quran.
  final int page;

  /// The starting line number of the Ayah in the Quran text.
  ///
  /// This represents the line number where the Ayah begins in the Quran.
  /// It is used to locate the exact position of the Ayah within the text.
  final int lineStart;

  /// The ending line number of the Ayah (verse) in the Quran.
  final int lineEnd;

  /// Represents the number of the Ayah (verse) in the Quran.
  ///
  /// This is a unique identifier for each Ayah within a Surah (chapter).
  ///
  /// Example:
  /// ```dart
  /// AyahModel.ayahNumber = 1; // Represents the first Ayah
  /// ```
  final int ayahNumber;

  /// Represents the quarter of the Ayah in the Quran.
  ///
  /// This value indicates the specific quarter within the Surah where the Ayah is located.
  final int quarter;

  /// Represents the Hizb number of the Ayah.
  ///
  /// A Hizb is one of the 60 equal parts into which the Quran is sometimes divided.
  /// This field stores the Hizb number to which the Ayah belongs.
  final int hizb;

  /// The English name of the Surah.
  final String englishName;

  /// The Arabic name of the Surah.
  final String arabicName;

  /// The text of the Ayah in Emlaey script.
  final String ayaTextEmlaey;

  /// The text of the Ayah (verse) from the Quran.
  String text;

  /// Indicates whether the Ayah (verse) contains a Sajda (prostration) mark.
  ///
  /// A Sajda mark signifies that a prostration is recommended or obligatory
  /// when reciting this Ayah.
  final bool sajda;

  /// Indicates whether the Ayah text should be centered.
  bool centered;

  /// Represents a model for an Ayah (verse) in the Quran.
  ///
  /// This model contains the properties and methods related to an Ayah.
  AyahModel({
    required this.ayahUQNumber,
    required this.juz,
    required this.surahNumber,
    required this.page,
    required this.lineStart,
    required this.lineEnd,
    required this.ayahNumber,
    required this.quarter,
    required this.hizb,
    required this.englishName,
    required this.arabicName,
    required this.text,
    required this.ayaTextEmlaey,
    required this.sajda,
    required this.centered,
  });

  Map<String, dynamic> _toJson() => {
        'id': ayahUQNumber,
        'jozz': juz,
        'sora': surahNumber,
        'page': page,
        'line_start': lineStart,
        'line_end': lineEnd,
        'aya_no': ayahNumber,
        'sora_name_en': englishName,
        'sora_name_ar': arabicName,
        'aya_text': text,
        'aya_text_emlaey': ayaTextEmlaey,
        'centered': centered,
      };

  @override
  String toString() =>
      "\"id\": $ayahUQNumber, \"jozz\": $juz,\"sora\": $surahNumber,\"page\": $page,\"line_start\": $lineStart,\"line_end\": $lineEnd,\"aya_no\": $ayahNumber,\"sora_name_en\": \"$englishName\",\"sora_name_ar\": \"$arabicName\",\"aya_text\": \"${text.replaceAll("\n", "\\n")}\",\"aya_text_emlaey\": \"${ayaTextEmlaey.replaceAll("\n", "\\n")}\",\"centered\": $centered";

  factory AyahModel._fromJson(Map<String, dynamic> json) {
    String ayahText = json['aya_text'];
    if (ayahText[ayahText.length - 1] == '\n') {
      ayahText = ayahText.insert(' ', ayahText.length - 1);
    } else {
      ayahText = '$ayahText ';
    }
    return AyahModel(
      ayahUQNumber: json['id'],
      juz: json['jozz'],
      surahNumber: json['sura_no'] ?? 0,
      page: json['page'],
      lineStart: json['line_start'],
      lineEnd: json['line_end'],
      ayahNumber: json['aya_no'],
      quarter: -1,
      hizb: -1,
      englishName: json['sura_name_en'],
      arabicName: json['sura_name_ar'],
      text: ayahText,
      ayaTextEmlaey: json['aya_text_emlaey'] ?? '',
      sajda: false,
      centered: json['centered'] ?? false,
    );
  }

  factory AyahModel._fromAya({
    required AyahModel ayah,
    required String aya,
    required String ayaText,
    bool centered = false,
  }) =>
      AyahModel(
        ayahUQNumber: ayah.ayahUQNumber,
        juz: ayah.juz,
        surahNumber: ayah.surahNumber,
        page: ayah.page,
        lineStart: ayah.lineStart,
        lineEnd: ayah.lineEnd,
        ayahNumber: ayah.ayahNumber,
        quarter: ayah.quarter,
        hizb: ayah.hizb,
        englishName: ayah.englishName,
        arabicName: ayah.arabicName,
        text: aya,
        ayaTextEmlaey: ayaText,
        sajda: false,
        centered: centered,
      );
}
