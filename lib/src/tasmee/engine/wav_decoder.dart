/// فكّ ترميز WAV إلى عيّنات PCM float32.
library;

import 'dart:typed_data';

/// نتيجة فكّ ترميز WAV.

/// نتيجة فكّ ترميز WAV.
class WavDecoded {
  WavDecoded({required this.samples, required this.sampleRate});

  /// العيّنات الخام بِـ float32 في [-1.0, 1.0].
  final Float64List samples;

  /// معدّل العيّنات (يُفترض 16000).
  final int sampleRate;

  /// عدد القنوات (يُفترض 1 = mono).
  int get channels => 1;
}

/// فكّ ترميز WAV (PCM 16-bit mono) إلى عيّنات float32.
///
/// تُعيد null إن لم يكن الملفّ WAV صالح PCM 16-bit.
WavDecoded? decodeWavBytes(final Uint8List bytes) {
  if (bytes.length < 44) return null;

  // تحقّق من RIFF header
  final header = String.fromCharCodes(bytes.sublist(0, 4));
  if (header != 'RIFF') return null;
  final wave = String.fromCharCodes(bytes.sublist(8, 12));
  if (wave != 'WAVE') return null;

  // ابحث عن chunk "fmt " و"data"
  int offset = 12;
  int sampleRate = 16000;
  int bitsPerSample = 16;
  Uint8List? dataBytes;

  while (offset + 8 <= bytes.length) {
    final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final chunkSize = bytes
        .sublist(offset + 4, offset + 8)
        .buffer
        .asByteData()
        .getInt32(0, Endian.little);

    if (chunkId == 'fmt ') {
      final fmtData = bytes.sublist(offset + 8, offset + 8 + chunkSize);
      if (fmtData.length >= 16) {
        sampleRate = fmtData.buffer.asByteData().getInt32(4, Endian.little);
        bitsPerSample = fmtData.buffer.asByteData().getInt16(14, Endian.little);
      }
    } else if (chunkId == 'data') {
      dataBytes = bytes.sublist(offset + 8, offset + 8 + chunkSize);
    }

    offset += 8 + chunkSize;
    // chunks مُحاذاة لِـ 2 بايت
    if (chunkSize.isOdd) offset += 1;
  }

  if (dataBytes == null) return null;
  if (bitsPerSample != 16) return null;

  // حوّل PCM 16-bit signed → float32
  final nSamples = dataBytes.length ~/ 2;
  final int16 = dataBytes.buffer.asInt16List();
  final floats = Float64List(nSamples);
  for (int i = 0; i < nSamples; i++) {
    floats[i] = int16[i] / 32768.0;
  }

  return WavDecoded(samples: floats, sampleRate: sampleRate);
}

/// يحوّل دفعة PCM ‏16-bit من الميكروفون إلى عيّنات [-1,1].
///
/// **محاذي لأي إزاحة**: دفعات `record` قد تصل كعروض (views) داخل ذاكرة
/// أكبر وبإزاحة غير زوجية أحيانًا (رُصد offset=5 على iOS) — التحويل
/// المباشر بـ`asInt16List(offset, len)` يرمي RangeError. ننسخ الدفعة
/// إلى ذاكرة محاذية جديدة (3200 بايت للدفعة — كلفة إهمالية).
Float32List pcm16ToFloats(final Uint8List chunk) {
  // نسخة محاذية: Uint8List.fromList يخصص ذاكرة جديدة من الإزاحة 0.
  final aligned = Uint8List.fromList(chunk);
  final int16 = aligned.buffer.asInt16List(0, aligned.length ~/ 2);
  final floats = Float32List(int16.length);
  for (var i = 0; i < int16.length; i++) {
    floats[i] = int16[i] / 32768.0;
  }
  return floats;
}
