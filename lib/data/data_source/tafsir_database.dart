part of '../../quran.dart';

// part 'tafsir_database.g.dart';

@drift.DriftDatabase(tables: [TafsirTable])
class TafsirDatabase extends _$TafsirDatabase {
  TafsirDatabase(String dbFileName) : super(_openConnection(dbFileName));

  @override
  int get schemaVersion => 1;

  Future<List<TafsirTableData>> getTafsirByPage(int pageNum,
      {String? databaseName}) async {
    final results = await customSelect(
      'SELECT * FROM ${databaseName ?? 'tafsir'} WHERE PageNum = ?',
      variables: [drift.Variable.withInt(pageNum)],
    ).get();

    return results.map((row) {
      return TafsirTableData(
        id: row.read<int>('index'),
        surahNum: row.read<int>('sura'),
        ayahNum: row.read<int>('aya'),
        tafsirText: row.read<String>('text'),
        pageNum: row.read<int>('PageNum'),
      );
    }).toList();
  }

  Future<List<TafsirTableData>> getTafsirByAyah(int ayahUQNumber,
      {String? databaseName}) async {
    final results = await customSelect(
      'SELECT * FROM ${databaseName ?? 'tafsir'} WHERE "index" = ?',
      variables: [drift.Variable.withInt(ayahUQNumber)],
    ).get();

    return results.map((row) {
      return TafsirTableData(
        id: row.read<int>('index'),
        surahNum: row.read<int>('sura'),
        ayahNum: row.read<int>('aya'),
        tafsirText: row.read<String>('text'),
        pageNum: row.read<int>('PageNum'),
      );
    }).toList();
  }
}

drift.LazyDatabase _openConnection(String dbFileName) {
  log('Starting _openConnection for database: $dbFileName');
  return drift.LazyDatabase(() async {
    log('Inside LazyDatabase for: $dbFileName');
    final dbFolder = await getApplicationDocumentsDirectory();
    log('Application documents directory: ${dbFolder.path}');

    final file = File(join(dbFolder.path, dbFileName));

    if (!await file.exists()) {
      log('Database file does not exist, copying from assets');
      try {
        ByteData data = TafsirCtrl.instance.radioValue.value == 3
            ? await rootBundle.load('packages/quran_library/assets/$dbFileName')
            : await rootBundle.load(join(dbFolder.path, dbFileName));
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await file.writeAsBytes(bytes, flush: true);
        log('Tafsir Database copied to ${file.path}');
      } catch (e) {
        log('Error copying database: $e');
        throw Exception('Failed to copy database from assets.');
      }
    } else {
      log('Database file already exists at ${file.path}');
    }

    return NativeDatabase(file);
  });
}
