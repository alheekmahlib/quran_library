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

  ShowTafseer(
      {super.key,
      required this.ayahUQNumber,
      required this.tafsirStyle,
      required this.ayahNumber,
      required this.pageIndex,
      required this.context});

  // شرح: تأكد من تسجيل الكنترولر بطريقة آمنة حسب تعليماتك
  // Explanation: Ensure controller is registered safely as per your instructions
  static TafsirCtrl get tafsirCtrlInstance => Get.isRegistered<TafsirCtrl>()
      ? Get.find<TafsirCtrl>()
      : Get.put(TafsirCtrl());

  final tafsirCtrl = tafsirCtrlInstance;
  final quranCtrl = QuranCtrl.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext ctx) {
    // شرح: نتأكد أن عناصر tafsirStyle غير فارغة لتجنب الخطأ
    // Explanation: Ensure tafsirStyle widgets are not null to avoid null check errors
    final iconCloseWidget = tafsirStyle.iconCloseWidget ?? const SizedBox();
    final tafsirNameWidget = tafsirStyle.tafsirNameWidget ?? const SizedBox();

    // شرح: استخدم Obx لمراقبة المتغيرات الريأكتيفية مباشرة
    // Explanation: Use Obx to directly observe reactive variables
    return Obx(() {
      // حماية من null للقوائم والمتغيرات
      final isTafsir = tafsirCtrl.isTafsir.value;
      final tafseerList = tafsirCtrl.tafseerList;
      final translationList = tafsirCtrl.translationList;
      final fontSizeArabic = tafsirCtrl.fontSizeArabic.value;

      // شرح: إذا لم يكن context تابع لـ MaterialApp/Scaffold نستخدم قيم افتراضية
      // Explanation: If context is not under MaterialApp/Scaffold, use default values
      final mediaQuery = MediaQuery.maybeOf(ctx);
      // final theme = Theme.maybeOf(ctx);

      final double height = mediaQuery?.size.height ?? 600;
      final double width = mediaQuery?.size.width ?? 400;
      // final Color surfaceColor = theme?.colorScheme.surface ?? Colors.white;
      // final Color primaryColor = theme?.colorScheme.primary ?? Colors.blue;

      return Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          height: height * .9,
          width: width,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              )),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        iconCloseWidget,
                        const SizedBox(width: 32),
                        tafsirNameWidget,
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ChangeTafsir(tafsirStyle: tafsirStyle),
                        Container(width: 1, height: 20, color: Colors.blue),
                        Transform.translate(
                            offset: const Offset(0, 5),
                            child: fontSizeDropDown(
                                height: 25.0, tafsirStyle: tafsirStyle)),
                      ],
                    ),
                  ],
                ),
                _pagesBuild(ctx, tafseerList, translationList, isTafsir,
                    fontSizeArabic, width),
              ],
            ),
          ),
        ),
      );
    });
  }

  // شرح: مرر القوائم والمتغيرات مباشرة لتقليل الاعتماد على الكنترولر داخل الدالة
  // Explanation: Pass lists and variables directly to reduce controller dependency inside the function
  Widget _pagesBuild(
    BuildContext context,
    List<TafsirTableData> tafseerList,
    List translationList,
    bool isTafsir,
    double fontSizeArabic,
    double width,
  ) {
    final pageAyahs = quranCtrl.getPageAyahsByIndex(pageIndex);
    final selectedAyahIndexInFullPage =
        pageAyahs.indexWhere((ayah) => ayah.ayahUQNumber == ayahUQNumber);

    if ((tafseerList.isEmpty && translationList.isEmpty)) {
      // شرح: إذا القوائم فارغة لا تعرض شيء
      // Explanation: If lists are empty, show nothing
      return const SizedBox.shrink();
    }

    return Flexible(
      child: PageView.builder(
        controller: PageController(initialPage: selectedAyahIndexInFullPage),
        itemCount: pageAyahs.length,
        itemBuilder: (context, i) {
          final ayahs = pageAyahs[i];
          int ayahIndex = pageAyahs.first.ayahUQNumber + i;
          final tafsir = tafseerList.firstWhere(
            (element) => element.id == ayahIndex,
            orElse: () => const TafsirTableData(
                id: 0, tafsirText: '', ayahNum: 0, pageNum: 0, surahNum: 0),
          );
          return Container(
            width: width, // شرح: استخدم القيمة المحمية
            decoration: BoxDecoration(
                color: tafsirStyle.backgroundColor ??
                    Colors.white.withValues(alpha: .1),
                border: Border.symmetric(
                    horizontal: BorderSide(
                  width: 2,
                  color: tafsirStyle.textColor ?? Colors.blue,
                ))),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: _actualTafseerWt(context, ayahIndex, tafsir, ayahs,
                      isTafsir, translationList, fontSizeArabic),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // شرح: أضف المتغيرات المطلوبة كوسائط لتقليل الاعتماد على الكنترولر
  // Explanation: Add required variables as parameters to reduce controller dependency
  Widget _actualTafseerWt(
      BuildContext context,
      int ayahIndex,
      TafsirTableData tafsir,
      AyahFontsModel ayahs,
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
              color: Colors.black,
            ),
          ),
          isTafsir
              ? TextSpan(
                  children: tafsir.tafsirText.customTextSpans(),
                  style: TextStyle(
                      color: Colors.black,
                      height: 1.5,
                      fontSize: fontSizeArabic),
                )
              : TextSpan(
                  text: (translationList.length > (ayahIndex - 1) &&
                          (ayahIndex - 1) >= 0)
                      ? translationList[ayahIndex - 1].text
                      : '',
                  style: TextStyle(
                      color: Colors.black,
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
