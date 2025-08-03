import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_library/quran.dart' show QuranCtrl;

import '/core/constants/svg_paths.dart';
import '/core/utils/custom_widgets.dart';
import '/core/utils/ui_helper.dart';
import '../surah_audio/controller/extensions/surah_audio_getters.dart';
import '../surah_audio/controller/surah_audio_controller.dart';
import 'change_reader.dart';
import 'play_ayah_widget.dart';
import 'skip_next.dart';
import 'skip_previouse.dart';

class AudioWidget extends StatelessWidget {
  AudioWidget({super.key});
  final quranCtrl = QuranCtrl.instance;
  final audioCtrl = SurahAudioController.instance;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
          margin: const EdgeInsets.only(bottom: 24.0, right: 32.0, left: 32.0),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              boxShadow: [
                BoxShadow(
                    offset: const Offset(0, -2),
                    blurRadius: 3,
                    spreadRadius: 3,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: .15))
              ]),
          child: Obx(() => AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                firstChild: SizedBox(
                  height: 50,
                  width: UiHelper.screenWidth(
                    MediaQuery.sizeOf(context).width * .64,
                    290,
                    context: context,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Center(child: PlayAyah()),
                        const Center(
                          child: ChangeReader(),
                        ),
                        Center(
                            child: GestureDetector(
                          child: Semantics(
                            button: true,
                            enabled: true,
                            label: 'Playlist',
                            child: CustomWidgets.customSvgWithColor(
                              SvgPath.svgPlaylist,
                              height: 25,
                              ctx: context,
                            ),
                          ),
                          onTap: () {
                            // Get.bottomSheet(AyahsPlayListWidget(),
                            //     isScrollControlled: true);
                          },
                        )),
                      ],
                    ),
                  ),
                ),
                secondChild: GetBuilder<SurahAudioController>(
                    id: 'audio_seekBar_id',
                    builder: (c) {
                      return SizedBox(
                          height: 155,
                          width: UiHelper.screenWidth(
                              MediaQuery.sizeOf(context).width * .64, 290,
                              context: context),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const SizedBox(height: 11),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomWidgets.customArrowDown(
                                      height: 26,
                                      isBorder: false,
                                      close: () => quranCtrl
                                          .state.isPlayExpanded.value = false,
                                      ctx: context,
                                    ),
                                    const ChangeReader(),
                                    GestureDetector(
                                      child: Semantics(
                                        button: true,
                                        enabled: true,
                                        label: 'Playlist',
                                        child: CustomWidgets.customSvgWithColor(
                                          SvgPath.svgPlaylist,
                                          height: 25,
                                          ctx: context,
                                        ),
                                      ),
                                      onTap: () {
                                        // Get.bottomSheet(AyahsPlayListWidget(),
                                        //     isScrollControlled: true);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Container(
                                  height: 67,
                                  alignment: Alignment.center,
                                  child: c.state.isDownloading.value
                                      ? GetX<SurahAudioController>(
                                          builder: (c) {
                                          final data =
                                              c.state.tmpDownloadedAyahsCount;
                                          return SliderWidget.downloading(
                                              currentPosition: data,
                                              filesCount: audioCtrl
                                                  .selectedSurahAyahsFileNames
                                                  .length,
                                              horizontalPadding: 0);
                                        })
                                      : StreamBuilder<PositionData>(
                                          stream: audioCtrl.positionDataStream,
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              final positionData =
                                                  snapshot.data;
                                              return SliderWidget.player(
                                                horizontalPadding: 0.0,
                                                duration:
                                                    positionData?.duration ??
                                                        Duration.zero,
                                                position:
                                                    positionData?.position ??
                                                        Duration.zero,
                                                activeTrackColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                onChangeEnd:
                                                    SurahAudioController
                                                        .instance
                                                        .state
                                                        .audioPlayer
                                                        .seek,
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    SkipToPrevious(),
                                    const PlayAyah(),
                                    SkipToNext(),
                                  ],
                                ),
                              ),
                            ],
                          ));
                    }),
                crossFadeState: quranCtrl.state.isPlayExpanded.value
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ))),
    );
  }
}
