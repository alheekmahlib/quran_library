part of '/quran.dart';

class WordInfoCtrl extends GetxController
    with GetSingleTickerProviderStateMixin {
  static WordInfoCtrl get instance =>
      GetInstance().putOrFind(() => WordInfoCtrl());

  WordInfoCtrl({WordInfoRepository? repository})
      : _repository = repository ?? WordInfoRepository();

  final WordInfoRepository _repository;

  // حارس لمنع إعادة prewarm لنفس السورة مراراً أثناء بناء صفحات المصحف.
  final Set<int> _prewarmedRecitationsSurahs = <int>{};

  final RxBool isPreparingDownload = false.obs;
  final RxBool isDownloading = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final Rx<WordInfoKind?> downloadingKind = Rx<WordInfoKind?>(null);

  final Rx<WordInfoKind> selectedKind = WordInfoKind.recitations.obs;

  final Rx<WordRef?> selectedWordRef = Rx<WordRef?>(null);
  late TabController tabController;

  bool get isTenRecitations => tabController.index == 1;

  @override
  void onInit() {
    tabController = TabController(length: 2, vsync: this);
    super.onInit();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void setSelectedKind(WordInfoKind kind) {
    selectedKind.value = kind;
    update(['word_info_kind']);
  }

  void setSelectedWord(WordRef ref) {
    selectedWordRef.value = ref;
    update(['word_info_data']);
  }

  void clearSelectedWord() {
    if (selectedWordRef.value == null) return;
    selectedWordRef.value = null;
    update(['word_info_data']);
  }

  bool isKindAvailable(WordInfoKind kind) => _repository.isKindDownloaded(kind);

  QiraatWordInfo? getRecitationsInfoSync(WordRef ref) =>
      _repository.getRecitationWordInfoSync(ref: ref);

  Future<QiraatWordInfo?> getRecitationsInfo(WordRef ref) =>
      _repository.getWordInfo(kind: WordInfoKind.recitations, ref: ref);

  Future<QiraatWordInfo?> getWordInfo({
    required WordInfoKind kind,
    required WordRef ref,
  }) =>
      _repository.getWordInfo(kind: kind, ref: ref);

  Future<void> downloadKind(WordInfoKind kind) async {
    if (isDownloading.value) return;

    try {
      downloadingKind.value = kind;
      isPreparingDownload.value = true;
      isDownloading.value = true;
      downloadProgress.value = 0.0;
      update(['word_info_download']);

      await _repository.downloadKind(
        kind: kind,
        onProgress: (p) {
          isPreparingDownload.value = false;
          downloadProgress.value = p;
          update(['word_info_download']);
        },
      );

      isPreparingDownload.value = false;
      isDownloading.value = false;
      downloadingKind.value = null;
      downloadProgress.value = 100.0;
      update(['word_info_download', 'word_info_data']);
    } catch (e) {
      isPreparingDownload.value = false;
      isDownloading.value = false;
      downloadingKind.value = null;
      downloadProgress.value = 0.0;
      update(['word_info_download']);
      rethrow;
    }
  }

  Future<void> prewarmRecitationsSurah(int surahNumber) async {
    if (!_prewarmedRecitationsSurahs.add(surahNumber)) return;
    await _repository.prewarmRecitationsSurah(surahNumber);
    // إعادة بناء واحدة بعد تحميل بيانات السورة الجديدة
    update(['word_info_data']);
  }

  Future<void> prewarmRecitationsSurahs(Iterable<int> surahNumbers) async {
    log('Prewarming recitations for surahs: $surahNumbers',
        name: 'WordInfoCtrl');
    final unique = surahNumbers.toSet();
    var didPrewarmAny = false;
    for (final s in unique) {
      if (!_prewarmedRecitationsSurahs.add(s)) continue;
      didPrewarmAny = true;
      await _repository.prewarmRecitationsSurah(s);
    }
    if (didPrewarmAny) {
      update(['word_info_data']);
    }
  }
}
