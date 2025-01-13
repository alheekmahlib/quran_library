class Preferences {
  final String bookmarks = 'bookmarks';
  final String lastPage = 'last_page';
  final String isDownloadedCodeV2Fonts = 'isDownloadedCodeV2Fonts';
  final String isBold = 'IS_BOLD';

  ///Singleton factory
  static final Preferences _instance = Preferences._internal();

  factory Preferences() {
    return _instance;
  }

  Preferences._internal();
}
