part of '/quran.dart';

/// خدمة تحميل وتسجيل خطوط QCF4 المضغوطة (tajweed).
///
/// الخطوط مخزّنة كملفات `.ttf.gz` في assets. عند أول استخدام يتم فك ضغطها
/// وتسجيلها عبر [loadFontFromList]. تُحفظ النسخ المفكوكة على القرص
/// (على المنصات غير الويب) لتسريع التشغيلات اللاحقة.
class QuranFontsService {
  QuranFontsService._();

  static const int _totalPages = 604;

  /// علم في الذاكرة: هل تم تسجيل جميع الخطوط في هذا التشغيل؟
  static bool _fontsRegistered = false;

  /// Future واحد لمنع تكرار التحميل عند الاستدعاء المتزامن.
  static Future<void>? _loadFuture;

  /// اسم عائلة الخط للصفحة المحددة (page1 .. page604).
  static String getFontFamily(int pageIndex) => 'page${pageIndex + 1}';

  /// مسار الـ asset المضغوط للصفحة (1-based).
  static String _assetPath(int page) {
    final padded = page.toString().padLeft(3, '0');
    return 'packages/quran_library/assets/fonts/quran_fonts_qfc4/'
        'QCF4_tajweed_$padded.ttf.gz';
  }

  /// تحميل جميع خطوط التجويد (604 صفحة) مرة واحدة.
  ///
  /// تُحدّث [progress] (0.0–1.0) بعد كل خط، وتضبط [ready] على `true`
  /// عند الانتهاء. إذا كانت الخطوط مسجّلة سابقًا تُرجع فورًا.
  static Future<void> loadAllFonts({
    required RxDouble progress,
    required RxBool ready,
  }) {
    // منع التكرار عند الاستدعاء من عدة أماكن في نفس الوقت
    _loadFuture ??= _doLoadAllFonts(progress: progress, ready: ready);
    return _loadFuture!;
  }

  static Future<void> _doLoadAllFonts({
    required RxDouble progress,
    required RxBool ready,
  }) async {
    if (_fontsRegistered) {
      ready.value = true;
      progress.value = 1.0;
      return;
    }

    Directory? cacheDir;
    if (!kIsWeb) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        cacheDir = Directory('${appDir.path}/quran_fonts_cache');
        if (!cacheDir.existsSync()) {
          await cacheDir.create(recursive: true);
        }
      } catch (e) {
        log('QuranFontsService: failed to create cache dir: $e',
            name: 'QuranFontsService');
        cacheDir = null;
      }
    }

    for (int i = 1; i <= _totalPages; i++) {
      try {
        Uint8List fontBytes;
        final familyName = 'page$i';

        // على غير الويب: جرّب قراءة الكاش أولاً
        if (cacheDir != null) {
          final cachedFile = File('${cacheDir.path}/$familyName.ttf');
          if (cachedFile.existsSync()) {
            fontBytes = await cachedFile.readAsBytes();
          } else {
            // فك الضغط من الـ asset وحفظ في الكاش
            fontBytes = await _decompressFromAsset(i);
            try {
              await cachedFile.writeAsBytes(fontBytes, flush: true);
            } catch (e) {
              log('QuranFontsService: cache write failed for page $i: $e',
                  name: 'QuranFontsService');
            }
          }
        } else {
          // ويب أو كاش غير متاح: فك الضغط في كل مرة
          fontBytes = await _decompressFromAsset(i);
        }

        await loadFontFromList(fontBytes, fontFamily: familyName);
      } catch (e, st) {
        log('QuranFontsService: failed to load font page $i: $e',
            name: 'QuranFontsService', stackTrace: st);
      }

      progress.value = i / _totalPages;
    }

    _fontsRegistered = true;
    ready.value = true;
  }

  /// فك ضغط ملف `.ttf.gz` من الـ assets.
  static Future<Uint8List> _decompressFromAsset(int page) async {
    final data = await rootBundle.load(_assetPath(page));
    final gzBytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final decompressed = const GZipDecoder().decodeBytes(gzBytes);
    return Uint8List.fromList(decompressed);
  }

  /// حذف كاش الخطوط من القرص.
  static Future<void> clearCache() async {
    if (kIsWeb) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/quran_fonts_cache');
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      log('QuranFontsService: clearCache failed: $e',
          name: 'QuranFontsService');
    }
    _fontsRegistered = false;
    _loadFuture = null;
  }
}
