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
    try {
      _course = await context.read<AuthProvider>().api.getCourse(widget.courseId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _enroll() async {
    await context.read<AuthProvider>().api.enrollCourse(widget.courseId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enrolled successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final lessons = (_course?['lessons'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(_course?['title'] ?? 'Course')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_course?['description'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _enroll, child: const Text('Enroll in Course')),
            ),
            const SizedBox(height: 24),
            Text('Lessons (${lessons.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...lessons.asMap().entries.map((entry) {
              final i = entry.key;
              final l = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  onTap: () => Navigator.pushNamed(context, '/lesson', arguments: l['id']),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l['title'] ?? 'Lesson', style: const TextStyle(fontWeight: FontWeight.w600))),
                      Text('${l['duration_minutes'] ?? 15} min', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
