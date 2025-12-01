// ignore_for_file: use_build_context_synchronously

part of '../../audio.dart';

extension AyahCtrlExtension on AudioCtrl {
  /// single Ayah
  ///
  Future<void> _playSingleAyahFile(
      BuildContext context, int currentAyahUniqueNumber) async {
    state.tmpDownloadedAyahsCount = 0;
    // لا تعتمد على التخزين فقط؛ تحقق من الواقع (غير الويب)
    bool isSurahDownloaded = false;
    if (!kIsWeb) {
      isSurahDownloaded = await isAyahSurahFullyDownloaded(currentSurahNumber);
    }

    try {
      // إيقاف أي تشغيل سابق / Stop any previous playback
      await state.stopAllAudio();

      QuranCtrl.instance.toggleAyahSelection(state.currentAyahUniqueNumber);
      if (kIsWeb) {
        await state.audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(currentAyahUrl),
            tag: mediaItem,
          ),
        );
      } else {
        final filePath = isSurahDownloaded
            ? join((await state.dir).path, currentAyahFileName)
            : await _downloadFileIfNotExist(currentAyahUrl, currentAyahFileName,
                context: context, ayahUqNumber: currentAyahUniqueNumber);

        await state.audioPlayer.setAudioSource(
          AudioSource.file(
            filePath,
            tag: mediaItem,
          ),
        );
      }
      state.isPlaying.value = true;
      await state.audioPlayer.play();
      log('تحميل $currentAyahFileName تم بنجاح.');
      state._playerStateSubscription ??=
          state.audioPlayer.playerStateStream.listen((d) async {
        if (d.processingState == ProcessingState.completed) {
          state.isPlaying.value = false;
          await state.audioPlayer.stop();
        }
      });
      return;
    } catch (e) {
      state.isPlaying.value = false;
      await state.audioPlayer.stop();
      log('Error in playFile: $e', name: 'AudioController');
    }
  }

  /// play Ayahs
  /// تشغيل الآيات
  Future<void> _playAyahsFile(BuildContext context, int currentAyahUniqueNumber,
      {AyahAudioStyle? ayahAudioStyle,
      AyahDownloadManagerStyle? ayahDownloadManagerStyle,
      bool? isDarkMode}) async {
    state.tmpDownloadedAyahsCount = 0;
    final ayahsFilesNames = selectedSurahAyahsFileNames;
    bool isDark = isDarkMode ??
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    log('isDarkMode2: $isDarkMode', name: 'AudioController');
    if (!kIsWeb) {
      // إذا لم تكن آيات السورة محمّلة بالكامل، افتح bottomSheet لإدارة التحميل
      final isSurahFullyDownloaded =
          await isAyahSurahFullyDownloaded(currentSurahNumber);
      if (!isSurahFullyDownloaded) {
        await _showAyahDownloadBottomSheet(
          context,
          initialSurahToDownload: currentSurahNumber,
          style: AyahDownloadManagerStyle.defaults(
              isDark: isDark, context: context),
          ayahStyle: AyahAudioStyle.defaults(isDark: isDark, context: context),
          isDark: isDark,
        );
        // بعد إغلاق الـ bottomSheet، أعد التحقق
        final downloadedNow =
            await isAyahSurahFullyDownloaded(currentSurahNumber);
        if (!downloadedNow) {
          // المستخدم أغلق أو لم يكتمل التحميل
          return;
        }
      }
    }

    // عند هذه النقطة كل الآيات محمّلة بالكامل، يمكن إنشاء المصادر وتشغيلها
    try {
      // أوقف أي تشغيل قائم، وألغِ جميع الاشتراكات القديمة قبل إعداد قائمة جديدة
      await state.audioPlayer.stop();
      state.cancelAllSubscriptions();

      // إنشاء مصادر الصوت / Create audio sources
      final List<AudioSource> audioSources;
      if (kIsWeb) {
        audioSources = List.generate(
          ayahsFilesNames.length,
          (i) => AudioSource.uri(
            Uri.parse(selectedSurahAyahsUrls[i]),
            tag: mediaItemsForCurrentSurah[i],
          ),
        );
      } else {
        final directory = await state.dir;
        audioSources = List.generate(
          ayahsFilesNames.length,
          (i) => AudioSource.file(
            join(directory.path, ayahsFilesNames[i]),
            tag: mediaItemsForCurrentSurah[i],
          ),
        );
      }

      if (!kIsWeb) {
        // التأكد من وجود ملفات الصوت / Verify audio files exist
        final directory = await state.dir;
        for (int i = 0; i < ayahsFilesNames.length; i++) {
          final filePath = join(directory.path, ayahsFilesNames[i]);
          if (!await File(filePath).exists()) {
            log('Audio file does not exist: $filePath',
                name: 'AudioController');
            throw Exception('ملف الصوت غير موجود: ${ayahsFilesNames[i]}');
          }
        }
      }

      // احسب فهرس البداية اعتمادًا على ترتيب آيات السورة الحالية لضمان الدقة
      final computedInitialIndex = currentAyahsSurah.ayahs
          .indexWhere((a) => a.ayahUQNumber == currentAyahUniqueNumber);
      final initialIndex = computedInitialIndex >= 0 ? computedInitialIndex : 0;

      // تعيين مصدر الصوت مع الفهرس الصحيح باستخدام واجهة playlist الحديثة
      await state.audioPlayer.setAudioSources(
        audioSources,
        initialIndex: initialIndex,
      );

      // إعدادات قائمة التشغيل: تعطيل العشوائي والتكرار لضمان انتقال تسلسلي
      await state.audioPlayer.setShuffleModeEnabled(false);
      await state.audioPlayer.setLoopMode(LoopMode.off);

      log('${'-' * 30} player is starting.. ${'-' * 30}',
          name: 'AudioController');

      // الاستماع لتغييرات الفهرس عبر sequenceStateStream (أوثق مع واجهة playlist)
      int? lastHandledIndex;
      int? lastHandledAyahUQ = state.currentAyahUniqueNumber;
      state._currentIndexSubscription =
          state.audioPlayer.sequenceStateStream.listen((sequenceState) async {
        final index = sequenceState.currentIndex;
        final currentIndex = (state.audioPlayer.currentIndex ?? 0);
        log('seq.index: $index | player.currentIndex: $currentIndex',
            name: 'index');
        if (index == null || index < 0 || index >= ayahsFilesNames.length) {
          return;
        }
        // تجاهل التكرارات لنفس الفهرس لتقليل الضجيج
        if (lastHandledIndex == index) {
          return;
        }
        lastHandledIndex = index;

        // احسب الآية الفريدة قبل وبعد للتأكد من تبدّل الصفحة
        final prevAyahUQ = lastHandledAyahUQ;
        final newAyahUQ = currentAyahsSurah.ayahs[index].ayahUQNumber;
        lastHandledAyahUQ = newAyahUQ;

        // حدّث رقم الآية الحالية بحسب الفهرس الجديد
        state.currentAyahUniqueNumber = newAyahUQ;

        // حدّث التحديد البصري للآية (مرة واحدة فقط عند تغيّر الآية)
        QuranCtrl.instance.toggleAyahSelection(state.currentAyahUniqueNumber);

        // إن تغيّرت الصفحة، حرّك صفحات المصحف بسلاسة
        if (prevAyahUQ != null) {
          final prevPage =
              QuranCtrl.instance.getPageNumberByAyahUqNumber(prevAyahUQ);
          final newPage = QuranCtrl.instance
              .getPageNumberByAyahUqNumber(state.currentAyahUniqueNumber);
          if (newPage != prevPage) {
            log('Page changed: $prevPage -> $newPage, animating...',
                name: 'AudioController');
            // animateToPage يستقبل فهرسًا صفريًا
            await QuranCtrl.instance.quranPagesController.animateToPage(
                newPage - 1,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut);
          }
        }
        log('Current playing index: $index', name: 'AudioController');
      });

      state.isPlaying.value = true;
      await state.audioPlayer.play();

      // استخدام اشتراك واحد لإدارة اكتمال قائمة التشغيل (نهاية السورة)
      state._playerStateSubscription =
          state.audioPlayer.playerStateStream.listen((d) async {
        if (d.processingState == ProcessingState.completed) {
          // اكتملت قائمة التشغيل الحالية
          log('Surah playlist completed. Stopping playback.',
              name: 'AudioController');
          state.isPlaying.value = false;
          await state.audioPlayer.stop();
        }
      });
    } catch (e) {
      state.isPlaying.value = false;
      await state.audioPlayer.stop();
      log('Error in ayahs playFile: $e', name: 'AudioController');

      // إظهار رسالة خطأ للمستخدم / Show error message to user
      ToastUtils().showToast(context, 'خطأ في تشغيل الآيات: ${e.toString()}');
    }
  }

  Future<void> playAyah(BuildContext context, int currentAyahUniqueNumber,
      {required bool playSingleAyah,
      AyahAudioStyle? ayahAudioStyle,
      AyahDownloadManagerStyle? ayahDownloadManagerStyle,
      bool? isDarkMode}) async {
    // التحقق من إمكانية التشغيل / Check if playback is allowed
    if (!await canPlayAudio()) {
      return;
    }

    log('isDarkMode: $isDarkMode', name: 'AudioController');

    state.playSingleAyahOnly = playSingleAyah;
    state.currentAyahUniqueNumber = currentAyahUniqueNumber;
    QuranCtrl.instance.isShowControl.value = true;
    // أوقف أي تشغيل قائم لتجنّب عاديات إعادة التشغيل
    if (state.audioPlayer.playing) await pausePlayer();
    Future.delayed(
      const Duration(milliseconds: 400),
      () => QuranCtrl.instance.state.isPlayExpanded.value = true,
    );

    if (playSingleAyah) {
      await _playSingleAyahFile(context, currentAyahUniqueNumber);
    } else {
      bool isDark = isDarkMode ??
          MediaQuery.of(context).platformBrightness == Brightness.dark;
      await _playAyahsFile(
        context,
        currentAyahUniqueNumber,
        ayahAudioStyle: ayahAudioStyle ??
            AyahAudioStyle.defaults(isDark: isDark, context: context),
        ayahDownloadManagerStyle: ayahDownloadManagerStyle ??
            AyahDownloadManagerStyle.defaults(isDark: isDark, context: context),
        isDarkMode: isDark,
      );
    }
    // }
  }

  Future<void> skipNextAyah(BuildContext context, int ayahUniqueNumber) async {
    if (state.playSingleAyahOnly) await pausePlayer();
    if (ayahUniqueNumber == 6236 || isLastAyahInSurah) {
      return;
    }
    if (isLastAyahInPageButNotInSurah) {
      await moveToNextPage();
    }
    state.currentAyahUniqueNumber += 1;
    QuranCtrl.instance.toggleAyahSelection(state.currentAyahUniqueNumber,
        forceAddition: true);
    if (state.playSingleAyahOnly) {
      return _playSingleAyahFile(context, ayahUniqueNumber);
    } else {
      return state.audioPlayer.seekToNext();
    }
  }

  Future<void> skipPreviousAyah(
      BuildContext context, int ayahUniqueNumber) async {
    if (state.playSingleAyahOnly) await pausePlayer();
    if (ayahUniqueNumber == 1 || isFirstAyahInSurah) {
      return;
    }

    if (isFirstAyahInPageButNotInSurah) {
      await moveToPreviousPage();
    }
    state.currentAyahUniqueNumber -= 1;
    QuranCtrl.instance.toggleAyahSelection(state.currentAyahUniqueNumber,
        forceAddition: true);
    if (state.playSingleAyahOnly) {
      return _playSingleAyahFile(context, ayahUniqueNumber);
    } else {
      return state.audioPlayer.seekToPrevious();
    }
  }

  Future<void> moveToNextPage({int? customPageIndex}) {
    return QuranCtrl.instance.quranPagesController.animateToPage(
        (customPageIndex ?? QuranCtrl.instance.state.currentPageNumber.value),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut);
  }

  Future<void> moveToPreviousPage({bool withScroll = true}) {
    return QuranCtrl.instance.quranPagesController.animateToPage(
        (QuranCtrl.instance.state.currentPageNumber.value - 2),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut);
  }

  /// تحديث خريطة الآيات المحملة - Update downloaded ayahs map
  Future<void> _updateDownloadedAyahsMap() async {
    if (kIsWeb) {
      for (final surah in QuranCtrl.instance.surahs) {
        for (final ayah in surah.ayahs) {
          state.ayahsDownloadStatus[ayah.ayahUQNumber] = false;
        }
      }
      update(['ayahDownloadManager']);
      return;
    }
    final dir = await state.dir;
    for (final surah in QuranCtrl.instance.surahs) {
      for (final ayah in surah.ayahs) {
        try {
          final fileName = _ayahFileNameFor(surah.surahNumber, ayah.ayahNumber);
          final path = join(dir.path, fileName);
          final exists = await File(path).exists();
          state.ayahsDownloadStatus[ayah.ayahUQNumber] = exists;
        } catch (_) {
          // تجاهل أي خطأ في الحساب واستمر
          state.ayahsDownloadStatus[ayah.ayahUQNumber] = false;
        }
      }
    }
    // تحديث واجهة مدير تنزيل الآيات بعد المزامنة
    update(['ayahDownloadManager']);
  }

  /// حالة تحميل آيات السورة بالكامل حسب القارئ الحالي
  Future<bool> isAyahSurahFullyDownloaded(int surahNumber) async {
    if (kIsWeb) return false;
    final key = 'surah_$surahNumberـ${state.ayahReaderIndex.value}';
    // أولاً تحقّق من الملفات فعلياً
    try {
      final surah = QuranCtrl.instance.surahs
          .firstWhere((s) => s.surahNumber == surahNumber);
      final dir = await state.dir;
      for (final ayah in surah.ayahs) {
        final fileName = _ayahFileNameFor(surahNumber, ayah.ayahNumber);
        final path = join(dir.path, fileName);
        if (!await File(path).exists()) {
          // تأكد من تخزين الحالة كغير محمّلة
          state.box.write(key, false);
          return false;
        }
      }
      // إذا وصلت هنا فكل الملفات موجودة
      state.box.write(key, true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// اسم ملف الآية لقارئ الآيات الحالي (حسب مصدر الروابط)
  String _ayahFileNameFor(int surahNumber, int ayahNumberInSurah) {
    if (ReadersConstants.activeAyahReaders[state.ayahReaderIndex.value].url ==
        ReadersConstants.ayahs1stSource) {
      // المصدر الأول يعتمد على الرقم الفريد للآية
      final aq = QuranCtrl.instance.surahs
          .firstWhere((s) => s.surahNumber == surahNumber)
          .ayahs[ayahNumberInSurah - 1]
          .ayahUQNumber;
      return '$ayahReaderValue/$aq.mp3';
    } else {
      final s = surahNumber.toString().padLeft(3, '0');
      final a = ayahNumberInSurah.toString().padLeft(3, '0');
      return '$ayahReaderValue/$s$a.mp3';
    }
  }

  /// بدء تحميل آيات سورة معيّنة بالكامل (متسلسلًا) مع تحديث الحالة
  Future<void> startDownloadAyahSurah(int surahNumber,
      {BuildContext? context}) async {
    if (kIsWeb) {
      // على الويب لا ندير تنزيلات محلية
      return;
    }
    // منع تشغيل صوت أثناء التحميل لتجنّب إلغاء التحميل
    await state.audioPlayer.pause();

    try {
      // علّم أن هناك تحميل جارٍ لهذه السورة تحديدًا
      state.currentDownloadingAyahSurahNumber.value = surahNumber;
      state.isDownloading.value = true;
      final surah = QuranCtrl.instance.surahs
          .firstWhere((s) => s.surahNumber == surahNumber);
      final ayahs = surah.ayahs;
      state.snackBarShownForBatch = false;
      state.cancelRequested.value = false;

      // تحميل متسلسل لضمان ثبات cancelToken والحالة
      for (final ayah in ayahs) {
        if (state.cancelRequested.value) {
          log('تم طلب إيقاف التحميل - إيقاف فوري للدُفعة');
          // حدّث الواجهة لإخفاء زر الإيقاف وإعادة تفعيل أزرار التحميل
          update(['ayahDownloadManager']);
          break;
        }
        final fileName = _ayahFileNameFor(surahNumber, ayah.ayahNumber);
        final url = '$ayahDownloadSource$fileName';
        await _downloadFileIfNotExist(url, fileName,
            setDownloadingStatus: false,
            context: context,
            ayahUqNumber: ayah.ayahUQNumber);
        // تحديث الواجهة بعد كل آية تُحمّل لإظهار التقدم
        update(['ayahDownloadManager']);
      }

      // تحقّق نهائي قبل وضع علامة مكتمل
      if (await isAyahSurahFullyDownloaded(surahNumber)) {
        log('تم تحميل جميع آيات السورة $surahNumber بالكامل');
      }
    } catch (e) {
      log('Error downloading surah ayahs: $e', name: 'AudioController');
    } finally {
      // إعادة ضبط مؤشرات التحميل
      state.isDownloading.value = false;
      state.currentDownloadingAyahSurahNumber.value = -1;
      state.cancelRequested.value = false;
      // تحديث الواجهة بعد نهاية الدفعة
      update(['ayahDownloadManager']);
    }
  }

  /// حذف جميع ملفات آيات سورة معيّنة للقارئ الحالي
  Future<void> deleteAyahSurahDownloads(int surahNumber) async {
    if (kIsWeb) {
      // على الويب لا توجد ملفات لحذفها
      return;
    }
    try {
      final surah = QuranCtrl.instance.surahs
          .firstWhere((s) => s.surahNumber == surahNumber);
      final dir = await state.dir;
      for (final ayah in surah.ayahs) {
        final fileName = _ayahFileNameFor(surahNumber, ayah.ayahNumber);
        final path = join(dir.path, fileName);
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
        state.ayahsDownloadStatus[ayah.ayahUQNumber] = false;
        update(['ayahDownloadManager']);
      }
      final key = 'surah_$surahNumberـ${state.ayahReaderIndex.value}';
      state.box.write(key, false);
      update(['ayahDownloadManager']);
    } catch (e) {
      log('Error deleting surah ayahs: $e', name: 'AudioController');
    }
  }

  /// عرض BottomSheet لإدارة تحميل آيات السور
  Future<void> _showAyahDownloadBottomSheet(BuildContext? context,
      {int? initialSurahToDownload,
      AyahAudioStyle? ayahStyle,
      AyahDownloadManagerStyle? style,
      bool? isDark = true}) async {
    // ابحث عن سياق يحوي MediaQuery لتجنّب أخطاء debugCheckHasMediaQuery
    BuildContext? resolveBottomSheetContext(BuildContext? ctx) {
      try {
        if (ctx != null && MediaQuery.maybeOf(ctx) != null) return ctx;
      } catch (_) {}
      try {
        if (Get.context != null && MediaQuery.maybeOf(Get.context!) != null) {
          return Get.context!;
        }
      } catch (_) {}
      try {
        if (Get.overlayContext != null &&
            MediaQuery.maybeOf(Get.overlayContext!) != null) {
          return Get.overlayContext!;
        }
      } catch (_) {}
      try {
        if (Get.key.currentContext != null &&
            MediaQuery.maybeOf(Get.key.currentContext!) != null) {
          return Get.key.currentContext!;
        }
      } catch (_) {}
      return null;
    }

    final bool resolvedDark = isDark ?? true;
    BuildContext? sheetContext = resolveBottomSheetContext(context);
    final AyahDownloadManagerStyle resolvedStyle = style ??
        (sheetContext != null
            ? (AyahDownloadManagerTheme.of(sheetContext)?.style ??
                AyahDownloadManagerStyle.defaults(
                    isDark: resolvedDark, context: sheetContext))
            : AyahDownloadManagerStyle.defaults(
                isDark: resolvedDark, context: context ?? Get.context!));
    // إعادة محاولة بعد Frame واحد إذا لم يُعثر على سياق صالح أولاً
    if (sheetContext == null) {
      await Future.delayed(const Duration(milliseconds: 16));
      sheetContext = resolveBottomSheetContext(context);
    }

    // مُنشئ الواجهة حتى يُستخدم مع أي سياق صالح
    Widget buildSheet(BuildContext ctx) {
      log('AyahDownloadManagerStyle source=${style != null ? 'passed' : 'defaults'}',
          name: 'AudioController');
      final AyahAudioStyle as = ayahStyle ??
          AyahAudioStyle.defaults(isDark: resolvedDark, context: ctx);
      return AyahDownloadManagerSheet(
        onRequestDownload: (surahNum) async {
          if (state.isDownloading.value) return;
          await startDownloadAyahSurah(surahNum, context: ctx);
        },
        onRequestDelete: (surahNum) async {
          await deleteAyahSurahDownloads(surahNum);
        },
        isSurahDownloadedChecker: (surahNum) =>
            isAyahSurahFullyDownloaded(surahNum),
        initialSurahToFocus: initialSurahToDownload,
        style: resolvedStyle,
        isDark: resolvedDark,
        ayahStyle: as,
      );
    }

    // حاول استخدام showModalBottomSheet بسياق آمن، وإلاFallback إلى Get.bottomSheet
    if (sheetContext != null) {
      await showModalBottomSheet(
        context: sheetContext,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: resolvedStyle.backgroundColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => buildSheet(sheetContext!),
      );
    } else {
      // كحل أخير، استخدم Get.bottomSheet الذي يعتمد على overlay context داخليًا
      final fallbackCtx =
          Get.context ?? Get.overlayContext ?? Get.key.currentContext;
      if (fallbackCtx == null) {
        log('No valid context found for bottom sheet. Skipping display.',
            name: 'AudioController');
        // محاولة إعلام المستخدم بتوست إن توفر سياق ممرّر أصلاً
        if (context != null) {
          try {
            ToastUtils().showToast(context, 'تعذّر فتح مدير تنزيل الآيات الآن');
          } catch (_) {}
        }
        return;
      }
      final AyahDownloadManagerStyle resolvedStyle = style ??
          AyahDownloadManagerStyle.defaults(
              isDark: resolvedDark, context: fallbackCtx);
      final AyahAudioStyle as = ayahStyle ??
          AyahAudioStyle.defaults(isDark: resolvedDark, context: fallbackCtx);
      await Get.bottomSheet(
        AyahDownloadManagerSheet(
          onRequestDownload: (surahNum) async {
            if (state.isDownloading.value) return;
            // قد لا يتوفر سياق هنا؛ التحميل لا يحتاج سياقًا إلا للتوستات
            await startDownloadAyahSurah(surahNum, context: fallbackCtx);
          },
          onRequestDelete: (surahNum) async {
            await deleteAyahSurahDownloads(surahNum);
          },
          isSurahDownloadedChecker: (surahNum) =>
              isAyahSurahFullyDownloaded(surahNum),
          initialSurahToFocus: initialSurahToDownload,
          style: resolvedStyle,
          isDark: resolvedDark,
          ayahStyle: as,
        ),
        isScrollControlled: true,
        backgroundColor: AppColors.getBackgroundColor(resolvedDark),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      );
    }
  }
}
