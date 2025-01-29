part of '../../../quran.dart';

class QuranPage {
  final int pageNumber;
  int numberOfNewSurahs;
  List<AyahModel> ayahs;
  List<Line> lines;
  int? hizb;
  bool hasSajda, lastLine;

  QuranPage({
    required this.pageNumber,
    required this.ayahs,
    required this.lines,
    this.hizb,
    this.hasSajda = false,
    this.lastLine = false,
    this.numberOfNewSurahs = 0,
  });
}

class Line {
  List<AyahModel> ayahs;
  bool centered;

  Line(this.ayahs, {this.centered = false});
}
