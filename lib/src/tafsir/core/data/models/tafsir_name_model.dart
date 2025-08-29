part of '../../../tafsir.dart';

enum TafsirFileType { json, sqlite }

class TafsirNameModel {
  final String name;
  final String bookName;
  final String
      databaseName; // for defaults this is filename, for custom this can be filename in app dir
  final bool isCustom;
  final TafsirFileType? type;
  final String? filePath; // absolute path for custom files

  TafsirNameModel({
    required this.name,
    required this.bookName,
    required this.databaseName,
    this.isCustom = false,
    this.type,
    this.filePath,
  });

  factory TafsirNameModel.fromJson(Map<String, dynamic> j) => TafsirNameModel(
        name: j['name'] as String,
        bookName: j['bookName'] as String,
        databaseName: j['databaseName'] as String,
        isCustom: j['isCustom'] == true,
        type: j['type'] == null
            ? null
            : (j['type'] == 'sqlite'
                ? TafsirFileType.sqlite
                : TafsirFileType.json),
        filePath: j['filePath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'bookName': bookName,
        'databaseName': databaseName,
        'isCustom': isCustom,
        'type': type == null
            ? null
            : (type == TafsirFileType.sqlite ? 'sqlite' : 'json'),
        'filePath': filePath,
      };
}
