part of '../../../audio.dart';

extension SurahUi on AudioCtrl {
  void changeAudioSource() {
    state.isSurahDownloadedByNumber(state.currentAudioListSurahNum.value).value
        ? state.audioPlayer.setAudioSource(AudioSource.file(
            localSurahFilePath,
            tag: mediaItem,
          ))
        : state.audioPlayer.setAudioSource(AudioSource.uri(
            Uri.parse(urlSurahFilePath),
            tag: mediaItem,
          ));
  }

  void changeSurahReadersOnTap(BuildContext context, int index) {
    initializeSurahDownloadStatus();
    state.box.write(StorageConstants.surahReaderIndex, index);
    state.surahReaderIndex.value = index;
    changeAudioSource();
    Navigator.of(context).pop();
  }

  void changeAyahReadersOnTap(BuildContext context, int index) {
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
    playAyah(context, state.currentAyahUniqueNumber,
        playSingleAyah: state.playSingleAyahOnly);
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
