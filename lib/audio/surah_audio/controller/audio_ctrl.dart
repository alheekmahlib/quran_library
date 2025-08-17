part of '../../audio.dart';

class AudioCtrl extends GetxController {
  AudioCtrl._();
  static AudioCtrl get instance => Get.isRegistered<AudioCtrl>()
      ? Get.find<AudioCtrl>()
      : Get.put<AudioCtrl>(AudioCtrl._(), permanent: true);

  SurahState state = SurahState();

  @override
  Future<void> onInit() async {
    initializeSurahDownloadStatus();
    state._dir ??= await getApplicationDocumentsDirectory();
    await Future.wait([
      _addDownloadedSurahToPlaylist(),
      _updateDownloadedAyahsMap(),
      loadLastSurahAndPosition(),
      setCachedArtUri(),
    ]);

    super.onInit();

    state.surahsPlayList = List.generate(114, (i) {
      state.selectedSurahIndex.value = i;
      return AudioSource.uri(
        Uri.parse(urlSurahFilePath),
      );
    });
    state.selectedSurahIndex.value = 0;
    loadSurahReader();
    loadAyahReader();

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
    // Future.delayed(const Duration(milliseconds: 700))
    //     .then((_) => jumpToSurah(state.currentAudioListSurahNum.value - 1));

    // Listen to player state changes to play the next Surah automatically
    state.audioPlayer.playerStateStream.listen((playerState) async {
      if (playerState.processingState == ProcessingState.completed &&
          state.isPlayingSurahsMode) {
        await playNextSurah();
      }
    });
    sheetState();
  }

  @override
  void onClose() {
    state.audioPlayer.pause();
    state.audioPlayer.dispose();
    super.onClose();
  }

  /// -------- [Methods] ----------

  Future<void> initAudioService() async {
    await AudioService.init(
      builder: () => AudioHandler.instance,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.alheekmah.quranPackage.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  }

  /// -------- [DownloadingMethods] ----------

  Future<void> downloadSurah({int? surahNum}) async {
    if (surahNum != null) {
      state.selectedSurahIndex.value = (surahNum - 1);
    }
    String filePath = localSurahFilePath;
    File file = File(filePath);
    log("File Path: $filePath", name: 'AudioCtrl');
    if (await file.exists()) {
      state.isPlaying.value = true;
      log("File exists. Playing...", name: 'AudioCtrl');

      await state.audioPlayer.setAudioSource(AudioSource.file(
        filePath,
        tag: mediaItem,
      ));
      state.audioPlayer.play();
    } else {
      if ((await Connectivity().checkConnectivity())
          .contains(ConnectivityResult.none)) {
        // عدم استخدام BuildContext عبر async gap - استخدام Get.snackbar بدلاً من ذلك
        // Show no internet connection error without using BuildContext
        if (Get.context != null) {
          UiHelper.showCustomErrorSnackBar(
              'لا يوجد اتصال بالإنترنت', Get.context!);
        }
      } else {
        state.isPlaying.value = true;
        log("File doesn't exist. Downloading...", name: 'AudioCtrl');
        log("state.sorahReaderNameValue: ${state.surahReaderNameValue}",
            name: 'AudioCtrl');
        log("Downloading from URL: $urlSurahFilePath", name: 'AudioCtrl');
        if (await _downloadFile(filePath, urlSurahFilePath)) {
          _addFileAudioSourceToPlayList(filePath);
          onDownloadSuccess(state.currentAudioListSurahNum.value);
          log("File successfully downloaded and saved to $filePath",
              name: 'AudioCtrl');
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
      {BuildContext? context,
      bool showSnakbars = true,
      bool setDownloadingStatus = true,
      int? ayahUqNumber}) async {
    String path = join((await state.dir).path, fileName);
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
        log('Error creating directory: $e', name: 'AudioCtrl');
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
          log('Error downloading file: $e', name: 'AudioCtrl');
        }
      } else {
        // إزالة استخدام BuildContext عبر async gap - استخدام Get.context بدلاً من ذلك
        // Avoid using BuildContext across async gap - use Get.context instead
        if (context != null && context.mounted) {
          UiHelper.showCustomErrorSnackBar('لا يوجد اتصال بالإنترنت', context);
        }
      }
    }

    if (setDownloadingStatus && state.isDownloading.isTrue) {
      state.isDownloading.value = false;
    }

    update(['audio_seekBar_id']);
    return path;
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
      log("Download completed for $path", name: 'AudioCtrl');
      if (ayahUqNumber != null) {
        state.ayahsDownloadStatus[ayahUqNumber] = true;
      }
      return true;
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        log('Download canceled', name: 'AudioCtrl');
        // Delete partially downloaded file
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
            state.isDownloading.value = false;
            log('Partially downloaded file deleted', name: 'AudioCtrl');
          }
        } catch (e) {
          log('Error deleting partially downloaded file: $e',
              name: 'AudioCtrl');
        }
        return false;
      } else {
        log('$e', name: 'AudioCtrl');
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
    Map<int, bool> surahDownloadStatus = {};
    final directory = await state.dir;

    for (int i = 1; i <= 114; i++) {
      String filePath =
          '${directory.path}/${state.surahReaderNameValue}${i.toString().padLeft(3, '0')}.mp3';
      File file = File(filePath);
      surahDownloadStatus[i] = await file.exists();
    }
    return surahDownloadStatus;
  }

  void cancelDownload() {
    state.isPlaying.value = false;
    state.cancelToken.cancel('Request cancelled');
  }

  Future<void> startDownload({int? surahNumber}) async {
    // إزالة BuildContext تماماً وجعل الدالة تستخدم Get.context داخلياً
    // Remove BuildContext completely and let the function use Get.context internally
    await state.audioPlayer.pause();
    await downloadSurah(surahNum: surahNumber);
  }

  Future<void> _addDownloadedSurahToPlaylist() async {
    final directory = await state.dir;
    for (int i = 1; i <= 114; i++) {
      String filePath =
          '${directory.path}/${state.surahReaderNameValue}${i.toString().padLeft(3, '0')}.mp3';

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

  void updateControllerValues(PackagePositionData positionData) {
    audioStream.listen((p) {
      state.lastPosition.value = p.position.inSeconds;
      state.seekNextSeconds.value = p.position.inSeconds;
      state.box.write(StorageConstants.lastPosition, p.position.inSeconds);
    });
  }

  Future<void> setCachedArtUri() async {
    final file =
        await DefaultCacheManager().getSingleFile(state.appIconUrl.value);
    final uri =
        await file.exists() ? file.uri : Uri.parse(state.appIconUrl.value);
    state.cachedArtUri = uri;
    return;
  }

  Future<void> pausePlayer() async {
    state.isPlaying.value = false;
    await state.audioPlayer.pause();
  }

  /// تحديث رابط أيقونة التطبيق / Update app icon URL
  /// [iconUrl] - الرابط الجديد لأيقونة التطبيق / New URL for app icon
  Future<void> updateAppIconUrl(String iconUrl) async {
    try {
      log('Updating app icon URL to: $iconUrl', name: 'AudioCtrl');

      // تحديث الرابط / Update the URL
      state.appIconUrl.value = iconUrl;

      // تحديث الأيقونة المخزنة مؤقتاً / Update cached icon
      await setCachedArtUri();

      log('App icon URL updated successfully', name: 'AudioCtrl');
    } catch (e) {
      log('Error updating app icon URL: $e', name: 'AudioCtrl');
      // في حالة الخطأ، استرجع الرابط الافتراضي / In case of error, revert to default URL
      state.appIconUrl.value =
          'https://raw.githubusercontent.com/alheekmahlib/thegarlanded/master/Photos/ios-1024.png';
      await setCachedArtUri();
    }
  }

  /// الحصول على رابط أيقونة التطبيق الحالي / Get current app icon URL
  String get currentAppIconUrl => state.appIconUrl.value;

  /// إعادة تعيين أيقونة التطبيق للرابط الافتراضي / Reset app icon to default URL
  Future<void> resetAppIconToDefault() async {
    await updateAppIconUrl(
        'https://raw.githubusercontent.com/alheekmahlib/thegarlanded/master/Photos/ios-1024.png');
  }

  void didChangeAppLifecycleState(AppLifecycleState states) {
    if (states == AppLifecycleState.paused) {
      state.audioPlayer.stop();
      state.isPlaying.value = false;
    }
  }
}
