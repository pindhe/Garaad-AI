import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/app_shell.dart';
import '../courses/courses_screen.dart';
import '../chat/ai_chat_screen.dart';
import 'student_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

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

    return AppShell(
      currentIndex: _tab,
      onTabChanged: (i) => setState(() => _tab = i),
      body: StudentDashboard(
        onOpenCourses: () => setState(() => _tab = 1),
        onOpenAiChat: () => setState(() => _tab = 2),
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
    final student = user?['student'] as Map<String, dynamic>?;

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
                if (student?['grade_level'] != null) ...[
                  const SizedBox(height: 8),
                  Text(student!['grade_level'].toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          _ProfileTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => Navigator.pushNamed(context, '/notifications')),
          _ProfileTile(icon: Icons.assignment_outlined, label: 'Assignments', onTap: () => Navigator.pushNamed(context, '/assignments')),
          _ProfileTile(icon: Icons.workspace_premium_outlined, label: 'Certificates', onTap: () => Navigator.pushNamed(context, '/certificates')),
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
