part of '../audio.dart';

class AyahChangeReader extends StatelessWidget {
  final AyahAudioStyle? style;
  final bool? isDark;
  const AyahChangeReader({super.key, this.style, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: style!.dialogBackgroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(style!.dialogBorderRadius ?? 8.0),
          ),
          alignment: Alignment.center,
          insetPadding: const EdgeInsets.symmetric(horizontal: 64.0),
          child: dialogBuild(context),
        ),
      ),
      child: titleBuild(),
    );
  }

  Widget dialogBuild(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            List.generate(ReadersConstants.ayahReaderInfo.length, (index) {
          final isSelected = AudioCtrl.instance.state.ayahReaderIndex.value ==
              ReadersConstants.ayahReaderInfo[index]['index'];
          return ListTile(
            title: Text(
              '${ReadersConstants.ayahReaderInfo[index]['name']}'.tr,
              style: QuranLibrary().naskhStyle.copyWith(
                    color: style!.readerNameInItemColor ??
                        (isSelected
                            ? isDark!
                                ? Colors.white
                                : Colors.black
                            : const Color(0xffcdba72)),
                    fontSize: style!.readerNameInItemFontSize ?? 14,
                  ),
            ),
            trailing: Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected
                        ? isDark!
                            ? Colors.white
                            : Colors.black
                        : const Color(0xffcdba72),
                    width: 2),
                // color: const Color(0xff39412a),
              ),
              child: isSelected
                  ? Icon(
                      Icons.done,
                      size: 16,
                      color: Colors.black,
                    )
                  : null,
            ),
            onTap: () =>
                AudioCtrl.instance.changeAyahReadersOnTap(context, index),
          );
        }),
      ),
    );
  }

  Widget titleBuild() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() => Text(
              '${ReadersConstants.ayahReaderInfo[AudioCtrl.instance.state.ayahReaderIndex.value]['name']}'
                  .tr,
              style: QuranLibrary().naskhStyle.copyWith(
                    color: style!.textColor ??
                        (isDark! ? Colors.white : Colors.black),
                    fontSize: style!.readerNameFontSize ?? 18,
                  ),
            )),
        Semantics(
          button: true,
          enabled: true,
          label: 'Change Reader',
          child: Icon(Icons.keyboard_arrow_down_outlined,
              size: style!.readerNameFontSize ?? 20,
              color:
                  style!.textColor ?? (isDark! ? Colors.white : Colors.black)),
        ),
      ],
    );
  }
}
