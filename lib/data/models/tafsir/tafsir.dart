import 'package:drift/drift.dart';

// enum MufaserName {
//   ibnkatheer,
//   baghawy,
//   qurtubi,
//   saadi,
//   tabari,
// }

// enum MufaserNameV2 {
//   ibnkatheerV2,
//   baghawyV2,
//   qurtubiV2,
//   saadi,
//   tabariV2,
// }

// List<String> tafsirDBName = [
//   'ibnkatheerV3.sqlite',
//   'baghawyV3.db',
//   'qurtubiV3.db',
//   'saadiV4.db',
//   'tabariV3.db',
// ];

class TafsirTable extends Table {
  IntColumn get id => integer().named('index').autoIncrement()();
  IntColumn get surahNum => integer().named('sura')();
  IntColumn get ayahNum => integer().named('aya')();
  TextColumn get tafsirText => text().named('Text')();
  IntColumn get pageNum => integer().named('PageNum')();
}
