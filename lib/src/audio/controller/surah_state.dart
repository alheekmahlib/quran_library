part of '../audio.dart';

class SurahState {
  /// -------- [Variables] ----------

  AudioPlayer audioPlayer = AudioPlayer();
  bool isPlayingSurahsMode = false;

  // إدارة حالة الصوت المركزية / Central audio state management
  static bool _isAudioServiceActive = false;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  // قد تتغير أنواع الدفق (int? أو SequenceState) بحسب واجهة المشغّل، لذا نجعلها غير مقيّدة
  StreamSubscription? _currentIndexSubscription;

  // getter وsetter للحالة النشطة / getter and setter for active state
  static bool get isAudioServiceActive => _isAudioServiceActive;
  static void setAudioServiceActive(bool value) =>
      _isAudioServiceActive = value;
  RxBool isDownloading = false.obs;
  RxBool isPlaying = false.obs;
  RxString progressString = "0".obs;
  RxDouble progress = 0.0.obs;
  var cancelToken = CancelToken();
  Uri? cachedArtUri;
  TextEditingController textController = TextEditingController();
  RxInt selectedSurahIndex = 0.obs;
  final ScrollController surahListController = ScrollController();
  String get surahReaderUrl =>
      ReadersConstants.activeSurahReaders[surahReaderIndex.value].url;
  String get surahReaderNameValue => ReadersConstants
      .activeSurahReaders[surahReaderIndex.value].readerNamePath;
  // RxString ayahReaderNameValue = "abdul_basit_murattal/".obs;
  final bool isDisposed = false;
  List<AudioSource>? surahsPlayList;
  List<Map<int, AudioSource>> downloadSurahsPlayList = [];
  double? lastTime;
  RxInt lastPosition = 0.obs;
  Rx<PackagePositionData>? positionData;
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
  // منع إعادة الإدخال عند الانتقال التلقائي للسورة التالية
  bool surahAutoNextInProgress = false;
  // إشارة لإلغاء التحميل الجاري (دفعة آيات السورة)
  RxBool cancelRequested = false.obs;
  // رقم السورة الجاري تحميل آياتها حاليًا (-1 إذا لا يوجد)
  RxInt currentDownloadingAyahSurahNumber = (-1).obs;
  Directory? _dir;
  Future<Directory> get dir async {
    if (!kIsWeb) {
      return _dir ??= await getApplicationDocumentsDirectory();
    }
    throw UnsupportedError('Directory access is not supported on web');
  }

  bool snackBarShownForBatch = false;

  /// ===== single verse =====
  int currentAyahUniqueNumber = 1;

  int tmpDownloadedAyahsCount = 0;
  RxInt ayahReaderIndex = 0.obs;

  /// if true, then play single ayah only.
  /// false state is not ready.
  bool playSingleAyahOnly = false;

  // App icon URL - يمكن للمستخدم تخصيصه / User can customize the app icon URL
  RxString appIconUrl =
      'https://raw.githubusercontent.com/alheekmahlib/thegarlanded/master/Photos/Packages/quran_library/quran_library_logo.jpg'
          .obs;
  SlidingPanelController panelController = SlidingPanelController();
  RxBool isSheetOpen = false.obs;
  RxInt get currentAudioListSurahNum => (selectedSurahIndex.value + 1).obs;

  /// إيقاف جميع الاشتراكات / Cancel all subscriptions
  void cancelAllSubscriptions() {
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _playerStateSubscription = null;
    _currentIndexSubscription = null;
  }

  /// إيقاف جميع الأصوات / Stop all audio
  Future<void> stopAllAudio() async {
    await audioPlayer.stop();
    isPlaying.value = false;
    cancelAllSubscriptions();
  }

  RxDouble ayahDownloadProgress = 0.0.obs;
}
