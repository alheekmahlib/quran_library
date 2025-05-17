part of '../../quran.dart';

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
    return Obx(() {
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        tafsirNameWidget,
                        Row(
                          children: [
                            ChangeTafsir(tafsirStyle: tafsirStyle),
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
                      child: _pagesBuild(context, width),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // شرح: بناء صفحات التفسير بشكل احترافي
  // Explanation: Build tafsir pages in a modern style
  Widget _pagesBuild(BuildContext context, double width) {
    final pageAyahs = quranCtrl.getPageAyahsByIndex(pageIndex);
    final selectedAyahIndexInFullPage =
        pageAyahs.indexWhere((ayah) => ayah.ayahUQNumber == ayahUQNumber);
    if ((tafsirCtrl.tafseerList.isEmpty &&
        tafsirCtrl.translationList.isEmpty)) {
      return const SizedBox.shrink();
    }
    return PageView.builder(
      controller: PageController(initialPage: selectedAyahIndexInFullPage),
      itemCount: pageAyahs.length,
      itemBuilder: (context, i) {
        final ayahs = pageAyahs[i];
        int ayahIndex = pageAyahs.first.ayahUQNumber + i;
        final tafsir = tafsirCtrl.tafseerList.firstWhere(
          (element) => element.id == ayahIndex,
          orElse: () => const TafsirTableData(
              id: 0, tafsirText: '', ayahNum: 0, pageNum: 0, surahNum: 0),
        );
        return Container(
          width: width,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tafsirStyle.backgroundColor ??
                (isDark ? const Color(0xff1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 0),
              ),
            ],
            border: Border.symmetric(
              horizontal: BorderSide(
                color:
                    tafsirStyle.textColor ?? Colors.grey.withValues(alpha: 0.8),
                width: 1.2,
              ),
            ),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: GetBuilder<TafsirCtrl>(
              id: 'change_font_size',
              builder: (tafsirCtrl) => _actualTafseerWt(
                  context,
                  ayahIndex,
                  tafsir,
                  ayahs,
                  tafsirCtrl.isTafsir.value,
                  tafsirCtrl.translationList,
                  tafsirCtrl.fontSizeArabic.value),
            ),
          ),
        );
      },
    );
  }

  // شرح: أضف المتغيرات المطلوبة كوسائط لتقليل الاعتماد على الكنترولر
  // Explanation: Add required variables as parameters to reduce controller dependency
  Widget _actualTafseerWt(
      BuildContext context,
      int ayahIndex,
      TafsirTableData tafsir,
      AyahModel ayahs,
      bool isTafsir,
      List translationList,
      double fontSizeArabic) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '﴿${ayahs.text}﴾\n',
            style: TextStyle(
              fontFamily: 'uthmanic2',
              fontSize: 24,
              height: 1.9,
              color: (isDark ? Colors.white : Colors.black),
            ),
          ),
          WidgetSpan(
              child: context.horizontalDivider(
            color: tafsirStyle.textColor ?? Colors.grey.withValues(alpha: 0.8),
            height: 1.5,
          )),
          isTafsir
              ? TextSpan(
                  children: tafsir.tafsirText.customTextSpans(),
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.5,
                      fontSize: fontSizeArabic),
                )
              : TextSpan(
                  text: (translationList.length > (ayahIndex - 1) &&
                          (ayahIndex - 1) >= 0)
                      ? translationList[ayahIndex - 1].text
                      : '',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.5,
                      fontSize: fontSizeArabic),
                ),
        ],
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );
  }
}
