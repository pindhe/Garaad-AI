import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enrolled successfully!')));
      _load();
    }
  }

  Future<void> _issueCertificate() async {
    try {
      final result = await context.read<AuthProvider>().api.issueCertificate(widget.courseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Certificate issued: ${result['certificateCode']}')),
        );
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final lessons = (_course?['lessons'] as List?) ?? [];
    final quizzes = (_course?['quizzes'] as List?) ?? [];
    final exams = (_course?['exams'] as List?) ?? [];
    final assignments = (_course?['assignments'] as List?) ?? [];
    final enrolled = _course?['enrollment'] != null;
    final progress = _progress();

    return Scaffold(
      appBar: AppBar(title: Text(_course?['title']?.toString() ?? 'Course')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_course?['subject'] != null)
                Text(_course!['subject'].toString(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_course?['description']?.toString() ?? '', style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 20),
              if (enrolled) ...[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Your progress', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('${progress.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (progress / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          color: AppColors.primary,
                        ),
                      ),
                      if (progress >= 100) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _issueCertificate,
                            icon: const Icon(Icons.workspace_premium_outlined),
                            label: const Text('Claim Certificate'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(onPressed: _enroll, child: const Text('Enroll in Course')),
                ),
              const SizedBox(height: 28),
              _SectionTitle('Lessons', lessons.length),
              const SizedBox(height: 10),
              if (lessons.isEmpty)
                const Text('No lessons yet', style: TextStyle(color: AppColors.textSecondary))
              else
                ...lessons.asMap().entries.map((entry) {
                  final i = entry.key;
                  final l = entry.value;
                  return _ListTile(
                    icon: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary,
                      child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    title: l['title']?.toString() ?? 'Lesson',
                    subtitle: '${l['duration_minutes'] ?? 15} min',
                    onTap: enrolled ? () => Navigator.pushNamed(context, '/lesson', arguments: l['id']) : null,
                  );
                }),
              const SizedBox(height: 24),
              _SectionTitle('Quizzes', quizzes.length),
              const SizedBox(height: 10),
              if (quizzes.isEmpty)
                const Text('No quizzes yet', style: TextStyle(color: AppColors.textSecondary))
              else
                ...quizzes.map((q) => _ListTile(
                      icon: const Icon(Icons.quiz_outlined, color: AppColors.accent),
                      title: q['title']?.toString() ?? 'Quiz',
                      subtitle: '${q['time_limit_minutes'] ?? 30} min',
                      onTap: enrolled ? () => Navigator.pushNamed(context, '/quiz', arguments: q['id']) : null,
                    )),
              const SizedBox(height: 24),
              _SectionTitle('Exams', exams.length),
              const SizedBox(height: 10),
              if (exams.isEmpty)
                const Text('No exams yet', style: TextStyle(color: AppColors.textSecondary))
              else
                ...exams.map((e) => _ListTile(
                      icon: const Icon(Icons.fact_check_outlined, color: Color(0xFF10B981)),
                      title: e['title']?.toString() ?? 'Exam',
                      subtitle: '${e['time_limit_minutes'] ?? 60} min · Full screen',
                      onTap: enrolled ? () => Navigator.pushNamed(context, '/exam', arguments: e['id']) : null,
                    )),
              const SizedBox(height: 24),
              _SectionTitle('Assignments', assignments.length),
              const SizedBox(height: 10),
              if (assignments.isEmpty)
                const Text('No assignments yet', style: TextStyle(color: AppColors.textSecondary))
              else
                ...assignments.map((a) => _ListTile(
                      icon: const Icon(Icons.assignment_outlined, color: AppColors.primary),
                      title: a['title']?.toString() ?? 'Assignment',
                      subtitle: a['due_date'] != null ? 'Due: ${a['due_date']}' : 'No due date',
                      onTap: enrolled ? () => _openAssignmentSubmit(a) : null,
                    )),
              if (!enrolled)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    'Enroll to access lessons, quizzes, exams, and assignments.',
                    style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAssignmentSubmit(Map<String, dynamic> assignment) {
    Navigator.pushNamed(context, '/assignments', arguments: assignment['id']);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  const _SectionTitle(this.title, this.count);

  @override
  Widget build(BuildContext context) {
    return Text('$title ($count)', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700));
  }
}

class _ListTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ListTile({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: onTap,
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: onTap == null ? AppColors.textSecondary : null)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
