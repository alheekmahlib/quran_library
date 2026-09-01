import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/wav_decoder.dart';

void main() {
  test('دفعة محاذية عادية تُحوَّل صحيحة', () {
    final bytes = Uint8List.fromList([0x00, 0x40, 0x00, 0x80]); // 16384, -32768
    final f = pcm16ToFloats(bytes);
    expect(f.length, 2);
    expect(f[0], closeTo(0.5, 1e-6));
    expect(f[1], closeTo(-1.0, 1e-6));
  });

  test('عرض داخل ذاكرة أكبر لا يسرب بايتات مجاورة', () {
    // ذاكرة 100 بايت، العرض من 10 بطول 4.
    final big = Uint8List(100);
    big[10] = 0x00;
    big[11] = 0x40;
    big[12] = 0x00;
    big[13] = 0xC0; // -16384
    final view = Uint8List.sublistView(big, 10, 14);
    final f = pcm16ToFloats(view);
    expect(f.length, 2);
    expect(f[0], closeTo(0.5, 1e-6));
    expect(f[1], closeTo(-0.5, 1e-6));
  });

  test('عرض بإزاحة فردية (رُصد offset=5 على iOS) لا يرمي RangeError', () {
    final big = Uint8List(64);
    // ضع PCM صحيح عند الإزاحة 5 داخل الذاكرة الكبيرة.
    big[5] = 0x00;
    big[6] = 0x40;
    big[7] = 0x00;
    big[8] = 0x80;
    final view = Uint8List.sublistView(big, 5, 9);
    final f = pcm16ToFloats(view);
    expect(f.length, 2);
    expect(f[0], closeTo(0.5, 1e-6));
    expect(f[1], closeTo(-1.0, 1e-6));
  });

  test('طول فردي يُسقط البايت الزائد', () {
    final bytes = Uint8List.fromList([0x00, 0x40, 0xFF]);
    expect(pcm16ToFloats(bytes).length, 1);
  });

  test('دفعة فارغة', () {
    expect(pcm16ToFloats(Uint8List(0)).length, 0);
  });
}
