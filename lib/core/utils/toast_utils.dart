part of '../../presentation/pages/quran_library_screen.dart';

class ToastUtils {
  SnackbarController showToast(String msg) => Get.showSnackbar(GetSnackBar(
        message: msg,
        backgroundColor: const Color(0xffe8decb),
      ));

  ///Singleton factory
  static final ToastUtils _instance = ToastUtils._internal();

  factory ToastUtils() {
    return _instance;
  }

  ToastUtils._internal();
}
