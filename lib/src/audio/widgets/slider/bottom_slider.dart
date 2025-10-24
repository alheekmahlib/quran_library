part of '../../../../quran.dart';

class BottomSlider extends StatelessWidget {
  // متغير يحدد إذا كان السلايدر ظاهر أم لا
  // Determines if the slider is visible
  final bool isVisible;
  final VoidCallback onClose;
  final Widget child;
  final Widget contentChild;
  final double? sliderHeight;
  final AyahAudioStyle? style;
  final bool isDark;

  BottomSlider({
    super.key,
    required this.isVisible,
    required this.onClose,
    required this.child,
    required this.contentChild,
    this.sliderHeight = 0.0,
    this.style,
    this.isDark = false,
  });

  // الحصول على الكونترولر الخاص بالسلايدر
  // Get the slider controller
  final sliderCtrl = SliderController.instance;

  @override
  Widget build(BuildContext context) {
    // تحديث حالة الظهور عند كل بناء
    // Update visibility state on every build
    sliderCtrl.updateBottomVisibility(isVisible);

    if (!isVisible) return const SizedBox.shrink();

    return Align(
      alignment: kIsWeb ? Alignment.bottomLeft : Alignment.bottomCenter,
      // لا داعي لاستخدام Obx هنا لأن bottomSlideAnim ليس Rx ولا متغير ملاحظ
      // No need for Obx here, bottomSlideAnim is not Rx and not observable
      child: SlideTransition(
        position: sliderCtrl.bottomSlideAnim,
        child: Obx(() => Container(
              // ارتفاع ديناميكي للسلايدر
              // Dynamic height for slider
              height: MediaQuery.of(context).size.height *
                      sliderCtrl.bottomSliderHeight.value +
                  sliderHeight!,
              width: kIsWeb
                  ? MediaQuery.of(context).size.width * .5
                  : MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: style!.backgroundColor ??
                    AppColors.getBackgroundColor(isDark),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(style!.borderRadius ?? 16),
                  topRight: Radius.circular(style!.borderRadius ?? 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -5), // changes position of shadow
                  ),
                ],
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                // تحديد ما إذا كان السلايدر في الحالة الصغيرة أم الكبيرة
                // Determine if slider is in small or large state
                // final isSmallState = constraints.maxHeight < 150;

                return Column(
                  mainAxisSize: MainAxisSize.min, // تغيير لـ min لتجنب overflow
                  children: [
                    // ====== Handle للسحب ======
                    // ====== Drag Handle ======
                    GestureDetector(
                      // عند السحب للأعلى يفتح السلايدر، وعند السحب للأسفل يغلق
                      // On vertical drag: up opens, down closes
                      onVerticalDragUpdate: (details) {
                        if (details.primaryDelta != null) {
                          if (details.primaryDelta! < -8) {
                            // سحب للأعلى: فتح السلايدر
                            // Drag up: open
                            sliderCtrl.setMediumHeight(context);
                            sliderCtrl.updateBottomHandleVisibility(true);
                            Future.delayed(
                              const Duration(milliseconds: 400),
                              () => QuranCtrl
                                  .instance.state.isPlayExpanded.value = true,
                            );
                          } else if (details.primaryDelta! > 8) {
                            // سحب للأسفل: إغلاق السلايدر
                            // Drag down: close

                            QuranCtrl.instance.state.isPlayExpanded.value =
                                false;
                            sliderCtrl.setSmallHeight();
                          }
                        }
                      },
                      child: Container(
                        width: 70,
                        height: 8,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    child,
                    // تقليل المساحة في الحالة الصغيرة
                    // Reduce space in small state
                    // SizedBox(height: isSmallState ? 4 : 8),
                  ],
                );
              }),
            )),
      ),
    );
  }
}
