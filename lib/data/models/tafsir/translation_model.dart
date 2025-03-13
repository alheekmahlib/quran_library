part of '../../../quran.dart';

class TranslationModel {
  final int resourceId;
  final String text;

  TranslationModel({required this.resourceId, required this.text});

  factory TranslationModel.fromJson(Map<String, dynamic> json) {
    return TranslationModel(
      resourceId: json['resource_id'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resource_id': resourceId,
      'text': text,
    };
  }
}

class TranslationsModel {
  final List<TranslationModel> translations;

  TranslationsModel({required this.translations});

  factory TranslationsModel.fromJson(String str) {
    final jsonData = json.decode(str);
    final translations = List<TranslationModel>.from(
      jsonData['translations'].map((x) => TranslationModel.fromJson(x)),
    );
    return TranslationsModel(translations: translations);
  }

  String toJson() {
    final jsonData = {
      'translations': translations.map((x) => x.toJson()).toList(),
    };
    return json.encode(jsonData);
  }
}
