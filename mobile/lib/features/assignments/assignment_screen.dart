import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
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

  Future<void> _submitAssignment(Map<String, dynamic> assignment) async {
    final contentController = TextEditingController();
    List<int>? fileBytes;
    String? fileName;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Submit: ${assignment['title']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                    icon: const Icon(Icons.attach_file),
                    label: Text(fileName ?? 'Attach file (PDF, image)'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Submit for AI Grading'),
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
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Graded!'),
            content: Text('Score: ${result['score'] ?? '—'}\n\n${result['feedback'] ?? ''}'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : _assignments.isEmpty
                  ? const Center(child: Text('No assignments yet'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _assignments.length,
                        itemBuilder: (_, i) {
                          final a = _assignments[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                  const SizedBox(height: 6),
                                  Text(a['description']?.toString() ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                                  if (a['due_date'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text('Due: ${a['due_date']}', style: const TextStyle(fontSize: 12, color: AppColors.accent)),
                                  ],
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _submitAssignment(a),
                                      icon: const Icon(Icons.upload_file, size: 18),
                                      label: const Text('Submit Assignment'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
