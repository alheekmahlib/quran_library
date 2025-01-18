part of '../../presentation/pages/quran_library_screen.dart';

class ToastUtils {
  Future<bool?> showToast(String msg,
          {ToastGravity? gravity, Toast? toastLength}) =>
      Fluttertoast.showToast(
          msg: msg,
          toastLength: toastLength ?? Toast.LENGTH_LONG,
          gravity: gravity ?? ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: const Color(0xffe8decb),
          textColor: Colors.black,
          fontSize: 16.0);

  Future<bool?> hideToast() => Fluttertoast.cancel();

  ///Singleton factory
  static final ToastUtils _instance = ToastUtils._internal();

  factory ToastUtils() {
    return _instance;
  }

  ToastUtils._internal();
}
