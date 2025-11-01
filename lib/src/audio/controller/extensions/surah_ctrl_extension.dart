part of '../../audio.dart';

extension SurahCtrlExtension on AudioCtrl {
  Future<void> playPreviousSurah() async {
    state.isPlayingSurahsMode = true;
    enableSurahAutoNextListener();
    if (state.currentAudioListSurahNum.value > 1) {
      state.currentAudioListSurahNum.value -= 1;
      state.selectedSurahIndex.value -= 1;
      state.isPlaying.value = true;
      saveLastSurahListen();
      await updateMediaItemAndPlay().then((_) => state.audioPlayer.play());
    } else {
      await state.audioPlayer.pause();
    }
  }

  Future<void> playNextSurah() async {
    state.isPlayingSurahsMode = true;
    enableSurahAutoNextListener();
    if (state.currentAudioListSurahNum.value < 114) {
      state.currentAudioListSurahNum.value += 1;
      state.selectedSurahIndex.value += 1;
      state.isPlaying.value = true;
      saveLastSurahListen();
      await updateMediaItemAndPlay().then((_) => state.audioPlayer.play());
    } else {
      await state.audioPlayer.pause();
    }
  }

  Future<void> playSurah({required int surahNumber}) async {
    // التحقق من إمكانية التشغيل / Check if playback is allowed
    if (!await canPlayAudio()) {
      return;
    }

    state.isPlayingSurahsMode = true;
    enableSurahAutoNextListener();
    state.currentAudioListSurahNum.value = surahNumber;
    changeAudioSource();
    cancelDownload();
    state.isPlaying.value = true;
    // await state.audioPlayer.pause();
    state.isSurahDownloadedByNumber(surahNumber).value
        ? await startDownload()
        : await state.audioPlayer.play();
  }

  Future<void> _addFileAudioSourceToPlayList(String filePath) async {
    state.downloadSurahsPlayList.add({
      state.currentAudioListSurahNum.value: AudioSource.file(
        filePath,
        tag: mediaItem,
      )
    });
  }
}
