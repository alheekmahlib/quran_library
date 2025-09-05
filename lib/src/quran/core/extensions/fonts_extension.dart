part of '/quran.dart';

/// Extension to handle font-related operations for the QuranCtrl class.
extension FontsExtension on QuranCtrl {
  /// يتحقق من إمكانية الوصول للإنترنت وإعدادات الشبكة
  /// Checks internet accessibility and network settings
  Future<bool> _checkNetworkConnectivity() async {
    try {
      // اختبار اتصال بسيط مع Google DNS
      // Simple connectivity test with Google DNS
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      log('Network connectivity check failed: $e', name: 'FontsDownload');
      return false;
    }
  }

  /// يقترح حلول لمشاكل الشبكة في macOS
  /// Suggests solutions for network issues on macOS
  void _showMacOSNetworkTroubleshooting() {
    Get.dialog(
      AlertDialog(
        title: const Text('مشكلة في الاتصال - Connection Issue'),
        content: const Text(
          'يبدو أن هناك مشكلة في الاتصال بالإنترنت أو إعدادات الشبكة في macOS.\n\n'
          'الحلول المقترحة:\n'
          '1. تحقق من اتصال الإنترنت\n'
          '2. أعد تشغيل التطبيق\n'
          '3. تحقق من إعدادات جدار الحماية\n'
          '4. جرب استخدام VPN\n\n'
          'It seems there\'s an internet connection or network settings issue on macOS.\n\n'
          'Suggested solutions:\n'
          '1. Check internet connection\n'
          '2. Restart the application\n'
          '3. Check firewall settings\n'
          '4. Try using a VPN',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('موافق - OK'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _tryAlternativeDownload();
            },
            child: const Text('جرب طريقة بديلة - Try Alternative'),
          ),
        ],
      ),
    );
  }

  /// طريقة بديلة للتحميل باستخدام Dio (للماك)
  /// Alternative download method using Dio (for macOS)
  Future<void> _downloadWithDio(String url, String savePath) async {
    try {
      final dio = Dio();

      // إعدادات خاصة لـ macOS
      // Special settings for macOS
      dio.options.headers = {
        'User-Agent': 'Flutter/Quran-Library-Dio',
        'Accept': '*/*',
        'Connection': 'keep-alive',
      };

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total * 100;
            state.fontsDownloadProgress.value = progress;
            update(['fontsDownloadingProgress']);
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
    } catch (e) {
      throw Exception('Dio download failed: $e');
    }
  }

  /// يجرب طريقة تحميل بديلة باستخدام Dio
  /// Tries alternative download method using Dio
  Future<void> _tryAlternativeDownload() async {
    try {
      log('Trying alternative download with Dio', name: 'FontsDownload');

      final zipPath = '${_dir.path}/quran_fonts.zip';

      await _downloadWithDio(
        'https://raw.githubusercontent.com/alheekmahlib/Islamic_database/main/quran_database/Quran%20Font/quran_fonts.zip',
        zipPath,
      );

      // إذا نجح التحميل، تابع مع استخراج الملفات
      // If download succeeds, continue with file extraction
      final zipFile = File(zipPath);
      await _extractAndProcessZip(zipFile);
    } catch (e) {
      log('Alternative download also failed: $e', name: 'FontsDownload');
      Get.snackbar(
        'خطأ - Error',
        'فشل في جميع طرق التحميل - All download methods failed',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// استخراج ومعالجة ملف ZIP
  /// Extract and process ZIP file
  Future<void> _extractAndProcessZip(File zipFile) async {
    try {
      final fontsDir = Directory('${_dir.path}/quran_fonts');

      final bytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      if (archive.isEmpty) {
        throw FormatException('Failed to extract ZIP file: Archive is empty');
      }

      // استخراج الملفات إلى مجلد الخطوط
      // Extract files to fonts directory
      for (final file in archive) {
        final filename = '${fontsDir.path}/${file.name}';
        if (file.isFile) {
          final outFile = File(filename);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      await QuranCtrl.instance.loadFontsQuran();

      // حفظ حالة التحميل في التخزين المحلي
      // Save download status in local storage
      GetStorage().write(_StorageConstants().isDownloadedCodeV2Fonts, true);
      state.fontsDownloadedList.add(0); // Font index 0 as default
      GetStorage().write(
          _StorageConstants().fontsDownloadedList, state.fontsDownloadedList);

      // تحديث حالة التحميل وإكمال شريط التقدم
      // Update download status and complete progress bar
      state.isDownloadedV2Fonts.value = true;
      state.isDownloadingFonts.value = false;
      state.isPreparingDownload.value = false;
      state.fontsDownloadProgress.value = 100.0;

      update(['fontsDownloadingProgress']);
      Get.forceAppUpdate();

      log('Fonts downloaded and extracted successfully', name: 'FontsDownload');
    } catch (e) {
      throw Exception('Failed to extract ZIP file: $e');
    }
  }

  /// Prepares fonts for the specified page index and adjacent pages.
  ///
  /// This method asynchronously loads the font for the given [pageIndex] and
  /// additionally preloads fonts for the next four pages if the [pageIndex] is
  /// less than 600, and the previous four pages if the [pageIndex] is greater
  /// than or equal to 4. This ensures smoother font loading experience as the
  /// user navigates through pages.
  ///
  /// [pageIndex] - The index of the page for which the font and its adjacent
  /// pages' fonts should be prepared.
  ///
  /// Returns a [Future] that completes when all specified fonts have been
  /// successfully loaded.
  Future<void> prepareFonts(int pageIndex, {bool isFontsLocal = false}) async {
    await loadFont(pageIndex, isFontsLocal: isFontsLocal);
    if (pageIndex < 600) {
      for (int i = pageIndex + 1; i < pageIndex + 1; i++) {
        await loadFont(i, isFontsLocal: isFontsLocal);
      }
    }
    if (pageIndex >= 4) {
      for (int i = pageIndex - 1; i > pageIndex - 1; i--) {
        await loadFont(i, isFontsLocal: isFontsLocal);
      }
    }
  }

  /// Loads a font from a ZIP file for the specified page index.
  ///
  /// This method asynchronously loads a font from a ZIP file based on the given
  /// [pageIndex]. The font is then available for use within the application.
  ///
  /// [pageIndex] - The index of the page for which the font should be loaded.
  ///
  /// Returns a [Future] that completes when the font has been successfully loaded.
  Future<void> loadFontFromZip(int pageIndex) async {
    try {
      final fontsDir = Directory('${_dir.path}/quran_fonts');

      // تحقق من الملفات داخل المجلد
      final files = await fontsDir.list().toList();
      log('Files in fontsDir: ${files.map((file) => file.path).join(', ')}');

      final fontFile =
          File('${fontsDir.path}/quran_fonts/p${(pageIndex + 2001)}.ttf');
      if (!await fontFile.exists()) {
        throw Exception("Font file not found for page: ${pageIndex + 1}");
      }

      final fontLoader = FontLoader('p${(pageIndex + 2001)}');
      fontLoader.addFont(_getFontLoaderBytes(fontFile));
      await fontLoader.load();
    } catch (e) {
      throw Exception("Failed to load font: $e");
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
    // if (GetStorage().read(StorageConstants().isDownloadedCodeV2Fonts) ??
    //     false || state.isDownloadingFonts.value) {
    //   return Future.value();
    // }

    // فحص الاتصال بالإنترنت أولاً (خاص بـ macOS)
    // Check internet connectivity first (specific for macOS)
    if (Platform.isMacOS) {
      final hasConnection = await _checkNetworkConnectivity();
      if (!hasConnection) {
        _showMacOSNetworkTroubleshooting();
        return;
      }
    }

    try {
      state.isPreparingDownload.value = true;
      state.isDownloadingFonts.value = true;
      update(['fontsDownloadingProgress']);

      // قائمة بالروابط البديلة للتحميل
      // List of alternative download URLs
      final urls = [
        'https://github.com/alheekmahlib/Islamic_database/raw/refs/heads/main/quran_database/Quran%20Font/quran_fonts.zip',
        'https://raw.githubusercontent.com/alheekmahlib/Islamic_database/main/quran_database/Quran%20Font/quran_fonts.zip',
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
                sendTimeout: Duration(seconds: 30),
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
      final fontsDir = Directory('${_dir.path}/quran_fonts');
      if (!await fontsDir.exists()) {
        await fontsDir.create(recursive: true);
      }

      // حفظ ملف ZIP إلى التطبيق
      final zipFile = File('${_dir.path}/quran_fonts.zip');
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
              throw FormatException(
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
            await QuranCtrl.instance.loadFontsQuran();
            // حفظ حالة التحميل في التخزين المحلي
            // Save download status in local storage
            GetStorage()
                .write(_StorageConstants().isDownloadedCodeV2Fonts, true);
            state.fontsDownloadedList.add(fontIndex);
            GetStorage().write(_StorageConstants().fontsDownloadedList,
                state.fontsDownloadedList);

            // تحديث حالة التحميل وإكمال شريط التقدم
            // Update download status and complete progress bar
            state.isDownloadedV2Fonts.value = true;
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

      // معالجة خاصة لأخطاء macOS
      // Special handling for macOS errors
      if (Platform.isMacOS &&
          e.toString().contains('Operation not permitted')) {
        _showMacOSNetworkTroubleshooting();
      }

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
    if (isFontsLocal) {
      return;
    } else {
      try {
        // تعديل المسار ليشمل المجلد الإضافي
        final fontFile = File(
            '${_dir.path}/quran_fonts/quran_fonts/p${(pageIndex + 2001)}.ttf');
        if (!await fontFile.exists()) {
          throw Exception("Font file not found for page: ${pageIndex + 2001}");
        }
        final fontLoader = FontLoader('p${(pageIndex + 2001)}');
        fontLoader.addFont(_getFontLoaderBytes(fontFile));
        await fontLoader.load();
      } catch (e) {
        throw Exception("Failed to load font: $e");
      }
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
      final fontsDir = Directory('${_dir.path}/quran_fonts');

      // التحقق من وجود مجلد الخطوط
      if (await fontsDir.exists()) {
        // حذف جميع الملفات والمجلدات داخل مجلد الخطوط
        await fontsDir.delete(recursive: true);
        log('Fonts directory deleted successfully.');

        // تحديث حالة التخزين المحلي
        GetStorage().write(_StorageConstants().isDownloadedCodeV2Fonts, false);
        GetStorage().write(_StorageConstants().fontsSelected, 0);
        // state.fontsDownloadedList.elementAt(fontIndex);
        GetStorage().write(
            _StorageConstants().fontsDownloadedList, state.fontsDownloadedList);
        state.isDownloadedV2Fonts.value = false;
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
