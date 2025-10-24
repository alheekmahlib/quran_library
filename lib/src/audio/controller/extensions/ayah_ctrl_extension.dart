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
      isSurahDownloaded = await _isAyahSurahFullyDownloaded(currentSurahNumber);
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
      await state.audioPlayer
          .play()
          .then((_) => state.isPlaying.value = true)
          .whenComplete(() {
        state.audioPlayer.stop();
        QuranCtrl.instance.clearSelection();
        state.isPlaying.value = false;
      });
      log('تحميل $currentAyahFileName تم بنجاح.');
      return;
    } catch (e) {
      log('Error in playFile: $e', name: 'AudioController');
    }
  }

  /// play Ayahs
  /// تشغيل الآيات
  Future<void> _playAyahsFile(
      BuildContext? context, int currentAyahUniqueNumber) async {
    state.tmpDownloadedAyahsCount = 0;
    final ayahsFilesNames = selectedSurahAyahsFileNames;

    if (!kIsWeb) {
      // إذا لم تكن آيات السورة محمّلة بالكامل، افتح bottomSheet لإدارة التحميل
      final isSurahFullyDownloaded =
          await _isAyahSurahFullyDownloaded(currentSurahNumber);
      if (!isSurahFullyDownloaded) {
        if (context != null) {
          await _showAyahDownloadBottomSheet(context,
              initialSurahToDownload: currentSurahNumber);
        }
        // بعد إغلاق الـ bottomSheet، أعد التحقق
        final downloadedNow =
            await _isAyahSurahFullyDownloaded(currentSurahNumber);
        if (!downloadedNow) {
          // المستخدم أغلق أو لم يكتمل التحميل
          return;
        }
      }
    }

    // عند هذه النقطة كل الآيات محمّلة بالكامل، يمكن إنشاء المصادر وتشغيلها
    try {
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

      final initialIndex = selectedSurahAyahsUrls.indexOf(currentAyahUrl);

      // تعيين مصدر الصوت مع الفهرس الصحيح / Set audio source with correct index
      await state.audioPlayer.setAudioSources(
        audioSources,
        initialIndex: initialIndex,
      );

      log('${'-' * 30} player is starting.. ${'-' * 30}',
          name: 'AudioController');

      // الاستماع لتغييرات الفهرس / Listen to index changes
      state._currentIndexSubscription =
          state.audioPlayer.currentIndexStream.listen((index) async {
        final currentIndex = (state.audioPlayer.currentIndex ?? 0);
        log('index: $index | currentIndex: $currentIndex', name: 'index');
        if (index != null && index < ayahsFilesNames.length) {
          state.currentAyahUniqueNumber =
              currentAyahsSurah.ayahs[currentIndex].ayahUQNumber;

          QuranCtrl.instance.toggleAyahSelection(state.currentAyahUniqueNumber);
          if (QuranCtrl.instance
                  .getPageAyahsByIndex(
                      QuranCtrl.instance.state.currentPageNumber.value - 1)
                  .first
                  .ayahUQNumber ==
              (state.currentAyahUniqueNumber)) {
            await moveToNextPage();
          }
          log('Current playing index: $index', name: 'AudioController');
        }
      });

      state.isPlaying.value = true;
      await state.audioPlayer.play();

      // استخدام subscription محدود لتجنب إنشاء listeners متعددة / Use limited subscription to avoid creating multiple listeners
      state._playerStateSubscription ??=
          state.audioPlayer.playerStateStream.listen((d) {
        if (d.processingState == ProcessingState.completed &&
            !state.playSingleAyahOnly &&
            currentSurahNumber < 114) {
          state.currentAyahUniqueNumber++;
          _playAyahsFile(context, state.currentAyahUniqueNumber);
        }
      });
    } catch (e) {
      state.isPlaying.value = false;
      await state.audioPlayer.stop();
      log('Error in ayahs playFile: $e', name: 'AudioController');

      // إظهار رسالة خطأ للمستخدم / Show error message to user
      if (context != null) {
        ToastUtils().showToast(context, 'خطأ في تشغيل الآيات: ${e.toString()}');
      }
    }
  }

  Future<void> playAyah(BuildContext context, int currentAyahUniqueNumber,
      {required bool playSingleAyah}) async {
    // التحقق من إمكانية التشغيل / Check if playback is allowed
    if (!await canPlayAudio()) {
      return;
    }

    state.playSingleAyahOnly = playSingleAyah;
    state.currentAyahUniqueNumber = currentAyahUniqueNumber;
    QuranCtrl.instance.isShowControl.value = true;
    SliderController.instance.setMediumHeight(context);
    SliderController.instance.updateBottomHandleVisibility(true);
    // أوقف أي تشغيل قائم لتجنّب عاديات إعادة التشغيل
    if (state.audioPlayer.playing) await pausePlayer();
    Future.delayed(
      const Duration(milliseconds: 400),
      () => QuranCtrl.instance.state.isPlayExpanded.value = true,
    );

    if (playSingleAyah) {
      await _playSingleAyahFile(context, currentAyahUniqueNumber);
    } else {
      await _playAyahsFile(context, currentAyahUniqueNumber);
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
  Future<bool> _isAyahSurahFullyDownloaded(int surahNumber) async {
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
    if (ReadersConstants.ayahReaderInfo[state.ayahReaderIndex.value]['url'] ==
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
  Future<void> _startDownloadAyahSurah(int surahNumber,
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
      if (await _isAyahSurahFullyDownloaded(surahNumber)) {
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
  Future<void> _deleteAyahSurahDownloads(int surahNumber) async {
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
  Future<void> _showAyahDownloadBottomSheet(BuildContext context,
      {int? initialSurahToDownload,
      AyahAudioStyle? ayahStyle,
      AyahDownloadManagerStyle? style,
      bool? isDark = false}) async {
    // ابدأ تحميل السورة المطلوبة تلقائياً بعد فتح الـ sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getBackgroundColor(isDark!),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        // لا تبدأ تحميل تلقائيًا؛ اجعل التحميل بيد المستخدم فقط
        return AyahDownloadManagerSheet(
          onRequestDownload: (surahNum) async {
            if (state.isDownloading.value) return;
            await _startDownloadAyahSurah(surahNum, context: ctx);
          },
          onRequestDelete: (surahNum) async {
            await _deleteAyahSurahDownloads(surahNum);
          },
          isSurahDownloadedChecker: (surahNum) =>
              _isAyahSurahFullyDownloaded(surahNum),
          initialSurahToFocus: initialSurahToDownload,
          style: style,
          isDark: isDark,
          ayahStyle: ayahStyle,
        );
      },
    );
  }
}
