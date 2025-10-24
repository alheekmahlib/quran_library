part of '../tafsir.dart';

class ChangeTafsirDialog extends StatelessWidget {
  final TafsirStyle tafsirStyle;
  final List<TafsirNameModel>? tafsirNameList;
  final int? pageNumber;
  final bool? isDark;
  ChangeTafsirDialog(
      {super.key,
      required this.tafsirStyle,
      this.tafsirNameList,
      this.pageNumber,
      this.isDark = false});

  final tafsirCtrl = TafsirCtrl.instance;

  @override
  Widget build(BuildContext context) {
    // tafsirCtrl.initializeTafsirDownloadStatus();
    return Semantics(
      button: true,
      enabled: true,
      label: 'Change Tafsir',
      child: GestureDetector(
        onTap: () {
          showDialog(
              context: context,
              builder: (context) {
                return DailogBuild(
                  tafsirStyle: tafsirStyle,
                  pageNumber: pageNumber,
                  tafsirNameList: tafsirNameList,
                  isDark: isDark!,
                );
              });
        },
        child: Container(
          width: 160.w,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  tafsirNameList?[tafsirCtrl.radioValue.value].name ??
                      tafsirCtrl
                          .tafsirAndTranslationsItems[
                              tafsirCtrl.radioValue.value]
                          .name,
                  style: QuranLibrary().cairoStyle.copyWith(
                        color: tafsirStyle.currentTafsirColor ??
                            const Color(0xffCDAD80),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 24,
                  color: tafsirStyle.unSelectedTafsirColor ?? Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class DailogBuild extends StatelessWidget {
  const DailogBuild({
    super.key,
    required this.tafsirStyle,
    required this.pageNumber,
    required this.tafsirNameList,
    required this.isDark,
  });

  final TafsirStyle tafsirStyle;
  final int? pageNumber;
  final List<TafsirNameModel>? tafsirNameList;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TafsirCtrl>(
        id: 'tafsirs_menu_list',
        builder: (tafsirCtrl) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 500),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                      tafsirCtrl.tafsirAndTranslationsItems.length, (index) {
                    return Column(
                      children: [
                        tafsirOrTranslateTitle(index),
                        TafsirItemWidget(
                          tafsirIndex: index,
                          pageNumber: pageNumber ??
                              QuranCtrl.instance.state.currentPageNumber.value,
                          tafsirNameList: tafsirNameList,
                          tafsirStyle: tafsirStyle,
                          isDark: isDark!,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          );
        });
  }

  Widget tafsirOrTranslateTitle(int index, {String? title}) {
    if (index == 0 || index == TafsirCtrl.instance.translationsStartIndex) {
      title ??= index == 0
          ? tafsirStyle.tafsirName ?? 'التفاسير'
          : tafsirStyle.translateName ?? 'الترجمات';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        decoration: BoxDecoration(
          color: tafsirStyle.backgroundTitleColor ?? Color(0xffCDAD80),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: QuranLibrary().cairoStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: tafsirStyle.textTitleColor ?? Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class TafsirItemWidget extends StatelessWidget {
  TafsirItemWidget({
    super.key,
    required this.tafsirNameList,
    required this.tafsirStyle,
    required this.tafsirIndex,
    this.pageNumber,
    required this.isDark,
  });

  final List<TafsirNameModel>? tafsirNameList;
  final TafsirStyle tafsirStyle;
  final int tafsirIndex;
  final int? pageNumber;
  final bool isDark;
  final tafsirCtrl = TafsirCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TafsirCtrl>(
      id: 'tafsirs_menu_list',
      builder: (tafsirCtrl) {
        RxBool isDownloaded =
            (kIsWeb || tafsirCtrl.tafsirDownloadIndexList.contains(tafsirIndex))
                .obs;
        return InkWell(
          onTap: () async {
            if (!isDownloaded.value) return;
            await tafsirCtrl.handleRadioValueChanged(tafsirIndex,
                pageNumber: pageNumber);
            // GetStorage().write(_StorageConstants().radioValue, index);
            // tafsirCtrl.fetchTranslate();
            // tafsirCtrl.update(['tafsirs_menu_list']);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: tafsirCtrl.radioValue.value == tafsirIndex
                  ? (tafsirStyle.selectedTafsirColor ?? const Color(0xffCDAD80))
                      .withValues(alpha: 0.3)
                  : (tafsirStyle.unSelectedTafsirColor ?? Color(0xffCDAD80))
                      .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tafsirCtrl.radioValue.value == tafsirIndex
                    ? (tafsirStyle.selectedTafsirBorderColor ??
                            const Color(0xffCDAD80))
                        .withValues(alpha: 0.5)
                    : tafsirStyle.unSelectedTafsirBorderColor ??
                        Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Obx(
                  () => isDownloaded.value
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
                                color: tafsirIndex ==
                                        tafsirCtrl.downloadIndex.value
                                    ? tafsirCtrl.onDownloading.value
                                        ? tafsirStyle.selectedTafsirColor ??
                                            const Color(0xffCDAD80)
                                        : Colors.transparent
                                    : Colors.transparent,
                                value: tafsirCtrl.progress.value,
                              ),
                            ),
                            if (!kIsWeb)
                              IconButton(
                                icon: Icon(Icons.cloud_download_outlined,
                                    size: 22,
                                    color: tafsirStyle.unSelectedTafsirColor ??
                                        const Color(0xffCDAD80)),
                                onPressed: () async {
                                  tafsirCtrl.downloadIndex.value = tafsirIndex;
                                  await tafsirCtrl.tafsirDownload(tafsirIndex);
                                },
                              ),
                          ],
                        ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tafsirNameList?[tafsirIndex].name ??
                                tafsirCtrl
                                    .tafsirAndTranslationsItems[tafsirIndex]
                                    .name,
                            style: QuranLibrary().cairoStyle.copyWith(
                                  color: tafsirCtrl.radioValue.value ==
                                          tafsirIndex
                                      ? tafsirStyle.selectedTafsirTextColor ??
                                          (isDark ? Colors.white : Colors.black)
                                      : tafsirStyle.unSelectedTafsirTextColor ??
                                          (isDark
                                              ? Colors.white
                                              : Colors.black),
                                  fontSize: 14,
                                ),
                          ),
                          Text(
                            tafsirIndex >= 28
                                ? ''
                                : tafsirNameList?[tafsirIndex].bookName ??
                                    tafsirCtrl
                                        .tafsirAndTranslationsItems[tafsirIndex]
                                        .bookName,
                            style: QuranLibrary().cairoStyle.copyWith(
                                  color: tafsirCtrl.radioValue.value ==
                                          tafsirIndex
                                      ? tafsirStyle.selectedTafsirTextColor ??
                                          (isDark ? Colors.white : Colors.black)
                                      : tafsirStyle.unSelectedTafsirTextColor ??
                                          (isDark
                                              ? Colors.white
                                              : Colors.black),
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
