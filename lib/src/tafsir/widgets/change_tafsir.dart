part of '../tafsir.dart';

class ChangeTafsirPopUp extends StatelessWidget {
  final TafsirStyle tafsirStyle;
  final List<TafsirNameModel>? tafsirNameList;
  final int? pageNumber;
  const ChangeTafsirPopUp(
      {super.key,
      required this.tafsirStyle,
      this.tafsirNameList,
      this.pageNumber});

  @override
  Widget build(BuildContext context) {
    // tafsirCtrl.initializeTafsirDownloadStatus();
    return GetBuilder<TafsirCtrl>(
        id: 'tafsirs_menu_list',
        builder: (tafsirCtrl) {
          return PopupMenuButton(
            position: PopupMenuPosition.under,
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            itemBuilder: (context) => List.generate(
                tafsirCtrl.tafsirAndTranslationsItems.length, (index) {
              return PopupMenuItem(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: tafsirCtrl.radioValue.value == index
                        ? (tafsirStyle.selectedTafsirColor ?? Colors.blue)
                            .withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tafsirCtrl.radioValue.value == index
                          ? tafsirStyle.selectedTafsirColor ?? Colors.blue
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      TafsirItemWidget(
                        tafsirIndex: index,
                        pageNumber: pageNumber ??
                            QuranCtrl.instance.state.currentPageNumber.value,
                        tafsirNameList: tafsirNameList,
                        tafsirStyle: tafsirStyle,
                      ),
                      index == 4
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 1,
                                      child: Container(
                                          width: 70,
                                          height: 2,
                                          color: tafsirStyle.linesColor ??
                                              Colors.blue)),
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
                                          width: 200,
                                          height: 2,
                                          color: tafsirStyle.linesColor ??
                                              Colors.blue))
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              );
            }),
            child: Semantics(
              button: true,
              enabled: true,
              label: 'Change Font Size',
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tafsirStyle.unSelectedTafsirColor ?? Colors.grey,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      tafsirNameList?[tafsirCtrl.radioValue.value].name ??
                          tafsirCtrl
                              .tafsirAndTranslationsItems[
                                  tafsirCtrl.radioValue.value]
                              .name,
                      style: QuranLibrary().naskhStyle.copyWith(
                            color: tafsirStyle.unSelectedTafsirColor ??
                                const Color(0xffCDAD80),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Semantics(
                      button: true,
                      enabled: true,
                      label: 'Change Reader',
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 24,
                          color:
                              tafsirStyle.unSelectedTafsirColor ?? Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}

class TafsirItemWidget extends StatelessWidget {
  TafsirItemWidget({
    super.key,
    required this.tafsirNameList,
    required this.tafsirStyle,
    required this.tafsirIndex,
    this.pageNumber,
  });

  final List<TafsirNameModel>? tafsirNameList;
  final TafsirStyle tafsirStyle;
  final int tafsirIndex;
  final int? pageNumber;
  final tafsirCtrl = TafsirCtrl.instance;

  @override
  Widget build(BuildContext context) {
    bool isDownloaded =
        tafsirCtrl.tafsirDownloadIndexList.contains(tafsirIndex);
    return ListTile(
      title: Text(
        tafsirNameList?[tafsirIndex].name ??
            tafsirCtrl.tafsirAndTranslationsItems[tafsirIndex].name,
        style: QuranLibrary().naskhStyle.copyWith(
              color: tafsirCtrl.radioValue.value == tafsirIndex
                  ? tafsirStyle.selectedTafsirColor ?? Colors.black
                  : tafsirStyle.unSelectedTafsirColor ??
                      const Color(0xffCDAD80),
              fontSize: 14,
            ),
      ),
      subtitle: Text(
        tafsirIndex >= 5
            ? ''
            : tafsirNameList?[tafsirIndex].bookName ??
                tafsirCtrl.tafsirAndTranslationsItems[tafsirIndex].bookName,
        style: QuranLibrary().naskhStyle.copyWith(
              color: tafsirCtrl.radioValue.value == tafsirIndex
                  ? tafsirStyle.selectedTafsirColor ?? Colors.black
                  : tafsirStyle.unSelectedTafsirColor ??
                      const Color(0xffCDAD80),
              fontSize: 12,
            ),
      ),
      trailing: isDownloaded
          ? Container(
              height: 20,
              width: 20,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: tafsirStyle.unSelectedTafsirColor ??
                        const Color(0xffCDAD80),
                    width: 2),
                color: Colors.white,
              ),
              child: tafsirCtrl.radioValue.value == tafsirIndex
                  ? Icon(
                      Icons.done,
                      size: 14,
                      color: tafsirStyle.selectedTafsirColor ??
                          const Color(0xffCDAD80),
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
                    color: tafsirIndex == tafsirCtrl.downloadIndex.value
                        ? tafsirCtrl.onDownloading.value
                            ? tafsirStyle.selectedTafsirColor ??
                                const Color(0xffCDAD80)
                            : Colors.transparent
                        : Colors.transparent,
                    value: tafsirCtrl.progress.value,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.cloud_download_outlined,
                      size: 22,
                      color: tafsirStyle.unSelectedTafsirColor ??
                          const Color(0xffCDAD80)),
                  onPressed: () async {
                    tafsirIndex >= 5
                        ? tafsirCtrl.isTafsir.value = false
                        : tafsirCtrl.isTafsir.value = true;
                    tafsirCtrl.downloadIndex.value = tafsirIndex;
                    await tafsirCtrl.tafsirDownload(tafsirIndex);
                  },
                ),
              ],
            ),
      onTap: () async {
        if (!isDownloaded) return;
        await tafsirCtrl.handleRadioValueChanged(tafsirIndex,
            pageNumber: pageNumber);
        // GetStorage().write(_StorageConstants().radioValue, index);
        // tafsirCtrl.fetchTranslate();
        // tafsirCtrl.update(['tafsirs_menu_list']);
        if (context.mounted) Navigator.of(context).pop();
      },
      leading: Container(
          height: 85.0,
          width: 41.0,
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: const BorderRadius.all(Radius.circular(4.0)),
              border: Border.all(
                  color: tafsirStyle.unSelectedTafsirColor ??
                      const Color(0xffCDAD80),
                  width: 2)),
          child: Opacity(
            opacity: tafsirCtrl.radioValue.value == tafsirIndex ? 1 : .4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                    height: 90,
                    width: 40.0,
                    color: tafsirStyle.linesColor ?? Colors.blue),
                Container(
                  height: 60,
                  width: 30.0,
                  alignment: Alignment.center,
                  child: Text(
                    tafsirNameList?[tafsirIndex].name ??
                        tafsirCtrl.tafsirAndTranslationsItems[tafsirIndex].name,
                    style: QuranLibrary().naskhStyle.copyWith(
                          color: tafsirCtrl.radioValue.value == tafsirIndex
                              ? tafsirStyle.selectedTafsirColor ?? Colors.black
                              : tafsirStyle.unSelectedTafsirColor ??
                                  const Color(0xffCDAD80),
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
  }
}
