import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<dynamic> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _courses = await context.read<AuthProvider>().api.getCourses();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? const Center(child: Text('No courses available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _courses.length,
                  itemBuilder: (_, i) {
                    final c = _courses[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        onTap: () => Navigator.pushNamed(context, '/course', arguments: c['id']),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.menu_book, color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(c['subject'] ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                                  if (c['description'] != null)
                                    Text(c['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
