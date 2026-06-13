import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';

class DashboardCourseTile extends StatelessWidget {
  final String title;
  final double progress;
  final String? thumbnailUrl;
  final VoidCallback onTap;

  const DashboardCourseTile({
    super.key,
    required this.title,
    required this.progress,
    this.thumbnailUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = progress.clamp(0, 100);
    final letter = title.isNotEmpty ? title[0].toUpperCase() : 'C';
    final hue = (title.hashCode.abs() % 360).toDouble();

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: pct / 100,
                    strokeWidth: 4,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        HSLColor.fromAHSL(1, hue, 0.55, 0.55).toColor(),
                        HSLColor.fromAHSL(1, (hue + 30) % 360, 0.6, 0.45).toColor(),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pct >= 100 ? 'Completed' : '${pct.toStringAsFixed(0)}% complete',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.play_circle_fill_rounded, color: AppColors.primary.withValues(alpha: 0.85), size: 32),
        ],
      ),
    );
  }
}
