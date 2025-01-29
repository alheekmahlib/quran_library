part of '../../quran.dart';

class ToastUtils {
  void showToast(BuildContext context, String msg) {
    final snackBar = SnackBar(
      content: Text(
        msg,
        style: QuranLibrary().naskhStyle,
      ),
      backgroundColor: const Color(0xffe8decb),
      duration: const Duration(seconds: 3),
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
