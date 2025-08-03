// ignore_for_file: use_build_context_synchronously
import 'dart:developer' show log;
import 'dart:io' show File, Directory, HttpHeaders, Platform;

import 'package:arabic_numbers/arabic_numbers.dart';
import 'package:audio_service/audio_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:dio/dio.dart' as d;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_sliding_box/flutter_sliding_box.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '/audio/constants/storage_constants.dart';
import '/audio/surah_audio/controller/extensions/surah_audio_getters.dart';
import '/audio/surah_audio/controller/extensions/surah_audio_storage_getters.dart';
import '/audio/surah_audio/controller/extensions/surah_audio_ui.dart';
import '/core/extensions/string_extensions.dart';
import '/core/utils/ui_helper.dart';
import '/core/widgets/custom_paint/custom_slider.dart';
import '/quran.dart';

part '../../widgets/seek_bar.dart';
part './audio_player_handler.dart';
part './surah_audio_state.dart';

class SurahAudioController extends GetxController {
  SurahAudioController._();
  static SurahAudioController get instance =>
      Get.isRegistered<SurahAudioController>()
          ? Get.find<SurahAudioController>()
          : Get.put<SurahAudioController>(SurahAudioController._(),
              permanent: true);

  SurahAudioState state = SurahAudioState();

  @override
  Future<void> onInit() async {
    initializeSurahDownloadStatus();
    state.dir = await getApplicationDocumentsDirectory();
    await Future.wait([
      _addDownloadedSurahToPlaylist(),
      _updateDownloadedAyahsMap(),
      loadLastSurahAndPosition(),
      setCachedArtUri(),
    ]);

    super.onInit();
    loadSurahReader();
    state.surahsPlayList = List.generate(114, (i) {
      state.currentAudioListSurahNum.value = i + 1;
      return AudioSource.uri(
        Uri.parse(urlSurahFilePath),
      );
    });

    state.audioServiceInitialized.value =
        state.box.read(StorageConstants.audioServiceInitialized) ?? false;
    if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) {
      if (!state.audioServiceInitialized.value) {
        if (!QuranCtrl.instance.state.isQuranLoaded) {
          await QuranCtrl.instance.loadQuran().then((_) async {
            await initAudioService();
            state.box.write(StorageConstants.audioServiceInitialized, true);
          });
        } else {
          await initAudioService();
          state.box.write(StorageConstants.audioServiceInitialized, true);
        }
      } else {
        await QuranCtrl.instance.loadQuran();
        log("Audio service already initialized",
            name: 'surah_audio_controller');
      }
    }
    Future.delayed(const Duration(milliseconds: 700))
        .then((_) => jumpToSurah(state.currentAudioListSurahNum.value - 1));

    // Listen to player state changes to play the next Surah automatically
    state.audioPlayer.playerStateStream.listen((playerState) async {
      if (playerState.processingState == ProcessingState.completed) {
        await playNextSurah();
      }
    });
  }

  @override
  void onClose() {
    state.audioPlayer.pause();
    state.audioPlayer.dispose();
    state.boxController.dispose();
    super.onClose();
  }

  /// -------- [Methods] ----------

  Future<void> playPreviousSurah() async {
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

  Future<void> _addFileAudioSourceToPlayList(String filePath) async {
    state.downloadSurahsPlayList.add({
      state.currentAudioListSurahNum.value: AudioSource.file(
        filePath,
        tag: mediaItem,
      )
    });
  }

  Future<void> initAudioService() async {
    await AudioService.init(
      builder: () => AudioPlayerHandler.instance,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.alheekmah.quranPackage.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  }

  /// -------- [DownloadingMethods] ----------

  Future<void> downloadSurah(BuildContext context) async {
    String filePath = localSurahFilePath;
    File file = File(filePath);
    log("File Path: $filePath");
    if (await file.exists()) {
      state.isPlaying.value = true;
      log("File exists. Playing...");

      await state.audioPlayer.setAudioSource(AudioSource.file(
        filePath,
        tag: mediaItem,
      ));
      state.audioPlayer.play();
    } else {
      if ((await Connectivity().checkConnectivity())
          .contains(ConnectivityResult.none)) {
        UiHelper.showCustomErrorSnackBar('noInternet'.tr, context);
      } else {
        state.isPlaying.value = true;
        log("File doesn't exist. Downloading...");
        log("state.sorahReaderNameValue: ${state.surahReaderNameValue.value}");
        log("Downloading from URL: $urlSurahFilePath");
        if (await _downloadFile(filePath, urlSurahFilePath)) {
          _addFileAudioSourceToPlayList(filePath);
          onDownloadSuccess(int.parse(
              state.currentAudioListSurahNum.value.toString().padLeft(3, "0")));
          log("File successfully downloaded and saved to $filePath");
          await state.audioPlayer
              .setAudioSource(AudioSource.file(
                filePath,
                tag: mediaItem,
              ))
              .then((_) => state.audioPlayer.play());
        }
      }
    }
    state.audioPlayer.playerStateStream.listen((playerState) async {
      if (playerState.processingState == ProcessingState.completed) {
        await playNextSurah();
      }
    });
  }

  Future<String> _downloadFileIfNotExist(String url, String fileName,
      {required BuildContext context,
      bool showSnakbars = true,
      bool setDownloadingStatus = true,
      int? ayahUqNumber}) async {
    String path = join(state.dir.path, fileName);
    var file = File(path);
    bool exists = await file.exists();
    final connectivity = (await Connectivity().checkConnectivity());

    if (!exists) {
      if (setDownloadingStatus && state.isDownloading.isFalse) {
        state.isDownloading.value = true;
      }

      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (e) {
        log('Error creating directory: $e');
      }

      if (showSnakbars && !state.snackBarShownForBatch) {
        if (!connectivity.contains(ConnectivityResult.none)) {
          // UiHelper.showCustomErrorSnackBar('noInternet'.tr, context);
        } else if (connectivity.contains(ConnectivityResult.mobile)) {
          state.snackBarShownForBatch = true; // Set the flag to true
          // UiHelper.customMobileNoteSnackBar('mobileDataAyat'.tr, context);
        }
      }

      // Proceed with the download
      if (!connectivity.contains(ConnectivityResult.none)) {
        try {
          await _downloadFile(path, url, ayahUqNumber: ayahUqNumber);
          // if (await _downloadFile(path, url)) return path;
        } catch (e) {
          log('Error downloading file: $e');
        }
      } else {
        // TODO: show snakbar no internet.
      }
    }

    if (setDownloadingStatus && state.isDownloading.isTrue) {
      state.isDownloading.value = false;
    }

    update(['audio_seekBar_id']);
    return path;
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

  Future<bool> _downloadFile(String path, String url,
      {int? ayahUqNumber}) async {
    Dio dio = Dio();
    state.cancelToken = CancelToken();

    try {
      // Get file size before downloading
      Response response = await dio.head(url);
      int? contentLength =
          response.headers.value(HttpHeaders.contentLengthHeader) != null
              ? int.tryParse(
                  response.headers.value(HttpHeaders.contentLengthHeader)!)
              : null;

      if (contentLength != null) {
        state.fileSize.value = contentLength;
        log('File size: $contentLength bytes');
      } else {
        log('Could not determine file size.');
      }

      await Directory(dirname(path)).create(recursive: true);
      state.isDownloading.value = true;
      state.progressString.value = "0";
      state.progress.value = 0;
      update(['seekBar_id']);

      await dio.download(url, path, onReceiveProgress: (rec, total) {
        state.progressString.value = ((rec / total) * 100).toStringAsFixed(0);
        state.progress.value = (rec / total).toDouble();
        state.downloadProgress.value = rec;
        update(['seekBar_id']);
      }, cancelToken: state.cancelToken);

      state.isDownloading.value = false;
      state.progressString.value = "100";
      log("Download completed for $path");
      if (ayahUqNumber != null) {
        state.ayahsDownloadStatus[ayahUqNumber] = true;
      }
      return true;
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        log('Download canceled');
        // Delete partially downloaded file
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
            state.isDownloading.value = false;
            log('Partially downloaded file deleted');
          }
        } catch (e) {
          log('Error deleting partially downloaded file: $e');
        }
        return false;
      } else {
        log('$e');
      }
      state.isDownloading.value = false;
      state.progressString.value = "0";
      update(['seekBar_id']);
      return false;
    }
  }

  void initializeSurahDownloadStatus() async {
    Map<int, bool> initialStatus = await checkAllSurahsDownloaded();
    state.surahDownloadStatus.value = initialStatus;
  }

  void updateDownloadStatus(int surahNumber, bool downloaded) {
    final newStatus = Map<int, bool>.from(state.surahDownloadStatus.value);
    newStatus[surahNumber] = downloaded;
    state.surahDownloadStatus.value = newStatus;
  }

  void onDownloadSuccess(int surahNumber) {
    updateDownloadStatus(surahNumber, true);
  }

  Future<Map<int, bool>> checkAllSurahsDownloaded() async {
    Directory? directory = await getApplicationDocumentsDirectory();
    Map<int, bool> surahDownloadStatus = {};

    for (int i = 1; i <= 114; i++) {
      String filePath =
          '${directory.path}/${state.surahReaderNameValue.value}${i.toString().padLeft(3, '0')}.mp3';
      File file = File(filePath);
      surahDownloadStatus[i] = await file.exists();
    }
    return surahDownloadStatus;
  }

  void cancelDownload() {
    state.isPlaying.value = false;
    state.cancelToken.cancel('Request cancelled');
  }

  Future<void> startDownload(BuildContext context) async {
    await state.audioPlayer.pause();
    await downloadSurah(context);
  }

  Future<void> _updateDownloadedAyahsMap() async {
    for (int i = 1; i <= 6236; i++) {
      String filePath =
          '${state.dir.path}/$ayahReaderValue/${currentAyahsSurah.ayahs[i].ayahUQNumber}.mp3';

      File file = File(filePath);
      final exists = await file.exists();
      if (exists) {
        state.ayahsDownloadStatus.update(i, (value) => exists);
      }
    }
  }

  Future<void> _addDownloadedSurahToPlaylist() async {
    for (int i = 1; i <= 114; i++) {
      String filePath =
          '${state.dir.path}/${state.surahReaderNameValue.value}${i.toString().padLeft(3, "0")}.mp3';

      File file = File(filePath);

      if (await file.exists()) {
        state.downloadSurahsPlayList.add({
          i: AudioSource.file(
            filePath,
            tag: mediaItem,
          )
        });
      }
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void updateControllerValues(PositionData positionData) {
    audioStream.listen((p) {
      state.lastPosition.value = p.position.inSeconds;
      state.seekNextSeconds.value = p.position.inSeconds;
      state.box.write(StorageConstants.lastPosition, p.position.inSeconds);
    });
  }

  Future<void> setCachedArtUri() async {
    final file = await DefaultCacheManager().getSingleFile(state.appIconUrl);
    final uri = await file.exists() ? file.uri : Uri.parse(state.appIconUrl);
    state.cachedArtUri = uri;
    return;
  }

  /// single Ayah
  ///
  Future<void> _playFile(BuildContext context) async {
    state.tmpDownloadedAyahsCount = 0;
    final ayahsFilesNames = selectedSurahAyahsFileNames;
    final surahKey = 'surah_$currentSurahNumberـ${state.ayahReaderIndex.value}';

    bool isSurahDownloaded = state.box.read(surahKey) ?? false;

    // if (!isSurahDownloaded) {
    try {
      if (state.playSingleAyahOnly) {
        final filePath = isSurahDownloaded
            ? join(state.dir.path, currentAyahFileName)
            : await _downloadFileIfNotExist(currentAyahUrl, currentAyahFileName,
                context: context, ayahUqNumber: state.currentAyahUnequeNumber);
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
        return;
      } else {
        state.snackBarShownForBatch = false;
        // final List<Future<String>> futures = List.generate(
        //   selectedSurahAyahsFileNames.length,
        //   (i) => _downloadFileIfNotExist(ayahsUrls[i], ayahsFilesNames[i],
        //           setDownloadingStatus: false,
        //           context: context,
        //           ayahUqNumber: currentAyahsSurah.ayahs[i].ayahUQNumber)
        //       .whenComplete(() {
        //     log('${state.tmpDownloadedAyahsCount} => download completed at ${DateTime.now().millisecond}');
        //     state.tmpDownloadedAyahsCount++;
        //   }),
        // );
        await state.audioPlayer.setAudioSources(
          currentSurahAudioSources,
          initialIndex: currentAyah.ayahNumber - 1,
        );
        // state.isDownloading.value = true;
        // await Future.wait(futures);
        // state.isDownloading.value = false;
        // state.box.write(surahKey, true);
      }

      log('تحميل سورة $selectedSurahAyahsFileNames تم بنجاح.');
    } catch (e) {
      log('Error in playFile: $e', name: 'AudioController');
    }
    // } else {
    //   state.isDownloading.value = false;
    //   log('سورة $selectedSurahAyahsFileNames محملة بالكامل.');
    // }

    try {
      log('${'-' * 30} player is starting.. ${'-' * 30}',
          name: 'AudioController');

      state.audioPlayer.currentIndexStream.listen((index) async {
        if (isLastAyahInPageButNotInSurah || isLastAyahInSurahAndPage) {
          await moveToNextPage(withScroll: true);
        }
        if (index != null && index < ayahsFilesNames.length) {
          log('state.currentAyahUQInPage.value: ${state.currentAyahUnequeNumber}');
          //   state.currentAyahUnequeNumber += index;
          // QuranLibrary.quranCtrl
          //     .toggleAyahSelection(state.currentAyahUnequeNumber);
        }
      });

      state.isPlaying.value = true;
      await state.audioPlayer
          .play()
          .then((_) => state.isPlaying.value = true)
          .whenComplete(() {
        state.audioPlayer.stop();
        state.isPlaying.value = false;
      });
    } catch (e) {
      state.isPlaying.value = false;
      state.audioPlayer.stop();
      log('Error in playFile: $e', name: 'AudioController');
    }
  }

  Future<void> playAyah(BuildContext context) async {
    // QuranCtrl.instance.toggleAyahSelection(state.currentAyahUnequeNumber);
    if (state.audioPlayer.playing || state.isPlaying.value) {
      state.isPlaying.value = false;
      await state.audioPlayer.pause();
    } else {
      await _playFile(context);
    }
  }

  Future<void> skipNextAyah() async {
    if (state.currentAyahUnequeNumber == 6236) {
      pausePlayer;
    } else if (isLastAyahInPageButNotInSurah || isLastAyahInSurahAndPage) {
      await moveToNextPage(withScroll: true);
      QuranCtrl.instance.toggleAyahSelection(state.currentAyahUnequeNumber);
      await state.audioPlayer.seekToNext();
    } else {
      QuranCtrl.instance.toggleAyahSelection(state.currentAyahUnequeNumber);
      await state.audioPlayer.seekToNext();
    }
  }

  void pausePlayer() async {
    state.isPlaying.value = false;
    await state.audioPlayer.pause();
  }

  Future<void> skipPreviousAyah() async {
    if (state.currentAyahUnequeNumber == 1) {
      return pausePlayer();
    } else if (isFirstAyahInPageButNotInSurah) {
      moveToPreviousPage();
      QuranLibrary.quranCtrl.toggleAyahSelection(state.currentAyahUnequeNumber);
      await state.audioPlayer.seekToPrevious();
    } else {
      QuranLibrary.quranCtrl.toggleAyahSelection(state.currentAyahUnequeNumber);
      await state.audioPlayer.seekToPrevious();
    }
  }

  void didChangeAppLifecycleState(AppLifecycleState states) {
    if (states == AppLifecycleState.paused) {
      state.audioPlayer.stop();
      state.isPlaying.value = false;
    }
  }
}
