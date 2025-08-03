import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/audio/surah_audio/controller/extensions/surah_audio_ui.dart';
import '/audio/surah_audio/controller/surah_audio_controller.dart';
import '../constants/readers_constants.dart';

class ChangeReader extends StatelessWidget {
  const ChangeReader({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      position: PopupMenuPosition.over,
      color: Theme.of(context).colorScheme.primaryContainer,
      itemBuilder: (context) => List.generate(
          ReadersConstants.ayahReaderInfo.length,
          (index) => PopupMenuItem(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: ListTile(
                  title: Text(
                    '${ReadersConstants.ayahReaderInfo[index]['name']}'.tr,
                    style: TextStyle(
                        color: SurahAudioController
                                    .instance.state.surahReaderValue ==
                                ReadersConstants.ayahReaderInfo[index]
                                    ['readerD']
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
                          color: SurahAudioController
                                      .instance.state.surahReaderValue ==
                                  ReadersConstants.ayahReaderInfo[index]
                                      ['readerD']
                              ? Theme.of(context).colorScheme.inversePrimary
                              : const Color(0xffcdba72),
                          width: 2),
                      // color: const Color(0xff39412a),
                    ),
                    child: SurahAudioController
                                .instance.state.surahReaderValue ==
                            ReadersConstants.ayahReaderInfo[index]['readerD']
                        ? Icon(Icons.done,
                            size: 14,
                            color: Theme.of(context).colorScheme.inversePrimary)
                        : null,
                  ),
                  onTap: () =>
                      SurahAudioController.instance.changeReadersOnTap(index),
                  leading: Container(
                    height: 80.0,
                    width: 80.0,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                              'assets/images/${ReadersConstants.ayahReaderInfo[index]['readerI']}.jpg'),
                          fit: BoxFit.fitWidth,
                          opacity: SurahAudioController
                                      .instance.state.surahReaderValue ==
                                  ReadersConstants.ayahReaderInfo[index]
                                      ['readerD']
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
            Obx(() => Text(
                  '${ReadersConstants.ayahReaderInfo[SurahAudioController.instance.state.surahReaderIndex.value]['name']}'
                      .tr,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 13,
                      fontFamily: 'kufi'),
                )),
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
