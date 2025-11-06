part of '/quran.dart';

class ToastUtils {
  void showToast(BuildContext context, String msg) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final style = SnackBarTheme.of(context)?.style ??
        SnackBarStyle.defaults(isDark: isDark, context: context);

    // إذا كانت الإشعارات المعروضة عبر SnackBar معطلة، لا تقم بعرض أي شيء
    if (style.enabled == false) return;

    final snackBar = SnackBar(
      content: Text(
        msg,
        style: style.textStyle ??
            QuranLibrary().naskhStyle.copyWith(
                  color: AppColors.getTextColor(isDark),
                ),
        textAlign: TextAlign.center,
      ),
      backgroundColor: style.backgroundColor,
      duration: style.duration ?? const Duration(seconds: 3),
      behavior: style.behavior ?? SnackBarBehavior.floating,
      margin: style.margin ??
          EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 100,
            right: 16,
            left: 16,
          ),
      padding: style.padding,
      elevation: style.elevation,
      shape: (style.borderRadius != null)
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(style.borderRadius!),
            )
          : null,
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
