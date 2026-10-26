import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/quran.dart';

/// آيات الصفحة بلا ازدواج وبترتيب مصحفي — الانحدار: سباق تحميل مزدوج
/// كان يضاعف قائمة الآيات فتتكرر آيات الصفحة، ونطاق التسميع يبني من
/// القائمة فيتوقف التتبّع عند توقّع الآية نفسها مرتين (علّق آية
/// «الحمد» بعد البسملة في صفحة الفاتحة وفتح شيت مصحّح زائفًا).
AyahModel _ayah(int uq, int numberInSurah, int surah, int page) => AyahModel(
      ayahUQNumber: uq,
      ayahNumber: numberInSurah,
      text: 'آية $uq',
      ayaTextEmlaey: '',
      juz: 1,
      page: page,
      surahNumber: surah,
    );

void main() {
  test('نسخ مكررة متتالية تُسقط — صفحة الفاتحة 7 آيات لا 14', () {
    // سيناريو الانحدار بالضبط: القائمة المضاعفة لصفحة الفاتحة.
    final doubled = <AyahModel>[
      for (var n = 1; n <= 7; n++) ...[
        _ayah(n, n, 1, 1),
        _ayah(n, n, 1, 1),
      ],
    ];
    final out = QuranCtrl.sortedUniquePageAyahs(doubled);
    expect(out.length, 7);
    expect(out.map((a) => a.ayahUQNumber), [1, 2, 3, 4, 5, 6, 7]);
  });

  test('صفحة تضم سورتين: الترتيب بالرقم الموحد لا برقم السورة', () {
    // آخر آيتين من سورة (مثال 100) ثم أول آيتين من التالية — فرز
    // ayahNumber القديم كان يتشابك عند تصفير الرقم عند حدود السور.
    final mixed = <AyahModel>[
      _ayah(6236, 2, 114, 604),
      _ayah(6235, 1, 114, 604),
      _ayah(6233, 5, 113, 604),
      _ayah(6234, 6, 113, 604),
    ];
    final out = QuranCtrl.sortedUniquePageAyahs(mixed);
    expect(out.map((a) => a.ayahUQNumber), [6233, 6234, 6235, 6236]);
  });

  test('قائمة سليمة بلا تكرار تبقى كما هي', () {
    final clean = [
      _ayah(1, 1, 1, 1),
      _ayah(2, 2, 1, 1),
      _ayah(3, 3, 1, 1),
    ];
    expect(
      QuranCtrl.sortedUniquePageAyahs(clean).map((a) => a.ayahUQNumber),
      [1, 2, 3],
    );
    expect(QuranCtrl.sortedUniquePageAyahs([]), isEmpty);
  });
}
