import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/audio/surah_audio/controller/surah_audio_controller.dart';
import '/core/constants/svg_paths.dart';
import '/core/utils/custom_widgets.dart';
import '/core/utils/ui_helper.dart';
import '../../widgets/online_play_button.dart';
import '../../widgets/skip_next.dart';
import '../../widgets/skip_previouse.dart';

class CollapsedPlayWidget extends StatelessWidget {
  const CollapsedPlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: UiHelper.customOrientation(width, width * .5, context),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .15),
        ),
        child: Stack(
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SkipToPrevious(),
                      OnlinePlayButton(
                        isRepeat: false,
                      ),
                      SkipToNext(),
                    ],
                  ),
                  Obx(
                    () => CustomWidgets.surahNameWidget(
                      SurahAudioController
                          .instance.state.currentAudioListSurahNum.value,
                      Theme.of(context).colorScheme.primary,
                      height: 50,
                      width: 100,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
