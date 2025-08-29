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

  BottomSlider({
    super.key,
    required this.isVisible,
    required this.onClose,
    required this.child,
    required this.contentChild,
    this.sliderHeight = 0.0,
    this.style,
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
      alignment: Alignment.bottomCenter,
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
              decoration: BoxDecoration(
                color: style!.backgroundColor ?? Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(style!.borderRadius ?? 16),
                  topRight: Radius.circular(style!.borderRadius ?? 16),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 32,
                    offset: Offset(0, -12),
                  ),
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 20,
                    offset: Offset(0, -8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                // تحديد ما إذا كان السلايدر في الحالة الصغيرة أم الكبيرة
                // Determine if slider is in small or large state
                final isSmallState = constraints.maxHeight < 150;

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
                    SizedBox(height: isSmallState ? 4 : 8),
                  ],
                );
              }),
            )),
      ),
    );
  }
}
