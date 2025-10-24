part of '../../audio.dart';

/// قائمة السور الصوتية مع دعم تمرير الألوان والأنماط
/// Audio Surah list with color and style passing support
class SurahAudioList extends StatelessWidget {
  final SurahAudioStyle? style;
  final bool isDark;
  final String? languageCode;

  SurahAudioList(
      {super.key, this.style, required this.isDark, this.languageCode});

  final QuranCtrl quranCtrl = QuranCtrl.instance;
  final surahAudioCtrl = AudioCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(392.72727272727275, 800.7272727272727),
      minTextAdapt: true,
      splitScreenMode: true,
      child: Container(
        margin: const EdgeInsets.all(12.0),
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          // شرح: تدرج لوني جميل للخلفية
          // Explanation: Beautiful gradient background
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (style?.backgroundColor ?? AppColors.getBackgroundColor(isDark))
                  .withValues(alpha: 0.05),
              (style?.backgroundColor ?? AppColors.getBackgroundColor(isDark))
                  .withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(style?.borderRadius ?? 16.0),
          ),
          border: Border.all(
            width: 1.5,
            color:
                (style?.backgroundColor ?? AppColors.getBackgroundColor(isDark))
                    .withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: (style?.backgroundColor ??
                      AppColors.getBackgroundColor(isDark))
                  .withValues(alpha: 0.1),
              blurRadius: 8.0,
              spreadRadius: 1.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListView.builder(
          shrinkWrap: true,
          controller: surahAudioCtrl.state.surahListController,
          physics: const BouncingScrollPhysics(),
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
          itemCount: quranCtrl.state.surahs.length,
          scrollDirection: Axis.vertical,
          itemBuilder: (_, index) {
            final surah = quranCtrl.state.surahs[index];
            int surahNumber = index + 1;

            return Obx(
              () => Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildEnhancedSurahItem(
                  context,
                  surah,
                  index,
                  surahNumber,
                  isDark,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// بناء عنصر سورة محسن مع تصميم جذاب
  /// Build enhanced surah item with attractive design
  Widget _buildEnhancedSurahItem(
    BuildContext context,
    SurahModel surah,
    int index,
    int surahNumber,
    bool isDark,
  ) {
    final isSelected = surahAudioCtrl.state.selectedSurahIndex.value == index;
    final isDownloaded =
        surahAudioCtrl.state.isSurahDownloadedByNumber(surahNumber);

    return GestureDetector(
      onTap: () async {
        surahAudioCtrl.state.selectedSurahIndex.value = index;
        surahAudioCtrl.changeAudioSource();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        decoration: BoxDecoration(
          // شرح: تدرج متحرك للعنصر المحدد
          // Explanation: Animated gradient for selected item
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    (style?.primaryColor ?? Colors.teal)
                        .withValues(alpha: 0.15),
                    (style?.primaryColor ?? Colors.teal)
                        .withValues(alpha: 0.08),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: !isSelected
              ? (isDark
                  ? Colors.grey[800]?.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.6))
              : null,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? (style?.primaryColor ?? Colors.teal).withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (style?.primaryColor ?? Colors.teal)
                        .withValues(alpha: 0.2),
                    blurRadius: 8.0,
                    spreadRadius: 1.0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // شرح: رقم السورة مع تصميم دائري محسن
            // Explanation: Surah number with enhanced circular design
            Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (style?.primaryColor ?? Colors.teal)
                        .withValues(alpha: isSelected ? 0.8 : 0.6),
                    (style?.primaryColor ?? Colors.teal)
                        .withValues(alpha: isSelected ? 0.6 : 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: (style?.primaryColor ?? Colors.teal)
                        .withValues(alpha: 0.3),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  surahNumber.toString().convertNumbersAccordingToLang(
                      languageCode: languageCode ?? 'ar'),
                  style: QuranLibrary().cairoStyle.copyWith(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),

            const SizedBox(width: 16.0),

            // شرح: معلومات السورة محسنة
            // Explanation: Enhanced surah information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.surahNumber.toString(),
                    style: TextStyle(
                      color:
                          (style?.textColor ?? AppColors.getTextColor(isDark)),
                      fontFamily: 'surahName',
                      fontSize: 32.sp.clamp(32, 40),
                      package: 'quran_library',
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Text(
                        surah.englishName,
                        style: QuranLibrary().cairoStyle.copyWith(
                              fontSize: 12.0.sp.clamp(12, 20),
                              height: 1.3,
                              color: (style?.textColor ??
                                      AppColors.getTextColor(isDark))
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                      const SizedBox(width: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: (style?.primaryColor ?? Colors.teal)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          '${surah.ayahs.length} ${surahAudioCtrl.getAyahOrAyat(surah.ayahs.length)}'
                              .convertNumbersAccordingToLang(
                                  languageCode: languageCode ?? 'ar'),
                          style: QuranLibrary().cairoStyle.copyWith(
                                fontSize: 10.0.sp.clamp(10, 14),
                                color: style?.primaryColor ??
                                    AppColors.getTextColor(isDark),
                                fontWeight: FontWeight.w600,
                                fontFamily: "kufi",
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // شرح: أيقونة التشغيل المحسنة
            // Explanation: Enhanced play icon
            kIsWeb
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      Container(
                        width: 36.0,
                        height: 36.0,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (style?.primaryColor ?? Colors.teal)
                              : (style?.primaryColor ?? Colors.teal)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        child: GestureDetector(
                          onTap: () => surahAudioCtrl.downloadSurah(
                              surahNum: surahNumber),
                          child: Obx(
                            () => Icon(
                              isDownloaded.value
                                  ? Icons.download_done
                                  : Icons.cloud_download_outlined,
                              color: isSelected
                                  ? Colors.white
                                  : (style?.primaryColor ?? Colors.teal),
                              size: 20.0,
                            ),
                          ),
                        ),
                      ),
                      Obx(
                        () {
                          if (index ==
                                  surahAudioCtrl
                                      .state.selectedSurahIndex.value &&
                              surahAudioCtrl.state.isDownloading.value &&
                              !isDownloaded.value) {
                            return SizedBox(
                              height: 10,
                              width: 40,
                              child: LinearProgressIndicator(
                                value: surahAudioCtrl.state.progress.value,
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        },
                      )
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
