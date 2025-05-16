part of '../../quran.dart';

extension FontSizeExtension on Widget {
  Widget fontSizeDropDown(
      {double? height, Color? color, required TafsirStyle tafsirStyle}) {
    final box = GetStorage();
    return PopupMenuButton(
      position: PopupMenuPosition.under,
      icon: Semantics(
        button: true,
        enabled: true,
        label: 'Change Font Size',
        child: tafsirStyle.fontSizeWidget,
      ),
      color: Colors.blue.withValues(alpha: .8),
      iconSize: height ?? 35.0,
      itemBuilder: (context) => [
        PopupMenuItem(
          height: 30,
          child: Obx(
            () => SizedBox(
              height: 30,
              width: MediaQuery.sizeOf(context).width,
              child: FlutterSlider(
                values: [TafsirCtrl.instance.fontSizeArabic.value],
                max: 50,
                min: 20,
                rtl: true,
                trackBar: FlutterSliderTrackBar(
                  inactiveTrackBarHeight: 5,
                  activeTrackBarHeight: 5,
                  inactiveTrackBar: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Get.theme.colorScheme.surface,
                  ),
                  activeTrackBar: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Get.theme.colorScheme.primaryContainer),
                ),
                handlerAnimation: const FlutterSliderHandlerAnimation(
                    curve: Curves.elasticOut,
                    reverseCurve: null,
                    duration: Duration(milliseconds: 700),
                    scale: 1.4),
                onDragging: (handlerIndex, lowerValue, upperValue) async {
                  lowerValue = lowerValue;
                  upperValue = upperValue;
                  TafsirCtrl.instance.fontSizeArabic.value = lowerValue;

                  box.write(_StorageConstants().fontSize, lowerValue);
                  TafsirCtrl.instance.update(['change_font_size']);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
