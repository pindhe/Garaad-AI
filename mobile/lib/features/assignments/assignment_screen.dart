import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/glass_card.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  List<dynamic> _assignments = [];
  bool _loading = true;
  String? _error;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _assignments = await context.read<AuthProvider>().api.getAssignments();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  List<dynamic> get _filtered {
    if (_filter == 'All') return _assignments;
    if (_filter == 'Pending') {
      return _assignments.where((a) => a['submission_id'] == null).toList();
    }
    return _assignments.where((a) => a['submission_status'] == 'graded').toList();
  }

  Future<void> _submitAssignment(Map<String, dynamic> assignment) async {
    final contentController = TextEditingController();
    List<int>? fileBytes;
    String? fileName;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Text('Submit assignment', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  Text(assignment['title']?.toString() ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Your answer',
                      hintText: 'Write your submission here...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(withData: true);
                      if (result != null && result.files.single.bytes != null) {
                        setModalState(() {
                          fileBytes = result.files.single.bytes;
                          fileName = result.files.single.name;
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file_rounded),
                    label: Text(fileName ?? 'Attach file (PDF, image)'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Submit for AI Grading'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (submitted != true || !mounted) return;

    try {
      final result = await context.read<AuthProvider>().api.submitAssignment(
            assignment['id'],
            content: contentController.text.trim(),
            fileBytes: fileBytes,
            fileName: fileName,
          );
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)), SizedBox(width: 8), Text('Graded!')]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score: ${result['score'] ?? '—'}/100', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primary)),
                if (result['demoMode'] == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Demo grading — set OPENAI_API_KEY in backend/.env for AI feedback', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                  ),
                ],
                const SizedBox(height: 12),
                Text(result['feedback']?.toString() ?? ''),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _showSubmission(Map<String, dynamic> a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submission result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${a['submission_score'] ?? '—'}/100', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primary)),
            const SizedBox(height: 12),
            Text(a['submission_feedback']?.toString() ?? 'No feedback yet'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _assignments.where((a) => a['submission_id'] == null).length;
    final graded = _assignments.where((a) => a['submission_status'] == 'graded').length;

    return AppPageScaffold(
      title: 'Assignments',
      subtitle: 'Submit work and get AI-powered feedback',
      headerColor: AppColors.accent,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(icon: Icons.cloud_off_outlined, title: 'Could not load', subtitle: _error!, action: FilledButton(onPressed: _load, child: const Text('Retry')))
              : Column(
                  children: [
                    PageSummaryRow(chips: [
                      PageSummaryChip(icon: Icons.assignment_rounded, label: '${_assignments.length} total', color: AppColors.accent),
                      PageSummaryChip(icon: Icons.pending_actions_rounded, label: '$pending pending', color: AppColors.primary),
                      PageSummaryChip(icon: Icons.grade_rounded, label: '$graded graded', color: const Color(0xFF10B981)),
                    ]),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: ['All', 'Pending', 'Graded'].map((f) {
                          final selected = _filter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(f),
                              selected: selected,
                              onSelected: (_) => setState(() => _filter = f),
                              selectedColor: AppColors.accent.withValues(alpha: 0.15),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const EmptyState(
                              icon: Icons.assignment_outlined,
                              title: 'No assignments',
                              subtitle: 'Assignments from your courses will appear here',
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) {
                                  final a = _filtered[i] as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _AssignmentCard(
                                      assignment: a,
                                      onSubmit: () => _submitAssignment(a),
                                      onViewResult: () => _showSubmission(a),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> assignment;
  final VoidCallback onSubmit;
  final VoidCallback onViewResult;

  const _AssignmentCard({required this.assignment, required this.onSubmit, required this.onViewResult});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final graded = assignment['submission_status'] == 'graded';
    final pending = assignment['submission_id'] == null;
    final due = DateTime.tryParse(assignment['due_date']?.toString() ?? '');

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment_rounded, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assignment['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    if (assignment['course_title'] != null)
                      Text(assignment['course_title'].toString(), style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                  ],
                ),
              ),
              _StatusBadge(graded: graded, pending: pending),
            ],
          ),
          if (assignment['description'] != null) ...[
            const SizedBox(height: 10),
            Text(assignment['description'].toString(), style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (due != null) ...[
                Icon(Icons.schedule_rounded, size: 14, color: isDark ? Colors.white54 : AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(_dueLabel(due), style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary)),
              ],
              const Spacer(),
              Text('Max ${assignment['max_score'] ?? 100} pts', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: graded
                ? OutlinedButton.icon(onPressed: onViewResult, icon: const Icon(Icons.visibility_rounded, size: 18), label: Text('View score: ${assignment['submission_score'] ?? '—'}'))
                : FilledButton.icon(onPressed: onSubmit, icon: const Icon(Icons.upload_file_rounded, size: 18), label: Text(pending ? 'Submit Assignment' : 'Resubmit')),
          ),
        ],
      ),
    );
  }

  String _dueLabel(DateTime due) {
    final diff = due.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in $diff days';
  }
}

class _StatusBadge extends StatelessWidget {
  final bool graded;
  final bool pending;

  const _StatusBadge({required this.graded, required this.pending});

  @override
  Widget build(BuildContext context) {
    final color = graded ? const Color(0xFF10B981) : (pending ? AppColors.accent : AppColors.primary);
    final label = graded ? 'Graded' : (pending ? 'Pending' : 'Submitted');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
