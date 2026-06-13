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

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _course;
  bool _loading = true;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
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
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text(subject, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 8),
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _HeroStat(icon: Icons.play_lesson_rounded, label: '${lessons.length} lessons'),
                            const SizedBox(width: 16),
                            _HeroStat(icon: Icons.quiz_rounded, label: '${quizzes.length} quizzes'),
                            const SizedBox(width: 16),
                            _HeroStat(icon: Icons.fact_check_rounded, label: '${exams.length} exams'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            if (_course?['description'] != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(_course!['description'].toString(), style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary, height: 1.5)),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: enrolled
                  ? _ProgressCard(progress: progress, onClaimCert: progress >= 100 ? _issueCertificate : null)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(onPressed: _enroll, icon: const Icon(Icons.add_rounded), label: const Text('Enroll in Course')),
                    ),
            ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Lessons (${lessons.length})'),
                Tab(text: 'Quizzes (${quizzes.length})'),
                Tab(text: 'Exams (${exams.length})'),
                Tab(text: 'Work (${assignments.length})'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ContentList(
                    empty: 'No lessons yet',
                    items: lessons,
                    enrolled: enrolled,
                    builder: (l, i) => _ContentTile(
                      icon: CircleAvatar(radius: 16, backgroundColor: AppColors.primary, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                      title: l['title']?.toString() ?? 'Lesson',
                      subtitle: '${l['duration_minutes'] ?? 15} min',
                      onTap: enrolled ? () => Navigator.pushNamed(context, '/lesson', arguments: l['id']) : null,
                    ),
                  ),
                  _ContentList(
                    empty: 'No quizzes yet',
                    items: quizzes,
                    enrolled: enrolled,
                    builder: (q, _) => _ContentTile(
                      icon: const Icon(Icons.quiz_rounded, color: AppColors.accent),
                      title: q['title']?.toString() ?? 'Quiz',
                      subtitle: '${q['time_limit_minutes'] ?? 30} min',
                      onTap: enrolled ? () => Navigator.pushNamed(context, '/quiz', arguments: q['id']) : null,
                    ),
                  ),
                  _ContentList(
                    empty: 'No exams yet',
                    items: exams,
                    enrolled: enrolled,
                    builder: (e, _) => _ContentTile(
                      icon: const Icon(Icons.fact_check_rounded, color: Color(0xFF10B981)),
                      title: e['title']?.toString() ?? 'Exam',
                      subtitle: '${e['time_limit_minutes'] ?? 60} min · Proctored',
                      onTap: enrolled ? () => Navigator.pushNamed(context, '/exam', arguments: e['id']) : null,
                    ),
                  ),
                  _ContentList(
                    empty: 'No assignments yet',
                    items: assignments,
                    enrolled: enrolled,
                    builder: (a, _) => _ContentTile(
                      icon: const Icon(Icons.assignment_rounded, color: AppColors.primary),
                      title: a['title']?.toString() ?? 'Assignment',
                      subtitle: a['due_date'] != null ? 'Due: ${a['due_date']}' : 'No due date',
                      onTap: enrolled ? () => Navigator.pushNamed(context, '/assignments') : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeroStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
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
      child: Column(
        children: [
          Row(
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
                    Text('Keep going to complete this course', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          if (onClaimCert != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onClaimCert,
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Claim Certificate'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContentList extends StatelessWidget {
  final String empty;
  final List<dynamic> items;
  final bool enrolled;
  final Widget Function(Map<String, dynamic> item, int index) builder;

  const _ContentList({required this.empty, required this.items, required this.enrolled, required this.builder});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(empty, style: const TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + (enrolled ? 0 : 1),
      itemBuilder: (_, i) {
        if (!enrolled && i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: Colors.orange, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('Enroll to unlock all content', style: TextStyle(fontSize: 13))),
                ],
              ),
            ),
          );
        }
        final idx = enrolled ? i : i - 1;
        final item = items[idx] as Map<String, dynamic>;
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: builder(item, idx));
      },
    );
  }
}

class _ContentTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ContentTile({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    );
  }
}
