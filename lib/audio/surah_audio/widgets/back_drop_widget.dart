import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/audio/surah_audio/controller/surah_audio_controller.dart';
import '/core/constants/lottie_constants.dart';
import '/core/utils/custom_widgets.dart';
import '/core/utils/ui_helper.dart';
import './last_listen.dart';
import './play_banner.dart';
import './surah_audio_list.dart';

class BackDropWidget extends StatelessWidget {
  const BackDropWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return UiHelper.customOrientation(
        Material(
          child: Column(
            children: [
              SizedBox(
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                        alignment: Alignment.center,
                        child: Padding(
                            padding: const EdgeInsets.only(top: 104.0),
                            child: CustomWidgets.customLottieWithColor(
                              LottieConstants.assetsLottieQuranAuIc,
                              height: 120,
                              isRepeat: false,
                              ctx: context,
                            ))),
                    Align(alignment: Alignment.topCenter, child: LastListen()),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 140.0),
                        child: Stack(
                          children: [
                            Obx(() => SurahAudioController
                                        .instance.state.isPlaying.value ==
                                    true
                                ? const Align(
                                    alignment: Alignment.topLeft,
                                    child: PlayBanner())
                                : const SizedBox.shrink())
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(child: SurahAudioList()),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(flex: 4, child: SurahAudioList()),
            Expanded(
              flex: 4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                      alignment: Alignment.center,
                      child: Padding(
                          padding: const EdgeInsets.only(top: 104.0),
                          child: CustomWidgets.customLottie(
                              LottieConstants.assetsLottieQuranAuIc,
                              height: 120,
                              isRepeat: false))),
                  Align(
                      alignment: Alignment.topCenter,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          LastListen(),
                          // TabBarWidget(
                          //   isFirstChild: true,
                          //   isCenterChild: true,
                          //   isQuranSetting: false,
                          //   isNotification: false,
                          //   centerChild: LastListen(),
                          // ),
                        ],
                      )),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 140.0),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Obx(() => SurahAudioController
                                          .instance.state.isPlaying.value ==
                                      true
                                  ? const Align(
                                      alignment: Alignment.topLeft,
                                      child: PlayBanner())
                                  : const SizedBox.shrink())
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        context);
  }
}
