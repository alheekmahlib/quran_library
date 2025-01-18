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
  final String aya_text_emlaey;
  final String code_v2;
  final int juz;
  final int page;
  final int hizbQuarter;
  dynamic sajda;

  AyahFontsModel({
    required this.ayahUQNumber,
    required this.ayahNumber,
    required this.text,
    required this.aya_text_emlaey,
    required this.code_v2,
    required this.juz,
    required this.page,
    required this.hizbQuarter,
    required this.sajda,
  });

  factory AyahFontsModel.fromJson(Map<String, dynamic> json) {
    return AyahFontsModel(
      ayahUQNumber: json['number'],
      ayahNumber: json['numberInSurah'],
      text: json['text'],
      aya_text_emlaey: json['aya_text_emlaey'],
      code_v2: json['code_v2'],
      juz: json['juz'],
      page: json['page'],
      hizbQuarter: json['hizbQuarter'],
      sajda: json['sajda'],
    );
  }

  factory AyahFontsModel.empty() {
    return AyahFontsModel(
      ayahUQNumber: 0,
      ayahNumber: 0,
      text: '',
      aya_text_emlaey: '',
      code_v2: '',
      juz: 0,
      page: 0,
      hizbQuarter: 0,
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
