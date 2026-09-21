/// واجهة مجرّدة لِمحرّك تقييم التلاوة.
///
/// تتيح للمكتبة العمل بِـ محرّكَين:
/// - [MuaalemClient] (online): يتواصل مع خادم quran-muaalem.
/// - [OnnxRecitationEngine] (offline): يشغّل نموذج ONNX محليّاً.
///
/// العقد الوحيد: [correctRecitation] يأخذ صوت WAV (16kHz mono) وُيعيد
/// [RecitationResult] بِنفس بنية الخادم.
library;

import 'dart:typed_data';

import 'models/muaalem_config.dart';
import 'models/recitation_result.dart';
import 'quran_reference.dart';

/// محرّك تقييم التلاوة (online أو offline).
abstract interface class RecitationEngine {
  /// يُقيّم تلاوةً من بيانات WAV.
  ///
  /// [wavBytes] بيانات ملفّ WAV (16kHz mono).
  /// [config] إعدادات المصحف (Hafs/Warsh، أطوال المدود...).
  /// [errorRatio] نسبة التسامح في المطابقة (0-1).
  /// [suraIdx]/[ayaIdx] (offline) رقم السورة والآية — لِـ جلب المرجع من DB
  ///   ومقارنة الفونيمات + كشف أخطاء التجويد بِشكل كامل.
  /// [range] (offline، بديل يشمل ما سبق) نطاق متعدد الآيات — وضع الصفحة.
  /// [referenceText] (offline، بديل) نصّ الآية العثماني — يُستخدم إن لم
  ///   يُعطَ suraIdx/ayaIdx. يُقارن بشكل أبسط (بِدون DB مرجعي كامل).
  Future<RecitationResult> correctRecitation({
    required final Uint8List wavBytes,
    final MuaalemConfig config = const MuaalemConfig(),
    final double errorRatio = 0.1,
    final int? suraIdx,
    final int? ayaIdx,
    final QuranReferenceRange? range,
    final String? referenceText,
  });

  /// هل المحرّك جاهز لِلاستخدام؟ (خادم صحّي / نموذج محمّل).
  Future<bool> isHealthy();

  /// (offline) ابحث عن نصّ آية عثماني من DB المرجعية.
  /// يُعيد null في الوضع online أو إن لم تُوجد الآية.
  String? getVerseText({required int suraIdx, required int ayaIdx});

  /// تحرير الموارد.
  void dispose();
}
