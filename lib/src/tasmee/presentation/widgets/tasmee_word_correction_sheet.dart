/// bottomSheet تصحيح الكلمة (نمط المصحح) — يُفتح تلقائيًا من الشريط
/// المشترك عند تجميد الجلسة على كلمة خاطئة: استمع، أعد النطق، أو تخطَّ.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../quran.dart' as q;
import '../../../core/utils/app_colors.dart';
import '../../controller/tasmee_ctrl.dart';
import '../../controller/tasmee_state.dart';
import '../../engine/tasmee_error_kind.dart';

/// يفتح bottomSheet تصحيح الكلمة المنتظرة ([TasmeeState.activeWordCorrection]).
///
/// الشيت غير قابل للإغلاق بالسحب/اللمس الخارجي — يُقفل عبر قبول النطق
/// الصحيح أو التخطي، وكلاهما يستأنف الجلسة المتوقفة ([TasmeeCtrl.resolveWordCorrection]).
/// الحلّ مركزي هنا: الأزرار تُقرر وتُغلق فقط، والإغلاق الخارجي يُعامَل
/// تخطيًا كي لا يبقى التسجيل معلقًا على كلمة بلا وسيلة ظاهرة لإكماله.
Future<void> showTasmeeWordCorrectionSheet({
  required BuildContext context,
  required bool isDark,
  q.TasmeeStyle? style,
  String? languageCode,
}) async {
  final ctrl = TasmeeCtrl.instance;
  if (ctrl.state.activeWordCorrection.value == null) return;
  final defaults = style ??
      q.TasmeeTheme.of(context)?.style ??
      q.TasmeeStyle.defaults(isDark: isDark, context: context);
  var accepted = false;

  await showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => _TasmeeWordCorrectionSheet(
      ctrl: ctrl,
      defaults: defaults,
      isDark: isDark,
      onResolved: (value) => accepted = value,
    ),
  );
  if (ctrl.state.activeWordCorrection.value != null) {
    await ctrl.resolveWordCorrection(accepted: accepted);
  }
}

class _TasmeeWordCorrectionSheet extends StatefulWidget {
  const _TasmeeWordCorrectionSheet({
    required this.ctrl,
    required this.defaults,
    required this.isDark,
    required this.onResolved,
  });

  final TasmeeCtrl ctrl;
  final q.TasmeeStyle defaults;
  final bool isDark;
  final void Function(bool accepted) onResolved;

  @override
  State<_TasmeeWordCorrectionSheet> createState() =>
      _TasmeeWordCorrectionSheetState();
}

class _TasmeeWordCorrectionSheetState
    extends State<_TasmeeWordCorrectionSheet> {
  Worker? _correctionWorker;

  @override
  void initState() {
    super.initState();
    // شغّل نطق الكلمة مرة عند الفتح — الميكروفون متوقف (pauseLive اكتمل
    // قبل ضبط الحالة) فلا يسمع الجلسة صدى الصوت من السماعة.
    // شغّل نطق الكلمة مرة عند الفتح — الميكروفون متوقف (pauseLive اكتمل
    // قبل ضبط الحالة) فلا يسمع الجلسة صدى الصوت من السماعة.
    WidgetsBinding.instance.addPostFrameCallback((_) => _playWord());
    // حُلّ التصحيح خارجيًا (خروج من الوضع مثلًا) — أغلق الشيت؛ المُغلق
    // المركزي لن يجد تصحيحًا نشطًا فلا يستأنف شيئًا. حارس isCurrent يمنع
    // طرحًا ثانيًا: زر الحل يطفئ الشيت أولًا فيبقى العامل بلا مسار حالي.
    _correctionWorker =
        ever<TasmeeWordCorrection?>(widget.ctrl.state.activeWordCorrection,
            (correction) {
      if (correction == null &&
          mounted &&
          ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _correctionWorker?.dispose();
    super.dispose();
  }

  Future<void> _playWord() async {
    final correction = widget.ctrl.state.activeWordCorrection.value;
    if (correction == null || widget.ctrl.state.isWordRetryListening.value) {
      return;
    }
    var started = false;
    try {
      final library = q.QuranLibrary();
      // المضيف قد لا يكون مهيّئًا خدمة صوت الكلمات — هيّئها هنا بدل
      // الفشل الصامت، وأوقف أي تشغيل سابق قبل النطق الجديد.
      if (!library.isWordAudioInitialized) q.QuranLibrary.initWordAudio();
      await library.stopWordAudio();
      // الخدمة تلتقط أخطاء التشغيل داخليًا — النتيجة الصريحة وحدها
      // تكشف فشل التحميل/التشغيل فتُعرض للمستخدم بدل الصمت.
      started = await library.playWordAudioByNumbers(
        surahNumber: correction.suraIdx,
        ayahNumber: correction.ayaIdx,
        wordNumber: correction.wordNumber,
      );
    } catch (_) {
      started = false;
    }
    if (!started && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
            content: Text('تعذّر تشغيل نطق الكلمة — تحقّق من الاتصال')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final defaults = widget.defaults;
    final bgColor =
        defaults.backgroundColor ?? AppColors.getBackgroundColor(widget.isDark);
    final textColor =
        defaults.textColor ?? AppColors.getTextColor(widget.isDark);

    return Obx(() {
      final correction = ctrl.state.activeWordCorrection.value;
      if (correction == null) return const SizedBox.shrink();
      final kindColor = switch (correction.errorKind) {
        TasmeeErrorKind.tajweed => defaults.tajweedErrorColor,
        TasmeeErrorKind.tashkeel => defaults.tashkeelErrorColor,
        _ => defaults.normalErrorColor,
      };

      return Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'تصحيح الكلمة',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'cairo',
                      package: 'quran_library',
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        (defaults.accentColor ?? textColor).withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${correction.suraIdx}:${correction.ayaIdx} — '
                    'كلمة ${correction.wordNumber}',
                    style: TextStyle(
                      color: textColor.withValues(alpha: .8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'cairo',
                      package: 'quran_library',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _WordView(
              correction: correction,
              defaults: defaults,
              kindColor: kindColor,
              listening: ctrl.state.isWordRetryListening.value,
              onPlay: _playWord,
            ),
            const SizedBox(height: 14),
            _RetrySection(
              ctrl: ctrl,
              defaults: defaults,
              onResolved: widget.onResolved,
            ),
          ],
        ),
      );
    });
  }
}

/// الكلمة الخاطئة مع سياق إعادة النطق وزر الاستماع وشرح الخطأ.
class _WordView extends StatelessWidget {
  const _WordView({
    required this.correction,
    required this.defaults,
    required this.kindColor,
    required this.listening,
    required this.onPlay,
  });

  final TasmeeWordCorrection correction;
  final q.TasmeeStyle defaults;
  final Color? kindColor;
  final bool listening;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final color = kindColor ?? defaults.incorrectColor ?? Colors.red;
    final kindLabel = switch (correction.errorKind) {
      TasmeeErrorKind.tajweed => defaults.tajweedErrorsLabel ?? 'تجويد',
      TasmeeErrorKind.tashkeel => defaults.tashkeelErrorsLabel ?? 'تشكيل',
      _ => defaults.normalErrorsLabel ?? 'نطق',
    };
    final mistakeLabel = switch (correction.errorType) {
      'insert' => 'حرف زائد',
      'delete' => 'حرف ناقص',
      _ => 'تبديل حرف',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'استمع إلى الكلمة',
                icon: Icon(Icons.volume_up_rounded, color: color),
                // أثناء الالتقاط لا تشغيل — صوت السماعة يدخل الميكروفون.
                onPressed: listening ? null : onPlay,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (correction.contextWordText.isNotEmpty)
                        TextSpan(
                          text: '${correction.contextWordText} ',
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'hafs',
                            package: 'quran_library',
                          ),
                        ),
                      TextSpan(
                        text: correction.wordText,
                        style: TextStyle(
                          fontSize: 24,
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'hafs',
                          package: 'quran_library',
                        ),
                      ),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
          if (correction.contextWordText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'أعد النطق بعد كلمتها السابقة وصلًا',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withValues(alpha: .8),
                fontSize: 11,
                fontFamily: 'cairo',
                package: 'quran_library',
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              _KindChip(label: kindLabel, color: color),
              _KindChip(label: mistakeLabel, color: color),
              if (correction.expectedSymbol?.isNotEmpty == true)
                _KindChip(
                  label:
                      '${defaults.expectedLabel ?? 'المتوقع'}: ${correction.expectedSymbol}',
                  color: defaults.correctColor ?? Colors.green,
                ),
              if (correction.predictedSymbol?.isNotEmpty == true)
                _KindChip(
                  label:
                      '${defaults.actualLabel ?? 'المنطوق'}: ${correction.predictedSymbol}',
                  color: defaults.incorrectColor ?? Colors.red,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontFamily: 'cairo',
          package: 'quran_library',
        ),
      ),
    );
  }
}

/// قسم إعادة النطق: زر المحاولة، ملاحظات المحاولة، والقبول/التخطي.
class _RetrySection extends StatelessWidget {
  const _RetrySection({
    required this.ctrl,
    required this.defaults,
    required this.onResolved,
  });

  final TasmeeCtrl ctrl;
  final q.TasmeeStyle defaults;
  final void Function(bool accepted) onResolved;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final listening = ctrl.state.isWordRetryListening.value;
      final outcome = ctrl.state.wordRetryOutcome.value;
      final feedback = ctrl.state.wordRetryFeedback.value;
      final attempts = ctrl.state.wordRetryAttempts.value;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (listening) ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (!listening && outcome == null)
            const Text(
              'جرّب نطق الكلمة — أو تخطَّها لتتابع التسميع',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'cairo',
                package: 'quran_library',
              ),
            ),
          if (outcome == TasmeeWordRetryOutcome.correct) ...[
            _OutcomeRow(
              icon: Icons.verified_rounded,
              color: defaults.correctColor ?? Colors.green,
              text: defaults.noErrorsLabel ?? 'أحسنت! لا أخطاء',
            ),
            const SizedBox(height: 10),
          ],
          if (outcome == TasmeeWordRetryOutcome.incorrect) ...[
            if (feedback != null) ...[
              _OutcomeRow(
                icon: Icons.error_outline,
                color: _feedbackColor(feedback.kind),
                text: _feedbackTitle(feedback),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  if (feedback.ruleName?.isNotEmpty == true)
                    _KindChip(
                        label: feedback.ruleName!,
                        color: _feedbackColor(feedback.kind)),
                  if (feedback.expectedSymbol?.isNotEmpty == true)
                    _KindChip(
                      label:
                          '${defaults.expectedLabel ?? 'المتوقع'}: ${feedback.expectedSymbol}',
                      color: defaults.correctColor ?? Colors.green,
                    ),
                  if (feedback.predictedSymbol?.isNotEmpty == true)
                    _KindChip(
                      label:
                          '${defaults.actualLabel ?? 'المنطوق'}: ${feedback.predictedSymbol}',
                      color: defaults.incorrectColor ?? Colors.red,
                    ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Text(
              attempts > 1 ? 'المحاولات الفاشلة: $attempts' : 'حاول مجددًا',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: defaults.incorrectColor ?? Colors.red,
                fontSize: 11,
                fontFamily: 'cairo',
                package: 'quran_library',
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (outcome == TasmeeWordRetryOutcome.inconclusive) ...[
            _OutcomeRow(
              icon: Icons.help_outline_rounded,
              color: defaults.accentColor ?? Colors.blue,
              text: 'لم تكتمل محاولة التقييم — حاول مجددًا أو تخطَّ الكلمة',
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.mic_rounded, size: 20),
                  label: Text(outcome == TasmeeWordRetryOutcome.correct
                      ? 'إعادة النطق'
                      : 'انطق الكلمة'),
                  // أوقف نطق الكلمة وانتظر توقفه قبل فتح الميكروفون —
                  // صدى السماعة قد يُحسب كلامًا فيُقصّر التسجيل.
                  onPressed: listening
                      ? null
                      : () async {
                          try {
                            await q.QuranLibrary().stopWordAudio();
                          } catch (_) {}
                          ctrl.startWordRetry();
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    outcome == TasmeeWordRetryOutcome.correct
                        ? Icons.play_arrow_rounded
                        : Icons.skip_next_rounded,
                    size: 20,
                  ),
                  label: Text(outcome == TasmeeWordRetryOutcome.correct
                      ? 'متابعة'
                      : 'تخطَّ الكلمة'),
                  // حلَّ وأغلق عبر مسار واحد: تصفير الحالة داخل الحلّ يطلق
                  // عامل الإغلاق أدناه (maybePop) — لا يطرح الزر بنفسه فلا
                  // يُقلب مسار ثانٍ تحته، والإغلاق الخارجي يغطيه المُغلق
                  // الاحتياطي (تخطي).
                  onPressed: listening
                      ? null
                      : () async {
                          final accepted =
                              outcome == TasmeeWordRetryOutcome.correct;
                          onResolved(accepted);
                          await ctrl.resolveWordCorrection(accepted: accepted);
                        },
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Color _feedbackColor(TasmeeErrorKind kind) => switch (kind) {
        TasmeeErrorKind.tajweed =>
          defaults.tajweedErrorColor ?? const Color(0xFF6A1B9A),
        TasmeeErrorKind.tashkeel =>
          defaults.tashkeelErrorColor ?? const Color(0xFFEF6C00),
        _ => defaults.normalErrorColor ?? Colors.red,
      };

  String _feedbackTitle(TasmeeRetryFeedback feedback) =>
      switch (feedback.errorType) {
        'insert' => 'حرف زائد في هذه المحاولة',
        'delete' => 'حرف ناقص في هذه المحاولة',
        _ => 'تبديل حرف في هذه المحاولة',
      };
}

class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontFamily: 'cairo',
              package: 'quran_library',
            ),
          ),
        ),
      ],
    );
  }
}
