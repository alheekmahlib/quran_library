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
      final filePath = isSurahDownloaded
          ? join(state.dir.path, currentAyahFileName)
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
        state.audioPlayer.stop();
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
      BuildContext context, int currentAyahUniqueNumber) async {
    state.tmpDownloadedAyahsCount = 0;
    final ayahsFilesNames = selectedSurahAyahsFileNames;
    final ayahsUrls = selectedSurahAyahsUrls;
    final surahKey = 'surah_$currentSurahNumberـ${state.ayahReaderIndex.value}';

    try {
      state.snackBarShownForBatch = false;
      final List<Future<String>> futures = List.generate(
        selectedSurahAyahsFileNames.length,
        (i) => _downloadFileIfNotExist(ayahsUrls[i], ayahsFilesNames[i],
                setDownloadingStatus: false,
                context: context,
                // استخدام الرقم الفريد مباشرة بدلاً من الوصول لآيات السورة
                // Use unique number directly instead of accessing surah ayahs
                ayahUqNumber: currentAyahUniqueNumber + i)
            .whenComplete(() {
          log('${state.tmpDownloadedAyahsCount} => download completed at ${DateTime.now().millisecond}');
          state.tmpDownloadedAyahsCount++;
        }),
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
      // التأكد من صحة الفهرس قبل التعيين / Validate index before setting
      int initialIndex = state.isDirectPlaying.value
          ? currentAyahInPage
          : currentAyahUniqueNumber;

      // التأكد من أن الفهرس في النطاق الصحيح / Ensure index is within valid range
      if (initialIndex >= ayahsFilesNames.length) {
        initialIndex = 0;
        log('Initial index was out of range, setting to 0',
            name: 'AudioController');
      }

      if (initialIndex < 0) {
        initialIndex = 0;
        log('Initial index was negative, setting to 0',
            name: 'AudioController');
      }

      // إنشاء مصادر الصوت / Create audio sources
      final audioSources = List.generate(
        ayahsFilesNames.length,
        (i) => AudioSource.file(
          join(state.dir.path, ayahsFilesNames[i]),
          tag: mediaItemsForCurrentSurah[i],
        ),
      );

      // التأكد من وجود ملفات الصوت / Verify audio files exist
      for (int i = 0; i < ayahsFilesNames.length; i++) {
        final filePath = join(state.dir.path, ayahsFilesNames[i]);
        if (!await File(filePath).exists()) {
          log('Audio file does not exist: $filePath', name: 'AudioController');
          throw Exception('ملف الصوت غير موجود: ${ayahsFilesNames[i]}');
        }
      }

      // تعيين مصدر الصوت مع الفهرس الصحيح / Set audio source with correct index
      await state.audioPlayer.setAudioSources(
        audioSources,
        initialIndex: initialIndex,
      );

      log('${'-' * 30} player is starting.. ${'-' * 30}',
          name: 'AudioController');

      // الاستماع لتغييرات الفهرس / Listen to index changes
      state.audioPlayer.currentIndexStream.listen((index) async {
        if (index != null && index < ayahsFilesNames.length) {
          if (isLastAyahInPageButNotInSurah || isLastAyahInSurahAndPage) {
            await moveToNextPage(withScroll: true);
          }
          state.currentAyahUniqueNumber =
              currentAyahsSurah.ayahs[index].ayahUQNumber;
          currentAyahUniqueNumber = currentAyahsSurah.ayahs[index].ayahUQNumber;
          QuranCtrl.instance.toggleAyahSelection(currentAyahUniqueNumber);
          log('Current playing index: $index', name: 'AudioController');
        }
      });

      state.isPlaying.value = true;
      await state.audioPlayer.play();
    } catch (e) {
      state.isPlaying.value = false;
      await state.audioPlayer.stop();
      log('Error in ayahs playFile: $e', name: 'AudioController');

      // إظهار رسالة خطأ للمستخدم / Show error message to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تشغيل الآيات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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

  /// TODO: Implement skipNextAyah and skipPreviousAyah methods
  Future<void> skipNextAyah(
      BuildContext context, int currentAyahUniqueNumber) async {
    if (currentAyahUniqueNumber == 6236) {
      return await pausePlayer();
    } else if (isLastAyahInPageButNotInSurah || isLastAyahInSurahAndPage) {
      currentAyahUniqueNumber += 1;
      await moveToNextPage(withScroll: true);
      QuranCtrl.instance.toggleAyahSelection(currentAyahUniqueNumber);
      await state.audioPlayer.seekToNext();
    } else {
      currentAyahUniqueNumber += 1;
      QuranCtrl.instance.toggleAyahSelection(currentAyahUniqueNumber);
      await state.audioPlayer.seekToNext();
    }
  }

  Future<void> skipPreviousAyah(
      BuildContext context, int currentAyahUniqueNumber) async {
    if (currentAyahUniqueNumber == 1) {
      return await pausePlayer();
    } else if (isFirstAyahInPageButNotInSurah) {
      currentAyahUniqueNumber -= 1;
      moveToPreviousPage();
      QuranCtrl.instance.toggleAyahSelection(currentAyahUniqueNumber);
      await state.audioPlayer.seekToPrevious();
    } else {
      currentAyahUniqueNumber -= 1;
      await state.audioPlayer.seekToPrevious();
    }
  }

  Future<void> moveToNextPage({bool withScroll = true}) async {
    if (withScroll) {
      await QuranCtrl.instance.state.quranPageController.animateToPage(
          (QuranCtrl.instance.state.currentPageNumber.value),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut);
      log('Going To Next Page at: ${QuranCtrl.instance.state.currentPageNumber.value} ');
    }
  }

  void moveToPreviousPage({bool withScroll = true}) {
    if (withScroll) {
      QuranCtrl.instance.state.quranPageController.animateToPage(
          (QuranCtrl.instance.state.currentPageNumber.value - 2),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut);
    }
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

        String filePath = '${state.dir.path}/$ayahReaderValue/$i.mp3';
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
