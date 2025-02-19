part of '../../quran.dart';

class _ToastUtils {
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
  static final _ToastUtils _instance = _ToastUtils._internal();

  factory _ToastUtils() {
    return _instance;
  }

  _ToastUtils._internal();
}
