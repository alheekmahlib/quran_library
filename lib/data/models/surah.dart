part of '../../../quran.dart';

class Surah {
  final int index, startPage;
  int endPage;
  final String nameEn, nameAr;

  Surah({
    required this.index,
    required this.startPage,
    required this.endPage,
    required this.nameEn,
    required this.nameAr,
  });

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
        index: json['index'],
        startPage: json['start_page'],
        endPage: json['end_page'],
        nameEn: json['name_en'],
        nameAr: json['name_ar'],
      );

  Map<String, dynamic> toJson() => {
        "index": index,
        "start_page": startPage,
        "end_page": endPage,
        "name_en": nameEn,
        "name_ar": nameAr,
      };
}
