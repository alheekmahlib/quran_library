part of '/quran.dart';

/// نمط واجهة التسميع (زر التسجيل، الحالات، النتائج، الإعدادات).
///
/// كل الحقول قابلة للتجاوز — والقيم الافتراضية عربية لتُلائم i18n
/// التطبيقات المضيفة عبر تمرير قيمها الخاصة.
class TasmeeStyle {
  const TasmeeStyle({
    this.backgroundColor,
    this.hiddenWordColor,
    this.textColor,
    this.accentColor,
    this.correctColor,
    this.incorrectColor,
    this.tajweedErrorColor,
    this.normalErrorColor,
    this.tashkeelErrorColor,
    this.recordButtonColor,
    this.stopButtonColor,
    this.iconColor,
    this.borderRadius,
    this.height,
    this.elevation,
    this.shadowColor,
    this.startRecordingLabel,
    this.stopRecordingLabel,
    this.processingLabel,
    this.recordingLabel,
    this.settingsLabel,
    this.retryLabel,
    this.exitLabel,
    this.showWordsLabel,
    this.hideWordsLabel,
    this.resultsToggleLabel,
    this.resultsTitle,
    this.noErrorsLabel,
    this.totalErrorsLabel,
    this.tajweedErrorsLabel,
    this.normalErrorsLabel,
    this.tashkeelErrorsLabel,
    this.expectedLabel,
    this.actualLabel,
    this.engineLocalLabel,
    this.engineServerLabel,
    this.serverUrlLabel,
    this.checkServerLabel,
    this.modelDownloadTitle,
    this.modelDownloadNote,
    this.disclaimer,
  });

  final Color? backgroundColor;
  final Color? textColor;
  final Color? accentColor;

  /// لون إخفاء كلمات التسميع غير المتلوّة (يجب أن يطابق خلفية الصفحة —
  /// يُستخدم backgroundColor ثم الافتراضي إن لم يُحدَّد).
  final Color? hiddenWordColor;

  /// لون الكلمة الصحيحة (أخضر — خط سفلي تحت الكلمة).
  final Color? correctColor;

  /// لون الكلمة الخاطئة (أحمر — يُستخدم احتياطًا عند غياب نوع الخطأ).
  final Color? incorrectColor;

  /// لون الخط السفلي لأخطاء التجويد (بنفسجي).
  final Color? tajweedErrorColor;

  /// لون الخط السفلي لأخطاء النطق (أحمر).
  final Color? normalErrorColor;

  /// لون الخط السفلي لأخطاء التشكيل (برتقالي).
  final Color? tashkeelErrorColor;

  final Color? recordButtonColor;
  final Color? stopButtonColor;
  final Color? iconColor;
  final double? borderRadius;
  final double? height;
  final double? elevation;
  final Color? shadowColor;

  // ── النصوص (قيم عربية افتراضية قابلة للتجاوز لِـ i18n) ────────
  final String? startRecordingLabel;
  final String? stopRecordingLabel;
  final String? processingLabel;
  final String? recordingLabel;
  final String? settingsLabel;
  final String? retryLabel;
  final String? exitLabel;

  /// زر إظهار/إخفاء كل كلمات الصفحة (العين).
  final String? showWordsLabel;
  final String? hideWordsLabel;

  /// زر فتح/إغلاق bottomSheet النتائج.
  final String? resultsToggleLabel;
  final String? resultsTitle;
  final String? noErrorsLabel;
  final String? totalErrorsLabel;
  final String? tajweedErrorsLabel;
  final String? normalErrorsLabel;
  final String? tashkeelErrorsLabel;
  final String? expectedLabel;
  final String? actualLabel;
  final String? engineLocalLabel;
  final String? engineServerLabel;
  final String? serverUrlLabel;
  final String? checkServerLabel;
  final String? modelDownloadTitle;
  final String? modelDownloadNote;

  /// إخلاء المسؤولية (إلزامي بموجب رخصة نموذج Quran-Lab NPL-1.2).
  final String? disclaimer;

  factory TasmeeStyle.defaults(
      {required bool isDark, required BuildContext context}) {
    final scheme = Theme.of(context).colorScheme;
    return TasmeeStyle(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      hiddenWordColor: AppColors.getBackgroundColor(isDark),
      textColor: AppColors.getTextColor(isDark),
      accentColor: scheme.primary,
      correctColor: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
      incorrectColor:
          isDark ? const Color(0xFFE57373) : const Color(0xFFC62828),
      tajweedErrorColor:
          isDark ? const Color(0xFFB39DDB) : const Color(0xFF6A1B9A),
      normalErrorColor:
          isDark ? const Color(0xFFE57373) : const Color(0xFFC62828),
      tashkeelErrorColor:
          isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00),
      recordButtonColor: scheme.primary,
      stopButtonColor:
          isDark ? const Color(0xFFE57373) : const Color(0xFFC62828),
      iconColor: scheme.primary,
      borderRadius: 12,
      height: 60,
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: .2),
      startRecordingLabel: 'ابدأ التسميع',
      stopRecordingLabel: 'إيقاف وعرض النتيجة',
      processingLabel: 'جارٍ تحليل التلاوة…',
      recordingLabel: 'جارٍ التسميع',
      settingsLabel: 'إعدادات التسميع',
      retryLabel: 'إعادة التسميع',
      exitLabel: 'خروج من وضع التسميع',
      showWordsLabel: 'إظهار الكلام',
      hideWordsLabel: 'إخفاء الكلام',
      resultsToggleLabel: 'عرض نتيجة التسميع',
      resultsTitle: 'نتيجة التسميع',
      noErrorsLabel: 'أحسنت! لا أخطاء',
      totalErrorsLabel: 'إجمالي الأخطاء',
      tajweedErrorsLabel: 'تجويد',
      normalErrorsLabel: 'نطق',
      tashkeelErrorsLabel: 'تشكيل',
      expectedLabel: 'المتوقع',
      actualLabel: 'المنطوق',
      engineLocalLabel: 'نموذج محلي (يعمل دون إنترنت)',
      engineServerLabel: 'خادم Muaalem (تصحيح بعد الإيقاف)',
      serverUrlLabel: 'عنوان الخادم',
      checkServerLabel: 'فحص الاتصال',
      modelDownloadTitle: 'تنزيل نموذج التسميع',
      modelDownloadNote: 'نموذج بحجم 73MB يُنزَّل مرة واحدة فقط، ثم يعمل '
          'التسميع دون اتصال بالإنترنت.',
      disclaimer: 'التصحيح الآلي قد يخطئ ولا يغني عن معلم مجاز — الأداء '
          'للأطفال دون 12 عاماً أقلّ دقة.',
    );
  }
}
