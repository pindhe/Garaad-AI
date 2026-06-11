import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/app_shell.dart';
import '../courses/courses_screen.dart';
import '../chat/ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  Map<String, dynamic>? _progress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      _progress = await context.read<AuthProvider>().api.getProgress();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double _parseProgress(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_tab == 1) {
      return AppShell(
        currentIndex: _tab,
        onTabChanged: (i) => setState(() => _tab = i),
        body: const CoursesScreen(embedded: true),
      );
    }
    if (_tab == 2) {
      return AppShell(
        currentIndex: _tab,
        onTabChanged: (i) => setState(() => _tab = i),
        body: const AiChatScreen(embedded: true),
      );
    }
    if (_tab == 3) {
      return AppShell(
        currentIndex: _tab,
        onTabChanged: (i) => setState(() => _tab = i),
        body: _ProfileTab(onLogout: () async {
          await context.read<AuthProvider>().logout();
          if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
        }),
      );
    }

    final user = context.watch<AuthProvider>().user;
    final name = user?['first_name']?.toString() ?? 'Student';
    final enrollments = (_progress?['enrollments'] as List?) ?? [];

    return AppShell(
      currentIndex: _tab,
      onTabChanged: (i) => setState(() => _tab = i),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProgress,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hello, $name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                              const Text('Ready to learn today?', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, Color(0xFF1D4ED8)],
                      ),
                      onTap: () => setState(() => _tab = 2),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AI Teacher', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                                SizedBox(height: 4),
                                Text('Ask anything, get step-by-step help', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.8), size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Continue Learning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        TextButton(onPressed: () => setState(() => _tab = 1), child: const Text('See all')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (enrollments.isEmpty)
                      GlassCard(
                        child: Column(
                          children: [
                            Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No courses yet', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            const Text('Browse courses to start learning', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 12),
                            TextButton(onPressed: () => setState(() => _tab = 1), child: const Text('Browse Courses')),
                          ],
                        ),
                      )
                    else
                      ...enrollments.take(3).map((e) {
                        final progress = _parseProgress(e['progress_percent']);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            onTap: () => Navigator.pushNamed(context, '/course', arguments: e['course_id']),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e['title']?.toString() ?? 'Course', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: (progress / 100).clamp(0.0, 1.0),
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text('${progress.toStringAsFixed(0)}% complete', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 28),
                    const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      children: [
                        _QuickAction(icon: Icons.menu_book_rounded, label: 'Courses', color: AppColors.primary, onTap: () => setState(() => _tab = 1)),
                        _QuickAction(icon: Icons.assignment_rounded, label: 'Assignments', color: AppColors.accent, onTap: () => Navigator.pushNamed(context, '/assignments')),
                        _QuickAction(icon: Icons.quiz_rounded, label: 'Exams', color: const Color(0xFF10B981), onTap: () => setState(() => _tab = 1)),
                        _QuickAction(icon: Icons.workspace_premium_rounded, label: 'Certificates', color: Colors.purple, onTap: () => Navigator.pushNamed(context, '/certificates')),
                      ],
                    ),
                  ],
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final VoidCallback onLogout;
  const _ProfileTab({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}'.trim();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name.isEmpty ? 'Student' : name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                Text(user?['email']?.toString() ?? '', style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _ProfileTile(icon: Icons.workspace_premium_outlined, label: 'Certificates', onTap: () => Navigator.pushNamed(context, '/certificates')),
          _ProfileTile(icon: Icons.assignment_outlined, label: 'Assignments', onTap: () => Navigator.pushNamed(context, '/assignments')),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade200),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
