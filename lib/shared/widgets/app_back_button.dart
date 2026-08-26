import 'package:flutter/material.dart';

import '../../core/localization/app_locale_provider.dart';

class AppBackButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final bool showWhenCannotPop;
  final Color foregroundColor;

  const AppBackButton({
    super.key,
    this.label,
    this.onPressed,
    this.showWhenCannotPop = true,
    this.foregroundColor = const Color(0xFF0D47A1),
  });

  @override
  Widget build(BuildContext context) {
    if (!showWhenCannotPop && onPressed == null && !Navigator.canPop(context)) {
      return const SizedBox.shrink();
    }

    return TextButton.icon(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      icon: const Icon(Icons.arrow_back_rounded),
      label: Text(label ?? context.tr('back')),
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          const haitiRed = Color(0xFFF20D1B);
          if (states.contains(WidgetState.pressed)) {
            return haitiRed.withValues(alpha: .24);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return haitiRed.withValues(alpha: .14);
          }
          return null;
        }),
      ),
    );
  }
}
