import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/error_detector.dart';
import 'package:quran_library/src/tasmee/engine/models/recitation_result.dart';
import 'package:quran_library/src/tasmee/engine/phoneme_aligner.dart';
import 'package:quran_library/src/tasmee/engine/quran_reference.dart';
import 'package:quran_library/src/tasmee/engine/quran_units.dart';

void main() {
  late QuranUnitLexicon lex;
  late QuranPhonemeReference refDb;
  late QuranReferenceVerse fatiha1;

  setUpAll(() async {
    lex = QuranUnitLexicon.fromTokensText(
        File('test/fixtures/tokens.txt').readAsStringSync());
    refDb = QuranPhonemeReference(lexicon: lex);
    await refDb.load(filePath: 'test/fixtures/quran_phonemes_sample.json.gz');
    fatiha1 = refDb.getReference(suraIdx: 1, ayaIdx: 1)!;
  });

  List<RecitationError> detect(List<String> predSymbols) {
    final pred = predSymbols.map((s) => lex.bySymbol[s]!).toList();
    final ops = alignUnits(fatiha1.units, pred);
    return buildErrorsFromUnitAlignment(
        ops: ops,
        refUnits: fatiha1.units,
        predUnits: pred,
        wordAt: fatiha1.wordAt);
  }

  test('تلاوة مطابقة تمامًا → صفر أخطاء', () {
    final pred = fatiha1.units.map((u) => u.symbol).toList();
    expect(detect(pred), isEmpty);
  });

  test('تشكيل مختلف (بِ نُطقت بُ) → خطأ tashkeel', () {
    final pred = fatiha1.units.map((u) => u.symbol).toList();
    pred[0] = 'بُ';
    final errors = detect(pred);
    expect(errors, isNotEmpty);
    final e = errors.first;
    expect(e.errorType, 'tashkeel');
    expect(e.wordText, isNotNull);
  });

  test('مدّ golden=2 صارم: اا→اااااا → tajweed بطولين', () {
    final pred = fatiha1.units.map((u) => u.symbol).toList();
    final idx = pred.indexWhere((s) => s == 'اا'); // مدّ «للَااهِ»
    expect(idx, greaterThan(0), reason: 'يجب أن تحتوي 1:1 مدّ ألف 2');
    pred[idx] = 'اااااا';
    final errors = detect(pred);
    final madd = errors.where((e) => e.errorType == 'tajweed').toList();
    expect(madd, isNotEmpty);
    expect(madd.first.expectedLen, 2);
    expect(madd.first.predictedLen, 6);
    expect(madd.first.refTajweedRules.first.nameAr, 'المدّ');
  });

  test('مدّ golden>=4 متسامح رمزيًا: تقصير 4→2 لا يُبلَّغ (الحكم للزمن)', () {
    final pred = fatiha1.units.map((u) => u.symbol).toList();
    final idx = pred.indexWhere((s) => s == 'ۦۦۦۦ');
    expect(idx, greaterThan(0), reason: 'يجب أن تحتوي 1:1 مدّ ياء 4');
    pred[idx] = 'ۦۦ';
    final errors = detect(pred)
        .where((e) => e.errorType == 'tajweed' && e.expectedLen != null)
        .toList();
    expect(errors, isEmpty);
  });

  test('مدّ (golden>=4) يقبل 2..golden+2 رمزيًا', () {
    final pred = fatiha1.units.map((u) => u.symbol).toList();
    final idx = pred.indexWhere((s) => s == 'ۦۦۦۦ');
    pred[idx] = 'ۦۦۦۦۦۦ'; // أطول باثنتين — ضمن النطاق
    final errors = detect(pred)
        .where((e) => e.errorType == 'tajweed' && e.expectedLen != null)
        .toList();
    expect(errors, isEmpty);
  });

  test('إقحام سكوت/حركة مفردة → يُتجاهل', () {
    final pred = fatiha1.units.map((u) => u.symbol).toList();
    pred.insert(1, 'ؙ');
    pred.insert(3, 'َ');
    expect(detect(pred), isEmpty);
  });

  test('حذف أول وحدة قصيرة (تسامح المجموعة الأولى) → يُتجاهل', () {
    final pred = fatiha1.units.map((u) => u.symbol).toList();
    pred.removeAt(0); // بِ
    expect(detect(pred), isEmpty);
  });

  test('فقد شدة (ررَ→رَ) → tajweed/replace بقاعدة الشدة', () {
    final pred = fatiha1.units.map((u) => u.symbol).toList();
    final idx = pred.indexWhere((s) => s.startsWith('رر'));
    expect(idx, greaterThan(0));
    pred[idx] = 'رَ';
    final errors = detect(pred);
    expect(errors.first.errorType, 'tajweed');
    expect(errors.first.speechErrorType, 'replace');
    expect(errors.first.refTajweedRules.first.nameAr, 'الشدة');
  });

  test('حذف وحدة قواعدية → tajweed/delete', () {
    final pred = fatiha1.units.map((u) => u.symbol).toList();
    pred.removeWhere((s) => s.startsWith('رر'));
    final errors = detect(pred);
    final del = errors.where((e) => e.speechErrorType == 'delete').toList();
    expect(del, isNotEmpty);
    expect(del.first.errorType, 'tajweed');
  });

  test('حرف زائد حقيقي → normal/insert', () {
    final pred = fatiha1.units.map((u) => u.symbol).toList();
    pred.insert(1, 'ق');
    final errors = detect(pred);
    expect(errors.first.errorType, 'normal');
    expect(errors.first.speechErrorType, 'insert');
  });

  test('استبدال حرف مختلف → normal/replace + wordText', () {
    final pred = fatiha1.units.map((u) => u.symbol).toList();
    pred[0] = 'تِ'; // بِ → تِ
    final errors = detect(pred);
    expect(errors.first.errorType, 'normal');
    expect(errors.first.speechErrorType, 'replace');
    expect(errors.first.wordText, isNotNull);
  });
}
