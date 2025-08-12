part of '../../audio.dart';

class SurahAudioState {
  /// -------- [Variables] ----------

  AudioPlayer audioPlayer = AudioPlayer();
  RxBool isDownloading = false.obs;
  RxBool isPlaying = false.obs;
  RxString progressString = "0".obs;
  RxDouble progress = 0.0.obs;
  RxInt currentAudioListSurahNum = 1.obs;
  var cancelToken = CancelToken();
  late Uri cachedArtUri;
  TextEditingController textController = TextEditingController();
  RxInt selectedSurahIndex = 0.obs;
  final ScrollController surahListController = ScrollController();
  RxString surahReaderValue = "https://download.quranicaudio.com/quran/".obs;
  RxString surahReaderNameValue = "abdul_basit_murattal/".obs;
  RxString ayahReaderValue = "https://download.quranicaudio.com/quran/".obs;
  RxString ayahReaderNameValue = "abdul_basit_murattal/".obs;
  final bool isDisposed = false;
  List<AudioSource>? surahsPlayList;
  List<Map<int, AudioSource>> downloadSurahsPlayList = [];
  double? lastTime;
  RxInt lastPosition = 0.obs;
  Rx<PositionData>? positionData;
  var activeButton = RxString('');
  final TextEditingController textEditingController = TextEditingController();
  RxInt surahReaderIndex = 1.obs;
  final Rx<Map<int, bool>> surahDownloadStatus = Rx<Map<int, bool>>({});
  RxBool isSurahDownloadedByNumber(int surahNumber) =>
      (surahDownloadStatus.value[surahNumber] ?? false).obs;
  Map<int, bool> ayahsDownloadStatus =
      Map.fromEntries(List.generate(6236, (i) => MapEntry(i + 1, false)));
  RxInt seekNextSeconds = 5.obs;
  final box = GetStorage();
  RxInt fileSize = 0.obs;
  RxInt downloadProgress = 0.obs;
  RxBool audioServiceInitialized = false.obs;
  RxBool isDirectPlaying = false.obs;
  late Directory dir;
  bool snackBarShownForBatch = false;

  /// ===== single verse =====
  int currentAyahUniqueNumber = 1;

  int tmpDownloadedAyahsCount = 0;
  RxInt ayahReaderIndex = 0.obs;

  /// if true, then play single ayah only.
  /// false state is not ready.
  bool playSingleAyahOnly = true;

  // App icon URL - يمكن للمستخدم تخصيصه / User can customize the app icon URL
  RxString appIconUrl =
      'https://raw.githubusercontent.com/alheekmahlib/thegarlanded/master/Photos/ios-1024.png'
          .obs;
  SlidingPanelController panelController = SlidingPanelController();
  RxBool isSheetOpen = false.obs;
}
