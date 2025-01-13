import '/src/utils/string_extensions.dart';

class AyahModel {
  final int id,
      jozz,
      surahNumber,
      page,
      lineStart,
      lineEnd,
      ayahNumber,
      quarter,
      hizb;
  final String surahNameEn, surahNameAr, ayahText;
  String ayah;
  final bool sajda;
  bool centered;

  AyahModel({
    required this.id,
    required this.jozz,
    required this.surahNumber,
    required this.page,
    required this.lineStart,
    required this.lineEnd,
    required this.ayahNumber,
    required this.quarter,
    required this.hizb,
    required this.surahNameEn,
    required this.surahNameAr,
    required this.ayah,
    required this.ayahText,
    required this.sajda,
    required this.centered,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'jozz': jozz,
        'sora': surahNumber,
        'page': page,
        'line_start': lineStart,
        'line_end': lineEnd,
        'aya_no': ayahNumber,
        'sora_name_en': surahNameEn,
        'sora_name_ar': surahNameAr,
        'aya_text': ayah,
        'aya_text_emlaey': ayahText,
        'centered': centered,
      };

  @override
  String toString() =>
      "\"id\": $id, \"jozz\": $jozz,\"sora\": $surahNumber,\"page\": $page,\"line_start\": $lineStart,\"line_end\": $lineEnd,\"aya_no\": $ayahNumber,\"sora_name_en\": \"$surahNameEn\",\"sora_name_ar\": \"$surahNameAr\",\"aya_text\": \"${ayah.replaceAll("\n", "\\n")}\",\"aya_text_emlaey\": \"${ayahText.replaceAll("\n", "\\n")}\",\"centered\": $centered";

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    String ayahText = json['aya_text'];
    if (ayahText[ayahText.length - 1] == '\n') {
      ayahText = ayahText.insert(' ', ayahText.length - 1);
    } else {
      ayahText = '$ayahText ';
    }
    return AyahModel(
      id: json['id'],
      jozz: json['jozz'],
      surahNumber: json['sura_no'] ?? 0,
      page: json['page'],
      lineStart: json['line_start'],
      lineEnd: json['line_end'],
      ayahNumber: json['aya_no'],
      quarter: -1,
      hizb: -1,
      surahNameEn: json['sura_name_en'],
      surahNameAr: json['sura_name_ar'],
      ayah: ayahText,
      ayahText: json['aya_text_emlaey'] ?? '',
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
        id: ayah.id,
        jozz: ayah.jozz,
        surahNumber: ayah.surahNumber,
        page: ayah.page,
        lineStart: ayah.lineStart,
        lineEnd: ayah.lineEnd,
        ayahNumber: ayah.ayahNumber,
        quarter: ayah.quarter,
        hizb: ayah.hizb,
        surahNameEn: ayah.surahNameEn,
        surahNameAr: ayah.surahNameAr,
        ayah: aya,
        ayahText: ayaText,
        sajda: false,
        centered: centered,
      );
}
