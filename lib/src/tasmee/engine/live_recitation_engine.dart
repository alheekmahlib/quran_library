/// واجهة اختيارية لِلمحرّكات التي تدعم البثّ الحي أثناء التسجيل.
///
/// الجلسة تفحص `is LiveCapableRecitationEngine` — المحرّك الأونلاين
/// (MuaalemClient) لا يطبّقها فَيُخفى الوضع الحي.
library;

import 'dart:typed_data';

import 'models/muaalem_config.dart';
import 'models/recitation_result.dart';
import 'quran_reference.dart';
import 'tasmee_error_kind.dart';
import 'recitation_engine.dart';

/// لقطة تنبؤ حيّة (وحدات + طوابع بدايتها بالثوان).
class LiveRecognitionFrame {
  const LiveRecognitionFrame({required this.units, required this.timestamps});

  final List<String> units;
  final List<double> timestamps;
}

/// محرّك يدعم التغذية الحيّة بِـ PCM ‏(16kHz mono).
abstract interface class LiveCapableRecitationEngine
    implements RecitationEngine {
  /// يبدأ جلسة بثّ جديدة. [onPartial] يُستدعى بعد كل تغذية بِـ آخر تنبؤ،
  /// و[onEndpoint] عند كشف صمت نهاية مقطع (فاصل — ليس إيقافًا).
  ///
  /// [suraIdx]/[ayaIdx] (اختياري) يفعّلان تتبّع الكلمات لِآية واحدة:
  /// تُحاذى الوحدات المتنامية مع الآية المرجعية ويُستدعى [onWord] بفهرس
  /// الكلمة الجارية (0-based، أو -1 قبل أول مطابقة).
  ///
  /// [range] (اختياري) يفعّل تتبّع نطاق متعدد الآيات (وضع الصفحة):
  /// - [onRangeWord] يُستدعى بِـ (فهرس الآية داخل النطاق، فهرس الكلمة).
  /// - [onWordDone] عند اكتمال نطق كلمة — بَعد مرور المحاذاة على آخر
  ///   وحدة فيها — ومعها صحة نطقها (كل وحداتها match = صحيح).
  /// - [onRangeComplete] عند اكتمال كل كلمات النطاق.
  void startLive({
    void Function(LiveRecognitionFrame frame)? onPartial,
    void Function()? onEndpoint,
    void Function(int wordIdx)? onWord,
    void Function(int verseIdx, int wordIdx)? onRangeWord,
    void Function(int verseIdx, int wordIdx, TasmeeErrorKind kind)? onWordDone,
    void Function()? onRangeComplete,
    int? suraIdx,
    int? ayaIdx,
    QuranReferenceRange? range,
  });

  /// يغذّي عيّنات PCM ‏(16kHz mono، [-1,1]).
  void feedPcm(Float32List samples);

  /// يُنهي البثّ (صمت ختامي + نتيجة نهائية).
  Future<LiveRecognitionFrame> endLive();

  /// يُقيّم لقطة نهائية بنفس مسار التقييم الكامل (محاذاة + كشف + مدّ).
  Future<RecitationResult> evaluateLive({
    required MuaalemConfig config,
    int? suraIdx,
    int? ayaIdx,
    QuranReferenceRange? range,
    String? referenceText,
    required LiveRecognitionFrame frame,
  });
}
