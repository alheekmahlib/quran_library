part of '../../audio.dart';

/// ويدجت خلفية تشغيل الصوت مع تصميم متجاوب للوضعين الأفقي والعمودي
/// Background widget for audio playback with responsive design for portrait and landscape orientations
class SurahBackDropWidget extends StatelessWidget {
  final SurahAudioStyle? style;
  final bool? isDark;
  const SurahBackDropWidget({super.key, this.style, this.isDark});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      // شرح: تطبيق خلفية متدرجة جميلة مع ظلال
      // Explanation: Apply beautiful gradient background with shadows
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            style?.backgroundColor?.withValues(alpha: 0.8) ??
                (isDark! ? Colors.grey[800]! : const Color(0xfffaf7f3)),
            style?.backgroundColor?.withValues(alpha: 0.4) ??
                (isDark! ? Colors.grey[900]! : const Color(0xfffaf7f3)),
          ],
        ),
        borderRadius: BorderRadius.circular(
          style?.borderRadius ?? 16.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (style?.backgroundColor ?? const Color(0xfffaf7f3))
                .withValues(alpha: 0.3),
            blurRadius: 20.0,
            spreadRadius: 2.0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color:
                const Color(0xfffaf7f3).withValues(alpha: isDark! ? 0.4 : 0.1),
            blurRadius: 15.0,
            spreadRadius: 1.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          style?.borderRadius ?? 16.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isDark! ? 0.05 : 0.15),
            border: Border.all(
              color: (style?.backgroundColor ?? Colors.blue)
                  .withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: UiHelper.currentOrientation(
            // الوضع العمودي - Portrait Mode
            _buildPortraitLayout(context, size, isDark!),
            // الوضع الأفقي - Landscape Mode
            _buildLandscapeLayout(context, size, isDark!),
            context,
          ),
        ),
      ),
    );
  }

  /// بناء التخطيط للوضع العمودي
  /// Build layout for portrait mode
  Widget _buildPortraitLayout(BuildContext context, Size size, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16.0),

          // شرح: كارد آخر استماع مع تصميم محسن
          // Explanation: Last listen card with enhanced design
          _buildEnhancedCard(
            child: SurahLastListen(style: style),
            context: context,
            elevation: 8.0,
            isDark: isDark,
          ),

          const SizedBox(height: 16.0),

          // شرح: قائمة السور مع تحسينات التصميم
          // Explanation: Surah list with design improvements
          _buildEnhancedCard(
            child: SizedBox(
              height: size.height * 0.68,
              child: SurahAudioList(style: style, isDark: isDark),
            ),
            context: context,
            elevation: 12.0,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// بناء التخطيط للوضع الأفقي
  /// Build layout for landscape mode
  Widget _buildLandscapeLayout(BuildContext context, Size size, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شرح: قائمة السور في الجانب الأيسر (الوضع الأفقي)
          // Explanation: Surah list on the left side (landscape mode)
          Expanded(
            flex: 3,
            child: Column(
              children: [
                const SizedBox(height: 16.0),
                Expanded(
                  child: _buildEnhancedCard(
                    child: SurahAudioList(style: style, isDark: isDark),
                    context: context,
                    elevation: 10.0,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20.0),

          // شرح: آخر استماع والمعلومات في الجانب الأيمن
          // Explanation: Last listen and info on the right side
          Expanded(
            flex: 2,
            child: Column(
              children: [
                const SizedBox(height: 16.0),

                // شرح: كارد آخر استماع
                // Explanation: Last listen card
                _buildEnhancedCard(
                  child: SurahLastListen(style: style),
                  context: context,
                  elevation: 8.0,
                  isDark: isDark,
                ),

                const SizedBox(height: 20.0),

                // شرح: معلومات إضافية محسنة
                // Explanation: Enhanced additional info
                _buildEnhancedCard(
                  child: _buildAudioControlsInfo(context, isDark),
                  context: context,
                  elevation: 6.0,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء معلومات التحكم في الصوت مع تصميم محسن
  /// Build audio controls info widget with enhanced design
  Widget _buildAudioControlsInfo(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // شرح: أيقونة رئيسية مع تأثيرات بصرية
          // Explanation: Main icon with visual effects
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (style?.primaryColor ?? Theme.of(context).primaryColor)
                      .withValues(alpha: 0.2),
                  (style?.primaryColor ?? Theme.of(context).primaryColor)
                      .withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(50.0),
              boxShadow: [
                BoxShadow(
                  color: (style?.primaryColor ?? Theme.of(context).primaryColor)
                      .withValues(alpha: 0.3),
                  blurRadius: 15.0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.headphones_rounded,
              size: 48.0,
              color: style?.playIconColor ?? Theme.of(context).primaryColor,
            ),
          ),

          const SizedBox(height: 20.0),

          // شرح: عنوان رئيسي محسن
          // Explanation: Enhanced main title
          Text(
            'استمع للقرآن الكريم',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: style?.textColor ??
                  Theme.of(context).textTheme.titleLarge?.color,
              fontFamily: "kufi",
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8.0),

          // شرح: وصف فرعي محسن
          // Explanation: Enhanced subtitle
          Text(
            'اختر السورة واستمتع بالتلاوة',
            style: TextStyle(
              fontSize: 14.0,
              color: style?.textColor?.withValues(alpha: 0.7) ??
                  Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7),
              fontFamily: "kufi",
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20.0),

          // شرح: معلومات إضافية مع تصميم محسن
          // Explanation: Additional info with enhanced design
          _buildQuickStats(context, isDark),
        ],
      ),
    );
  }

  /// بناء إحصائيات سريعة مع تصميم جذاب
  /// Build quick stats with attractive design
  Widget _buildQuickStats(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          context,
          Icons.library_books_rounded,
          '114',
          'سورة',
          isDark,
        ),
        Container(
          width: 1.0,
          height: 40.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                (style?.primaryColor ?? Theme.of(context).primaryColor)
                    .withValues(alpha: 0.3),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        _buildStatItem(
          context,
          Icons.timer_rounded,
          '83+',
          'ساعة',
          isDark,
        ),
      ],
    );
  }

  /// بناء عنصر إحصائي مع تصميم محسن
  /// Build stat item with enhanced design
  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String number,
    String label,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24.0,
          color: style?.primaryColor ?? Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 4.0),
        Text(
          number,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: style?.primaryColor ?? Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.0,
            color: style?.textColor?.withValues(alpha: 0.6) ??
                Theme.of(context).textTheme.bodySmall?.color,
            fontFamily: "kufi",
          ),
        ),
      ],
    );
  }

  /// بناء كارد محسن مع ظلال وتأثيرات
  /// Build enhanced card with shadows and effects
  Widget _buildEnhancedCard({
    required Widget child,
    required BuildContext context,
    double elevation = 8.0,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color:
                (style?.backgroundColor ?? Colors.blue).withValues(alpha: 0.01),
            blurRadius: elevation,
            spreadRadius: 2.0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.03 : 0.01),
            blurRadius: elevation / 2,
            spreadRadius: 1.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (style?.backgroundColor ?? Colors.blue).withValues(alpha: 0.05),
                (style?.backgroundColor ?? Colors.blue).withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: (style?.backgroundColor ?? Colors.blue)
                  .withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
