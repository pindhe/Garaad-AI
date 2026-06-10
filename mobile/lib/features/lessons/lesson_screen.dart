import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class LessonScreen extends StatefulWidget {
  final int lessonId;
  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  Map<String, dynamic>? _lesson;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _lesson = await context.read<AuthProvider>().api.getLesson(widget.lessonId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _complete() async {
    await context.read<AuthProvider>().api.completeLesson(widget.lessonId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson completed!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final examples = (_lesson?['examples'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(_lesson?['title'] ?? 'Lesson')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_lesson?['content'] ?? 'No content', style: const TextStyle(fontSize: 16, height: 1.6)),
            if (examples.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Examples', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...examples.map((e) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text('$e', style: const TextStyle(height: 1.4)),
              )),
            ],
            if (_lesson?['notes'] != null) ...[
              const SizedBox(height: 24),
              const Text('Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_lesson!['notes'], style: const TextStyle(height: 1.5)),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _complete, child: const Text('Mark as Complete')),
            ),
          ],
        ),
      ),
    );
  }
}
