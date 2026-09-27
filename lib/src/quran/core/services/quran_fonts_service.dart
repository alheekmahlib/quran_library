part of '/quran.dart';

/// خدمة تحميل كسول (lazy) وتسجيل خطوط QCF4 المضغوطة (tajweed).
///
/// الخطوط تُنزَّل كملفات `.ttf.gz` من المرايا في [_fontBaseUrls] بدل أن تُحزم
/// في التطبيق (65 MB). عند الحاجة يتم فك ضغطها وتسجيلها عبر [loadFontFromList]،
/// وتُحفظ النسخ المفكوكة على القرص (على المنصات غير الويب) فلا يُعاد التنزيل.
///
/// **التحميل الكسول**: تُحمّل فقط الصفحات القريبة من الصفحة الحالية،
/// ثم تُكمَل بقية الصفحات في الخلفية تدريجيًا.
class QuranFontsService {
  QuranFontsService._();

  static const int _totalPages = 604;

  /// إصدار كاش الخطوط المفكوكة على القرص.
  ///
  /// يُرفع هذا الرقم عند أي تحديث لمحتوى ملفات الخطوط كي تُبطَل
  /// النسخ المفكوكة القديمة لدى المستخدمين القدامى وتُعاد من المرايا
  /// تلقائيًا (فحص الوجود وحده لا يكشف تغيّر محتوى الخط).
  ///
  /// بدأ من 2 لأن 4.2.0 حدّثت خطوط 80+ صفحة بينما كاش الإصدارات
  /// السابقة بلا ملف إصدار أصلاً — فيُفرَّغ عند أول ترقية للنسخة هذه.
  static const int _cacheVersion = 2;

  /// اسم ملف العلم الذي يُخزَّن فيه رقم إصدار الكاش داخل مجلد الخطوط.
  static const String _cacheVersionFileName = 'cache_version.txt';

  /// الصفحات المحمّلة في هذا التشغيل (1-based).
  static final Set<int> _loadedPages = {};

  /// Futures لمنع تكرار تحميل نفس الصفحة عند الاستدعاء المتزامن.
  static final Map<int, Future<void>> _pageLoadFutures = {};

  /// Future واحد لتحميل الخلفية لمنع التكرار.
  static Future<void>? _backgroundLoadFuture;

  /// كاش مجلد الخطوط المفكوكة (يُهيّأ مرة واحدة).
  static Directory? _cacheDir;
  static bool _cacheDirInitialized = false;

  /// هل الصفحة المحددة جاهزة للعرض؟ (1-based)
  static bool isPageReady(int page) => _loadedPages.contains(page);

  /// عدد الصفحات المحمّلة حتى الآن.
  static int get loadedCount => _loadedPages.length;

  /// هل تم تحميل جميع الصفحات؟
  static bool get allLoaded => _loadedPages.length >= _totalPages;

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

  /// اسم عائلة الخط الأحمر للخلاف (page1nr .. page604nr).
  static String getRedFontFamily(int pageIndex) => 'page${pageIndex + 1}nr';

  /// اسم عائلة الخط الشفاف للتسميع (page1t .. page604t) — كل ألوان CPAL
  /// ألفا 0: الكلمات تختفي بصريًا مع بقاء المقاييس والمواضع كما هي.
  static String getTransparentFontFamily(int pageIndex) =>
      'page${pageIndex + 1}t';

  /// الصفحات التي سُجّل متغيرها الشفاف (تحميل كسول — عند الطلب فقط).
  static final Set<int> _transparentLoadedPages = {};

  /// هل المتغير الشفاف للصفحة (1-based) جاهز؟
  static bool isTransparentPageReady(int page) =>
      _transparentLoadedPages.contains(page);

  /// يحمّل المتغير الشفاف لصفحة واحدة عند الطلب (وضع التسميع).
  ///
  /// يقرأ كاش القرص إن وُجد (مثل [_loadSinglePage])، يرقّع كل ألوان CPAL
  /// إلى شفاف تمامًا، ويسجّل العائلة `page{N}t`. يُعيد false عند الفشل
  /// (يتراجع العرض عندها إلى حذف مقاطع الكلمات المخفية).
  static Future<bool> ensureTransparentFont(int page) async {
    if (_transparentLoadedPages.contains(page)) return true;
    try {
      final familyName = 'page$page';
      final fontBytes = await _fontBytesFor(page, await _ensureCacheDir());
      final transparentBytes = _modifyCpalAllColors(
        Uint8List.fromList(fontBytes),
        const Color(0x00000000), // شفاف بالكامل — الألفا 0.
      );
      await loadFontFromList(transparentBytes, fontFamily: '${familyName}t');
      _transparentLoadedPages.add(page);
      return true;
    } catch (e, st) {
      log('QuranFontsService: transparent font failed for page $page: $e',
          name: 'QuranFontsService', stackTrace: st);
      return false;
    }
  }

  /// مرايا ملفات `.ttf.gz` بالترتيب: jsDelivr أولًا (كاش CDN أوسع)، ثم
  /// GitHub الخام احتياطًا عند بلوغ حدود المعدّل. المسار مثبَّت على وسم
  /// المستودع فلا يتغيّر محتوى الخط دون رفع [_cacheVersion].
  static const List<String> _fontBaseUrls = <String>[
    'https://cdn.jsdelivr.net/gh/Imad-Ainine/quran_library@v5.0.1-hydro.1/'
        'assets/fonts/quran_fonts_qfc4/',
    'https://raw.githubusercontent.com/Imad-Ainine/quran_library/'
        'v5.0.1-hydro.1/assets/fonts/quran_fonts_qfc4/',
  ];

  static const Duration _fontConnectTimeout = Duration(seconds: 15);
  static const Duration _fontReceiveTimeout = Duration(seconds: 60);

  /// Dio مشترك بين كل الصفحات لإعادة استخدام الاتصال.
  static Dio? _fontDio;

  static Dio get _http {
    final existing = _fontDio;
    if (existing != null) return existing;
    final created = Dio()
      ..options.connectTimeout = _fontConnectTimeout
      ..options.receiveTimeout = _fontReceiveTimeout;
    _fontDio = created;
    return created;
  }

  /// اسم الملف المضغوط للصفحة (1-based).
  static String _fontFileName(int page) {
    final padded = page.toString().padLeft(3, '0');
    return 'QCF4${padded}_COLOR-Regular.ttf.gz';
  }

  // ---------------------------------------------------------------------------
  // تهيئة مجلد الكاش
  // ---------------------------------------------------------------------------

  static Future<Directory?> _ensureCacheDir() async {
    if (_cacheDirInitialized) return _cacheDir;
    _cacheDirInitialized = true;
    if (kIsWeb) return null;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/quran_fonts_cache');
      await _validateCacheVersion(dir);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      _cacheDir = dir;
    } catch (e) {
      log('QuranFontsService: failed to create cache dir: $e',
          name: 'QuranFontsService');
      _cacheDir = null;
    }
    return _cacheDir;
  }

  /// مطابقة إصدار الكاش المخزّن مع [_cacheVersion] قبل أي استخدام:
  /// - تطابق: لا شيء يُفعل.
  /// - غياب الملف أو اختلاف الرقم (تحديث خطوط أو تثبيت قديم): يُفرَّغ
  ///   المجلد كي تُعاد الخطوط من الـ assets المحدثة عند أول طلب.
  /// ثم يُضمن وجود المجلد ويُكتب رقم الإصدار الحالي.
  static Future<void> _validateCacheVersion(Directory cacheDir) async {
    final versionFile = File('${cacheDir.path}/$_cacheVersionFileName');
    if (await cacheDir.exists()) {
      final stored = await _readStoredCacheVersion(versionFile);
      if (stored == _cacheVersion) return;
      log(
        'QuranFontsService: font cache version mismatch '
        '($stored != $_cacheVersion) — clearing cache',
        name: 'QuranFontsService',
      );
      await cacheDir.delete(recursive: true);
    }
    await cacheDir.create(recursive: true);
    try {
      await versionFile.writeAsString('$_cacheVersion', flush: true);
    } catch (e) {
      log('QuranFontsService: failed to write cache version: $e',
          name: 'QuranFontsService');
    }
  }

  /// يقرأ رقم الإصدار المخزّن من ملف العلم؛ null عند الغياب أو الفساد.
  static Future<int?> _readStoredCacheVersion(File versionFile) async {
    try {
      if (!await versionFile.exists()) return null;
      return int.tryParse((await versionFile.readAsString()).trim());
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // التحميل الكسول: تحميل صفحات قريبة فقط
  // ---------------------------------------------------------------------------

  /// تحميل الصفحات القريبة من [centerPage] (1-based) بنصف قطر [radius].
  ///
  /// مثال: `ensurePagesLoaded(100, radius: 10)` يحمّل الصفحات 90–110.
  /// يتم تخطّي الصفحات المحمّلة مسبقًا. يُنتظر حتى انتهاء التحميل.
  static Future<void> ensurePagesLoaded(
    int centerPage, {
    int radius = 10,
  }) async {
    final cacheDir = await _ensureCacheDir();
    final start = (centerPage - radius).clamp(1, _totalPages);
    final end = (centerPage + radius).clamp(1, _totalPages);

    final futures = <Future<void>>[];
    for (int p = start; p <= end; p++) {
      if (!_loadedPages.contains(p)) {
        futures.add(_loadSinglePage(p, cacheDir));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// تحميل بقية الصفحات في الخلفية بترتيب يبدأ من [startNearPage].
  ///
  /// تُحدّث [progress] (0.0–1.0) و[ready] عند الانتهاء الكامل.
  /// لا تُنتظر — تعمل بشكل غير متزامن.
  static Future<void> loadRemainingInBackground({
    required int startNearPage,
    required RxDouble progress,
    required RxBool ready,
  }) {
    if (allLoaded) {
      progress.value = 1.0;
      ready.value = true;
      return Future.value();
    }
    // منع التكرار
    _backgroundLoadFuture ??= _doLoadRemaining(
      startNearPage: startNearPage,
      progress: progress,
      ready: ready,
    );
    return _backgroundLoadFuture!;
  }

  static Future<void> _doLoadRemaining({
    required int startNearPage,
    required RxDouble progress,
    required RxBool ready,
  }) async {
    final cacheDir = await _ensureCacheDir();
    final loadOrder = _buildLoadOrder(startNearPage);

    for (final page in loadOrder) {
      if (_loadedPages.contains(page)) continue;
      await _loadSinglePage(page, cacheDir);
      progress.value = _loadedPages.length / _totalPages;
    }

    progress.value = 1.0;
    ready.value = true;
  }

  /// بناء ترتيب التحميل: يبدأ من [startPage] ويتوسع للخارج.
  ///
  /// مثلاً لو startPage=100: 100، 101، 99، 102، 98، 103، 97 ...
  static List<int> _buildLoadOrder(int startPage) {
    final order = <int>[];
    final start = startPage.clamp(1, _totalPages);
    order.add(start);

    for (int delta = 1; delta < _totalPages; delta++) {
      final after = start + delta;
      final before = start - delta;
      if (after <= _totalPages) order.add(after);
      if (before >= 1) order.add(before);
    }

    return order;
  }

  // ---------------------------------------------------------------------------
  // تحميل صفحة واحدة مع كل المتغيرات (4 خطوط)
  // ---------------------------------------------------------------------------

  /// تحميل صفحة واحدة (1-based) مع متغيراتها الأربعة.
  ///
  /// - `page{N}` — فاتح مع تجويد
  /// - `page{N}d` — داكن مع تجويد (CPAL: أسود→أبيض)
  /// - `page{N}n` — فاتح بدون تجويد (CPAL: كل الألوان→أسود)
  /// - `page{N}nd` — داكن بدون تجويد (CPAL: كل الألوان→أبيض)
  static Future<void> _loadSinglePage(int page, Directory? cacheDir) {
    // منع التكرار عند الاستدعاء المتزامن لنفس الصفحة
    return _pageLoadFutures.putIfAbsent(page, () async {
      try {
        final familyName = 'page$page';
        final fontBytes = await _fontBytesFor(page, cacheDir);

        // 1. خط فاتح أصلي
        await loadFontFromList(fontBytes, fontFamily: familyName);

        // 2. خط داكن: CPAL أسود → أبيض
        final darkBytes = _modifyCpalBaseColor(
          Uint8List.fromList(fontBytes),
          const Color(0xFFFFFFFF),
        );
        await loadFontFromList(darkBytes, fontFamily: '${familyName}d');

        // 3. بدون تجويد فاتح: كل الألوان → أسود
        final ntBytes = _modifyCpalAllColors(
          Uint8List.fromList(fontBytes),
          const Color(0xFF000000),
        );
        await loadFontFromList(ntBytes, fontFamily: '${familyName}n');

        // 4. بدون تجويد داكن: كل الألوان → أبيض
        final ntdBytes = _modifyCpalAllColors(
          Uint8List.fromList(fontBytes),
          const Color(0xFFFFFFFF),
        );
        await loadFontFromList(ntdBytes, fontFamily: '${familyName}nd');

        // 5. أحمر للخلاف (القراءات العشر): كل الألوان → أحمر
        final nrBytes = _modifyCpalAllColors(
          Uint8List.fromList(fontBytes),
          const Color(0xFFFF0000),
        );
        await loadFontFromList(nrBytes, fontFamily: '${familyName}nr');

        _loadedPages.add(page);
      } catch (e, st) {
        log('QuranFontsService: failed to load font page $page: $e',
            name: 'QuranFontsService', stackTrace: st);
        // مع التنزيل المؤقت يجب أن تُعاد المحاولة لاحقًا: لو بقي الـ future
        // الفاشل في الخريطة فلن تطلب الصفحة مرة أخرى أبدًا في هذا التشغيل.
        _pageLoadFutures.remove(page);
      }
    });
  }

  /// بيانات خط الصفحة: من كاش القرص إن وُجد، وإلا تنزيل + فك ضغط ثم تخزين.
  ///
  /// يُستخدم هذا المسار نفسه لمتغير التجويد العادي وللشفاف (وضع التسميع)
  /// كي لا يُنزَّل الملف مرتين.
  static Future<Uint8List> _fontBytesFor(int page, Directory? cacheDir) async {
    if (cacheDir != null) {
      final cachedFile = File('${cacheDir.path}/page$page.ttf');
      if (cachedFile.existsSync()) {
        return Uint8List.fromList(await cachedFile.readAsBytes());
      }
      final fontBytes = await _downloadAndDecompress(page);
      try {
        await cachedFile.writeAsBytes(fontBytes, flush: true);
      } catch (e) {
        log('QuranFontsService: cache write failed for page $page: $e',
            name: 'QuranFontsService');
      }
      return fontBytes;
    }
    return _downloadAndDecompress(page);
  }

  /// تنزيل ملف `.ttf.gz` من المرايا وفك ضغطه.
  ///
  /// تُرفض الاستجابة غير الـ200 وكل جسم ليس GZip فعلًا (صفحة خطأ)، فلا يصل
  /// محتوى تالف إلى كاش القرص ولا إلى `loadFontFromList`.
  static Future<Uint8List> _downloadAndDecompress(int page) async {
    final fileName = _fontFileName(page);
    String? failure;
    for (final base in _fontBaseUrls) {
      final url = '$base$fileName';
      try {
        final response = await _http.get<Uint8List>(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            headers: const <String, String>{'Accept-Encoding': 'identity'},
          ),
        );
        final gzBytes = response.data;
        if (response.statusCode != 200 ||
            gzBytes == null ||
            gzBytes.length < 2) {
          failure = 'HTTP ${response.statusCode} from $url';
          continue;
        }
        if (gzBytes[0] != 0x1f || gzBytes[1] != 0x8b) {
          failure = 'non-gzip body from $url';
          continue;
        }
        return Uint8List.fromList(const GZipDecoder().decodeBytes(gzBytes));
      } catch (e) {
        failure = '$e ($url)';
        log('QuranFontsService: mirror failed: $url: $e',
            name: 'QuranFontsService');
      }
    }
    throw StateError('QCF font page $page unavailable: $failure');
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

    if (fontBytes.length < 12) return fontBytes;
    final numTables = bd.getUint16(4);

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

    if (cpalOffset + 12 > fontBytes.length) return fontBytes;
    final numColorRecords = bd.getUint16(cpalOffset + 6);
    final colorRecordsArrayOffset = bd.getUint32(cpalOffset + 8);

    final absColorRecordsOffset = cpalOffset + colorRecordsArrayOffset;

    final newR = (newBaseColor.r * 255).round();
    final newG = (newBaseColor.g * 255).round();
    final newB = (newBaseColor.b * 255).round();
    final newA = (newBaseColor.a * 255).round();

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
    _loadedPages.clear();
    _pageLoadFutures.clear();
    _backgroundLoadFuture = null;
    _cacheDir = null;
    _cacheDirInitialized = false;
  }
}
