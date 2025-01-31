part of '../../quran.dart';

extension ConvertArabicToEnglishNumbersExtension on String {
  String convertArabicNumbersToEnglish(String input) {
    const arabicNumbers = '٠١٢٣٤٥٦٧٨٩';
    const englishNumbers = '0123456789';

    return input.split('').map((char) {
      int index = arabicNumbers.indexOf(char);
      if (index != -1) {
        return englishNumbers[index];
      }
      return char;
    }).join('');
  }

  String convertEnglishNumbersToArabic(String input) {
    const arabicNumbers = '٠١٢٣٤٥٦٧٨٩';
    const englishNumbers = '0123456789';

    return input.split('').map((char) {
      int index = englishNumbers.indexOf(char);
      if (index != -1) {
        return arabicNumbers[index];
      }
      return char;
    }).join('');
  }
}
