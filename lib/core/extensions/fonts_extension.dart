part of '../../quran.dart';

extension FontsExtension on QuranCtrl {
  Future<void> prepareFonts(int pageIndex) async {
    await loadFont(pageIndex);
    if (pageIndex < 608) {
      for (int i = pageIndex; i < 5; i++) {
        await loadFont(i);
      }
      if (pageIndex > 5) {
        for (int i = pageIndex; i < 5; i--) {
          await loadFont(i);
        }
      }
    }
  }

  Future<void> loadFontFromZip(int pageIndex) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory('${appDir.path}/quran_fonts');

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

  Future<void> downloadAllFontsZipFile(int fontIndex) async {
    // if (GetStorage().read(StorageConstants().isDownloadedCodeV2Fonts) ??
    //     false || state.isDownloadingFonts.value) {
    //   return Future.value();
    // }

    try {
      state.isDownloadingFonts.value = true;
      update(['fontsDownloadingProgress']);

      // تحميل الملف باستخدام http.Client
      final client = http.Client();
      final response = await client.send(http.Request(
        'GET',
        Uri.parse('https://archive.org/download/quran_fonts/quran_fonts.zip'),
      ));

      if (response.statusCode != 200) {
        throw Exception('Failed to download ZIP file: ${response.statusCode}');
      }

      // تحديد المسار الذي سيتم حفظ الملف فيه
      final appDir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory('${appDir.path}/quran_fonts');
      if (!await fontsDir.exists()) {
        await fontsDir.create(recursive: true);
      }

      // حفظ ملف ZIP إلى التطبيق
      final zipFile = File('${appDir.path}/quran_fonts.zip');
      final fileSink = zipFile.openWrite();

      // حجم الملف الإجمالي
      final contentLength = response.contentLength ?? 0;
      int totalBytesDownloaded = 0;

      // متابعة التدفق وكتابة البيانات في الملف مع حساب نسبة التحميل
      response.stream.listen(
        (List<int> chunk) {
          totalBytesDownloaded += chunk.length;
          fileSink.add(chunk);
          state.isDownloadingFonts.value = true;
          // حساب نسبة التحميل
          double progress = totalBytesDownloaded / contentLength * 100;
          state.fontsDownloadProgress.value = progress;
          // log('Download progress: ${progress.toStringAsFixed(2)}%');
          update(['fontsDownloadingProgress']);
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
            GetStorage()
                .write(StorageConstants().isDownloadedCodeV2Fonts, true);
            state.fontsDownloadedList.add(fontIndex);
            GetStorage().write(StorageConstants().fontsDownloadedList,
                state.fontsDownloadedList);
            state.isDownloadedV2Fonts.value = true;
            state.isDownloadingFonts.value = false;
            Get.forceAppUpdate();
            // update();
            log('Fonts unzipped successfully');
            // Get.back();
          } catch (e) {
            log('Failed to extract ZIP file: $e');
          }
        },
        onError: (error) {
          log('Error during download: $error');
          client.close();
        },
        cancelOnError: true,
      );
    } catch (e) {
      log('Failed to Download Code_v2 fonts: $e');
    }

    state.isDownloadingFonts.value = false;
    update(['fontsDownloadingProgress']);
  }

  Future<ByteData> _getFontLoaderBytes(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return ByteData.view(bytes.buffer);
    } catch (e) {
      throw Exception("Failed to get font loader bytes: $e");
    }
  }

  Future<void> loadFont(int pageIndex) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      // تعديل المسار ليشمل المجلد الإضافي
      final fontFile = File(
          '${appDir.path}/quran_fonts/quran_fonts/p${(pageIndex + 2001)}.ttf');
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

  Future<void> deleteFonts(int fontIndex) async {
    try {
      state.fontsDownloadedList.value = [];
      final appDir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory('${appDir.path}/quran_fonts');

      // التحقق من وجود مجلد الخطوط
      if (await fontsDir.exists()) {
        // حذف جميع الملفات والمجلدات داخل مجلد الخطوط
        await fontsDir.delete(recursive: true);
        log('Fonts directory deleted successfully.');

        // تحديث حالة التخزين المحلي
        GetStorage().write(StorageConstants().isDownloadedCodeV2Fonts, false);
        GetStorage().write(StorageConstants().fontsSelected, 0);
        // state.fontsDownloadedList.elementAt(fontIndex);
        GetStorage().write(
            StorageConstants().fontsDownloadedList, state.fontsDownloadedList);
        state.isDownloadedV2Fonts.value = false;
        state.fontsSelected2.value = 0;
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
