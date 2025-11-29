part of '/quran.dart';

/// نموذج يُمثل سطرًا واحدًا من تخطيط المصحف في ملف quran_info.json
/// يحوي معلومات عن نطاق الكلمات، نوع السطر، رقم الصفحة/السورة، وتموضعه (مُتمركز أم لا)
class QuranInfoLine {
  final int? firstWordId;
  final int? lastWordId;
  final bool isCentered;
  final int lineNumber;
  final String lineType; // ayah | basmallah | surah_name | ...
  final int pageNumber;
  final int? surahNumber;

  QuranInfoLine({
    required this.firstWordId,
    required this.lastWordId,
    required this.isCentered,
    required this.lineNumber,
    required this.lineType,
    required this.pageNumber,
    required this.surahNumber,
  });

  factory QuranInfoLine.fromJson(Map<String, dynamic> json) {
    int? toIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) {
        final s = v.trim();
        if (s.isEmpty) return null;
        return int.tryParse(s);
      }
      return null;
    }

    bool toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.trim();
        if (s.isEmpty) return false;
        return s == '1' || s.toLowerCase() == 'true';
      }
      return false;
    }

    return QuranInfoLine(
      firstWordId: toIntOrNull(json['first_word_id']),
      lastWordId: toIntOrNull(json['last_word_id']),
      isCentered: toBool(json['is_centered']),
      lineNumber: toIntOrNull(json['line_number']) ?? 0,
      lineType: (json['line_type'] ?? '').toString(),
      pageNumber: toIntOrNull(json['page_number']) ?? 0,
      surahNumber: toIntOrNull(json['surah_number']),
    );
  }

  Map<String, dynamic> toJson() => {
        'first_word_id': firstWordId,
        'last_word_id': lastWordId,
        'is_centered': isCentered ? 1 : 0,
        'line_number': lineNumber,
        'line_type': lineType,
        'page_number': pageNumber,
        'surah_number': surahNumber,
      };
}
