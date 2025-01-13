const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

extension StringExtensions on String {
  String insert(String text, int index) =>
      substring(0, index) + text + substring(index);

  String toArabic() {
    String number = this;
    for (int i = 0; i < english.length; i++) {
      number = number.replaceAll(english[i], arabic[i]);
    }
    return number;
  }
}
