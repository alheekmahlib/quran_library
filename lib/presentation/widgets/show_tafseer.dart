part of '../../quran.dart';

class ShowTafseer extends StatelessWidget {
  late final int ayahUQNumber;
  final int pageIndex;
  final TafsirStyle tafsirStyle;

  final int index;

  ShowTafseer(
      {super.key,
      required this.ayahUQNumber,
      required this.tafsirStyle,
      required this.index,
      required this.pageIndex});

  final ScrollController _scrollController = ScrollController();
  final quranCtrl = QuranCtrl.instance;

  final tafsirCtrl = TafsirCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          height: Get.height * .9,
          width: Get.width,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              )),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        tafsirStyle.iconCloseWidget!,
                        const SizedBox(width: 32),
                        tafsirStyle.tafsirNameWidget!,
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ChangeTafsir(tafsirStyle: tafsirStyle),
                        Container(width: 1, height: 20, color: Colors.blue),
                        Transform.translate(
                            offset: const Offset(0, 5),
                            child: fontSizeDropDown(
                                height: 25.0, tafsirStyle: tafsirStyle)),
                      ],
                    ),
                  ],
                ),
                _pagesBuild(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actualTafseerWt(BuildContext context, int ayahIndex,
      TafsirTableData tafsir, AyahFontsModel ayahs) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '﴿${ayahs.text}﴾\n',
            style: TextStyle(
              fontFamily: 'uthmanic2',
              fontSize: 24,
              height: 1.9,
              color: Colors.black,
            ),
          ),
          // WidgetSpan(
          //   child: ShareCopyWidget(
          //     ayahNumber: ayahs.ayahNumber,
          //     ayahText: ayahs.text,
          //     ayahTextNormal: ayahs.ayaTextEmlaey,
          //     ayahUQNumber: ayahIndex,
          //     surahName:
          //         quranCtrl.getSurahDataByAyahUQ(ayahIndex).arabicName,
          //     surahNumber:
          //         quranCtrl.getSurahDataByAyahUQ(ayahIndex).surahNumber,
          //     tafsirName: tafsirName[tafsirCtrl.radioValue.value]
          //         ['name'],
          //     tafsir: tafsirCtrl.isTafsir.value
          //         ? tafsirCtrl.tafseerList[index].tafsirText
          //         : TranslateDataController.instance
          //                     .data[tafsirCtrl.ayahUQNumber.value - 1]
          //                 ['text'] ??
          //             '',
          //   ),
          // ),

          tafsirCtrl.isTafsir.value
              ? TextSpan(
                  children: tafsir.tafsirText.customTextSpans(),
                  style: TextStyle(
                      color: Colors.black,
                      height: 1.5,
                      fontSize: tafsirCtrl.fontSizeArabic.value),
                )
              : TextSpan(
                  text: tafsirCtrl.translationList[ayahIndex - 1].text ?? '',
                  style: TextStyle(
                      color: Colors.black,
                      height: 1.5,
                      fontSize: tafsirCtrl.fontSizeArabic.value),
                ),
          // TextSpan(text: 'world', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      // showCursor: true,
      // cursorWidth: 3,
      // cursorColor: Theme.of(context).dividerColor,
      // cursorRadius: const Radius.circular(5),
      // scrollPhysics:
      //     const ClampingScrollPhysics(),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      // contextMenuBuilder:
      //     buildMyContextMenu(),
      // onSelectionChanged:
      //     handleSelectionChanged,
    );
  }

  Widget _pagesBuild(BuildContext context) {
    final pageAyahs = quranCtrl.getPageAyahsByIndex(pageIndex);
    final selectedAyahIndexInFullPage =
        pageAyahs.indexWhere((ayah) => ayah.ayahUQNumber == ayahUQNumber);
    return GetBuilder<TafsirCtrl>(
      id: 'change_tafsir',
      builder: (tafsirCtrl) =>
          tafsirCtrl.tafseerList.isEmpty && tafsirCtrl.translationList.isEmpty
              ? const SizedBox.shrink()
              : Flexible(
                  child: PageView.builder(
                      controller: PageController(
                          initialPage: (selectedAyahIndexInFullPage).toInt()),
                      itemCount: pageAyahs.length,
                      itemBuilder: (context, i) {
                        final ayahs = pageAyahs[i];
                        int ayahIndex = pageAyahs.first.ayahUQNumber + i;
                        final tafsir = tafsirCtrl.tafseerList.firstWhere(
                          (element) => element.id == ayahIndex,
                          orElse: () => const TafsirTableData(
                              id: 0,
                              tafsirText: '',
                              ayahNum: 0,
                              pageNum: 0,
                              surahNum: 0), // تصرف في حالة عدم وجود التفسير
                        );
                        return Container(
                          width: MediaQuery.sizeOf(context).width,
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: .1),
                              border: Border.symmetric(
                                  horizontal: BorderSide(
                                width: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ))),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Scrollbar(
                              controller: _scrollController,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                child: _actualTafseerWt(
                                    context, ayahIndex, tafsir, ayahs),
                              ),
                            ),
                          ),
                        );
                      }),
                ),
    );
  }
}
