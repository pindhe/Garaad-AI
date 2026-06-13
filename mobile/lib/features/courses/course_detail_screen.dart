import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import 'course_steps.dart';
import 'widgets/course_step_path.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Map<String, dynamic>? _course;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _course = await context.read<AuthProvider>().api.getCourse(widget.courseId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _enroll() async {
    await context.read<AuthProvider>().api.enrollCourse(widget.courseId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enrolled! Start Step 1 below.')));
      _load();
    }
  }

  Future<void> _issueCertificate() async {
    try {
      final result = await context.read<AuthProvider>().api.issueCertificate(widget.courseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Certificate issued: ${result['certificateCode'] ?? result['certificate_code']}')),
        );
        Navigator.pushNamed(context, '/certificates');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  double _progress() {
    final v = _course?['enrollment']?['progress_percent'];
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  Future<void> _openStep(CourseStep step) async {
    if (step.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete the previous step first')),
      );
      return;
    }

    dynamic result;
    switch (step.type) {
      case CourseStepType.lesson:
        result = await Navigator.pushNamed(context, '/lesson', arguments: step.id);
        break;
      case CourseStepType.quiz:
        result = await Navigator.pushNamed(context, '/quiz', arguments: step.id);
        break;
      case CourseStepType.assignment:
        result = await Navigator.pushNamed(context, '/assignments');
        break;
      case CourseStepType.exam:
        result = await Navigator.pushNamed(context, '/exam', arguments: step.id);
        break;
    }
    if (mounted) _load();
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Step complete! Continue to the next step.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _course?['title']?.toString() ?? 'Course';
    final subject = _course?['subject']?.toString() ?? 'General';
    final lessons = (_course?['lessons'] as List?) ?? [];
    final quizzes = (_course?['quizzes'] as List?) ?? [];
    final exams = (_course?['exams'] as List?) ?? [];
    final assignments = (_course?['assignments'] as List?) ?? [];
    final enrolled = _course?['enrollment'] != null;
    final progress = _progress();
    final hue = (title.hashCode.abs() % 360).toDouble();

    final steps = buildCourseSteps(
      lessons: lessons,
      quizzes: quizzes,
      assignments: assignments,
      exams: exams,
      enrolled: enrolled,
    );
    final current = currentCourseStep(steps);
    final allLessonStepsDone = steps.where((s) => s.type == CourseStepType.lesson).every((s) => s.completed);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        HSLColor.fromAHSL(1, hue, 0.55, 0.5).toColor(),
                        HSLColor.fromAHSL(1, (hue + 40) % 360, 0.6, 0.4).toColor(),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(subject, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text('${steps.length} steps · complete in order', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: enrolled
                    ? _ProgressCard(progress: progress, onClaimCert: progress >= 100 ? _issueCertificate : null)
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(onPressed: _enroll, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Enroll & Start Step 1')),
                      ),
              ),
            ),
            if (enrolled && current != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: GlassCard(
                    gradient: LinearGradient(colors: [AppColors.primary, const Color(0xFF1D4ED8)]),
                    onTap: () => _openStep(current),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Step ${current.stepNumber}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                              Text(current.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                            ],
                          ),
                        ),
                        const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            if (enrolled && current == null && allLessonStepsDone && steps.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassCard(
                    child: Row(
                      children: [
                        const Icon(Icons.celebration_rounded, color: Color(0xFF10B981), size: 32),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('All lesson steps complete! Finish quiz, assignment & exam below.', style: TextStyle(fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Course path', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
              ),
            ),
            SliverToBoxAdapter(
              child: enrolled
                  ? CourseStepPath(steps: steps, onStepTap: _openStep)
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Enroll to see the step-by-step learning path.', style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary)),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final double progress;
  final VoidCallback? onClaimCert;

  const _ProgressCard({required this.progress, this.onClaimCert});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (progress / 100).clamp(0, 1),
                  strokeWidth: 5,
                  backgroundColor: Colors.grey.shade200,
                  color: AppColors.primary,
                ),
                Text('${progress.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your progress', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('Complete each step in order', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (onClaimCert != null)
            IconButton(onPressed: onClaimCert, icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.accent), tooltip: 'Claim certificate'),
        ],
      ),
    );
  }
}
