part of '../../../audio.dart';

extension SurahAudioStorageGetters on AudioCtrl {
  /// -------- [Storage] ----------

  Future loadLastSurahListen() async {
    int? lastSurah = state.box.read(StorageConstants.lastSurah) ?? 1;
    int? selectedSurah = state.box.read(StorageConstants.selectedSurah) ?? 1;
    int? lastPosition = state.box.read(StorageConstants.lastPosition) ?? 0;
    return {
      StorageConstants.lastSurah: lastSurah,
      StorageConstants.selectedSurah: selectedSurah,
      StorageConstants.lastPosition: lastPosition,
    };
  }

  Future<void> loadLastSurahAndPosition() async {
    final lastSurahData = await loadLastSurahListen();

    state.currentAudioListSurahNum.value =
        lastSurahData[StorageConstants.lastSurah];
    state.selectedSurahIndex.value =
        lastSurahData[StorageConstants.selectedSurah];
    state.lastPosition.value = lastSurahData[StorageConstants.lastPosition];
  }

  void saveLastSurahListen() {
    state.box.write(
        StorageConstants.lastSurah, state.currentAudioListSurahNum.value);
    state.box.write(
      StorageConstants.selectedSurah,
      state.selectedSurahIndex.value,
    );
  }

  void loadSurahReader() {
    state.surahReaderValue.value =
        state.box.read(StorageConstants.surahAudioPlayerSound) ??
            ReadersConstants.surahUrl1;
    state.surahReaderNameValue.value =
        state.box.read(StorageConstants.surahAudioPlayerName) ??
            'abdul_basit_murattal/';
    state.surahReaderIndex.value =
        state.box.read(StorageConstants.surahReaderIndex) ?? 0;
  }

  void loadAyahReader() {
    state.ayahReaderValue.value =
        state.box.read(StorageConstants.ayahAudioPlayerSound) ??
            ReadersConstants.ayahs1stSource;
    state.ayahReaderNameValue.value =
        state.box.read(StorageConstants.ayahAudioPlayerName) ??
            'abdul_basit_murattal/';
    state.ayahReaderIndex.value =
        state.box.read(StorageConstants.ayahReaderIndex) ?? 0;
    state.surahReaderIndex.value =
        state.box.read(StorageConstants.surahReaderIndex) ?? 0;
  }
}
