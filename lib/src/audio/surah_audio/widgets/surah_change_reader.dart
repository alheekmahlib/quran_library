part of '../../audio.dart';

class SurahChangeSurahReader extends StatelessWidget {
  final SurahAudioStyle? style;
  SurahChangeSurahReader({super.key, this.style});
  final surahAudioCtrl = AudioCtrl.instance;

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => Text(
                '${ReadersConstants.surahReaderInfo[surahAudioCtrl.state.surahReaderIndex.value]['name']}'
                    .tr,
                style: QuranLibrary().naskhStyle.copyWith(
                      color: style?.readerNameInItemColor ?? Colors.black,
                      fontSize: 20,
                    ),
              )),
          Semantics(
            button: true,
            enabled: true,
            label: 'Change Reader',
            child: Icon(Icons.keyboard_arrow_down_outlined,
                size: 24, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget dialogBuild(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        shrinkWrap: true,
        children: List.generate(
          ReadersConstants.surahReaderInfo.length,
          (index) => ListTile(
            minTileHeight: 40,
            selectedColor: Colors.blue,
            title: Text(
              '${ReadersConstants.surahReaderInfo[index]['name']}'.tr,
              style: QuranLibrary().naskhStyle.copyWith(
                  color: surahAudioCtrl.state.surahReaderNameValue ==
                          ReadersConstants.surahReaderInfo[index]['readerN']
                      ? style?.readerNameInItemColor ?? Colors.black
                      : const Color(0xffcdba72),
                  fontSize: 14,
                  fontFamily: "kufi"),
            ),
            trailing: Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: surahAudioCtrl.state.surahReaderNameValue ==
                            ReadersConstants.surahReaderInfo[index]['readerN']
                        ? Colors.black
                        : const Color(0xffcdba72),
                    width: 2),
              ),
              child: surahAudioCtrl.state.surahReaderNameValue ==
                      ReadersConstants.surahReaderInfo[index]['readerN']
                  ? Icon(Icons.done, size: 14, color: Colors.black)
                  : null,
            ),
            onTap: () => surahAudioCtrl.changeSurahReadersOnTap(context, index),
          ),
        ),
      ),
    );
  }
}
