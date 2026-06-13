import 'package:flutter/material.dart';
import '../course_steps.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

class CourseStepPath extends StatelessWidget {
  final List<CourseStep> steps;
  final void Function(CourseStep step) onStepTap;

  const CourseStepPath({super.key, required this.steps, required this.onStepTap});

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No steps in this course yet.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: steps.length,
      itemBuilder: (_, i) {
        final step = steps[i];
        final isLast = i == steps.length - 1;
        return _StepRow(step: step, isLast: isLast, onTap: step.locked ? null : () => onStepTap(step));
      },
    );
  }
}

class _StepRow extends StatelessWidget {
  final CourseStep step;
  final bool isLast;
  final VoidCallback? onTap;

  const _StepRow({required this.step, required this.isLast, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color nodeColor;
    IconData nodeIcon;

    if (step.completed) {
      nodeColor = const Color(0xFF10B981);
      nodeIcon = Icons.check_rounded;
    } else if (step.locked) {
      nodeColor = isDark ? Colors.white24 : Colors.grey.shade400;
      nodeIcon = Icons.lock_rounded;
    } else if (step.isCurrent) {
      nodeColor = AppColors.primary;
      nodeIcon = Icons.play_arrow_rounded;
    } else {
      nodeColor = AppColors.textSecondary;
      nodeIcon = Icons.circle_outlined;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: nodeColor.withValues(alpha: step.locked ? 0.15 : 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: nodeColor, width: step.isCurrent ? 2.5 : 1.5),
                  ),
                  child: Icon(nodeIcon, size: 18, color: nodeColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: step.completed ? const Color(0xFF10B981).withValues(alpha: 0.5) : (isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: GlassCard(
                onTap: onTap,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Step ${step.stepNumber}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: step.isCurrent ? AppColors.primary : AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(step.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: step.locked ? AppColors.textSecondary : null)),
                          const SizedBox(height: 2),
                          Text(step.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          if (step.isCurrent) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: const Text('Current step', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            ),
                          ],
                          if (step.locked) ...[
                            const SizedBox(height: 8),
                            Text('Complete the previous step to unlock', style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                          ],
                        ],
                      ),
                    ),
                    if (!step.locked)
                      Icon(step.completed ? Icons.replay_rounded : Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
