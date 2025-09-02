part of '../../../tafsir.dart';

final List<TafsirNameModel> _defaultTafsirTranslationsList = [
  TafsirNameModel(
    name: 'English',
    bookName: 'en',
    databaseName: 'en.json',
    isTranslation: true,
  ),
  TafsirNameModel(
    name: 'Español',
    bookName: 'es',
    databaseName: 'es.json',
    isTranslation: true,
  ),
  TafsirNameModel(
    name: 'বাংলা',
    bookName: 'be',
    databaseName: 'be.json',
    isTranslation: true,
  ),
  TafsirNameModel(
    name: 'اردو',
    bookName: 'urdu',
    databaseName: 'urdu.json',
    isTranslation: true,
  ),
  TafsirNameModel(
    name: 'Soomaali',
    bookName: 'so',
    databaseName: 'so.json',
    isTranslation: true,
  ),
  TafsirNameModel(
    name: 'bahasa Indonesia',
    bookName: 'in',
    databaseName: 'in.json',
    isTranslation: true,
  ),
  TafsirNameModel(
    name: 'کوردی',
    bookName: 'ku',
    databaseName: 'ku.json',
    isTranslation: true,
  ),
  TafsirNameModel(
    name: 'Türkçe',
    bookName: 'tr',
    databaseName: 'tr.json',
    isTranslation: true,
  ),
];
List<TafsirNameModel> get _defaultTafsirList =>
    [..._defaultTafsirItemsList, ..._defaultTafsirTranslationsList];
final List<TafsirNameModel> _defaultTafsirItemsList = [
  TafsirNameModel(
    name: 'تفسير ابن كثير',
    bookName: 'تفسير القرآن العظيم',
    databaseName: 'ibnkatheerV3.sqlite',
    type: TafsirFileType.sqlite,
  ),
  TafsirNameModel(
    name: 'تفسير البغوي',
    bookName: 'معالم التنزيل في تفسير القرآن',
    databaseName: 'baghawyV3.db',
    type: TafsirFileType.sqlite,
  ),
  TafsirNameModel(
    name: 'تفسير القرطبي',
    bookName: 'الجامع لأحكام القرآن',
    databaseName: 'qurtubiV3.db',
    type: TafsirFileType.sqlite,
  ),
  TafsirNameModel(
    name: 'تفسير السعدي',
    bookName: 'تيسير الكريم الرحمن',
    databaseName: 'saadiV4.db',
    type: TafsirFileType.sqlite,
  ),
  TafsirNameModel(
    name: 'تفسير الطبري',
    bookName: 'جامع البيان عن تأويل آي القرآن',
    databaseName: 'tabariV3.db',
    type: TafsirFileType.sqlite,
  ),
];
