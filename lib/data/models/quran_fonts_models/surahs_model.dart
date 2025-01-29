part of '../../../quran.dart';

class SurahFontsModel {
  final int surahNumber;
  final String arabicName;
  final String englishName;
  final String revelationType;
  final List<AyahFontsModel> ayahs;

  SurahFontsModel(
      {required this.surahNumber,
      required this.arabicName,
      required this.englishName,
      required this.revelationType,
      required this.ayahs});

  factory SurahFontsModel.fromJson(Map<String, dynamic> json) {
    var ayahsFromJson = json['ayahs'] as List;
    List<AyahFontsModel> ayahsList =
        ayahsFromJson.map((i) => AyahFontsModel.fromJson(i)).toList();

    return SurahFontsModel(
      surahNumber: json['number'],
      arabicName: json['name'],
      englishName: json['englishName'],
      revelationType: json['revelationType'],
      ayahs: ayahsList,
    );
  }
}

class AyahFontsModel {
  final int ayahUQNumber;
  final int ayahNumber;
  final String text;
  final String ayaTextEmlaey;
  final String codeV2;
  final int juz;
  final int page;
  final int hizb;
  dynamic sajda;

  AyahFontsModel({
    required this.ayahUQNumber,
    required this.ayahNumber,
    required this.text,
    required this.ayaTextEmlaey,
    required this.codeV2,
    required this.juz,
    required this.page,
    required this.hizb,
    required this.sajda,
  });

  factory AyahFontsModel.fromJson(Map<String, dynamic> json) {
    return AyahFontsModel(
      ayahUQNumber: json['number'],
      ayahNumber: json['numberInSurah'],
      text: json['text'],
      ayaTextEmlaey: json['aya_text_emlaey'],
      codeV2: json['code_v2'],
      juz: json['juz'],
      page: json['page'],
      hizb: json['hizbQuarter'],
      sajda: json['sajda'],
    );
  }

  factory AyahFontsModel.empty() {
    return AyahFontsModel(
      ayahUQNumber: 0,
      ayahNumber: 0,
      text: '',
      ayaTextEmlaey: '',
      codeV2: '',
      juz: 0,
      page: 0,
      hizb: 0,
      sajda: dynamic,
    );
  }
}

class SajdaFontsModel {
  final int id;
  final bool recommended;
  final bool obligatory;

  SajdaFontsModel(
      {required this.id, required this.recommended, required this.obligatory});

  factory SajdaFontsModel.fromJson(Map<String, dynamic> json) {
    return SajdaFontsModel(
      id: json['id'],
      recommended: json['recommended'],
      obligatory: json['obligatory'] ??
          false, // Assuming obligatory might not always be present
    );
  }
}
