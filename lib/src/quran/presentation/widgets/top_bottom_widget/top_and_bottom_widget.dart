part of '/quran.dart';

/// ويدجت لعرض محتوى السورة المخصصة مع المعلومات المطلوبة
/// Widget for displaying custom surah content with required information
class TopAndBottomWidget extends StatelessWidget {
  final int pageIndex;
  final bool isRight;
  final bool? isSurah;
  final int? surahNumber;
  final String? languageCode;
  final Widget child;

  TopAndBottomWidget({
    super.key,
    required this.pageIndex,
    required this.isRight,
    required this.child,
    this.languageCode,
    this.isSurah = false,
    this.surahNumber,
  });

  final surahCtrl = SurahCtrl.instance;
  final quranCtrl = QuranCtrl.instance;

  @override
  Widget build(BuildContext context) {
    final isMobileLargeOrDesktop = Responsive.isMobile(context) ||
        Responsive.isMobileLarge(context) ||
        Responsive.isDesktop(context);
    return UiHelper.currentOrientation(
      // شرح: التخطيط العمودي (Portrait)
      // Explanation: Portrait layout
      Stack(
        children: [
          // شرح: العنوان العلوي
          // Explanation: Top title
          Align(
            alignment: Alignment.topCenter,
            child: BuildTopSection(
              isRight: isRight,
              languageCode: languageCode,
              pageIndex: pageIndex,
              isSurah: isSurah!,
              surahNumber: surahNumber,
            ),
          ),

          // شرح: المحتوى الرئيسي
          // Explanation: Main content
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: child,
            ),
          ),

          // شرح: القسم السفلي
          // Explanation: Bottom section
          Align(
            alignment: Alignment.bottomCenter,
            child: Stack(
              children: [
                BuildBottomSection(
                    pageIndex: pageIndex,
                    isRight: isRight,
                    languageCode: languageCode!),
                /// My Note: in Portrait مثلث في الزاوية اليمنى (يمين رقم الصفحة)
                if (pageIndex != 0 && pageIndex != 1)
                  buildBottomSectionTriangle(
                      isRight: isRight,
                      size: 0.12.sw,
                      color: isRight
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.blue.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ],
      ),

      // شرح: التخطيط الأفقي (Landscape)
      // Explanation: Landscape layout
      isMobileLargeOrDesktop
          ? LayoutBuilder(
              builder: (context, constraints) {
                final bounded = constraints.maxHeight.isFinite;
                return Stack(
                  children: [
                    Column(
                      children: [
                        BuildTopSection(
                          isRight: isRight,
                          languageCode: languageCode,
                          pageIndex: pageIndex,
                          isSurah: isSurah!,
                          surahNumber: surahNumber,
                        ),
                        if (bounded) Flexible(child: child) else child,
                        BuildBottomSection(
                            pageIndex: pageIndex,
                            isRight: isRight,
                            languageCode: languageCode!),
                      ],
                    ),
                    /// My Notes: in Landscape مثلث في الزاوية اليمنى (يمين رقم الصفحة)
                    if (pageIndex != 0 && pageIndex != 1)
                      buildBottomSectionTriangle(
                          isRight: isRight,
                          size: math.min(0.09.sh, 0.09.sw),
                          color: isRight
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.blue.withValues(alpha: 0.3)),
                  ],
                );
              },
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  BuildTopSection(
                    isRight: isRight,
                    languageCode: languageCode,
                    pageIndex: pageIndex,
                    isSurah: isSurah!,
                    surahNumber: surahNumber,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: child,
                  ),
                  BuildBottomSection(
                      pageIndex: pageIndex,
                      isRight: isRight,
                      languageCode: languageCode!),
                ],
              ),
            ),
      context,
    );
  }
}

Widget buildBottomSectionTriangle(
    {required bool isRight, required Color color, required double size}) {
  return Align(
    alignment: isRight ? Alignment.bottomRight : Alignment.bottomLeft,
    child: CustomPaint(
      size: Size.square(size),
      // fill the triangle to the height of the page number text
      painter: _TrianglePainter(
        color: color,
        isRight: isRight,
      ),
    ),
  );
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool isRight;

  _TrianglePainter({
    required this.color,
    required this.isRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    final double length = size.width;
    if (!isRight) {
      path.moveTo(0, 0);
      path.lineTo(length, length);
      path.lineTo(0, length);
    } else {
      path.moveTo(length, 0);
      path.lineTo(0, length);
      path.lineTo(length, length);
    }

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
