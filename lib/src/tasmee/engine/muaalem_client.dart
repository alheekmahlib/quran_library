import 'dart:developer' show log;
import 'dart:typed_data' show Uint8List;

import 'package:dio/dio.dart';

import 'models/muaalem_config.dart';
import 'models/recitation_result.dart';
import 'recitation_engine.dart';

/// خطأ من خادم quran-muaalem (مثل HTTP 500).
///
/// An error from the quran-muaalem server (e.g. HTTP 500).
class RecitationServerException implements Exception {
  const RecitationServerException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// عميل HTTP لِخادم quran-muaalem.
///
/// HTTP client for the quran-muaalem server.
///
/// quran-muaalem خادم self-hosted يُقدّم API REST لِتصحيح التلاوة. ثبّته
/// وشغّله عبر:
/// ```
/// pip install "quran-muaalem[engine]"
/// quran-muaalem-engine  # منفذ 8000 (النموذج)
/// quran-muaalem-app     # منفذ 8001 (HTTP API)
/// ```
///
/// ثم أنشئ عميلاً:
/// ```dart
/// final client = MuaalemClient(baseUrl: 'http://localhost:8001');
/// ```
class MuaalemClient implements RecitationEngine {
  MuaalemClient({
    required this.baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: connectTimeout ?? const Duration(seconds: 10),
          receiveTimeout: receiveTimeout ?? const Duration(minutes: 2),
        ));

  /// عنوان الخادم الأساسي (مثل 'http://localhost:8001').
  /// Base server URL (e.g. 'http://localhost:8001').
  final String baseUrl;
  final Dio _dio;

  /// صحّح تلاوة — أرسل ملف WAV كاملاً، استلم الأخطاء.
  ///
  /// Correct a recitation — send a full WAV file, receive errors.
  ///
  /// [wavBytes] - بيانات ملف WAV (16kHz mono مُفضَّل).
  /// [config] - إعدادات المصحف (افتراضي: Hafs).
  /// [errorRatio] - أقصى نسبة خطأ لِلبحث (0.0-1.0، افتراضي 0.1). زيادتها تُسهّل
  ///   التطابق لكن قد تُعطي نتائج غير دقيقة.
  ///
  /// [wavBytes] - WAV file bytes (16kHz mono preferred).
  /// [config] - moshaf config (default: Hafs).
  /// [errorRatio] - max error ratio for search (0.0-1.0, default 0.1).
  @override
  Future<RecitationResult> correctRecitation({
    required Uint8List wavBytes,
    MuaalemConfig config = const MuaalemConfig(),
    double errorRatio = 0.1,
    int? suraIdx, // @unused — الخادم يبحث في القرآن كاملاً
    int? ayaIdx, // @unused
    String? referenceText, // @unused
  }) async {
    final form = FormData();
    form.files.add(MapEntry(
      'file',
      MultipartFile.fromBytes(wavBytes, filename: 'recitation.wav'),
    ));
    form.fields.add(MapEntry('error_ratio', errorRatio.toString()));
    config.toFormFields().forEach((k, v) => form.fields.add(MapEntry(k, v)));

    try {
      final response =
          await _dio.post<dynamic>('/correct-recitation', data: form);
      final json = response.data as Map<String, dynamic>;
      log(
          'MuaalemClient ← correct-recitation: '
          '${(json['errors'] as List?)?.length ?? 0} errors',
          name: 'MuaalemClient');
      return RecitationResult.fromJson(json);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      // اقرأ نصّ الاستجابة من الخادم (قد يحوي تفاصيل الخطأ).
      // Read the server's error text (may contain details).
      String serverDetail = '';
      final data = e.response?.data;
      if (data is Map) {
        serverDetail =
            (data['detail'] as String?) ?? (data['message'] as String?) ?? '';
      } else if (data is String) {
        serverDetail = data;
      }

      // HTTP 404 يعني "لا تطابق" — نُعيد نتيجة بِرسالة بدل طرح استثناء.
      // HTTP 404 means "no match" — return a result with a message instead of
      // throwing.
      if (code == 404) {
        return RecitationResult(
          predictedPhonemes:
              data is Map ? (data['predicted_phonemes'] as String?) : null,
          noMatchMessage: serverDetail.isNotEmpty
              ? serverDetail
              : 'لا تطابق — جرّب زيادة errorRatio',
        );
      }

      // HTTP 500: خطأ داخلي في الخادم. السبب الأكثر شيوعاً هو صوت لا يحوي
      // كلاماً واضحاً (صمت/ضوضاء)، أو صوت أطول من 15 ثانية، أو engine معطّل.
      // نُعيد نتيجة بِرسالة ودودة بدل طرح استثناء قبيح.
      // HTTP 500: internal server error. The most common cause is audio without
      // clear speech (silence/noise), audio longer than 15s, or a dead engine.
      // Return a result with a friendly message instead of an ugly exception.
      if (code == 500) {
        log('MuaalemClient: 500 server error. detail: $serverDetail',
            name: 'MuaalemClient');
        return const RecitationResult(
          noMatchMessage:
              'تعذّر معالجة الصوت — تأكّد من التحدّث بِوضوح أثناء التلاوة '
              'وأنّ التسجيل أقلّ من 15 ثانية.',
        );
      }

      log('MuaalemClient: correctRecitation error ($code): ${e.message}',
          name: 'MuaalemClient');
      rethrow;
    }
  }

  /// ابحث عن موضع الصوت في القرآن (بدون تصحيح).
  ///
  /// Search for the audio's position in the Quran (no correction).
  Future<List<SurahAyahPosition>> search({
    required Uint8List wavBytes,
    double errorRatio = 0.1,
  }) async {
    final form = FormData();
    form.files.add(MapEntry(
      'file',
      MultipartFile.fromBytes(wavBytes, filename: 'recitation.wav'),
    ));
    form.fields.add(MapEntry('error_ratio', errorRatio.toString()));

    try {
      final response = await _dio.post<dynamic>('/search', data: form);
      final json = response.data as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>? ?? [];
      return results
          .whereType<Map>()
          .map((m) {
            final start = m['start'];
            return start != null
                ? SurahAyahPosition.fromJson(
                    Map<String, dynamic>.from(start as Map))
                : null;
          })
          .whereType<SurahAyahPosition>()
          .toList();
    } on DioException catch (e) {
      log('MuaalemClient: search error: ${e.message}', name: 'MuaalemClient');
      rethrow;
    }
  }

  /// (online) يُعيد null دائماً — الخادم يبحث في القرآن ولا يُوفّر DB محليّة.
  @override
  String? getVerseText({required int suraIdx, required int ayaIdx}) => null;

  /// تحقّق من صحة الخادم (هل هو يعمل والنموذج محمّل؟).
  ///
  /// Check server health (is it running and the model loaded?).
  @override
  Future<bool> isHealthy() async {
    try {
      final response = await _dio.get<dynamic>('/health');
      final json = response.data as Map<String, dynamic>?;
      return json?['status'] == 'healthy';
    } catch (_) {
      return false;
    }
  }

  /// أغلق العميل وحرّر الموارد.
  /// Close the client and release resources.
  @override
  void dispose() {
    _dio.close();
  }
}
