// final List<TajweedRuleModel> tajweedRulesListAr = [
//   TajweedRuleModel(color: 0xff999999, text: "إدغام ، وما لا يُلفَظ"),
//   TajweedRuleModel(color: 0xffFFC1E0, text: "مدّ حركتان"),
//   TajweedRuleModel(color: 0xffFF8E3B, text: "مدّ ٢ أو ٤ أو ٦ جوازا"),
//   TajweedRuleModel(color: 0xffFF5E8E, text: "مدّ واجب ٤ أو ٥ حركات"),
//   TajweedRuleModel(color: 0xffE30000, text: "مدّ ٦ حركات لزوما"),
//   TajweedRuleModel(color: 0xff26B55D, text: "إخفاء ، ومواقع الغُنًّة (حركتان)"),
//   TajweedRuleModel(color: 0xff00DEFF, text: "قلقلة"),
//   TajweedRuleModel(color: 0xff3C84D5, text: "تفخيم"),
// ];
//
// final List<TajweedRuleModel> tajweedRulesListEn = [
//   TajweedRuleModel(color: 0xff999999, text: "Silent letter"),
//   TajweedRuleModel(color: 0xffFFC1E0, text: "Normal madd (2)"),
//   TajweedRuleModel(color: 0xffFF8E3B, text: "Separated madd (2/4/6)"),
//   TajweedRuleModel(color: 0xffFF5E8E, text: "Connected madd (4/5)"),
//   TajweedRuleModel(color: 0xffE30000, text: "Necessary madd (6)"),
//   TajweedRuleModel(color: 0xff26B55D, text: "Ghunna/ikhfa’"),
//   TajweedRuleModel(color: 0xff00DEFF, text: "Qalqala (echo)"),
//   TajweedRuleModel(color: 0xff3C84D5, text: "Tafkhim (heavy)"),
// ];
//
// final List<TajweedRuleModel> tajweedRulesListBn = [
//   TajweedRuleModel(color: 0xff999999, text: "ইদগাম"),
//   TajweedRuleModel(color: 0xffFFC1E0, text: "মাদ 2 সেকেন্ড"),
//   TajweedRuleModel(color: 0xffFF8E3B, text: "অনুমোদিত মাদ 2 বা 4 বা 6 সেকেন্ড"),
//   TajweedRuleModel(color: 0xffFF5E8E, text: "প্রয়োজনীয় মাদ ৪ বা ৫ সেকেন্ড"),
//   TajweedRuleModel(color: 0xffE30000, text: "প্রয়োজনীয় মাদ ৬ সেকেন্ড"),
//   TajweedRuleModel(color: 0xff26B55D, text: "ইখফা ও ঘুন্না"),
//   TajweedRuleModel(color: 0xff00DEFF, text: "কলকালা"),
//   TajweedRuleModel(color: 0xff3C84D5, text: "তাফখিম"),
// ];
//
// final List<TajweedRuleModel> tajweedRulesListId = [
//   TajweedRuleModel(color: 0xff999999, text: "Idgham"),
//   TajweedRuleModel(color: 0xffFFC1E0, text: "Maad 2 detik"),
//   TajweedRuleModel(
//       color: 0xffFF8E3B, text: "Diperbolehkan Maad 2 atau 4 atau 6 detik"),
//   TajweedRuleModel(color: 0xffFF5E8E, text: "Diperlukan Maad 4 atau 5 detik"),
//   TajweedRuleModel(color: 0xffE30000, text: "Perlu Maad 6 detik"),
//   TajweedRuleModel(color: 0xff26B55D, text: "Ikhfa dan Ghunna"),
//   TajweedRuleModel(color: 0xff00DEFF, text: "Qalqala"),
//   TajweedRuleModel(color: 0xff3C84D5, text: "Tafkhim"),
// ];
//
// final List<TajweedRuleModel> tajweedRulesListTr = [
//   TajweedRuleModel(color: 0xff999999, text: "İdğam"),
//   TajweedRuleModel(color: 0xffFFC1E0, text: "2 saniye bekle"),
//   TajweedRuleModel(
//       color: 0xffFF8E3B, text: "İzin verilen Maad 2 veya 4 veya 6 saniye"),
//   TajweedRuleModel(color: 0xffFF5E8E, text: "Gerekli Maad 4 veya 5 saniye"),
//   TajweedRuleModel(color: 0xffE30000, text: "Gerekli Maad 6 saniye"),
//   TajweedRuleModel(color: 0xff26B55D, text: "İhfa ve Ghunna"),
//   TajweedRuleModel(color: 0xff00DEFF, text: "Kalkala"),
//   TajweedRuleModel(color: 0xff3C84D5, text: "Tefhim"),
// ];
//
// final List<TajweedRuleModel> tajweedRulesListUr = [
//   TajweedRuleModel(color: 0xff999999, text: "ادغام"),
//   TajweedRuleModel(color: 0xffFFC1E0, text: "مد طبعی (2 حرکات)"),
//   TajweedRuleModel(
//       color: 0xffFF8E3B, text: "مد جائز منفصل (2 یا 4 یا 6 حرکات)"),
//   TajweedRuleModel(color: 0xffFF5E8E, text: "مد واجب متصل (4 یا 5 حرکات)"),
//   TajweedRuleModel(color: 0xffE30000, text: "مد لازم (6 حرکات)"),
//   TajweedRuleModel(color: 0xff26B55D, text: "اخفاء اور غنہ"),
//   TajweedRuleModel(color: 0xff00DEFF, text: "قلقلہ"),
//   TajweedRuleModel(color: 0xff3C84D5, text: "تفخیم"),
// ];
//
// class TajweedRuleModel {
//   final int color;
//   final String text;
//
//   TajweedRuleModel({required this.color, required this.text});
//
//   factory TajweedRuleModel.fromJson(Map<String, dynamic> json) {
//     return TajweedRuleModel(
//       color: json['color'],
//       text: json['text'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'color': color,
//       'text': text,
//     };
//   }
// }
