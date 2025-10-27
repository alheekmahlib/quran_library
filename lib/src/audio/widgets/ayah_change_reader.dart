part of '../audio.dart';

class AyahChangeReader extends StatelessWidget {
  final AyahAudioStyle? style;
  final bool? isDark;
  const AyahChangeReader({super.key, this.style, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final AyahAudioStyle effectiveStyle = style ?? AyahAudioStyle();
    final bool dark = isDark ?? false;

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: effectiveStyle.dialogBackgroundColor ??
              AppColors.getBackgroundColor(dark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                effectiveStyle.dialogBorderRadius ?? 12.0),
          ),
          alignment: Alignment.center,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: _buildDialog(context, effectiveStyle, dark),
        ),
      ),
      child: _buildTitle(effectiveStyle, dark),
    );
  }

  Widget _buildDialog(
      BuildContext context, AyahAudioStyle effectiveStyle, bool dark) {
    final Color activeColor =
        effectiveStyle.readerNameInItemColor ?? AppColors.getTextColor(dark);
    final Color inactiveColor = Colors.teal.withValues(alpha: 0.05);
    final double itemFontSize = effectiveStyle.readerNameInItemFontSize ?? 14;
    final Color textColor =
        effectiveStyle.textColor ?? AppColors.getTextColor(dark);

    final int selectedIndex = AudioCtrl.instance.state.ayahReaderIndex.value;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          minWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const HeaderDialogWidget(title: 'تغيير القارئ'),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: ReadersConstants.ayahReaderInfo.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.getTextColor(dark).withValues(alpha: 0.08),
                ),
                itemBuilder: (context, index) {
                  final info = ReadersConstants.ayahReaderInfo[index];
                  final bool isSelected = selectedIndex == info['index'];
                  final Color itemColor =
                      isSelected ? inactiveColor : activeColor;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.0),
                    child: ListTile(
                      minTileHeight: 44,
                      dense: true,
                      focusColor: itemColor.withValues(alpha: 0.12),
                      splashColor: itemColor.withValues(alpha: 0.12),
                      selectedColor: itemColor,
                      selectedTileColor: itemColor.withValues(alpha: 0.12),
                      tileColor: itemColor.withValues(alpha: 0.07),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        '${info['name']}'.tr,
                        style: QuranLibrary().cairoStyle.copyWith(
                              color: textColor,
                              fontSize: itemFontSize,
                            ),
                      ),
                      trailing: _SelectionIndicator(
                          isSelected: isSelected, color: textColor),
                      onTap: () async => await AudioCtrl.instance
                          .changeAyahReadersOnTap(context, index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(AyahAudioStyle effectiveStyle, bool dark) {
    final Color textColor =
        effectiveStyle.textColor ?? AppColors.getTextColor(dark);
    final double fontSize = effectiveStyle.readerNameFontSize ?? 16;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(
          () => Text(
            '${ReadersConstants.ayahReaderInfo[AudioCtrl.instance.state.ayahReaderIndex.value]['name']}'
                .tr,
            style: QuranLibrary().cairoStyle.copyWith(
                  color: textColor,
                  fontSize: fontSize,
                ),
          ),
        ),
        const SizedBox(width: 4),
        Semantics(
          button: true,
          enabled: true,
          label: 'Change Reader'.tr,
          child: Icon(
            Icons.keyboard_arrow_down_outlined,
            size: fontSize.clamp(16, 20),
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool isSelected;
  final Color color;
  const _SelectionIndicator({required this.isSelected, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      width: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: isSelected
          ? const Icon(
              Icons.done,
              size: 14,
              color: Colors.black,
            )
          : null,
    );
  }
}
