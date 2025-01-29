part of '../../quran.dart';

class AyahModel {
  final int ayahUQNumber,
      juz,
      surahNumber,
      page,
      lineStart,
      lineEnd,
      ayahNumber,
      quarter,
      hizb;
  final String englishName, arabicName, ayaTextEmlaey;
  String text;
  final bool sajda;
  bool centered;

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

  Map<String, dynamic> toJson() => {
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

  factory AyahModel.fromJson(Map<String, dynamic> json) {
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

  factory AyahModel.fromAya({
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
