import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _progress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final api = context.read<AuthProvider>().api;
      _progress = await api.getProgress();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?['first_name'] ?? 'Student';
    final enrollments = (_progress?['enrollments'] as List?) ?? [];

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadProgress,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hello, $name 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              const Text('Ready to learn today?', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout),
                            onPressed: () async {
                              await context.read<AuthProvider>().logout();
                              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/chat'),
                        child: GlassCard(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF1D4ED8)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 32),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('AI Teacher', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text('Ask anything, anytime', style: TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Continue Learning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (enrollments.isEmpty)
                        GlassCard(
                          child: Column(
                            children: [
                              const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 8),
                              const Text('No courses yet'),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/courses'),
                                child: const Text('Browse Courses'),
                              ),
                            ],
                          ),
                        )
                      else
                        ...enrollments.take(3).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            onTap: () => Navigator.pushNamed(context, '/course', arguments: e['course_id']),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e['title'] ?? 'Course', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: (e['progress_percent'] ?? 0) / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 4),
                                Text('${e['progress_percent'] ?? 0}% complete', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        )),
                      const SizedBox(height: 24),
                      const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _QuickAction(icon: Icons.menu_book, label: 'Courses', color: AppColors.primary, onTap: () => Navigator.pushNamed(context, '/courses')),
                          _QuickAction(icon: Icons.assignment, label: 'Assignments', color: AppColors.accent, onTap: () => Navigator.pushNamed(context, '/assignments')),
                          _QuickAction(icon: Icons.quiz, label: 'Exams', color: Colors.green, onTap: () => Navigator.pushNamed(context, '/courses')),
                          _QuickAction(icon: Icons.workspace_premium, label: 'Certificates', color: Colors.purple, onTap: () => Navigator.pushNamed(context, '/certificates')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
