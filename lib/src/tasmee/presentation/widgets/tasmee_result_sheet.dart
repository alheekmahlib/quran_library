/// bottomSheet نتائج التسميع — ملخص الأخطاء وبطاقات التصحيح.
library;

import 'package:flutter/material.dart';

import '../../../../quran.dart' as q;
import '../../../core/utils/app_colors.dart';
import '../../controller/tasmee_ctrl.dart';
import '../../engine/models/recitation_result.dart';

/// يفتح bottomSheet نتائج آخر جلسة تسميع.
Future<void> showTasmeeResultSheet({
  required BuildContext context,
  required bool isDark,
  q.TasmeeStyle? style,
  String? languageCode,
}) async {
  final ctrl = TasmeeCtrl.instance;
  final defaults = style ??
      q.TasmeeTheme.of(context)?.style ??
      q.TasmeeStyle.defaults(isDark: isDark, context: context);
  final size = MediaQuery.sizeOf(context);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    constraints: BoxConstraints(maxHeight: size.height * .85),
    builder: (modalContext) => _TasmeeResultSheet(
      ctrl: ctrl,
      defaults: defaults,
      isDark: isDark,
    ),
  );
}

class _TasmeeResultSheet extends StatelessWidget {
  const _TasmeeResultSheet({
    required this.ctrl,
    required this.defaults,
    required this.isDark,
  });

  final TasmeeCtrl ctrl;
  final q.TasmeeStyle defaults;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final result = ctrl.state.lastResult.value;
    final bgColor =
        defaults.backgroundColor ?? AppColors.getBackgroundColor(isDark);
    final textColor = defaults.textColor ?? AppColors.getTextColor(isDark);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // مقبض السحب + العنوان.
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
                  defaults.resultsTitle ?? 'نتيجة التسميع',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'cairo',
                    package: 'quran_library',
                  ),
                ),
              ),
              _positionLabel(result, textColor),
            ],
          ),
          const SizedBox(height: 12),
          if (result == null || !result.hasMatch)
            _NoMatchView(defaults: defaults, message: ctrl.state.lastError.value)
          else ...[
            _ErrorSummaryBar(result: result, defaults: defaults),
            const SizedBox(height: 12),
            if (result.errors.isEmpty)
              _SuccessRow(defaults: defaults)
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: result.errors.length,
                  itemBuilder: (_, i) => _ErrorCard(
                    error: result.errors[i],
                    defaults: defaults,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          // إخلاء المسؤولية (إلزامي — رخصة NPL-1.2).
          Text(
            defaults.disclaimer ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.55),
              fontSize: 11,
              fontFamily: 'cairo',
              package: 'quran_library',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.replay_rounded, size: 20),
                  label: Text(defaults.retryLabel ?? 'إعادة التسميع'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ctrl.retryTasmee();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: Text(defaults.exitLabel ?? 'خروج'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ctrl.exitTasmeeMode();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _positionLabel(RecitationResult? result, Color textColor) {
    if (result?.start == null) return const SizedBox.shrink();
    final s = result!.start!;
    final e = result.end ?? s;
    final sameAyah = s.suraIdx == e.suraIdx && s.ayaIdx == e.ayaIdx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (defaults.accentColor ?? textColor).withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        sameAyah
            ? '${s.suraIdx}:${s.ayaIdx}'
            : '${s.suraIdx}:${s.ayaIdx} — ${e.suraIdx}:${e.ayaIdx}',
        style: TextStyle(
          color: textColor.withValues(alpha: .8),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'cairo',
          package: 'quran_library',
        ),
      ),
    );
  }
}

class _NoMatchView extends StatelessWidget {
  const _NoMatchView({required this.defaults, required this.message});

  final q.TasmeeStyle defaults;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: defaults.incorrectColor),
          const SizedBox(height: 8),
          Text(
            message.isEmpty
                ? 'لم يتمكّن النموذج من التعرّف على التلاوة — حاول مجددًا '
                    'بنطق أوضح وأقرب من الميكروفون'
                : message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'cairo',
              package: 'quran_library',
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorSummaryBar extends StatelessWidget {
  const _ErrorSummaryBar({required this.result, required this.defaults});

  final RecitationResult result;
  final q.TasmeeStyle defaults;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryChip(
          label: defaults.totalErrorsLabel ?? 'إجمالي',
          value: '${result.errors.length}',
        ),
        _SummaryChip(
          label: defaults.tajweedErrorsLabel ?? 'تجويد',
          value: '${result.tajweedErrors.length}',
          color: defaults.accentColor,
        ),
        _SummaryChip(
          label: defaults.normalErrorsLabel ?? 'نطق',
          value: '${result.normalErrors.length}',
          color: defaults.incorrectColor,
        ),
        _SummaryChip(
          label: defaults.tashkeelErrorsLabel ?? 'تشكيل',
          value: '${result.tashkeelErrors.length}',
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip(
      {required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                color: c,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'cairo',
                package: 'quran_library',
              )),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                color: c.withValues(alpha: .8),
                fontSize: 12,
                fontFamily: 'cairo',
                package: 'quran_library',
              )),
        ],
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  const _SuccessRow({required this.defaults});

  final q.TasmeeStyle defaults;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (defaults.correctColor ?? Colors.green).withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded,
              color: defaults.correctColor ?? const Color(0xFF2E7D32)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              defaults.noErrorsLabel ?? 'أحسنت! لا أخطاء',
              style: TextStyle(
                color: defaults.correctColor ?? Colors.green,
                fontWeight: FontWeight.w700,
                fontFamily: 'cairo',
                package: 'quran_library',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.defaults});

  final RecitationError error;
  final q.TasmeeStyle defaults;

  @override
  Widget build(BuildContext context) {
    final isTajweed = error.errorType == 'tajweed';
    final iconColor =
        isTajweed ? defaults.accentColor : defaults.incorrectColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: iconColor!.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isTajweed ? Icons.music_note_rounded : Icons.error_outline,
              color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'cairo',
                    package: 'quran_library',
                  ),
                ),
                if (error.wordText != null &&
                    error.wordText!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error.wordText!,
                      style: TextStyle(
                        fontSize: 15,
                        color: iconColor,
                        fontFamily: 'hafs',
                        package: 'quran_library',
                      ),
                    ),
                  ),
                ],
                if (error.expectedPh != null &&
                    error.expectedPh!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _PhonemeChip(
                        label:
                            '${defaults.expectedLabel ?? 'المتوقع'}: ${error.expectedPh}',
                        color: defaults.correctColor ?? Colors.green,
                      ),
                      if (error.predictedPh != null &&
                          error.predictedPh!.isNotEmpty)
                        _PhonemeChip(
                          label:
                              '${defaults.actualLabel ?? 'المنطوق'}: ${error.predictedPh}',
                          color: defaults.incorrectColor ?? Colors.red,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhonemeChip extends StatelessWidget {
  const _PhonemeChip({required this.label, required this.color});

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
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
