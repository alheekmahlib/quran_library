import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A utility class for displaying toast messages.
///
/// This class provides methods to display various types of toast messages
/// to the user, such as success, error, and information messages.
class ToastUtils {
  /// Singleton instance
  static final ToastUtils _instance = ToastUtils._();

  /// Private constructor
  ToastUtils._();

  /// Factory constructor to return the singleton instance
  factory ToastUtils() => _instance;

  /// Shows a success toast message.
  ///
  /// [message] - The message to display.
  /// [duration] - How long to display the message. Defaults to 3 seconds.
  void showSuccessToast(String message, {Duration? duration}) {
    Get.snackbar(
      'نجاح',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Shows an error toast message.
  ///
  /// [message] - The message to display.
  /// [duration] - How long to display the message. Defaults to 3 seconds.
  void showErrorToast(String message, {Duration? duration}) {
    Get.snackbar(
      'خطأ',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Shows an information toast message.
  ///
  /// [message] - The message to display.
  /// [duration] - How long to display the message. Defaults to 3 seconds.
  void showInfoToast(String message, {Duration? duration}) {
    Get.snackbar(
      'معلومات',
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Shows a warning toast message.
  ///
  /// [message] - The message to display.
  /// [duration] - How long to display the message. Defaults to 3 seconds.
  void showWarningToast(String message, {Duration? duration}) {
    Get.snackbar(
      'تحذير',
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}