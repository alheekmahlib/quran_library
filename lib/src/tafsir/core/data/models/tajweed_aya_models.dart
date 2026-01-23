part of '../../../tafsir.dart';

class TajweedAyahInfo {
  final int ayaNumber;
  final String content;

  const TajweedAyahInfo({
    required this.ayaNumber,
    required this.content,
  });

  factory TajweedAyahInfo.fromJson(Map<String, dynamic> jsonMap) {
    return TajweedAyahInfo(
      ayaNumber: (jsonMap['aya_number'] as num?)?.toInt() ??
          int.tryParse(jsonMap['aya_number']?.toString() ?? '') ??
          0,
      content: (jsonMap['content'] ?? '').toString(),
    );
  }
}

class TajweedSurahAyahs {
  final int surahNumber;
  final Map<int, TajweedAyahInfo> ayahsByNumber;

  const TajweedSurahAyahs({
    required this.surahNumber,
    required this.ayahsByNumber,
  });

  factory TajweedSurahAyahs.fromJson({
    required int surahNumber,
    required List<dynamic> jsonList,
  }) {
    final map = <int, TajweedAyahInfo>{};
    for (final item in jsonList) {
      if (item is! Map) continue;
      final info = TajweedAyahInfo.fromJson(item.cast<String, dynamic>());
      if (info.ayaNumber != 0) {
        map[info.ayaNumber] = info;
      }
    }

    return TajweedSurahAyahs(
      surahNumber: surahNumber,
      ayahsByNumber: map,
    );
  }

  TajweedAyahInfo? lookup({required int ayahNumber}) =>
      ayahsByNumber[ayahNumber];
}
