import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../data/models/styles_models/surah_info_style.dart';
import '../../presentation/controllers/quran/quran_ctrl.dart';
import 'convert_number_extension.dart';
import 'extensions.dart';
import 'text_span_extension.dart';

extension SurahInfoExtension on void {
  void surahInfoDialogWidget(int surahNumber, SurahInfoStyle surahStyle,
      {String? languageCode}) {
    final quranCtrl = QuranCtrl.instance;
    final surah = quranCtrl.surahsList[surahNumber];
    Get.dialog(Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Container(
          height: 460,
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: surahStyle.backgroundColor ?? Colors.white,
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
                          onPressed: () => Get.back(),
                          icon: Icon(
                            Icons.close,
                            color: surahStyle.closeIconColor ?? Colors.black,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Get.context!.vDivider(height: 30),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'packages/quran_library/lib/assets/svg/surah_name/00${surah.number}.svg',
                          height: 45,
                          colorFilter: ColorFilter.mode(
                              surahStyle.surahNameColor ?? Colors.black,
                              BlendMode.srcIn),
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SvgPicture.asset(
                              'packages/quran_library/lib/assets/svg/sora_num.svg',
                              height: 40,
                              width: 40,
                              colorFilter: ColorFilter.mode(
                                  surahStyle.surahNameColor ?? Colors.black,
                                  BlendMode.srcIn),
                            ),
                            Transform.translate(
                              offset: const Offset(0, 1),
                              child: Text(
                                '${surah.number}'.convertNumbers(
                                    languageCode: languageCode ?? 'ar'),
                                style: TextStyle(
                                    color: surahStyle.surahNumberColor ??
                                        Colors.black,
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
                width: Get.width,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                    color: surahStyle.primaryColor ??
                        Colors.amber.withValues(alpha: .1),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    border: Border.all(
                      width: 1,
                      color: surahStyle.primaryColor ??
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
                              color: surahStyle.titleColor ?? Colors.black,
                              fontFamily: "kufi",
                              fontSize: 14,
                              height: 2,
                              package: "quran_library"),
                        ),
                      ),
                    ),
                    Get.context!.vDivider(height: 30),
                    Expanded(
                      flex: 4,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Center(
                          child: Text(
                            '${surahStyle.ayahCount ?? 'عدد الآيات'}: ${surah.ayahsNumber}'
                                .convertNumbers(
                                    languageCode: languageCode ?? 'ar'),
                            style: TextStyle(
                                color: surahStyle.titleColor ?? Colors.black,
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
                            color: surahStyle.primaryColor ??
                                Colors.amber.withValues(alpha: .1),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            border: Border.all(
                              width: 1,
                              color: surahStyle.primaryColor ??
                                  Colors.amber.withValues(alpha: .3),
                            )),
                        child: TabBar(
                          unselectedLabelColor: Colors.grey,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicatorColor: surahStyle.primaryColor ??
                              Colors.amber.withValues(alpha: .2),
                          indicatorWeight: 3,
                          labelStyle: TextStyle(
                            color: surahStyle.titleColor ?? Colors.black,
                            fontFamily: 'kufi',
                            fontSize: 11,
                            package: "quran_library",
                          ),
                          unselectedLabelStyle: TextStyle(
                            color: surahStyle.titleColor ?? Colors.black,
                            fontFamily: 'kufi',
                            fontSize: 11,
                            package: "quran_library",
                          ),
                          indicator: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            color: surahStyle.indicatorColor ??
                                Colors.amber.withValues(alpha: .2),
                          ),
                          tabs: [
                            Tab(
                                text:
                                    surahStyle.firstTabText ?? 'أسماء السورة'),
                            Tab(text: surahStyle.secondTabText ?? 'عن السورة'),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 290,
                        child: TabBarView(
                          children: <Widget>[
                            SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        children:
                                            surah.surahNames.buildTextSpans(),
                                        style: TextStyle(
                                          color: surahStyle.textColor ??
                                              Colors.black,
                                          fontFamily: "naskh",
                                          fontSize: 22,
                                          height: 2,
                                          package: "quran_library",
                                        ),
                                      ),
                                      TextSpan(
                                        children: surah.surahNamesFromBook
                                            .buildTextSpans(),
                                        style: TextStyle(
                                          color: surahStyle.textColor ??
                                              Colors.black,
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        children:
                                            surah.surahInfo.buildTextSpans(),
                                        style: TextStyle(
                                          color: surahStyle.textColor ??
                                              Colors.black,
                                          fontFamily: "naskh",
                                          fontSize: 22,
                                          height: 2,
                                          package: "quran_library",
                                        ),
                                      ),
                                      TextSpan(
                                        children: surah.surahInfoFromBook
                                            .buildTextSpans(),
                                        style: TextStyle(
                                          color: surahStyle.textColor ??
                                              Colors.black,
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
    ));
  }
}
