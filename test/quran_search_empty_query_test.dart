import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/quran_library.dart';

/// بحث المكتبة: الاستعلام الفارغ أو المكوّن من مسافات يجب أن يُعيد قائمة
/// فارغة. قبل الإصلاح كانت المسافات تُقصّ إلى '' فتصدق `contains('')` على
/// كل آية وكل سورة، فيُعاد القرآن كاملًا.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranCtrl ctrl;

  setUp(() {
    ctrl = QuranCtrl();
    ctrl.state.allAyahs = [
      AyahModel(
        ayahUQNumber: 1,
        ayahNumber: 1,
        text: 'بِسْمِ اللَّهِ',
        ayaTextEmlaey: 'بسم الله الرحمن الرحيم',
        juz: 1,
        page: 1,
        surahNumber: 1,
        arabicName: 'الفاتحة',
        englishName: 'Al-Fatihah',
      ),
    ];
    ctrl.surahs = [
      SurahModel(
        surahNumber: 1,
        arabicName: 'الفاتحة',
        englishName: 'Al-Fatihah',
        ayahs: const [],
      ),
    ];
  });

  test('search returns nothing for empty or whitespace-only queries', () {
    expect(ctrl.search(''), isEmpty);
    expect(ctrl.search('   '), isEmpty);
  });

  test('search still finds a real word', () {
    expect(ctrl.search('الرحمن'), hasLength(1));
  });

  test('searchSurah returns nothing for empty or whitespace-only queries', () {
    expect(ctrl.searchSurah(''), isEmpty);
    expect(ctrl.searchSurah('   '), isEmpty);
  });

  test('searchSurah still finds a surah by name', () {
    expect(ctrl.searchSurah('الفاتحة'), hasLength(1));
  });
}
