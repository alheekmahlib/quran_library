part of '../../audio.dart';

extension SurahUi on AudioCtrl {
  /// تعيين مصدر السورة الحالي بشكل آمن (يوقف المشغّل أولًا لتجنّب Loading interrupted)
  Future<void> changeAudioSource() async {
    try {
      // أوقف أي تشغيل/تحميل جارٍ قبل تبديل المصدر
      await state.audioPlayer.stop();
      if (state
          .isSurahDownloadedByNumber(state.currentAudioListSurahNum.value)
          .value) {
        await state.audioPlayer.setAudioSource(
          AudioSource.file(
            localSurahFilePath,
            tag: mediaItem,
          ),
        );
      } else {
        await state.audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(urlSurahFilePath),
            tag: mediaItem,
          ),
        );
      }
    } catch (e, s) {
      log('changeAudioSource failed: $e', name: 'SurahUi', stackTrace: s);
    }
  }

  /// اختيار سورة من القائمة مع ضبط الحالة المناسبة لوضع السور
  Future<void> selectSurahFromList(int index, {bool autoPlay = false}) async {
    // التحويل إلى وضع السور وتعطيل أي مستمعات قديمة
    state.isPlayingSurahsMode = true;
    disableSurahAutoNextListener();
    state.cancelAllSubscriptions();

    // عيّن الفهرس الجديد
    state.selectedSurahIndex.value = index;

    // بدّل المصدر بأمان
    await changeAudioSource();

    // شغّل تلقائيًا إذا طُلب ذلك
    if (autoPlay) {
      enableSurahAutoNextListener();
      state.isPlaying.value = true;
      await state.audioPlayer.play();
    }
  }

  void changeSurahReadersOnTap(BuildContext context, int index) {
    initializeSurahDownloadStatus();
    state.box.write(StorageConstants.surahReaderIndex, index);
    state.surahReaderIndex.value = index;
    // إعادة تعيين المصدر وفق القارئ الجديد بأمان
    changeAudioSource();
    Navigator.of(context).pop();
  }

  Future<void> changeAyahReadersOnTap(BuildContext context, int index) async {
    state.ayahReaderNameValue.value =
        ReadersConstants.ayahReaderInfo[index]['readerD'];
    state.ayahReaderValue.value =
        ReadersConstants.ayahReaderInfo[index]['readerI'];
    state.box.write(StorageConstants.ayahAudioPlayerSound,
        ReadersConstants.ayahReaderInfo[index]['readerD']);
    state.box.write(StorageConstants.ayahAudioPlayerName,
        ReadersConstants.ayahReaderInfo[index]['readerN']);
    state.box.write(StorageConstants.ayahReaderIndex, index);
    state.ayahReaderIndex.value = index;
    Navigator.of(context).pop();
    update(['audio_seekBar_id']);
    await _updateDownloadedAyahsMap();
    if (context.mounted) {
      state.isPlaying.value
          ? playAyah(context, state.currentAyahUniqueNumber,
              playSingleAyah: state.playSingleAyahOnly)
          : null;
    }
  }

  void sheetState() {
    state.panelController.addListener(() {
      // تحديث حالة الـ Sheet بناءً على الوضعية الحالية
      // Update Sheet state based on current status
      if (state.panelController.status.index == 0) {
        state.isSheetOpen.value = true;
        log('Sheet is now open', name: 'SurahAudioController');
      } else {
        state.isSheetOpen.value = false;
        log('Sheet is now closed', name: 'SurahAudioController');
      }
    });
  }
}
