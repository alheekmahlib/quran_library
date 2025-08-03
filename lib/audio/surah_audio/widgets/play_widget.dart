import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_library/audio/surah_audio/controller/surah_audio_controller.dart';
import 'package:quran_library/core/utils/custom_widgets.dart';

import '/core/constants/svg_paths.dart';
import '/core/utils/ui_helper.dart';
import '../../widgets/online_play_button.dart';
import '../../widgets/skip_next.dart';
import '../../widgets/skip_previouse.dart';
import 'change_reader.dart';
import 'download_play_button.dart';
import 'surah_seek_bar.dart';

class PlayWidget extends StatelessWidget {
  PlayWidget({super.key});

  final surahCtrl = SurahAudioController.instance;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      height: 297,
      width: UiHelper.customOrientation(size.width, size.width * .5, context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: RotatedBox(
              quarterTurns: 2,
              child: Opacity(
                opacity: .6,
                child: CustomWidgets.customSvgWithColor(
                  SvgPath.svgDecorations,
                  height: 60,
                  ctx: context,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Opacity(
              opacity: .6,
              child: CustomWidgets.customSvgWithColor(
                SvgPath.svgDecorations,
                height: 60,
                ctx: context,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomWidgets.customArrowDown(
                isBorder: true,
                close: () => surahCtrl.state.boxController.closeBox(),
                ctx: context,
              ),
            ),
          ),
          Column(
            children: [
              Obx(
                () => Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: .1,
                      child: CustomWidgets.surahNameWidget(
                        surahCtrl.state.currentAudioListSurahNum.value,
                        Get.theme.colorScheme.primary,
                        height: 90,
                        width: 150,
                      ),
                    ),
                    CustomWidgets.surahNameWidget(
                      surahCtrl.state.currentAudioListSurahNum.value,
                      Get.theme.colorScheme.primary,
                      height: 70,
                      width: 150,
                    ),
                  ],
                ),
              ),
              const ChangeSurahReader(),
              const SurahSeekBar(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Obx(
                      () => surahCtrl.state.surahDownloadStatus.value[surahCtrl
                                  .state.currentAudioListSurahNum.value] ??
                              false
                          ? const SizedBox.shrink()
                          : const DownloadPlayButton(),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Semantics(
                            button: true,
                            enabled: true,
                            label: 'backward'.tr,
                            child: CustomWidgets.customSvgWithColor(
                              SvgPath.svgBackward,
                              height: 20,
                              ctx: context,
                            ),
                          ),
                          onPressed: () {
                            surahCtrl.state.audioPlayer.seek(Duration(
                                seconds: surahCtrl
                                    .state.seekNextSeconds.value -= 5));
                          },
                        ),
                        const SkipToPrevious(),
                      ],
                    ),
                    const OnlinePlayButton(
                      isRepeat: true,
                    ),
                    Row(
                      children: [
                        SkipToNext(),
                        IconButton(
                          icon: Semantics(
                            button: true,
                            enabled: true,
                            label: 'rewind'.tr,
                            child: CustomWidgets.customSvgWithColor(
                              SvgPath.svgRewind,
                              height: 20,
                              ctx: context,
                            ),
                          ),
                          onPressed: () => surahCtrl.state.audioPlayer.seek(
                              Duration(
                                  seconds: surahCtrl
                                      .state.seekNextSeconds.value += 5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
