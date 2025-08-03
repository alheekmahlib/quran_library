import 'dart:developer' show log;

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '/audio/constants/readers_constants.dart';
import '/audio/constants/storage_constants.dart';
import '/core/extensions/string_extensions.dart';
import '/quran.dart';
import '../../controller/extensions/surah_audio_getters.dart';

extension SurahAudioUi on SurahAudioController {
  Future<void> changeAudioSource() async {
    state.surahDownloadStatus.value[state.currentAudioListSurahNum.value] ??
            false
        ? await state.audioPlayer.setAudioSource(AudioSource.file(
            localSurahFilePath,
            tag: mediaItem,
          ))
        : await state.audioPlayer.setAudioSource(AudioSource.uri(
            Uri.parse(urlSurahFilePath),
            tag: mediaItem,
          ));
  }

  void changeReadersOnTap(int index) {
    initializeSurahDownloadStatus();
    state.surahReaderValue.value =
        ReadersConstants.surahReaderInfo[index]['readerD'];
    state.surahReaderNameValue.value =
        ReadersConstants.surahReaderInfo[index]['readerN'];
    state.box.write(StorageConstants.surahAudioPlayerSound,
        ReadersConstants.surahReaderInfo[index]['readerD']);
    state.box.write(StorageConstants.surahAudioPlayerName,
        ReadersConstants.surahReaderInfo[index]['readerN']);
    state.box.write(StorageConstants.surahReaderIndex, index);
    state.surahReaderIndex.value = index;
    changeAudioSource();
    Get.back();
  }

  void searchSurah(String searchInput) {
    final surahList = QuranCtrl.instance.state.surahs;

    int index;
    if (int.tryParse(searchInput.convertArabicToEnglishNumbers) != null) {
      // If input is a number, search by surah number
      index = surahList.indexWhere((surah) =>
          surah.surahNumber ==
          int.parse(searchInput.convertArabicToEnglishNumbers));
    } else {
      // If input is text, search by surah name
      index = surahList.indexWhere(
          (surah) => surah.arabicName.removeDiacritics.contains(searchInput));
    }

    log('surahNumber: $index');
    if (index != -1 && state.surahsScrollController.isAttached) {
      jumpToSurah(index);
      state.selectedSurahIndex.value = index;
    }
  }

  void jumpToSurah(int index) async {
    // Ensure ScrollablePositionedList is fully built
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 700))
          .then((_) => state.surahsScrollController.jumpTo(index: index));
    });
  }
}
