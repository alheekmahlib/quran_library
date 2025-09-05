class LottieConstants {
  LottieConstants._();
  static const String _packageBasePath =
      'packages/quran_library/assets/lottie/';

  /// play_button.json
  static String get assetsLottiePlayButton => "play_button.json";

  /// quran_au_ic.json
  static String get assetsLottieQuranAuIc => "quran_au_ic.json";

  static String get(String assetName) {
    return _packageBasePath + assetName;
  }
}
