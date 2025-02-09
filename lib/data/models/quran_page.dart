part of '../../../quran.dart';

class QuranPage {
  final int pageNumber;
  int numberOfNewSurahs;
  List<Line> lines;
  int? hizb;
  bool hasSajda, lastLine;

  QuranPage({
    required this.pageNumber,
    required this.lines,
    this.hizb,
    this.hasSajda = false,
    this.lastLine = false,
    this.numberOfNewSurahs = 0,
  });
}

class Line {
  bool centered;

  Line({this.centered = false});
}
