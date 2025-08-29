// ignore_for_file: use_build_context_synchronously

part of '../../../audio.dart';

extension AyahCtrlExtension on AudioCtrl {
  /// single Ayah
  ///
  Future<void> _playSingleAyahFile(
      BuildContext context, int currentAyahUniqueNumber) async {
    state.tmpDownloadedAyahsCount = 0;
    final surahKey = 'surah_$currentSurahNumberـ${state.ayahReaderIndex.value}';

    bool isSurahDownloaded = state.box.read(surahKey) ?? false;

    try {
      if (state.isPlaying.value || state.audioPlayer.playing) {
        await state.audioPlayer.stop();
      }
      QuranCtrl.instance.toggleAyahSelection(state.currentAyahUniqueNumber);
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
      state.isPlaying.value = true;
      await state.audioPlayer
          .play()
          .then((_) => state.isPlaying.value = true)
          .whenComplete(() {
        QuranCtrl.instance.clearSelection();
        state.isPlaying.value = false;
      });
      log('تحميل سورة $selectedSurahAyahsFileNames تم بنجاح.');
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
    final ayahsUrls = selectedSurahAyahsUrls;
    final surahKey = 'surah_$currentSurahNumberـ${state.ayahReaderIndex.value}';

    try {
      state.snackBarShownForBatch = false;
      final List<Future<String>> futures = List.generate(
        selectedSurahAyahsFileNames.length,
        (i) {
          final furure = _downloadFileIfNotExist(
                  ayahsUrls[i], ayahsFilesNames[i],
                  setDownloadingStatus: false,
                  context: context,
                  // استخدام الرقم الفريد مباشرة بدلاً من الوصول لآيات السورة
                  // Use unique number directly instead of accessing surah ayahs
                  ayahUqNumber: currentAyahUniqueNumber)
              .whenComplete(() {
            log('${state.tmpDownloadedAyahsCount} => download completed at ${DateTime.now().millisecond}');
            state.tmpDownloadedAyahsCount++;
          });
          currentAyahUniqueNumber++;
          return furure;
        },
      );

      state.isDownloading.value = true;
      await Future.wait(futures);
      state.isDownloading.value = false;
      state.box.write(surahKey, true);

      log('تحميل سورة $selectedSurahAyahsFileNames تم بنجاح.');
    } catch (e) {
      log('Error in ayahs download: $e', name: 'AudioController');
      state.isDownloading.value = false;
    }

    try {
      final directory = await state.dir;
      // إنشاء مصادر الصوت / Create audio sources
      final audioSources = List.generate(
        ayahsFilesNames.length,
        (i) => AudioSource.file(
          join(directory.path, ayahsFilesNames[i]),
          tag: mediaItemsForCurrentSurah[i],
        ),
      );

      // التأكد من وجود ملفات الصوت / Verify audio files exist
      for (int i = 0; i < ayahsFilesNames.length; i++) {
        final filePath = join(directory.path, ayahsFilesNames[i]);
        if (!await File(filePath).exists()) {
          log('Audio file does not exist: $filePath', name: 'AudioController');
          throw Exception('ملف الصوت غير موجود: ${ayahsFilesNames[i]}');
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
        UiHelper.showCustomErrorSnackBar(
            'خطأ في تشغيل الآيات: ${e.toString()}', context);
      }
    }
  }

  Future<void> playAyah(BuildContext context, int currentAyahUniqueNumber,
      {required bool playSingleAyah}) async {
    state.playSingleAyahOnly = playSingleAyah;
    state.currentAyahUniqueNumber = currentAyahUniqueNumber;
    QuranCtrl.instance.isShowControl.value = true;
    SliderController.instance.setMediumHeight(context);
    SliderController.instance.updateBottomHandleVisibility(true);
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
    for (int i = 1; i <= 6236; i++) {
      try {
        // التحقق من وجود الآية - Check if ayah exists
        QuranCtrl.instance.ayahs.firstWhere(
          (a) => a.ayahUQNumber == i,
          orElse: () => throw StateError('No ayah found with number $i'),
        );

        String filePath = '${(await state.dir).path}/$ayahReaderValue/$i.mp3';
        File file = File(filePath);
        final exists = await file.exists();

        if (exists) {
          state.ayahsDownloadStatus.update(i, (value) => exists);
        }
      } catch (e) {
        // في حالة عدم العثور على الآية، تجاهل ومتابعة
        // If ayah not found, skip and continue
        continue;
      }
    }
  }
}
