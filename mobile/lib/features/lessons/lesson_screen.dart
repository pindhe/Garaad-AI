import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

class LessonScreen extends StatefulWidget {
  final int lessonId;
  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  Map<String, dynamic>? _lesson;
  bool _loading = true;
  bool _completing = false;
  String? _error;
  final _scrollController = ScrollController();
  double _readProgress = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    final p = (_scrollController.offset / max).clamp(0.0, 1.0);
    if ((p - _readProgress).abs() > 0.02) setState(() => _readProgress = p);
  }

  Future<void> _load() async {
    if (widget.lessonId <= 0) {
      setState(() {
        _loading = false;
        _error = 'No lesson selected. Open a lesson from a course.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _lesson = await context.read<AuthProvider>().api.getLesson(widget.lessonId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent <= 0) {
        setState(() => _readProgress = 1);
      }
    });
  }

  bool get _completed {
    return _lesson?['completed'] == true || _lesson?['completed'] == 1;
  }

  bool get _hasNext {
    final next = _lesson?['next_lesson'];
    if (next is Map && next['id'] != null) return true;
    return false;
  }

  bool get _canComplete => _completed || _readProgress >= 0.85;

  Future<void> _goNext() async {
    if (!_completed) return;
    final next = _lesson?['next_lesson'];
    if (next is Map && next['id'] != null) {
      await Navigator.pushReplacementNamed(context, '/lesson', arguments: next['id']);
    } else {
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _complete() async {
    if (_completed || _completing) return;
    setState(() => _completing = true);
    try {
      await context.read<AuthProvider>().api.completeLesson(widget.lessonId);
      if (mounted) {
        setState(() {
          _lesson = {...?_lesson, 'completed': true};
          _completing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_hasNext ? 'Step complete! Tap Next to continue.' : 'Last lesson complete! Tap Finish.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _completing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  List<dynamic> _listField(String key) {
    final v = _lesson?[key];
    if (v is List) return v;
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_error != null || _lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lesson')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(_error ?? 'Lesson not found', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Go back')),
              ],
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _lesson!['title']?.toString() ?? 'Lesson';
    final course = _lesson!['course'] as Map<String, dynamic>?;
    final duration = _lesson!['duration_minutes'] ?? 15;
    final examples = _listField('examples');
    final slides = _listField('slides');
    final hue = (title.hashCode.abs() % 360).toDouble();

    return Scaffold(
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _readProgress,
            minHeight: 3,
            backgroundColor: Colors.transparent,
            color: AppColors.primary,
          ),
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  actions: [
                    if (_completed)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Done', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            HSLColor.fromAHSL(1, hue, 0.5, 0.5).toColor(),
                            HSLColor.fromAHSL(1, (hue + 35) % 360, 0.55, 0.38).toColor(),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (course?['subject'] != null)
                                Text(course!['subject'].toString(), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                              if (course?['title'] != null) ...[
                                const SizedBox(height: 4),
                                Text(course!['title'].toString(), style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                              ],
                              const SizedBox(height: 8),
                              Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                                  const SizedBox(width: 4),
                                  Text('$duration min read', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                                  const SizedBox(width: 16),
                                  Icon(Icons.auto_stories_rounded, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                                  const SizedBox(width: 4),
                                  Text('${(_readProgress * 100).toStringAsFixed(0)}% read', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SectionLabel(icon: Icons.article_rounded, label: 'Lesson content'),
                      const SizedBox(height: 12),
                      Text(
                        _lesson!['content']?.toString() ?? 'No content available for this lesson.',
                        style: TextStyle(fontSize: 16, height: 1.75, color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.textPrimary),
                      ),
                      if (examples.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _SectionLabel(icon: Icons.lightbulb_outline_rounded, label: 'Examples', color: AppColors.accent),
                        const SizedBox(height: 12),
                        ...examples.asMap().entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                                    child: Text('${e.key + 1}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text('${e.value}', style: const TextStyle(height: 1.5, fontSize: 14))),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                      if (slides.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _SectionLabel(icon: Icons.slideshow_rounded, label: 'Key points'),
                        const SizedBox(height: 12),
                        ...slides.map((s) {
                          final text = s is Map ? (s['title'] ?? s['content'] ?? s).toString() : s.toString();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4))),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                      if (_lesson!['notes'] != null && _lesson!['notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _SectionLabel(icon: Icons.tips_and_updates_rounded, label: 'Teacher notes', color: AppColors.accent),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: isDark ? 0.12 : 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
                          ),
                          child: Text(_lesson!['notes'].toString(), style: TextStyle(height: 1.6, fontSize: 14, color: isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.textPrimary)),
                        ),
                      ],
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/chat'),
                        icon: const Icon(Icons.smart_toy_outlined),
                        label: const Text('Ask AI about this lesson'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          _BottomBar(
            completed: _completed,
            completing: _completing,
            readProgress: _readProgress,
            canComplete: _canComplete,
            hasNext: _hasNext,
            nextTitle: _lesson?['next_lesson'] is Map ? (_lesson!['next_lesson']['title']?.toString()) : null,
            onComplete: _complete,
            onNext: _goNext,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _SectionLabel({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Row(
      children: [
        Icon(icon, size: 20, color: c),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c)),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool completed;
  final bool completing;
  final double readProgress;
  final bool canComplete;
  final bool hasNext;
  final String? nextTitle;
  final VoidCallback onComplete;
  final VoidCallback onNext;

  const _BottomBar({
    required this.completed,
    required this.completing,
    required this.readProgress,
    required this.canComplete,
    required this.hasNext,
    this.nextTitle,
    required this.onComplete,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  completed ? 'Step complete!' : (canComplete ? 'Ready to complete' : 'Read to the end'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  completed
                      ? (hasNext ? 'Next: ${nextTitle ?? 'lesson'}' : 'All lessons done')
                      : '${(readProgress * 100).toStringAsFixed(0)}% read${canComplete ? '' : ' · scroll to end'}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (completed)
            FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(hasNext ? 'Next' : 'Finish'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            )
          else
            FilledButton.icon(
              onPressed: (completing || !canComplete) ? null : onComplete,
              icon: completing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded, size: 20),
              label: const Text('Complete'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }
}
