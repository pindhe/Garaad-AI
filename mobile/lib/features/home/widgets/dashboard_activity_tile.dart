import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';

class DashboardActivityTile extends StatelessWidget {
  final String title;
  final double score;
  final String? submittedAt;

  const DashboardActivityTile({
    super.key,
    required this.title,
    required this.score,
    this.submittedAt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = score >= 80
        ? const Color(0xFF10B981)
        : score >= 60
            ? AppColors.accent
            : Colors.redAccent;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                score.toStringAsFixed(0),
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  _timeLabel(submittedAt),
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.quiz_rounded, size: 18, color: isDark ? Colors.white38 : AppColors.textSecondary),
        ],
      ),
    );
  }

  String _timeLabel(String? iso) {
    if (iso == null || iso.isEmpty) return 'Quiz completed';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Quiz completed';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
