import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';

/// Adds the public ISRG Root X1 only to the Android model download client.
/// Android 7 images may predate this root. Normal TLS validation remains on.
Future<Dio> createZipformerDownloadClient() async {
  final dio = Dio();
  if (!Platform.isAndroid) return dio;
  final cert = await rootBundle.load(
    'packages/quran_library/assets/quran_lab/isrg-root-x1.pem',
  );
  final context = SecurityContext(withTrustedRoots: true)
    ..setTrustedCertificatesBytes(cert.buffer.asUint8List(
      cert.offsetInBytes,
      cert.lengthInBytes,
    ));
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () => HttpClient(context: context),
  );
  return dio;
}
