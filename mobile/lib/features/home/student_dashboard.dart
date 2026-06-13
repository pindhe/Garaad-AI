import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import 'widgets/dashboard_activity_tile.dart';
import 'widgets/dashboard_course_tile.dart';
import 'widgets/dashboard_stat_card.dart';

class StudentDashboard extends StatefulWidget {
  final VoidCallback onOpenCourses;
  final VoidCallback onOpenAiChat;

  const StudentDashboard({
    super.key,
    required this.onOpenCourses,
    required this.onOpenAiChat,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;

  Map<String, dynamic>? _progress;
  List<dynamic> _assignments = [];
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final api = context.read<AuthProvider>().api;
    try {
      final results = await Future.wait([
        api.getProgress(),
        api.getAssignments(),
        api.getNotifications(),
      ]);
      if (!mounted) return;
      setState(() {
        _progress = Map<String, dynamic>.from(results[0] as Map);
        _assignments = results[1] as List<dynamic>;
        _notifications = results[2] as List<dynamic>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  double _parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  int _unreadCount() => _notifications.where((n) => n['is_read'] != true && n['is_read'] != 1).length;

  double _avgQuizScore(List<dynamic> results) {
    if (results.isEmpty) return 0;
    final scores = results.map((r) => _parseNum(r['score'])).where((s) => s > 0);
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  List<dynamic> _upcomingAssignments() {
    final sorted = List<dynamic>.from(_assignments);
    sorted.sort((a, b) {
      final da = DateTime.tryParse(a['due_date']?.toString() ?? '') ?? DateTime(2099);
      final db = DateTime.tryParse(b['due_date']?.toString() ?? '') ?? DateTime(2099);
      return da.compareTo(db);
    });
    return sorted.take(3).toList();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = context.watch<AuthProvider>().user;
    final firstName = user?['first_name']?.toString() ?? 'Student';
    final student = user?['student'] as Map<String, dynamic>?;
    final grade = student?['grade_level']?.toString();
    final enrollments = (_progress?['enrollments'] as List?) ?? [];
    final quizResults = (_progress?['quiz_results'] as List?) ?? (_progress?['quizResults'] as List?) ?? [];
    final totalXp = _parseNum(_progress?['totalXp'] ?? _progress?['total_xp'] ?? student?['total_xp']).toInt();
    final completedCourses = enrollments.where((e) => _parseNum(e['progress_percent']) >= 100).length;
    final avgScore = _avgQuizScore(quizResults);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = _unreadCount();

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut),
              child: _DashboardHeader(
                greeting: _greeting(),
                name: firstName,
                grade: grade,
                unread: unread,
                totalXp: totalXp,
                isDark: isDark,
                onNotifications: () => Navigator.pushNamed(context, '/notifications'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.1, 1, curve: Curves.easeOut)),
                child: Row(
                  children: [
                    Expanded(
                      child: DashboardStatCard(
                        icon: Icons.menu_book_rounded,
                        label: 'Courses',
                        value: '${enrollments.length}',
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DashboardStatCard(
                        icon: Icons.bolt_rounded,
                        label: 'XP',
                        value: _fmt(totalXp),
                        color: AppColors.accent,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DashboardStatCard(
                        icon: Icons.quiz_rounded,
                        label: 'Avg Quiz',
                        value: quizResults.isEmpty ? '—' : '${avgScore.toStringAsFixed(0)}%',
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DashboardStatCard(
                        icon: Icons.check_circle_rounded,
                        label: 'Done',
                        value: '$completedCourses',
                        color: Colors.purple,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _AiHeroCard(onTap: widget.onOpenAiChat),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Continue Learning',
                action: 'See all',
                onAction: widget.onOpenCourses,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: enrollments.isEmpty
                ? SliverToBoxAdapter(child: _EmptyCourses(onBrowse: widget.onOpenCourses))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final e = enrollments[i] as Map<String, dynamic>;
                        if (i >= 3) return null;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DashboardCourseTile(
                            title: e['title']?.toString() ?? 'Course',
                            progress: _parseNum(e['progress_percent']),
                            thumbnailUrl: e['thumbnail_url']?.toString(),
                            onTap: () => Navigator.pushNamed(context, '/course', arguments: e['course_id']),
                          ),
                        );
                      },
                      childCount: math.min(enrollments.length, 3),
                    ),
                  ),
          ),
          if (_upcomingAssignments().isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Upcoming',
                  action: 'Assignments',
                  onAction: () => Navigator.pushNamed(context, '/assignments'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final a = _upcomingAssignments()[i] as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AssignmentRow(
                        title: a['title']?.toString() ?? 'Assignment',
                        dueDate: a['due_date']?.toString(),
                        onTap: () => Navigator.pushNamed(context, '/assignments'),
                      ),
                    );
                  },
                  childCount: _upcomingAssignments().length,
                ),
              ),
            ),
          ],
          if (quizResults.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: const SliverToBoxAdapter(child: _SectionHeader(title: 'Recent Activity')),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final r = quizResults[i] as Map<String, dynamic>;
                    if (i >= 4) return null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DashboardActivityTile(
                        title: r['quiz_title']?.toString() ?? 'Quiz',
                        score: _parseNum(r['score']),
                        submittedAt: r['submitted_at']?.toString(),
                      ),
                    );
                  },
                  childCount: math.min(quizResults.length, 4),
                ),
              ),
            ),
          ],
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: const SliverToBoxAdapter(child: _SectionHeader(title: 'Quick Actions')),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            sliver: SliverToBoxAdapter(
              child: _QuickActionsGrid(
                onCourses: widget.onOpenCourses,
                onAiChat: widget.onOpenAiChat,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _DashboardHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final String? grade;
  final int unread;
  final int totalXp;
  final bool isDark;
  final VoidCallback onNotifications;

  const _DashboardHeader({
    required this.greeting,
    required this.name,
    this.grade,
    required this.unread,
    required this.totalXp,
    required this.isDark,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${_weekday(now.weekday)}, ${_month(now.month)} ${now.day}';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
              : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Builder(
                  builder: (ctx) => IconButton(
                    onPressed: () {
                      final scaffold = Scaffold.maybeOf(ctx);
                      if (scaffold?.hasDrawer ?? false) scaffold!.openDrawer();
                    },
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    tooltip: 'Menu',
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15)),
                  ),
                ),
                const SizedBox(width: 4),
                Text(dateStr, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                const Spacer(),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: onNotifications,
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15)),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        '$name 👋',
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      ),
                      if (grade != null && grade!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(grade!, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 14, color: AppColors.accent.withValues(alpha: 0.95)),
                        const SizedBox(width: 2),
                        Text('$totalXp XP', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _weekday(int d) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];
  String _month(int m) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
}

class _AiHeroCard extends StatefulWidget {
  final VoidCallback onTap;
  const _AiHeroCard({required this.onTap});

  @override
  State<_AiHeroCard> createState() => _AiHeroCardState();
}

class _AiHeroCardState extends State<_AiHeroCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return GlassCard(
          onTap: widget.onTap,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xFF2563EB), const Color(0xFF7C3AED), _pulse.value * 0.3)!,
              const Color(0xFF1D4ED8),
            ],
          ),
          child: child!,
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ask your AI Teacher', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Instant help with lessons, quizzes & homework', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        if (action != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _EmptyCourses extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyCourses({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('Start your learning journey', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Enroll in a course to track progress here', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onBrowse, icon: const Icon(Icons.explore_rounded, size: 18), label: const Text('Browse Courses')),
        ],
      ),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  final String title;
  final String? dueDate;
  final VoidCallback onTap;

  const _AssignmentRow({required this.title, this.dueDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final due = DateTime.tryParse(dueDate ?? '');
    final dueLabel = due != null ? 'Due ${_fmtDue(due)}' : 'No due date';

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment_rounded, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(dueLabel, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : AppColors.textSecondary),
        ],
      ),
    );
  }

  String _fmtDue(DateTime d) {
    final now = DateTime.now();
    final diff = d.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    if (diff < 7) return 'in $diff days';
    return '${d.month}/${d.day}';
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onCourses;
  final VoidCallback onAiChat;

  const _QuickActionsGrid({required this.onCourses, required this.onAiChat});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(Icons.menu_book_rounded, 'Courses', AppColors.primary, onCourses),
      _Action(Icons.smart_toy_rounded, 'AI Chat', const Color(0xFF7C3AED), onAiChat),
      _Action(Icons.assignment_rounded, 'Assignments', AppColors.accent, () => Navigator.pushNamed(context, '/assignments')),
      _Action(Icons.workspace_premium_rounded, 'Certificates', Colors.purple, () => Navigator.pushNamed(context, '/certificates')),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: actions.map((a) => _QuickActionTile(action: a)).toList(),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.color, this.onTap);
}

class _QuickActionTile extends StatelessWidget {
  final _Action action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: action.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: action.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(action.icon, color: action.color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(action.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
