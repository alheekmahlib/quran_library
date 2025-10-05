import 'package:flutter/material.dart';
import 'package:quran_library/src/core/utils/app_colors.dart';

class HeaderDialogWidget extends StatelessWidget {
  final bool? isDark;
  final String title;
  const HeaderDialogWidget({
    super.key,
    this.isDark = false,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        Container(
          height: 45,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [
                Colors.cyan.withValues(alpha: .12),
                Colors.cyan.withValues(alpha: .04),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.font_download_rounded, color: Colors.cyan),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'cairo',
                  height: 1.3,
                  color: AppColors.getTextColor(isDark!),
                  package: 'quran_library',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'إغلاق',
          icon: Icon(Icons.close,
              color: AppColors.getTextColor(isDark!), size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
