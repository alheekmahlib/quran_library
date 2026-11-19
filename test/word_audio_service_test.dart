import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/quran.dart' as q;

void main() {
  test('playWord reports failure explicitly when playback cannot start',
      () async {
    // خدمة غير مهيّأة: العقد نتيجة صريحة لا استثناء ولا فشل صامت —
    // الشيت (والمضيف) يبني إبلاغ المستخدم على هذه القيمة.
    expect(q.WordAudioService.instance.isInitialized, isFalse);
    final started = await q.WordAudioService.instance.playWord(
      const q.WordRef(surahNumber: 1, ayahNumber: 1, wordNumber: 1),
    );
    expect(started, isFalse);
  });
}
