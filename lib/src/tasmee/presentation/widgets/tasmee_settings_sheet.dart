/// bottomSheet إعدادات التسميع — اختيار المحرك وعنوان الخادم والنموذج.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../quran.dart' as q;
import '../../../core/utils/app_colors.dart';
import '../../controller/tasmee_ctrl.dart';
import '../../controller/tasmee_state.dart';

/// يفتح bottomSheet إعدادات التسميع.
Future<void> showTasmeeSettingsSheet({
  required BuildContext context,
  required bool isDark,
  q.TasmeeStyle? style,
  String? languageCode,
}) async {
  final defaults = style ??
      q.TasmeeTheme.of(context)?.style ??
      q.TasmeeStyle.defaults(isDark: isDark, context: context);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor:
        defaults.backgroundColor ?? AppColors.getBackgroundColor(isDark),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .7,
    ),
    builder: (_) => _TasmeeSettingsSheet(defaults: defaults, isDark: isDark),
  );
}

class _TasmeeSettingsSheet extends StatefulWidget {
  const _TasmeeSettingsSheet({required this.defaults, required this.isDark});

  final q.TasmeeStyle defaults;
  final bool isDark;

  @override
  State<_TasmeeSettingsSheet> createState() => _TasmeeSettingsSheetState();
}

class _TasmeeSettingsSheetState extends State<_TasmeeSettingsSheet> {
  late final TextEditingController _urlCtrl;
  String? _serverCheckMessage;
  bool _checkingServer = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(
        text: TasmeeCtrl.instance.state.serverUrl.value);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.defaults.textColor ?? AppColors.getTextColor(widget.isDark);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GetBuilder<TasmeeCtrl>(
          id: TasmeeUpdateIds.control,
          builder: (ctrl) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.defaults.settingsLabel ?? 'إعدادات التسميع',
                style: _titleStyle(textColor),
              ),
              const SizedBox(height: 16),
              _engineOption(
                ctrl: ctrl,
                mode: TasmeeEngineMode.offline,
                title: widget.defaults.engineLocalLabel ?? 'نموذج محلي',
                icon: Icons.phone_android_rounded,
              ),
              if (ctrl.state.engineMode.value == TasmeeEngineMode.offline)
                _offlineSection(ctrl, textColor),
              const SizedBox(height: 8),
              _engineOption(
                ctrl: ctrl,
                mode: TasmeeEngineMode.online,
                title: widget.defaults.engineServerLabel ?? 'خادم Muaalem',
                icon: Icons.dns_rounded,
              ),
              if (ctrl.state.engineMode.value == TasmeeEngineMode.online)
                _onlineSection(ctrl, textColor),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _titleStyle(Color textColor) => TextStyle(
        color: textColor,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        fontFamily: 'cairo',
        package: 'quran_library',
      );

  TextStyle _bodyStyle(Color textColor, {double alpha = 1}) => TextStyle(
        color: textColor.withValues(alpha: alpha),
        fontSize: 13,
        fontFamily: 'cairo',
        package: 'quran_library',
      );

  Widget _engineOption({
    required TasmeeCtrl ctrl,
    required TasmeeEngineMode mode,
    required String title,
    required IconData icon,
  }) {
    final selected = ctrl.state.engineMode.value == mode;
    final accent = widget.defaults.accentColor;
    final textColor = widget.defaults.textColor ??
        AppColors.getTextColor(widget.isDark);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => ctrl.setEngineMode(mode),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (accent ?? textColor).withValues(alpha: .08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? (accent ?? textColor).withValues(alpha: .5)
                : textColor.withValues(alpha: .12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected
                    ? accent ?? textColor
                    : textColor.withValues(alpha: .6)),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: _bodyStyle(textColor))),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  size: 20, color: accent ?? textColor),
          ],
        ),
      ),
    );
  }

  /// قسم النموذج المحلي: حالة/تنزيل.
  Widget _offlineSection(TasmeeCtrl ctrl, Color textColor) {
    final state = ctrl.state;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.isDownloadingModel.value) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.modelDownloadProgress.value == 0
                    ? null
                    : state.modelDownloadProgress.value,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.defaults.modelDownloadTitle ?? 'تنزيل النموذج'} — '
              '${(state.modelDownloadProgress.value * 100).toInt()}%',
              style: _bodyStyle(textColor, alpha: .8),
            ),
          ] else if (state.isModelReady.value)
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 18, color: widget.defaults.correctColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'النموذج جاهز — التسميع يعمل دون إنترنت',
                    style: _bodyStyle(textColor, alpha: .8),
                  ),
                ),
              ],
            )
          else ...[
            Text(
              widget.defaults.modelDownloadNote ??
                  'يُنزَّل النموذج مرة واحدة عند أول استخدام.',
              style: _bodyStyle(textColor, alpha: .7),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.download_rounded, size: 20),
              label: Text(widget.defaults.modelDownloadTitle ?? 'تنزيل النموذج'),
              onPressed: () => ctrl.downloadModelIfNeeded(),
            ),
          ],
        ],
      ),
    );
  }

  /// قسم الخادم: عنوان + فحص اتصال.
  Widget _onlineSection(TasmeeCtrl ctrl, Color textColor) {
    final state = ctrl.state;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملاحظة: وضع الخادم لا يعرض الكلمات أثناء التلاوة — تظهر النتائج '
            'بعد الإيقاف فقط.',
            style: _bodyStyle(textColor, alpha: .7),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlCtrl,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: widget.defaults.serverUrlLabel ?? 'عنوان الخادم',
              hintText: 'http://localhost:8001',
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: ctrl.setServerUrl,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: _checkingServer
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.wifi_tethering_rounded, size: 20),
            label: Text(widget.defaults.checkServerLabel ?? 'فحص الاتصال'),
            onPressed: _checkingServer ? null : () => _checkServer(ctrl),
          ),
          if (_serverCheckMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _serverCheckMessage!,
              style: _bodyStyle(
                textColor,
                alpha: .85,
              ),
            ),
          ],
          if (state.lastError.value.isNotEmpty &&
              state.engineMode.value == TasmeeEngineMode.online) ...[
            const SizedBox(height: 6),
            Text(
              state.lastError.value,
              style: TextStyle(
                color: widget.defaults.incorrectColor,
                fontSize: 12,
                fontFamily: 'cairo',
                package: 'quran_library',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _checkServer(TasmeeCtrl ctrl) async {
    setState(() {
      _checkingServer = true;
      _serverCheckMessage = null;
    });
    final ok = await ctrl.testServerConnection();
    if (!mounted) return;
    setState(() {
      _checkingServer = false;
      _serverCheckMessage = ok
          ? 'تم الاتصال بالخادم بنجاح ✓'
          : 'تعذّر الاتصال بالخادم — تحقّق من العنوان والتشغيل';
    });
  }
}
