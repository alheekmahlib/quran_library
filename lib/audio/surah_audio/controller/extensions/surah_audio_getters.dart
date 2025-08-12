part of '../../../audio.dart';

extension SurahAudioGetters on AudioCtrl {
  /// -------- [Getters] ----------
  String get localSurahFilePath {
    return '${state.dir.path}/${state.surahReaderNameValue.value}${state.currentAudioListSurahNum.value.toString().padLeft(3, "0")}.mp3';
  }

  String get urlSurahFilePath {
    return '${state.surahReaderValue.value}${state.surahReaderNameValue.value}${state.currentAudioListSurahNum.value.toString().padLeft(3, "0")}.mp3';
  }

  /// single verse
  /// الحصول على الآية الحالية - Get current ayah
  AyahModel get currentAyah {
    try {
      return QuranCtrl.instance.ayahs
          .firstWhere((a) => a.ayahUQNumber == state.currentAyahUniqueNumber);
    } catch (e) {
      // في حالة عدم العثور على الآية، إرجاع الآية الأولى
      // If ayah not found, return first ayah
      return QuranCtrl.instance.ayahs.first;
    }
  }

  /// الحصول على السورة الحالية للآية - Get current surah for the ayah
  SurahModel get currentAyahsSurah {
    try {
      return QuranCtrl.instance.surahs
          .firstWhere((s) => s.surahNumber == currentAyah.surahNumber!);
    } catch (e) {
      // في حالة عدم العثور على السورة، إرجاع السورة الأولى
      // If surah not found, return first surah
      return QuranCtrl.instance.surahs.first;
    }
  }

  /// single verse
  int get currentSurahNumber => currentAyahsSurah.surahNumber;

  Stream<PositionData> get audioStream => positionDataStream;

  MediaItem get mediaItem => MediaItem(
        id: '${state.currentAudioListSurahNum.value}',
        title: QuranCtrl.instance.state
            .surahs[(state.currentAudioListSurahNum.value - 1)].arabicName,
        artist:
            '${ReadersConstants.surahReaderInfo[state.surahReaderIndex.value]['name']}'
                .tr,
        artUri: state.cachedArtUri,
      );

  Future<void> lastAudioSource() async {
    await updateMediaItemAndPlay().then((_) async => await state.audioPlayer
        .seek(Duration(seconds: state.lastPosition.value)));
  }

  Future<void> updateMediaItemAndPlay() async {
    final newMediaItem = mediaItem;
    AudioPlayerHandler.instance.mediaItem.add(newMediaItem);
    await state.audioPlayer.setAudioSource(state
            .isSurahDownloadedByNumber(state.currentAudioListSurahNum.value)
            .value
        ? AudioSource.file(
            localSurahFilePath,
            tag: newMediaItem,
          )
        : AudioSource.uri(
            Uri.parse(urlSurahFilePath),
            tag: newMediaItem,
          ));
  }

  Stream<PositionData> get positionDataStream =>
      r.Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          state.audioPlayer.positionStream,
          state.audioPlayer.bufferedPositionStream,
          state.audioPlayer.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  Stream<PositionData> get downloadPositionDataStream =>
      r.Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          state.audioPlayer.positionStream,
          state.audioPlayer.bufferedPositionStream,
          state.audioPlayer.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));
  String get ayahReaderValue =>
      ReadersConstants.ayahReaderInfo[state.ayahReaderIndex.value]['readerD'];

  List<String> get selectedSurahAyahsFileNames {
    return List.generate(
        currentAyahsSurah.ayahs.length,
        (i) => ReadersConstants.ayahReaderInfo[state.ayahReaderIndex.value]
                    ['url'] ==
                ReadersConstants.ayahs1stSource
            ? '$ayahReaderValue/${currentAyahsSurah.ayahs[i].ayahUQNumber}.mp3'
            : '$ayahReaderValue/${currentAyahsSurah.surahNumber.toString().padLeft(3, "0")}${currentAyahsSurah.ayahs[i].ayahNumber.toString().padLeft(3, "0")}.mp3');
  }

  List<String> get selectedSurahAyahsUrls {
    return List.generate(selectedSurahAyahsFileNames.length,
        (i) => '$ayahDownloadSource${selectedSurahAyahsFileNames[i]}');
  }

  String get ayahDownloadSource =>
      ReadersConstants.ayahReaderInfo[state.ayahReaderIndex.value]['url'];
  String get currentAyahUrl => '$ayahDownloadSource$currentAyahFileName';
  String get currentAyahFileName {
    if (ReadersConstants.ayahReaderInfo[state.ayahReaderIndex.value]['url'] ==
        ReadersConstants.ayahs1stSource) {
      return '$ayahReaderValue/${state.currentAyahUniqueNumber}.mp3';
    } else {
      final surahNum = currentAyahsSurah.surahNumber.toString().padLeft(3, '0');
      final currentAyahNumber =
          currentAyah.ayahNumber.toString().padLeft(3, '0');
      return '$ayahReaderValue/$surahNum$currentAyahNumber.mp3';
    }
  }

  List<AudioSource> get currentSurahAudioSources => List.generate(
        selectedSurahAyahsFileNames.length,
        (i) {
          /// check if file is downloaded or add it as uri
          if (state.ayahsDownloadStatus[currentAyah.ayahUQNumber + i] ==
              false) {
            return AudioSource.uri(
              Uri.parse(join(state.dir.path, selectedSurahAyahsFileNames[i])),
              tag: mediaItemsForCurrentSurah[i],
            );
          }
          return AudioSource.file(
            join(state.dir.path, selectedSurahAyahsFileNames[i]),
            tag: mediaItemsForCurrentSurah[i],
          );
        },
      );

  MediaItem get mediaItemForCurrentAyah => MediaItem(
        id: '${state.currentAyahUniqueNumber}',
        title: QuranCtrl.instance
            .getPageAyahsByIndex(
                QuranCtrl.instance.state.currentPageNumber.value - 1)
            .firstWhere((a) => a.ayahUQNumber == state.currentAyahUniqueNumber)
            .text,
        artist:
            '${ReadersConstants.ayahReaderInfo[state.ayahReaderIndex.value]['name']}'
                .tr,
        artUri: state.cachedArtUri,
      );
  List<MediaItem> get mediaItemsForCurrentSurah {
    return List.generate(
        currentAyahsSurah.ayahs.length,
        (i) => MediaItem(
              id: '${currentAyahsSurah.ayahs[i].ayahUQNumber}',
              title: currentAyahsSurah.ayahs[i].text,
              artist:
                  '${ReadersConstants.ayahReaderInfo[state.ayahReaderIndex.value]['name']}'
                      .tr,
              artUri: state.cachedArtUri,
            ));
  }

  bool get isLastAyahInPage =>
      QuranCtrl.instance
          .getPageAyahsByIndex(
              QuranCtrl.instance.state.currentPageNumber.value - 1)
          .last
          .ayahUQNumber ==
      state.currentAyahUniqueNumber;

  bool get isFirstAyahInPage =>
      QuranCtrl.instance
          .getPageAyahsByIndex(
              QuranCtrl.instance.state.currentPageNumber.value - 1)
          .first
          .ayahUQNumber ==
      state.currentAyahUniqueNumber;

  bool get isLastAyahInSurah =>
      QuranCtrl.instance
          .getCurrentSurahByPage(
              QuranCtrl.instance.state.currentPageNumber.value - 1)
          .ayahs
          .last
          .ayahUQNumber ==
      state.currentAyahUniqueNumber;

  bool get isFirstAyahInSurah =>
      QuranCtrl.instance
          .getCurrentSurahByPage(
              QuranCtrl.instance.state.currentPageNumber.value - 1)
          .ayahs
          .first
          .ayahUQNumber ==
      state.currentAyahUniqueNumber;

  bool get isLastAyahInSurahButNotInPage =>
      isLastAyahInSurah && !isLastAyahInPage;

  bool get isLastAyahInSurahAndPage => isLastAyahInSurah && isLastAyahInPage;

  bool get isLastAyahInPageButNotInSurah =>
      isLastAyahInPage && !isLastAyahInSurah;

  bool get isFirstAyahInPageButNotInSurah =>
      isFirstAyahInPage && !isFirstAyahInSurah;
}
