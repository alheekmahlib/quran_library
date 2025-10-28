part of '/quran.dart';

/// مُعرّف جيل لتحميل الخطوط يُستخدم لإلغاء دفعات قديمة عند تغيّر الصفحة بسرعة
/// Generation token to cancel outdated preloading batches when page changes quickly
// int _fontPreloadGeneration = 0;

/// Extension to handle font-related operations for the QuranCtrl class.
extension FontsExtension on QuranCtrl {
  bool get isPhones =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isFuchsia);

  String getFontFullPath(Directory fontsDir, int pageIndex) => isPhones
      ? '${fontsDir.path}/qcf4_woff/qcf4_woff/QCF4${((pageIndex + 1).toString().padLeft(3, '0'))}_X-Regular.woff'
      : '${fontsDir.path}/qcf4_ttf/qcf4_ttf/QCF4${((pageIndex + 1).toString().padLeft(3, '0'))}_X-Regular.ttf';

  String getFontPath(int pageIndex) =>
      'QCF4${((pageIndex + 1).toString().padLeft(3, '0'))}_X-Regular';

  /// URL مباشر لملف الخط على الويب (GitHub Raw)
  /// ملاحظة: بعض المستودعات/الفروع قد تختلف في المسار؛ جهّز بدائل متعددة وتحقّق بالتسلسل
  String getWebFontUrl(int pageIndex) {
    final id = (pageIndex + 1).toString().padLeft(3, '0');
    // المسار المرجّح (raw + main + مجلد واحد qcf4_woff)
    return 'https://raw.githubusercontent.com/alheekmahlib/Islamic_database/main/quran_database/Quran%20Font/qcf4_woff/QCF4${id}_X-Regular.woff';
  }

  /// جميع المسارات المرشّحة لتحميل الخط على الويب (WOFF أولاً ثم TTF كاحتياط)
  List<String> _webFontCandidateUrls(int pageIndex) {
    final id = (pageIndex + 1).toString().padLeft(3, '0');
    return [
      // raw.githubusercontent.com مع main
      'https://raw.githubusercontent.com/alheekmahlib/Islamic_database/main/quran_database/Quran%20Font/qcf4_woff/QCF4${id}_X-Regular.woff',
      'https://raw.githubusercontent.com/alheekmahlib/Islamic_database/main/quran_database/Quran%20Font/qcf4_ttf/QCF4${id}_X-Regular.ttf',
      // raw.githubusercontent.com مع refs/heads/main
      'https://raw.githubusercontent.com/alheekmahlib/Islamic_database/refs/heads/main/quran_database/Quran%20Font/qcf4_woff/QCF4${id}_X-Regular.woff',
      'https://raw.githubusercontent.com/alheekmahlib/Islamic_database/refs/heads/main/quran_database/Quran%20Font/qcf4_ttf/QCF4${id}_X-Regular.ttf',
      // github.com/raw كحلٍ أخير
      'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/quran_database/Quran%20Font/qcf4_woff/QCF4${id}_X-Regular.woff',
      'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/quran_database/Quran%20Font/qcf4_ttf/QCF4${id}_X-Regular.ttf',
    ];
  }

  // Deprecated: استخدم _getWebFontBytes بدلاً من ذلك
  // Future<ByteData> _getFontLoaderBytesFromNetwork(String url) async { ... }

  /// يحاول تحميل الخط من عدة روابط مرشّحة حتى ينجح
  Future<ByteData> _getWebFontBytes(int pageIndex) async {
    final dio = Dio();
    final candidates = _webFontCandidateUrls(pageIndex);
    DioException? lastError;
    for (final url in candidates) {
      try {
        final resp = await dio.get<List<int>>(url,
            options: Options(responseType: ResponseType.bytes, headers: {
              'Accept': '*/*',
              'Connection': 'keep-alive',
              'User-Agent': 'Flutter/Quran-Library',
            }));
        if (resp.statusCode == 200 &&
            resp.data != null &&
            resp.data!.isNotEmpty) {
          final buffer = Uint8List.fromList(List<int>.from(resp.data!)).buffer;
          return ByteData.view(buffer);
        }
      } on DioException catch (e) {
        lastError = e;
        // جرّب المرشح التالي
        continue;
      } catch (_) {
        // أي خطأ آخر، واصل المحاولة في الرابط التالي
        continue;
      }
    }
    // إذا فشلت كل الروابط
    throw Exception(
        'Failed to fetch web font for page ${(pageIndex + 1).toString().padLeft(3, '0')}. Last error: ${lastError?.message ?? 'unknown'}');
  }

  /// يقوم بتحميل وتسجيل جميع الصفحات المحفوظة دفعة واحدة (Bulk)
  /// - يقرأ القائمة من GetStorage.loadedFontPages
  /// - يتخطّى الصفحات المسجّلة في الذاكرة state.loadedFontPages
  /// - يعمل على دفعات صغيرة لتجنّب حجب واجهة المستخدم
  // Future<void> loadPersistedFontsBulk({
  //   List<int>? pages,
  //   int batchSize = 24,
  // }) async {
  //   try {
  //     final storage = GetStorage();
  //     final stored = (pages ??
  //             (storage
  //                     .read<List<dynamic>>(_StorageConstants().loadedFontPages)
  //                     ?.cast<int>() ??
  //                 []))
  //         .where((p) => p >= 0 && p < 604)
  //         .toSet()
  //         .toList()
  //       ..sort();

  //     if (stored.isEmpty) return;

  //     // تحميل على دفعات صغيرة لتجنّب الجانك
  //     for (int i = 0; i < stored.length; i += batchSize) {
  //       final chunk =
  //           stored.sublist(i, (i + batchSize).clamp(0, stored.length));
  //       for (final page in chunk) {
  //         // سيقوم loadFont بتخطّي الصفحة إذا كانت محمّلة مسبقًا
  //         await loadFont(page, isFontsLocal: true);
  //       }
  //       // بعد كل دفعة على المنصات غير الويب: أعد بناء الواجهة كي تنعكس الخطوط
  //       // On non-web, a chunk-level rebuild is sufficient; web already rebuilds per page load
  //       if (!kIsWeb && !isClosed) {
  //         try {
  //           update();
  //         } catch (_) {}
  //       }
  //       // فسح المجال للإطار التالي
  //       await Future.delayed(const Duration(milliseconds: 1));
  //     }
  //   } catch (e) {
  //     log('Bulk load persisted fonts failed: $e', name: 'FontsLoad');
  //   }
  // }
  Future<void> prepareFonts(int pageIndex, {bool isFontsLocal = false}) async {
    SchedulerBinding.instance.scheduleTask(() async {
      // QuranCtrl.instance.prepareFonts(index);
      await QuranCtrl.instance.loadFont(pageIndex);

      // الصفحات المجاورة: ±2 كتحضير مسبق أوسع لتقليل أي نتش متبقٍ
      final neighbors = [-2, -1, 1, 2];
      final candidates = neighbors
          .map((o) => pageIndex + o)
          .where((i) => i >= 0 && i < 604)
          .toList();
      for (final i in candidates) {
        try {
          SchedulerBinding.instance.scheduleTask(() async {
            await QuranCtrl.instance.loadFont(i);
          }, Priority.idle);
          // await loadFont(i, isFontsLocal: isFontsLocal);
        } catch (_) {
          // تجاهل أخطاء التحميل المسبق
        }
      }
    }, Priority.animation);
  }

  /// تهيئة خاملة لخطوط صفحات مجاورة حول [centerIndex]
  /// - على الهواتف: نطاق ±1
  /// - على الأجهزة الأخرى: نطاق ±2
  /// تُنفَّذ بوقت الخمول لتجنّب حجب واجهة المستخدم.
  void idlePreloadFontsAround(int centerIndex) {
    // لا تنفّذ إذا كان المتحكم مغلقًا/محرّرًا
    if (isClosed) return;

    // تحديد نصف القطر حسب الجهاز
    final radius = isPhones ? 1 : 2;
    final targets = <int>{};
    for (int o = -radius; o <= radius; o++) {
      final idx = centerIndex + o;
      if (idx >= 0 && idx < 604) targets.add(idx);
    }
    // تجنّب تحميل الصفحات المسجلة بالفعل
    targets.removeWhere((i) => state.loadedFontPages.contains(i));
    if (targets.isEmpty) return;

    // جدولة بوقت الخمول
    SchedulerBinding.instance.scheduleTask(() async {
      if (isClosed) return;
      for (final t in targets) {
        try {
          await loadFont(t, isFontsLocal: true);
        } catch (_) {
          // تجاهل فشل صفحة واحدة
        }
      }
    }, Priority.idle);
  }

  /// Loads a font from a ZIP file for the specified page index.
  ///
  /// This method asynchronously loads a font from a ZIP file based on the given
  /// [pageIndex]. The font is then available for use within the application.
  ///
  /// [pageIndex] - The index of the page for which the font should be loaded.
  ///
  /// Returns a [Future] that completes when the font has been successfully loaded.
  Future<void> loadFontFromZip([int? pageIndex]) async {
    try {
      // مسار مجلد الخطوط بعد فك الضغط
      final fontsDir = Directory(
          isPhones ? '${_dir.path}/qcf4_woff' : '${_dir.path}/qcf4_ttf');

      final loadedSet = state.loadedFontPages; // في الذاكرة

      // حمّل جميع الخطوط المتاحة 001..604
      for (int i = 0; i < 604; i++) {
        try {
          // إذا كان محمّلًا في هذه الجلسة، تخطّه
          if (loadedSet.contains(i)) continue;

          final fontPath = getFontFullPath(fontsDir, i);
          final fontFile = File(fontPath);
          if (!await fontFile.exists()) {
            // قد تكون بعض الملفات غير موجودة في مجموعة معينة
            continue;
          }

          final loader = FontLoader(getFontPath(i));
          loader.addFont(_getFontLoaderBytes(fontFile));
          await loader.load();
          loadedSet.add(i);
        } catch (e) {
          // تجاهل فشل صفحة واحدة واستمر
          log('Failed to register font for page ${i + 1}: $e',
              name: 'FontsLoad');
          continue;
        }
      }

      // حفظ الصفحات التي تم تحميل خطوطها
      GetStorage()
          .write(_StorageConstants().loadedFontPages, loadedSet.toList());
    } catch (e) {
      throw Exception("Failed to load fonts from disk: $e");
    }
  }

  /// Downloads a zip file containing all fonts for the specified font index.
  ///
  /// This method asynchronously downloads a zip file that contains all the fonts
  /// associated with the given [fontIndex]. The downloaded file will be saved
  /// locally for later use.
  ///
  /// [fontIndex] - The index of the font set to be downloaded.
  ///
  /// Returns a [Future] that completes when the download is finished.
  Future<void> downloadAllFontsZipFile(int fontIndex) async {
    // على الويب لا نحتاج التنزيل، سنحمّل مباشرة عند الحاجة
    if (kIsWeb) {
      state.isFontDownloaded.value = true;
      state.isDownloadingFonts.value = false;
      state.isPreparingDownload.value = false;
      update(['fontsDownloadingProgress']);
      return;
    }
    // if (GetStorage().read(StorageConstants().isDownloadedCodeV2Fonts) ??
    //     false || state.isDownloadingFonts.value) {
    //   return Future.value();
    // }

    try {
      state.isPreparingDownload.value = true;
      state.isDownloadingFonts.value = true;
      update(['fontsDownloadingProgress']);

      // قائمة بالروابط البديلة للتحميل
      // List of alternative download URLs
      final urls = (!kIsWeb &&
              (Platform.isAndroid || Platform.isIOS || Platform.isFuchsia))
          ? [
              'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/quran_database/Quran%20Font/qcf4_woff.zip',
              'https://raw.githubusercontent.com/alheekmahlib/Islamic_database/main/quran_database/Quran%20Font/qcf4_woff.zip',
            ]
          : [
              'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/quran_database/Quran%20Font/qcf4_ttf.zip',
              'https://raw.githubusercontent.com/alheekmahlib/Islamic_database/main/quran_database/Quran%20Font/qcf4_ttf.zip',
            ];
      // تحميل الملف باستخدام Dio

      // تحميل الملف باستخدام http.Client مع إعدادات محسنة للماك
      // Download file using http.Client with improved settings for macOS
      // final response = dio.get(
      //   'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/quran_database/Quran%20Font/quran_fonts.zip',
      //   options: Options(responseType: ResponseType.stream),
      // );
      final dio = Dio();
      String? successUrl;
      late Response response;

      // جرب كل رابط حتى ينجح واحد منها
      // Try each URL until one succeeds
      for (String url in urls) {
        try {
          log('Attempting to download from: $url', name: 'FontsDownload');

          response = await dio.get(url,
              options: Options(
                responseType: ResponseType.stream,
                sendTimeout: const Duration(seconds: 30),
                headers: {
                  'User-Agent': 'Flutter/Quran-Library',
                  'Accept': '*/*',
                  'Connection': 'keep-alive',
                  'Accept-Encoding': 'identity',
                },
              ));

// التحقق من نجاح الاتصال بأحد الروابط
          // Check if connection to any URL succeeded
          if (response.statusCode != 200) {
            log('Failed to connect to $url: ${response.statusCode}',
                name: 'FontsDownload');
            break;
          }

          log('Download started successfully from: $successUrl',
              name: 'FontsDownload');
          if (response.statusCode == 200) {
            successUrl = url;
            log('Successfully connected to: $url', name: 'FontsDownload');
            break;
          }
        } catch (e) {
          log('Failed to connect to $url: $e', name: 'FontsDownload');
          continue;
        }
      }

      // تحديد المسار الذي سيتم حفظ الملف فيه
      // final fontsDir = Directory('${_dir.path}/quran_fonts');
      final fontsDir = Directory(
          isPhones ? '${_dir.path}/qcf4_woff' : '${_dir.path}/qcf4_ttf');
      if (!await fontsDir.exists()) {
        await fontsDir.create(recursive: true);
      }

      // حفظ ملف ZIP إلى التطبيق
      // final zipFile = File('${_dir.path}/quran_fonts.zip');
      final zipFile = File(isPhones
          ? '${_dir.path}/qcf4_woff.zip'
          : '${_dir.path}/qcf4_ttf.zip');
      final fileSink = zipFile.openWrite();

      // حجم الملف الإجمالي
      final contentLength = int.tryParse(
              response.headers.value(Headers.contentLengthHeader) ?? '0') ??
          0;
      int totalBytesDownloaded = 0;

      // متابعة التدفق وكتابة البيانات في الملف مع حساب نسبة التحميل
      (response.data as ResponseBody).stream.listen(
        (List<int> chunk) {
          totalBytesDownloaded += chunk.length;
          fileSink.add(chunk);
          state.isDownloadingFonts.value = true;
          state.isPreparingDownload.value = false;
          // حساب نسبة التحميل
          if (contentLength > 0) {
            double progress = totalBytesDownloaded / contentLength * 100;
            state.fontsDownloadProgress.value = progress;
            log('Download progress: ${progress.toStringAsFixed(2)}%',
                name: 'FontsDownload');
            update(['fontsDownloadingProgress']);
          }
        },
        onDone: () async {
          await fileSink.flush();
          await fileSink.close();

          // فك ضغط الـ ZIP بعد إغلاق الملف بنجاح
          try {
            // التحقق من أن الملف تم تنزيله بالكامل
            final zipFileSize = await zipFile.length();
            log('Downloaded ZIP file size: $zipFileSize bytes');

            if (zipFileSize == 0) {
              throw Exception('Downloaded ZIP file is empty');
            }

            // فك ضغط الـ ZIP
            final bytes = zipFile.readAsBytesSync();
            final archive = ZipDecoder().decodeBytes(bytes);

            if (archive.isEmpty) {
              throw const FormatException(
                  'Failed to extract ZIP file: Archive is empty');
            }

            // استخراج الملفات إلى مجلد الخطوط
            for (final file in archive) {
              final filename = '${fontsDir.path}/${file.name}';
              if (file.isFile) {
                final outFile = File(filename);
                await outFile.create(recursive: true);
                await outFile.writeAsBytes(file.content as List<int>);
                // log('Extracted file: $filename'); // سجل لاستخراج الملف
              } else {
                log('Skipped directory: ${file.name}');
              }
            }

            // تحقق من وجود الملفات في المجلد
            final files = await fontsDir.list().toList();
            if (files.isEmpty) {
              log('No files found in fontsDir after extraction');
            } else {
              log('Files in fontsDir after extraction: ${files.map((file) => file.path).join(', ')}');
            }
            // await QuranCtrl.instance.loadFontsQuran();
            // بعد فك الضغط، حمّل (سجّل) كل الخطوط دفعة واحدة واحفظ النتائج
            // await loadFontFromZip();
            // .then((_) =>
            //     loadPersistedFontsBulk(pages: List.generate(604, (i) => i)));
            // حفظ حالة التحميل في التخزين المحلي
            // Save download status in local storage
            GetStorage()
                .write(_StorageConstants().isDownloadedCodeV4Fonts, true);
            state.fontsDownloadedList.add(fontIndex);
            GetStorage().write(_StorageConstants().fontsDownloadedList,
                state.fontsDownloadedList);

            // تحديث حالة التحميل وإكمال شريط التقدم
            // Update download status and complete progress bar
            state.isFontDownloaded.value = true;
            state.isDownloadingFonts.value = false;
            state.isPreparingDownload.value = false;
            state.fontsDownloadProgress.value = 100.0;

            update(['fontsDownloadingProgress']);
            Get.forceAppUpdate();

            log('Fonts unzipped successfully', name: 'FontsDownload');
            // Get.back();
          } catch (e) {
            log('Failed to extract ZIP file: $e');
          }
        },
        onError: (error) {
          log('Error during download: $error');
          dio.close();
        },
        cancelOnError: true,
      );
    } catch (e) {
      log('Failed to Download Code_v2 fonts: $e', name: 'FontsDownload');

      // تحديث حالة التحميل في حالة فشل العملية
      // Update download status if operation fails
      state.isDownloadingFonts.value = false;
      state.isPreparingDownload.value = false;
      state.fontsDownloadProgress.value = 0.0;
      update(['fontsDownloadingProgress']);

      // رمي استثناء ليتم التعامل معه في الدالة الأم
      // Throw exception to be handled in parent function
      throw Exception('Download failed: $e');
    }
  }

  Future<ByteData> _getFontLoaderBytes(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return ByteData.view(bytes.buffer);
    } catch (e) {
      throw Exception("Failed to get font loader bytes: $e");
    }
  }

  /// Loads the font for the specified page index.
  ///
  /// This method asynchronously loads the font for the given [pageIndex].
  /// The font is then available for use within the application.
  ///
  /// [pageIndex] - The index of the page for which the font should be loaded.
  ///
  /// Returns a [Future] that completes when the font has been successfully loaded.
  Future<void> loadFont(int pageIndex, {bool isFontsLocal = false}) async {
    try {
      // إذا كان الخط لهذه الصفحة محملًا، لا تعِد التحميل
      // If font for this page is already loaded, skip
      if (state.loadedFontPages.contains(pageIndex)) {
        return;
      }
      final fontLoader = FontLoader(getFontPath(pageIndex));
      if (kIsWeb) {
        fontLoader.addFont(_getWebFontBytes(pageIndex));
      } else {
        // التحميل من التخزين المحلي (سواء كانت isFontsLocal true أم false)
        final fontFile = File(getFontFullPath(_dir, pageIndex));
        if (!await fontFile.exists()) {
          throw Exception(
              "Font file not exists for page: ${(pageIndex + 1).toString().padLeft(3, '0')}");
        }
        fontLoader.addFont(_getFontLoaderBytes(fontFile));
      }
      await fontLoader.load();
      state.loadedFontPages.add(pageIndex);
      // حفظ القائمة لتسريع الجلسات اللاحقة
      GetStorage().write(
          _StorageConstants().loadedFontPages, state.loadedFontPages.toList());
      // على الويب بشكل خاص: أعد بناء الواجهة لتفعيل الخط فورًا دون قلب الصفحة
      if (kIsWeb && !isClosed) {
        try {
          update();
        } catch (_) {}
      }
    } catch (e) {
      throw Exception(
          "Failed to load font for page ${(pageIndex + 1).toString().padLeft(3, '0')}: $e");
    }
  }

  /// Deletes the font at the specified index.
  ///
  /// This method asynchronously deletes the font from the storage or database
  /// based on the provided [fontIndex].
  ///
  /// [fontIndex]: The index of the font to be deleted.
  ///
  /// Returns a [Future] that completes when the font has been deleted.
  Future<void> deleteFonts() async {
    try {
      state.fontsDownloadedList.value = [];
      final fontsDir = Directory(
          isPhones ? '${_dir.path}/qcf4_woff' : '${_dir.path}/qcf4_ttf');

      // التحقق من وجود مجلد الخطوط
      if (await fontsDir.exists()) {
        // حذف جميع الملفات والمجلدات داخل مجلد الخطوط
        await fontsDir.delete(recursive: true);
        log('Fonts directory deleted successfully.');

        // تحديث حالة التخزين المحلي
        GetStorage().write(_StorageConstants().isDownloadedCodeV4Fonts, false);
        GetStorage().write(_StorageConstants().fontsSelected, 0);
        // state.fontsDownloadedList.elementAt(fontIndex);
        GetStorage().write(
            _StorageConstants().fontsDownloadedList, state.fontsDownloadedList);
        state.isFontDownloaded.value = false;
        state.fontsSelected.value = 0;
        state.fontsDownloadProgress.value = 0;
        Get.forceAppUpdate();
      } else {
        log('Fonts directory does not exist.');
      }
    } catch (e) {
      log('Failed to delete fonts: $e');
    }
  }

  Future<void> deleteOldFonts() async {
    if (GetStorage().read('isDownloadedCodeV2Fonts') == true) {
      try {
        state.fontsDownloadedList.value = [];
        final fontsDir = Directory('${_dir.path}/quran_fonts');

        // التحقق من وجود مجلد الخطوط
        if (await fontsDir.exists()) {
          // حذف جميع الملفات والمجلدات داخل مجلد الخطوط
          await fontsDir.delete(recursive: true);
          log('Fonts directory deleted successfully.');

          // تحديث حالة التخزين المحلي
          GetStorage().write('isDownloadedCodeV2Fonts', false);
          GetStorage().write(_StorageConstants().fontsSelected, 0);
          // state.fontsDownloadedList.elementAt(fontIndex);
          GetStorage().write(_StorageConstants().fontsDownloadedList,
              state.fontsDownloadedList);
          state.isFontDownloaded.value = false;
          state.fontsSelected.value = 0;
          state.fontsDownloadProgress.value = 0;
          Get.forceAppUpdate();
        } else {
          log('Fonts directory does not exist.');
        }
      } catch (e) {
        log('Failed to delete fonts: $e');
      }
    }
  }

  /// يحمّل الخطوط في isolate منفصل
  Future<void> loadFontsInBackground(List<int> pages) async {
    await compute(_loadFontsIsolate, pages);
  }

  /// دالة الـ isolate
  static Future<void> _loadFontsIsolate(List<int> pages) async {
    for (final page in pages) {
      try {
        final loader = FontLoader('p$page');
        final fontData = rootBundle.load('fonts/p$page.ttf');
        loader.addFont(fontData);
        await loader.load();
      } catch (e) {
        // تجاهل الأخطاء في الـ isolate
      }
      // فترة راحة صغيرة
      await Future.delayed(const Duration(microseconds: 500));
    }
  }
}
