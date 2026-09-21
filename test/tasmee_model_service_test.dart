import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:quran_library/src/tasmee/core/services/tasmee_model_service.dart';

/// مزوّد مسارات وهمي يشير إلى مجلد مؤقت (لا يحتاج path_provider الحقيقي).
class _MockPathProvider extends PathProviderPlatform {
  _MockPathProvider(this.supportDir);
  final Directory supportDir;

  @override
  Future<String?> getApplicationSupportPath() async => supportDir.path;
}

void main() {
  late Directory tmpDir;
  late HttpServer server;
  late Uint8List modelBytes;

  setUpAll(() async {
    modelBytes = Uint8List.fromList(List.generate(4096, (i) => i % 251));
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      Uint8List body;
      if (req.uri.path == '/model.onnx') {
        body = modelBytes;
      } else if (req.uri.path == '/short.onnx') {
        body = modelBytes.sublist(0, 16);
      } else {
        req.response.statusCode = 404;
        await req.response.close();
        return;
      }
      req.response.contentLength = body.length;
      req.response.add(body);
      await req.response.close();
    });
  });

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('tasmee_model_test');
    PathProviderPlatform.instance = _MockPathProvider(tmpDir);
  });

  tearDown(() async {
    if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
  });

  tearDownAll(() async {
    await server.close(force: true);
  });

  TasmeeModelService service(String path) => TasmeeModelService(
        modelUrl: 'http://127.0.0.1:${server.port}$path',
        minValidBytes: 1024, // عتبة مصغّرة لِلاختبار.
      );

  test('غير جاهز عند غياب الملف أو صغر حجمه عن العتبة', () async {
    final s = service('/model.onnx');
    expect(await s.isModelReady(), isFalse);
    final path = await s.modelPath;
    await File(path).writeAsBytes(modelBytes.sublist(0, 100));
    expect(await s.isModelReady(), isFalse, reason: 'أصغر من العتبة');
  });

  test('downloadModel ينزّل ذرّياً (part → rename) ويصبح جاهزاً', () async {
    final s = service('/model.onnx');
    var lastProgress = 0.0;
    await s.downloadModel(onProgress: (p) => lastProgress = p);
    expect(lastProgress, 1.0);
    expect(await s.isModelReady(), isTrue);
    final path = await s.modelPath;
    expect(await File(path).length(), modelBytes.length);
    expect(await File('$path.part').exists(), isFalse,
        reason: 'لا ملف جزئي بعد النجاح');
    // إعادة النداء بعد الجاهزية لا تعيد التنزيل.
    await s.downloadModel();
    expect(await File(path).length(), modelBytes.length);
  });

  test('ملف أصغر من العتبة يُرفض ويُحذف الجزئي', () async {
    final s = service('/short.onnx');
    Object? caught;
    try {
      await s.downloadModel();
    } catch (e) {
      caught = e;
    }
    expect(caught, isNotNull, reason: 'التنزيل الناقص يرمي');
    expect(await s.isModelReady(), isFalse);
    final path = await s.modelPath;
    expect(await File(path).exists(), isFalse);
    expect(await File('$path.part').exists(), isFalse,
        reason: 'الجزئي يُنظَّف عند الفشل');
  });

  test('deleteModel يحرّر القرص', () async {
    final s = service('/model.onnx');
    await s.downloadModel();
    await s.deleteModel();
    expect(await s.isModelReady(), isFalse);
  });
}
