/// شريط تحكم التسميع السفلي — يحلّ محل شريط الصوت في وضع التسميع.
///
/// الحالات: خمول (زر تسجيل + إعدادات) / تسجيل (عداد كلمات + إيقاف) /
/// معالجة (انتظار) / خطأ (رسالة + إعادة). عند اكتمال التقييم يفتح
/// bottomSheet النتائج تلقائياً.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../quran.dart' as q;
import '../../../core/utils/app_colors.dart';
import '../../controller/tasmee_ctrl.dart';
import '../../engine/recitation_state.dart';
import 'tasmee_result_sheet.dart';
import 'tasmee_settings_sheet.dart';

class TasmeeControlWidget extends StatefulWidget {
  const TasmeeControlWidget({
    super.key,
    required this.isDark,
    this.languageCode,
    this.style,
  });

  final bool isDark;
  final String? languageCode;

  /// نمط مخصص (أو الافتراضي من TasmeeTheme).
  final q.TasmeeStyle? style;

  @override
  State<TasmeeControlWidget> createState() => _TasmeeControlWidgetState();
}

class _TasmeeControlWidgetState extends State<TasmeeControlWidget> {
  Worker? _resultWorker;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    final ctrl = TasmeeCtrl.instance;
    _resultWorker = ever<RecitationState>(ctrl.state.sessionState, (s) {
      // افتح bottomSheet النتائج تلقائياً عند اكتمال التقييم — مرة لكل
      // جلسة (يُعاد ضبط الحارس عند بدء تسجيل جديد).
      if (s == RecitationState.recording) {
        _sheetOpen = false;
        return;
      }
      if (s == RecitationState.finished && !_sheetOpen && mounted) {
        _sheetOpen = true;
        showTasmeeResultSheet(
          context: context,
          isDark: widget.isDark,
          style: widget.style,
          languageCode: widget.languageCode,
        );
      }
    });
  }

  @override
  void dispose() {
    _resultWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaults = widget.style ??
        q.TasmeeTheme.of(context)?.style ??
        q.TasmeeStyle.defaults(isDark: widget.isDark, context: context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: defaults.height ?? 64,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: defaults.backgroundColor ??
              AppColors.getBackgroundColor(widget.isDark),
          borderRadius: BorderRadius.circular(defaults.borderRadius ?? 12),
          boxShadow: [
            BoxShadow(
              color: defaults.shadowColor ?? Colors.black.withValues(alpha: .2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: GetBuilder<TasmeeCtrl>(
          id: TasmeeUpdateIds.control,
          builder: (ctrl) {
            final state = ctrl.state;
            final sessionState = state.sessionState.value;
            return Row(
              textDirection: TextDirection.rtl,
              children: [
                // زر الإعدادات (محرك/خادم).
                IconButton(
                  icon:
                      Icon(Icons.settings_outlined, color: defaults.iconColor),
                  onPressed: (sessionState == RecitationState.recording ||
                          sessionState == RecitationState.processing)
                      ? null
                      : () => showTasmeeSettingsSheet(
                            context: context,
                            isDark: widget.isDark,
                            style: defaults,
                            languageCode: widget.languageCode,
                          ),
                ),
                Expanded(child: _buildStatus(ctrl, defaults)),
                _buildAction(ctrl, defaults),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatus(TasmeeCtrl ctrl, q.TasmeeStyle defaults) {
    final state = ctrl.state;
    switch (state.sessionState.value) {
      case RecitationState.recording:
        final done = state.completedWords.value;
        final total = state.totalWords.value;
        return Row(
          children: [
            const _PulsingDot(),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${defaults.recordingLabel ?? 'جارٍ التسميع'}  ($done/$total)',
                style: _textStyle(defaults, alpha: .9),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case RecitationState.processing:
        return Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                defaults.processingLabel ?? 'جارٍ تحليل التلاوة…',
                style: _textStyle(defaults, alpha: .9),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case RecitationState.error:
        return Text(
          state.lastError.value.isEmpty
              ? 'تعذّر إكمال التسميع — حاول مجددًا'
              : state.lastError.value,
          style: _textStyle(defaults, color: defaults.incorrectColor),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        );
      default:
        if (state.lastError.value.isNotEmpty &&
            state.lastResult.value == null) {
          return Text(
            state.lastError.value,
            style: _textStyle(defaults, color: defaults.incorrectColor),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          );
        }
        if (state.isPreparingEngine.value) {
          return Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.isDownloadingModel.value
                      ? '${defaults.modelDownloadTitle ?? 'تنزيل النموذج'} '
                          '${(state.modelDownloadProgress.value * 100).toInt()}%'
                      : 'جارٍ تجهيز المحرك…',
                  style: _textStyle(defaults, alpha: .9),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }
        return Text(
          defaults.startRecordingLabel ?? 'ابدأ التسميع',
          style: _textStyle(defaults),
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  Widget _buildAction(TasmeeCtrl ctrl, q.TasmeeStyle defaults) {
    switch (ctrl.state.sessionState.value) {
      case RecitationState.recording:
        return _RoundActionButton(
          color: defaults.stopButtonColor ?? Colors.red,
          icon: Icons.stop_rounded,
          label: defaults.stopRecordingLabel,
          onPressed: ctrl.stopRecording,
        );
      case RecitationState.processing:
        return const SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      default:
        return _RoundActionButton(
          color: defaults.recordButtonColor,
          icon: Icons.mic_rounded,
          label: defaults.startRecordingLabel,
          onPressed: ctrl.startRecording,
        );
    }
  }

  TextStyle _textStyle(q.TasmeeStyle defaults, {Color? color, double? alpha}) {
    final base = defaults.textColor ?? AppColors.getTextColor(widget.isDark);
    return TextStyle(
      color: color ?? (alpha == null ? base : base.withValues(alpha: alpha)),
      fontSize: 13,
      fontWeight: FontWeight.w600,
      fontFamily: 'cairo',
      package: 'quran_library',
    );
  }
}

/// زر دائري (تسجيل/إيقاف).
class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Color? color;
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label ?? '',
      child: Material(
        color: color ?? Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

/// نقطة نابضة تشير إلى التسجيل الجاري.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: .3, end: 1).animate(_controller),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
