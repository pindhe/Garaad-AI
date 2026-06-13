import 'package:flutter/material.dart';
import '../../../core/services/public_api.dart';
import '../../../core/theme/app_theme.dart';

class LoginStatsStrip extends StatelessWidget {
  final PlatformStats stats;
  final bool apiOnline;

  const LoginStatsStrip({super.key, required this.stats, required this.apiOnline});

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: apiOnline ? const Color(0xFF22C55E) : Colors.orange,
                boxShadow: [
                  BoxShadow(
                    color: (apiOnline ? const Color(0xFF22C55E) : Colors.orange).withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              apiOnline ? 'Live · Connected to MacallinAI' : 'Offline · Start backend to sync',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _StatChip(icon: Icons.people_alt_rounded, label: 'Students', value: _fmt(stats.totalStudents))),
            const SizedBox(width: 8),
            Expanded(child: _StatChip(icon: Icons.menu_book_rounded, label: 'Courses', value: _fmt(stats.totalCourses))),
            const SizedBox(width: 8),
            Expanded(child: _StatChip(icon: Icons.smart_toy_rounded, label: 'AI Today', value: _fmt(stats.aiSessionsToday))),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : Colors.white),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : AppColors.textPrimary)),
          Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : AppColors.textSecondary)),
        ],
      ),
    );
  }
}
