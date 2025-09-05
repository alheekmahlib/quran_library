part of '../tafsir.dart';
// ملاحظة هامة: يجب تضمين هذا الودجت ضمن Scaffold عند الاستدعاء حتى لا تظهر مشكلة "No Scaffold widget found"
// Important: This widget must be shown inside a Scaffold to avoid "No Scaffold widget found" error.

// مثال للاستخدام الصحيح:
// Example for correct usage:
// showModalBottomSheet(
//   context: context,
//   builder: (_) => Scaffold(body: ShowTafseer(...)),
// );

class ShowTafseer extends StatelessWidget {
  late final int ayahUQNumber;
  final int pageIndex;
  final TafsirStyle tafsirStyle;
  final BuildContext context;
  final int ayahNumber;
  final bool isDark;

  ShowTafseer(
      {super.key,
      required this.ayahUQNumber,
      required this.tafsirStyle,
      required this.ayahNumber,
      required this.pageIndex,
      required this.context,
      required this.isDark});

  final tafsirCtrl = TafsirCtrl.instance;
  final quranCtrl = QuranCtrl.instance;

  @override
  Widget build(BuildContext context) {
    // شرح: نتأكد أن عناصر tafsirStyle غير فارغة لتجنب الخطأ
    // Explanation: Ensure tafsirStyle widgets are not null to avoid null check errors
    final tafsirNameWidget = tafsirStyle.tafsirNameWidget ?? const SizedBox();
    final double height = MediaQuery.maybeOf(context)?.size.height ?? 600;
    final double width = MediaQuery.maybeOf(context)?.size.width ?? 400;
    // تحسين الشكل: إضافة شريط علوي أنيق مع زر إغلاق واسم التفسير
    // UI Enhancement: Add a modern top bar with close button and tafsir name
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: height * .9,
        width: width,
        child: SafeArea(
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: tafsirStyle.backgroundColor ??
                  (isDark ? const Color(0xff1E1E1E) : Colors.white),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                // خط فاصل جمالي
                Container(
                  width: 60,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade500,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // شريط علوي احترافي
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      tafsirNameWidget,
                      Row(
                        children: [
                          ChangeTafsirPopUp(tafsirStyle: tafsirStyle),
                          const SizedBox(width: 8),
                          Container(
                              width: 1,
                              height: 24,
                              color: Colors.grey.shade300),
                          const SizedBox(width: 8),
                          Transform.translate(
                            offset: const Offset(0, 2),
                            child: fontSizeDropDown(
                                height: 30.0, tafsirStyle: tafsirStyle),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // محتوى التفسير
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: tafsirStyle.backgroundColor ??
                          (isDark ? const Color(0xff1E1E1E) : Colors.white),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: TafsirPagesBuild(
                      pageIndex: pageIndex,
                      ayahUQNumber: ayahUQNumber,
                      tafsirStyle: tafsirStyle,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
