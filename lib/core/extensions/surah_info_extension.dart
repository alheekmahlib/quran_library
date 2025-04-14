part of '../../quran.dart';

/// An extension on the `void` type to provide additional functionality
/// related to Surah information.
///
/// This extension is intended to add methods and properties that
/// enhance the handling and manipulation of Surah data within the
/// application.
extension SurahInfoExtension on void {
  /// Displays a dialog widget with information about a specific Surah.
  ///
  /// This method shows a dialog containing details about the Surah specified
  /// by the [surahNumber]. The dialog is displayed in the given [context].
  ///
  /// Example:
  /// ```dart
  /// surahInfoDialogWidget(context, 1); // Displays information about Surah Al-Fatiha
  /// ```
  ///
  /// [context]: The BuildContext in which to display the dialog.
  /// [surahNumber]: The number of the Surah to display information about.
  void surahInfoDialogWidget(BuildContext context, int surahNumber,
      {SurahInfoStyle? surahStyle,
      String? languageCode,
      Size? deviceWidth,
      bool isDark = false}) {
    final quranCtrl = QuranCtrl.instance;
    final surah = quranCtrl.surahsList[surahNumber];
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: 460,
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: surahStyle?.backgroundColor ??
                  (isDark ? Colors.white : Colors.black),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: surahStyle?.closeIconColor ??
                                  (isDark ? Colors.white : Colors.black),
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          context.verticalDivider(
                              height: 30,
                              color: isDark ? Colors.white : Colors.black),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'packages/quran_library/assets/svg/surah_name/00${surah.number}.svg',
                            height: 45,
                            colorFilter: ColorFilter.mode(
                                surahStyle?.surahNameColor ??
                                    (isDark ? Colors.white : Colors.black),
                                BlendMode.srcIn),
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SvgPicture.asset(
                                'packages/quran_library/assets/svg/sora_num.svg',
                                height: 40,
                                width: 40,
                                colorFilter: ColorFilter.mode(
                                    surahStyle?.surahNameColor ??
                                        (isDark ? Colors.white : Colors.black),
                                    BlendMode.srcIn),
                              ),
                              Transform.translate(
                                offset: const Offset(0, 1),
                                child: Text(
                                  '${surah.number}'
                                      .convertNumbersAccordingToLang(
                                          languageCode: languageCode ?? 'ar'),
                                  style: TextStyle(
                                      color: surahStyle?.surahNumberColor ??
                                          (isDark
                                              ? Colors.white
                                              : Colors.black),
                                      fontFamily: "kufi",
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      height: 2,
                                      package: "quran_library"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Container(
                  height: 35,
                  width: deviceWidth?.width == null
                      ? double.infinity
                      : deviceWidth!.width,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                      color: surahStyle?.primaryColor ??
                          Colors.amber.withValues(alpha: .1),
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      border: Border.all(
                        width: 1,
                        color: surahStyle?.primaryColor ??
                            Colors.amber.withValues(alpha: .3),
                      )),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Center(
                          child: Text(
                            surah.revelationType.tr,
                            style: TextStyle(
                                color: surahStyle?.titleColor ??
                                    (isDark ? Colors.white : Colors.black),
                                fontFamily: "kufi",
                                fontSize: 14,
                                height: 2,
                                package: "quran_library"),
                          ),
                        ),
                      ),
                      context.verticalDivider(
                          height: 30,
                          color: isDark ? Colors.white : Colors.black),
                      Expanded(
                        flex: 4,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Center(
                            child: Text(
                              '${surahStyle?.ayahCount ?? 'عدد الآيات'}: ${surah.ayahsNumber}'
                                  .convertNumbersAccordingToLang(
                                      languageCode: languageCode ?? 'ar'),
                              style: TextStyle(
                                  color: surahStyle?.titleColor ??
                                      (isDark ? Colors.white : Colors.black),
                                  fontFamily: "kufi",
                                  fontSize: 14,
                                  height: 2,
                                  package: "quran_library"),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 35,
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                              color: surahStyle?.primaryColor ??
                                  Colors.amber.withValues(alpha: .1),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              border: Border.all(
                                width: 1,
                                color: surahStyle?.primaryColor ??
                                    Colors.amber.withValues(alpha: .3),
                              )),
                          child: TabBar(
                            unselectedLabelColor: Colors.grey,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            indicatorColor: surahStyle?.primaryColor ??
                                Colors.amber.withValues(alpha: .2),
                            indicatorWeight: 3,
                            labelStyle: TextStyle(
                              color: surahStyle?.titleColor ??
                                  (isDark ? Colors.white : Colors.black),
                              fontFamily: 'kufi',
                              fontSize: 11,
                              package: "quran_library",
                            ),
                            unselectedLabelStyle: TextStyle(
                              color: surahStyle?.titleColor ??
                                  (isDark ? Colors.white : Colors.black),
                              fontFamily: 'kufi',
                              fontSize: 11,
                              package: "quran_library",
                            ),
                            indicator: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              color: surahStyle?.indicatorColor ??
                                  Colors.amber.withValues(alpha: .2),
                            ),
                            tabs: [
                              Tab(
                                  text: surahStyle?.firstTabText ??
                                      'أسماء السورة'),
                              Tab(
                                  text:
                                      surahStyle?.secondTabText ?? 'عن السورة'),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 290,
                          child: TabBarView(
                            children: <Widget>[
                              SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          children: surah.surahNames
                                              .customTextSpans(),
                                          style: TextStyle(
                                            color: surahStyle?.textColor ??
                                                (isDark
                                                    ? Colors.white
                                                    : Colors.black),
                                            fontFamily: "naskh",
                                            fontSize: 22,
                                            height: 2,
                                            package: "quran_library",
                                          ),
                                        ),
                                        TextSpan(
                                          children: surah.surahNamesFromBook
                                              .customTextSpans(),
                                          style: TextStyle(
                                            color: surahStyle?.textColor ??
                                                (isDark
                                                    ? Colors.white
                                                    : Colors.black),
                                            fontFamily: "naskh",
                                            fontSize: 18,
                                            height: 2,
                                            package: "quran_library",
                                          ),
                                        )
                                      ],
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                ),
                              ),
                              SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          children:
                                              surah.surahInfo.customTextSpans(),
                                          style: TextStyle(
                                            color: surahStyle?.textColor ??
                                                (isDark
                                                    ? Colors.white
                                                    : Colors.black),
                                            fontFamily: "naskh",
                                            fontSize: 22,
                                            height: 2,
                                            package: "quran_library",
                                          ),
                                        ),
                                        TextSpan(
                                          children: surah.surahInfoFromBook
                                              .customTextSpans(),
                                          style: TextStyle(
                                            color: surahStyle?.textColor ??
                                                (isDark
                                                    ? Colors.white
                                                    : Colors.black),
                                            fontFamily: "naskh",
                                            fontSize: 18,
                                            height: 2,
                                            package: "quran_library",
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
