/// خدمة نموذج Zipformer: فحص الجاهزية وتنزيل النموذج وقت التشغيل.
///
/// Zipformer model service: readiness check + runtime download.
///
/// النموذج (73MB ONNX) **ليس ضمن أصول الحزمة** — يُنزَّل مرة واحدة من
/// GitHub Release إلى مجلد دعم التطبيق، ثم يعمل التسميع دون إنترنت.
///
/// web-safe: عمليات الملفات عبر PlatformIo الشرطي (بلا dart:io مباشر).
library;

import 'dart:developer' show log;

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../engine/platform_io.dart';
import '../../engine/zipformer_model.dart';

/// يدير نموذج Zipformer على القرص (فحص/تنزيل/حذف).
class TasmeeModelService {
  TasmeeModelService({
    Dio? dio,
    int minValidBytes = kZipformerMinValidBytes,
    String? modelUrl,
  })  : _dio = dio ?? Dio(),
        _minValidBytes = minValidBytes,
        _modelUrl = modelUrl ?? kZipformerModelUrl;

  final Dio _dio;

  /// أقل حجم صالح (قابل لِلحقن لِلاختبارات).
  final int _minValidBytes;

  /// رابط التنزيل (قابل لِلحقن لِلاختبارات).
  final String _modelUrl;

  /// مسار النموذج المتوقع في مجلد دعم التطبيق.
  Future<String> get modelPath async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/$kZipformerModelFileName';
  }

  /// هل النموذج منزّل وصالح (حجمه > الحد الأدنى)؟
  Future<bool> isModelReady() async {
    final p = await modelPath;
    if (!await PlatformIo.fileExists(p)) return false;
    return await PlatformIo.fileLength(p) > _minValidBytes;
  }

  /// ينزّل النموذج بِـ تقدم لحظي — تنزيل ذرّي: ملف مؤقّت ثم إعادة تسمية.
  ///
  /// [onProgress] نسبة 0.0–1.0. يرمي عند الفشل ويحذف الملف الجزئي.
  Future<void> downloadModel({
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final dest = await modelPath;
    if (await isModelReady()) {
      onProgress?.call(1.0);
      return;
    }
    final partial = '$dest.part';
    try {
      await PlatformIo.deleteFile(partial);
      log('TasmeeModelService: downloading model…', name: 'TasmeeModel');
      await _dio.download(
        _modelUrl,
        partial,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );
      final size = await PlatformIo.fileLength(partial);
      if (size <= _minValidBytes) {
        throw Exception(
            'الملف المنزّل غير مكتمل (${(size / 1024 / 1024).toStringAsFixed(1)}MB)');
      }
      await PlatformIo.renameFile(partial, dest);
      onProgress?.call(1.0);
      log('TasmeeModelService: model ready → $dest', name: 'TasmeeModel');
    } catch (e) {
      // نظّف الجزئي كي لا يُحسب جاهزاً لاحقاً.
      await PlatformIo.deleteFile(partial);
      rethrow;
    }
  }

  /// يحذف النموذج من القرص (تحرير مساحة).
  Future<void> deleteModel() async {
    final p = await modelPath;
    await PlatformIo.deleteFile(p);
    await PlatformIo.deleteFile('$p.part');
  }
}
