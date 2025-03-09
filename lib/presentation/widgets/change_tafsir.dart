part of '../../quran.dart';

class ChangeTafsir extends StatelessWidget {
  final TafsirStyle tafsirStyle;
  ChangeTafsir({super.key, required this.tafsirStyle});

  final ayatCtrl = TafsirCtrl.instance;

  @override
  Widget build(BuildContext context) {
    ayatCtrl.initializeTafsirDownloadStatus();
    return GetBuilder<TafsirCtrl>(
      id: 'change_tafsir',
      builder: (tafsirCtrl) => PopupMenuButton(
        position: PopupMenuPosition.under,
        color: Colors.white,
        itemBuilder: (context) => List.generate(tafsirName.length, (index) {
          return PopupMenuItem(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _tafsirBuild(context, index),
                index == 4
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 1,
                                child: Container(
                                    width: 70, height: 2, color: Colors.blue)),
                            Expanded(
                              flex: 3,
                              child: Text(
                                tafsirStyle.translateName ?? 'الترجمات',
                                style: QuranLibrary()
                                    .naskhStyle
                                    .copyWith(fontSize: 20),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                                flex: 5,
                                child: Container(
                                    width: 200, height: 2, color: Colors.blue))
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          );
        }),
        child: Semantics(
          button: true,
          enabled: true,
          label: 'Change Font Size',
          child: SizedBox(
            width: 120,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    tafsirName[tafsirCtrl.radioValue.value]['name'],
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'kufi'),
                  ),
                  Semantics(
                    button: true,
                    enabled: true,
                    label: 'Change Reader',
                    child: Icon(Icons.keyboard_arrow_down_outlined,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tafsirBuild(BuildContext context, int index) {
    return GetBuilder<TafsirCtrl>(
        id: 'change_tafsir',
        builder: (tafsirCtrl) {
          bool isDownloaded = tafsirCtrl.tafsirDownloadIndex.contains(index);
          return ListTile(
            title: Text(
              tafsirName[index]['name'],
              style: QuranLibrary().naskhStyle.copyWith(
                    color: tafsirCtrl.radioValue.value == index
                        ? Colors.black
                        : const Color(0xffCDAD80),
                    fontSize: 14,
                  ),
            ),
            subtitle: Text(
              index >= 5 ? '' : tafsirName[index]['bookName'],
              style: QuranLibrary().naskhStyle.copyWith(
                    color: tafsirCtrl.radioValue.value == index
                        ? Colors.black
                        : const Color(0xffCDAD80),
                    fontSize: 12,
                  ),
            ),
            trailing: isDownloaded
                ? Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xffCDAD80), width: 2),
                      color: Colors.white,
                    ),
                    child: tafsirCtrl.radioValue.value == index
                        ? Icon(
                            Icons.done,
                            size: 14,
                            color: const Color(0xffCDAD80),
                          )
                        : null,
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Obx(
                        () => CircularProgressIndicator(
                          strokeWidth: 2,
                          backgroundColor: Colors.transparent,
                          color: index == tafsirCtrl.downloadIndex.value
                              ? tafsirCtrl.onDownloading.value
                                  ? Get.theme.indicatorColor
                                  : Colors.transparent
                              : Colors.transparent,
                          value: tafsirCtrl.progress.value,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.cloud_download_outlined,
                            size: 22, color: Get.theme.indicatorColor),
                        onPressed: () async {
                          index >= 5
                              ? tafsirCtrl.isTafsir.value = false
                              : tafsirCtrl.isTafsir.value = true;
                          tafsirCtrl.downloadIndex.value = index;
                          await tafsirCtrl.tafsirDownload(index);
                        },
                      ),
                    ],
                  ),
            onTap: () async {
              if (!isDownloaded) return;
              await tafsirCtrl.handleRadioValueChanged(index);
              GetStorage().write(_StorageConstants().tafsirValue, index);
              tafsirCtrl.fetchTranslate();
              tafsirCtrl.update(['change_tafsir']);
              Get.back();
            },
            leading: Container(
                height: 85.0,
                width: 41.0,
                decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                    border: Border.all(
                        color: Theme.of(context).cardColor, width: 2)),
                child: Opacity(
                  opacity: tafsirCtrl.radioValue.value == index ? 1 : .4,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(height: 90, width: 40.0, color: Colors.blue),
                      Container(
                        height: 60,
                        width: 30.0,
                        alignment: Alignment.center,
                        child: Text(
                          tafsirName[index]['name'],
                          style: QuranLibrary().naskhStyle.copyWith(
                                color: tafsirCtrl.radioValue.value == index
                                    ? Colors.black
                                    : const Color(0xffCDAD80),
                                fontSize: 7,
                              ),
                          maxLines: 3,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )),
          );
        });
  }
}
