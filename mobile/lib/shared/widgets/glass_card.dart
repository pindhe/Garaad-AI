import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final EdgeInsets padding;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.gradient,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null
            ? (isDark ? AppColors.darkSurface : Colors.white)
            : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradient != null
              ? Colors.transparent
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: gradient != null
                ? AppColors.primary.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: gradient != null ? 20 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: card),
      );
    }
    return card;
  }
}
