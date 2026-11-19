/// bottomSheet إعدادات التسميع — اختيار المحرك وعنوان الخادم والنموذج.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../quran.dart' as q;
import '../../../core/utils/app_colors.dart';
import '../../controller/tasmee_ctrl.dart';
import '../../controller/tasmee_mode.dart';
import '../../controller/tasmee_state.dart';
import '../../engine/models/tasmee_tolerance.dart';

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
    _urlCtrl =
        TextEditingController(text: TasmeeCtrl.instance.state.serverUrl.value);
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
              Text('نمط التسميع', style: _titleStyle(textColor)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final entry in const [
                    (mode: TasmeeMode.tasmee, label: 'تسميع'),
                    (mode: TasmeeMode.corrector, label: 'المصحّح'),
                    (mode: TasmeeMode.teacher, label: 'المعلّم'),
                  ])
                    ChoiceChip(
                      label: Text(entry.label),
                      selected: ctrl.state.mode.value == entry.mode,
                      onSelected: (_) => ctrl.setMode(entry.mode),
                    ),
                ],
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
                mode: TasmeeEngineMode.tajweedFormer,
                title: 'TajweedFormer V4',
                icon: Icons.graphic_eq_rounded,
              ),
              const SizedBox(height: 8),
              _engineOption(
                ctrl: ctrl,
                mode: TasmeeEngineMode.online,
                title: widget.defaults.engineServerLabel ?? 'خادم Muaalem',
                icon: Icons.dns_rounded,
              ),
              if (ctrl.state.engineMode.value == TasmeeEngineMode.online)
                _onlineSection(ctrl, textColor),
              if (ctrl.state.engineMode.value == TasmeeEngineMode.tajweedFormer) ...[
                _v4Section(ctrl, textColor),
                _toleranceSection(ctrl, textColor),
              ],
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
    final textColor =
        widget.defaults.textColor ?? AppColors.getTextColor(widget.isDark);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => ctrl.setEngineMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  /// قسم نموذج V4: تنزيل مسبق وقت التشغيل (مثل نموذج Zipformer ونهتدي).
  Widget _v4Section(TasmeeCtrl ctrl, Color textColor) {
    final state = ctrl.state;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.isDownloadingV4Model.value) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.v4ModelDownloadProgress.value == 0
                    ? null
                    : state.v4ModelDownloadProgress.value,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'تنزيل نموذج TajweedFormer — '
              '${(state.v4ModelDownloadProgress.value * 100).toInt()}%',
              style: _bodyStyle(textColor, alpha: .8),
            ),
          ] else if (state.isV4ModelReady.value)
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 18, color: widget.defaults.correctColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'نموذج V4 جاهز — التسميع يعمل دون إنترنت',
                    style: _bodyStyle(textColor, alpha: .8),
                  ),
                ),
                TextButton(
                  onPressed: () => ctrl.removeV4Model(),
                  child: const Text('حذف النموذج'),
                ),
              ],
            )
          else ...[
            Text(
              'يُنزَّل نموذج V4 مرة واحدة على الجهاز (وقت التشغيل) ويُخزَّنه SDK '
              'Quran Lab؛ اضغط التنزيل الآن أو ابدأ التسميع وسيدخل تلقائيًا.',
              style: _bodyStyle(textColor, alpha: .7),
            ),
            CheckboxListTile(
              value: state.v4WifiOnly.value,
              onChanged: (v) => ctrl.setV4WifiOnly(v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('التنزيل عبر Wi-Fi فقط',
                  style: _bodyStyle(textColor)),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text('تنزيل نموذج V4'),
              onPressed: () => ctrl.downloadV4Model(),
            ),
          ],
          if (state.lastError.value.isNotEmpty &&
              state.engineMode.value == TasmeeEngineMode.tajweedFormer &&
              !state.isV4ModelReady.value) ...[
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

  Widget _toleranceSection(TasmeeCtrl ctrl, Color textColor) {
    final profile = ctrl.state.tolerance.value;
    final matchedPreset = _tolerancePresetOf(profile);
    final accent = widget.defaults.accentColor ?? textColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child:
                  Text('مستوى الصرامة والتسامح', style: _titleStyle(textColor)),
            ),
            if (matchedPreset == null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: .7)),
                ),
                child: Text(
                  'مخصّص',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'cairo',
                    package: 'quran_library',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'تسري على محرك TajweedFormer V4 فقط وتضبط مؤشراته التجريبية؛ '
          'لا تُصدر حكمًا نهائيًا بصحة التلاوة.',
          style: _bodyStyle(textColor, alpha: .75),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 6, children: [
          for (final preset in TasmeeStrictness.values)
            ChoiceChip(
              label: Text(switch (preset) {
                TasmeeStrictness.lenient => 'مُيسّر',
                TasmeeStrictness.balanced => 'متوازن',
                TasmeeStrictness.strict => 'متقن',
              }),
              selected: matchedPreset == preset,
              onSelected: (_) => ctrl.setTolerancePreset(preset),
            ),
        ]),
        const SizedBox(height: 6),
        Text(
          matchedPreset == null
              ? 'مخصّص — مستويات مستقلة لكل محور'
              : switch (matchedPreset) {
                  TasmeeStrictness.lenient =>
                    'يتجاوز الهفوات الخفيفة ويركّز على الأخطاء الواضحة',
                  TasmeeStrictness.balanced =>
                    'توازن معتدل للأخطاء الجلية والحركات والمدود',
                  TasmeeStrictness.strict =>
                    'تدقيق عالٍ يلتقط التغيرات الدقيقة في التشكيل والمدود',
                },
          style: _bodyStyle(textColor, alpha: .75),
        ),
        _toleranceAxis(
          title: 'الحروف والكلمات',
          subtitle: 'إبدال أو سقوط أو زيادة حرف',
          selected: profile.letters,
          allowSkip: false,
          onChanged: (level) =>
              ctrl.setToleranceProfile(profile.copyWith(letters: level)),
          textColor: textColor,
        ),
        _toleranceAxis(
          title: 'التشكيل والحركات',
          subtitle: 'تبديل الفتحة والكسرة والضمة',
          selected: profile.tashkeel,
          allowSkip: true,
          onChanged: (level) =>
              ctrl.setToleranceProfile(profile.copyWith(tashkeel: level)),
          textColor: textColor,
        ),
        _toleranceAxis(
          title: 'المدود',
          subtitle: 'قياس طول المد مقارنة بالحركة القصيرة',
          selected: profile.madd,
          allowSkip: true,
          onChanged: (level) =>
              ctrl.setToleranceProfile(profile.copyWith(madd: level)),
          textColor: textColor,
        ),
      ],
    );
  }

  Widget _toleranceAxis({
    required String title,
    required String subtitle,
    required TasmeeToleranceLevel selected,
    required bool allowSkip,
    required ValueChanged<TasmeeToleranceLevel> onChanged,
    required Color textColor,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 10),
      Text(title, style: _bodyStyle(textColor)),
      const SizedBox(height: 2),
      Text(subtitle, style: _bodyStyle(textColor, alpha: .65)),
      const SizedBox(height: 6),
      Wrap(spacing: 6, children: [
        for (final level in TasmeeToleranceLevel.values)
          if (allowSkip || level != TasmeeToleranceLevel.skip)
            ChoiceChip(
              label: Text(switch (level) {
                TasmeeToleranceLevel.skip => 'تجاهل',
                TasmeeToleranceLevel.lenient => 'متسامح',
                TasmeeToleranceLevel.balanced => 'متوازن',
                TasmeeToleranceLevel.strict => 'صارم',
              }),
              selected: selected == level,
              onSelected: (_) => onChanged(level),
            ),
      ]),
    ]);
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
              label:
                  Text(widget.defaults.modelDownloadTitle ?? 'تنزيل النموذج'),
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

/// المسبق العام المطابق للملف، أو null إذا خالفه أي محور (مخصّص).
TasmeeStrictness? _tolerancePresetOf(TasmeeToleranceProfile profile) {
  for (final preset in TasmeeStrictness.values) {
    final level = TasmeeToleranceLevel.parse(
        preset.name, TasmeeToleranceLevel.balanced);
    if (profile.letters == level &&
        profile.tashkeel == level &&
        profile.madd == level) {
      return preset;
    }
  }
  return null;
}
