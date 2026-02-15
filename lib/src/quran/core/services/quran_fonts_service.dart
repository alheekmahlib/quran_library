part of '/quran.dart';

/// خدمة تحميل وتسجيل خطوط QCF4 المضغوطة (tajweed).
///
/// الخطوط مخزّنة كملفات `.ttf.gz` في assets. عند أول استخدام يتم فك ضغطها
/// وتسجيلها عبر [loadFontFromList]. تُحفظ النسخ المفكوكة على القرص
/// (على المنصات غير الويب) لتسريع التشغيلات اللاحقة.
///
/// في الوضع الداكن مع التجويد، تُسجّل نسخة إضافية من كل خط باسم `page{i}d`
/// حيث يتم تعديل جدول CPAL لتحويل اللون الأسود الأساسي إلى الأبيض،
/// مع الحفاظ على جميع ألوان التجويد كما هي.
class QuranFontsService {
  QuranFontsService._();

  static const int _totalPages = 604;

  /// علم في الذاكرة: هل تم تسجيل جميع الخطوط في هذا التشغيل؟
  static bool _fontsRegistered = false;

  /// علم منفصل للخطوط الداكنة.
  static bool _darkFontsRegistered = false;

  /// علم للخطوط بدون تجويد (كل ألوان CPAL موحّدة).
  static bool _noTajweedFontsRegistered = false;

  /// Future واحد لمنع تكرار التحميل عند الاستدعاء المتزامن.
  static Future<void>? _loadFuture;

  /// اسم عائلة الخط للصفحة المحددة (page1 .. page604).
  static String getFontFamily(int pageIndex) => 'page${pageIndex + 1}';

  /// اسم عائلة الخط الداكن للصفحة المحددة (page1d .. page604d).
  static String getDarkFontFamily(int pageIndex) => 'page${pageIndex + 1}d';

  /// اسم عائلة الخط بدون تجويد فاتح (page1n .. page604n).
  static String getNoTajweedFontFamily(int pageIndex) =>
      'page${pageIndex + 1}n';

  /// اسم عائلة الخط بدون تجويد داكن (page1nd .. page604nd).
  static String getNoTajweedDarkFontFamily(int pageIndex) =>
      'page${pageIndex + 1}nd';

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
    if (_fontsRegistered && _darkFontsRegistered && _noTajweedFontsRegistered) {
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

        // تسجيل الخط الأصلي (فاتح)
        if (!_fontsRegistered) {
          await loadFontFromList(fontBytes, fontFamily: familyName);
        }

        // تسجيل نسخة داكنة: تعديل CPAL لتحويل الأسود→أبيض
        if (!_darkFontsRegistered) {
          final darkBytes = _modifyCpalBaseColor(
            Uint8List.fromList(fontBytes),
            const Color(0xFFFFFFFF),
          );
          await loadFontFromList(darkBytes, fontFamily: '${familyName}d');
        }

        // تسجيل نسخة بدون تجويد فاتحة: كل ألوان CPAL → أسود
        if (!_noTajweedFontsRegistered) {
          final ntBytes = _modifyCpalAllColors(
            Uint8List.fromList(fontBytes),
            const Color(0xFF000000),
          );
          await loadFontFromList(ntBytes, fontFamily: '${familyName}n');

          // نسخة بدون تجويد داكنة: كل ألوان CPAL → أبيض
          final ntdBytes = _modifyCpalAllColors(
            Uint8List.fromList(fontBytes),
            const Color(0xFFFFFFFF),
          );
          await loadFontFromList(ntdBytes, fontFamily: '${familyName}nd');
        }
      } catch (e, st) {
        log('QuranFontsService: failed to load font page $i: $e',
            name: 'QuranFontsService', stackTrace: st);
      }

      progress.value = i / _totalPages;
    }

    _fontsRegistered = true;
    _darkFontsRegistered = true;
    _noTajweedFontsRegistered = true;
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

  // ---------------------------------------------------------------------------
  // تعديل جدول CPAL في ملف TTF/OTF
  // ---------------------------------------------------------------------------

  /// يبحث عن جدول `CPAL` في بيانات الخط ويستبدل اللون الأسود الأساسي
  /// (الطبقة الأساسية لنص القرآن) بـ [newBaseColor].
  ///
  /// ألوان التجويد (أحمر، أخضر، أزرق، إلخ) تبقى كما هي تماماً.
  /// إذا لم يُعثر على جدول CPAL، تُرجع البيانات بدون تعديل.
  static Uint8List _modifyCpalBaseColor(
      Uint8List fontBytes, Color newBaseColor) {
    final bd = ByteData.view(
        fontBytes.buffer, fontBytes.offsetInBytes, fontBytes.lengthInBytes);

    // 1. قراءة عدد الجداول من الترويسة
    // OpenType header: sfVersion(4) + numTables(2) + ...
    if (fontBytes.length < 12) return fontBytes;
    final numTables = bd.getUint16(4);

    // 2. البحث عن جدول CPAL في Table Directory
    // كل سجل: tag(4) + checkSum(4) + offset(4) + length(4) = 16 bytes
    int? cpalOffset;
    int? cpalLength;
    const cpalTag = 0x4350414C; // 'CPAL' in ASCII
    for (int t = 0; t < numTables; t++) {
      final recordOffset = 12 + t * 16;
      if (recordOffset + 16 > fontBytes.length) break;
      final tag = bd.getUint32(recordOffset);
      if (tag == cpalTag) {
        cpalOffset = bd.getUint32(recordOffset + 8);
        cpalLength = bd.getUint32(recordOffset + 12);
        break;
      }
    }

    if (cpalOffset == null || cpalLength == null) return fontBytes;
    if (cpalOffset + cpalLength > fontBytes.length) return fontBytes;

    // 3. قراءة بنية CPAL
    // CPAL header:
    //   version(2) + numPaletteEntries(2) + numPalettes(2) +
    //   numColorRecords(2) + colorRecordsArrayOffset(4)
    //   + paletteIndices[numPalettes] (each 2 bytes)
    if (cpalOffset + 12 > fontBytes.length) return fontBytes;
    final numColorRecords = bd.getUint16(cpalOffset + 6);
    final colorRecordsArrayOffset = bd.getUint32(cpalOffset + 8);

    // العنوان المطلق لسجلات الألوان
    final absColorRecordsOffset = cpalOffset + colorRecordsArrayOffset;

    // 4. تعديل سجلات CPAL: استبدال الأسود فقط
    // كل سجل لون: B(1) + G(1) + R(1) + A(1) = 4 bytes (ترتيب BGRA)
    // ملاحظة: Color.r/g/b/a تُرجع قيمًا عشرية (0.0–1.0) في Flutter الحديث
    final newR = (newBaseColor.r * 255).round();
    final newG = (newBaseColor.g * 255).round();
    final newB = (newBaseColor.b * 255).round();
    final newA = (newBaseColor.a * 255).round();

    // نفحص جميع سجلات الألوان (عبر كل الـ palettes)
    for (int c = 0; c < numColorRecords; c++) {
      final colorOffset = absColorRecordsOffset + c * 4;
      if (colorOffset + 4 > fontBytes.length) break;

      final b = fontBytes[colorOffset];
      final g = fontBytes[colorOffset + 1];
      final r = fontBytes[colorOffset + 2];
      final a = fontBytes[colorOffset + 3];

      // اكتشاف اللون الأسود: RGB ≤ 30 و Alpha ≥ 200
      if (r <= 30 && g <= 30 && b <= 30 && a >= 200) {
        fontBytes[colorOffset] = newB;
        fontBytes[colorOffset + 1] = newG;
        fontBytes[colorOffset + 2] = newR;
        fontBytes[colorOffset + 3] = newA;
      }
    }

    return fontBytes;
  }

  /// يستبدل **جميع** ألوان CPAL بلون واحد موحّد.
  ///
  /// يُستخدم لإنشاء نسخة "بدون تجويد" حيث يُرسم كل شيء بلون واحد.
  static Uint8List _modifyCpalAllColors(Uint8List fontBytes, Color color) {
    final bd = ByteData.view(
        fontBytes.buffer, fontBytes.offsetInBytes, fontBytes.lengthInBytes);

    if (fontBytes.length < 12) return fontBytes;
    final numTables = bd.getUint16(4);

    int? cpalOffset;
    int? cpalLength;
    const cpalTag = 0x4350414C;
    for (int t = 0; t < numTables; t++) {
      final recordOffset = 12 + t * 16;
      if (recordOffset + 16 > fontBytes.length) break;
      final tag = bd.getUint32(recordOffset);
      if (tag == cpalTag) {
        cpalOffset = bd.getUint32(recordOffset + 8);
        cpalLength = bd.getUint32(recordOffset + 12);
        break;
      }
    }

    if (cpalOffset == null || cpalLength == null) return fontBytes;
    if (cpalOffset + cpalLength > fontBytes.length) return fontBytes;
    if (cpalOffset + 12 > fontBytes.length) return fontBytes;

    final numColorRecords = bd.getUint16(cpalOffset + 6);
    final colorRecordsArrayOffset = bd.getUint32(cpalOffset + 8);
    final absColorRecordsOffset = cpalOffset + colorRecordsArrayOffset;

    final newR = (color.r * 255).round();
    final newG = (color.g * 255).round();
    final newB = (color.b * 255).round();
    final newA = (color.a * 255).round();

    // استبدال كل سجلات الألوان بلون واحد
    for (int c = 0; c < numColorRecords; c++) {
      final colorOffset = absColorRecordsOffset + c * 4;
      if (colorOffset + 4 > fontBytes.length) break;
      fontBytes[colorOffset] = newB;
      fontBytes[colorOffset + 1] = newG;
      fontBytes[colorOffset + 2] = newR;
      fontBytes[colorOffset + 3] = newA;
    }

    return fontBytes;
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
    _darkFontsRegistered = false;
    _noTajweedFontsRegistered = false;
    _loadFuture = null;
  }
}
