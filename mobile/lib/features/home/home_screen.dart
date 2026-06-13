import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/app_shell.dart';
import '../courses/courses_screen.dart';
import '../chat/ai_chat_screen.dart';
import '../profile/profile_screen.dart';
import 'student_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final _chatKey = GlobalKey<AiChatScreenState>();

  static const _titles = ['Home', 'Courses', 'AI Chat', 'Profile'];

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}'.trim();
    final student = user?['student'] as Map<String, dynamic>?;
    final totalXp = student?['total_xp'] is num
        ? (student!['total_xp'] as num).toInt()
        : int.tryParse(student?['total_xp']?.toString() ?? '') ?? 0;

    return AppShell(
      currentIndex: _tab,
      onTabChanged: (i) => setState(() => _tab = i),
      title: _titles[_tab],
      showHeader: _tab != 0,
      headerActions: _tab == 2
          ? [
              IconButton(
                icon: const Icon(Icons.add_comment_outlined),
                tooltip: 'New chat',
                onPressed: () => _chatKey.currentState?.clearChat(),
              ),
            ]
          : null,
      onAssignments: () => Navigator.pushNamed(context, '/assignments'),
      onCertificates: () => Navigator.pushNamed(context, '/certificates'),
      onNotifications: () => Navigator.pushNamed(context, '/notifications'),
      onLogout: _logout,
      userName: name.isEmpty ? 'Student' : name,
      userEmail: user?['email']?.toString() ?? '',
      totalXp: totalXp,
      body: IndexedStack(
        index: _tab,
        children: [
          StudentDashboard(
            onOpenCourses: () => setState(() => _tab = 1),
            onOpenAiChat: () => setState(() => _tab = 2),
          ),
          const CoursesScreen(embedded: true),
          AiChatScreen(key: _chatKey, embedded: true),
          ProfileScreen(onLogout: _logout),
        ],
      ),
    );
  }
}
