part of '/quran.dart';

class ToastUtils {
  void showToast(BuildContext context, String msg) {
    final snackBar = SnackBar(
      content: Text(
        msg,
        style: QuranLibrary().naskhStyle,
        textAlign: TextAlign.center,
      ),
      backgroundColor: const Color(0xffe8decb),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          right: 16,
          left: 16),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  ///Singleton factory
  static final ToastUtils _instance = ToastUtils._internal();

  factory ToastUtils() {
    return _instance;
  }

  ToastUtils._internal();
}
