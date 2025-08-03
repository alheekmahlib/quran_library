import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/readers_constants.dart';
import '../controller/extensions/surah_audio_ui.dart';
import '../controller/surah_audio_controller.dart';

class ChangeSurahReader extends StatelessWidget {
  const ChangeSurahReader({super.key});

  @override
  Widget build(BuildContext context) {
    final surahAudioCtrl = SurahAudioController.instance;
    return PopupMenuButton(
      position: PopupMenuPosition.over,
      color: Theme.of(context).colorScheme.primaryContainer,
      itemBuilder: (context) => List.generate(
          ReadersConstants.surahReaderInfo.length,
          (index) => PopupMenuItem(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: ListTile(
                  title: Text(
                    '${ReadersConstants.surahReaderInfo[index]['name']}'.tr,
                    style: TextStyle(
                        color: surahAudioCtrl.state.surahReaderNameValue ==
                                ReadersConstants.surahReaderInfo[index]
                                    ['readerN']
                            ? Theme.of(context).colorScheme.inversePrimary
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
                                  ReadersConstants.surahReaderInfo[index]
                                      ['readerN']
                              ? Theme.of(context).colorScheme.inversePrimary
                              : const Color(0xffcdba72),
                          width: 2),
                    ),
                    child: surahAudioCtrl.state.surahReaderNameValue ==
                            ReadersConstants.surahReaderInfo[index]['readerN']
                        ? Icon(Icons.done,
                            size: 14,
                            color: Theme.of(context).colorScheme.inversePrimary)
                        : null,
                  ),
                  onTap: () => surahAudioCtrl.changeReadersOnTap(index),
                  leading: Container(
                    height: 80.0,
                    width: 80.0,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                              'assets/images/${ReadersConstants.surahReaderInfo[index]['readerI']}.jpg'),
                          fit: BoxFit.fitWidth,
                          opacity: surahAudioCtrl.state.surahReaderNameValue ==
                                  ReadersConstants.surahReaderInfo[index]
                                      ['readerN']
                              ? 1
                              : .4,
                        ),
                        shape: BoxShape.rectangle,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4.0)),
                        border: Border.all(
                            color: Theme.of(context).dividerColor, width: 2)),
                  ),
                ),
              )),
      child: Semantics(
        button: true,
        enabled: true,
        label: 'Change Font Size',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              return Text(
                '${ReadersConstants.surahReaderInfo[surahAudioCtrl.state.surahReaderIndex.value]['name']}'
                    .tr,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 13,
                    fontFamily: 'kufi'),
              );
            }),
            Semantics(
              button: true,
              enabled: true,
              label: 'Change Reader',
              child: Icon(Icons.keyboard_arrow_down_outlined,
                  size: 20, color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
