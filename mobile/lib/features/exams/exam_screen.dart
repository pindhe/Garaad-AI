import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class ExamScreen extends StatefulWidget {
  final int examId;
  const ExamScreen({super.key, required this.examId});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  Map<String, dynamic>? _exam;
  bool _loading = true;
  int _current = 0;
  final _answers = <dynamic>[];
  Timer? _timer;
  int _secondsLeft = 0;
  int _startTime = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _load();
  }

  Future<void> _load() async {
    try {
      _exam = await context.read<AuthProvider>().api.getExam(widget.examId);
      _secondsLeft = ((_exam?['time_limit_minutes'] ?? 60) as num).toInt() * 60;
      _startTime = DateTime.now().millisecondsSinceEpoch;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          _submit();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _submit() async {
    _timer?.cancel();
    final timeTaken = ((DateTime.now().millisecondsSinceEpoch - _startTime) / 1000).round();
    try {
      final result = await context.read<AuthProvider>().api.submitExam(widget.examId, _answers, timeTaken);
      if (mounted) Navigator.pushReplacementNamed(context, '/results', arguments: result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave exam?'),
        content: const Text('Your progress will be lost if you exit now.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Exit')),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.dark,
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final questions = (_exam?['questions'] as List?) ?? [];
    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.dark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No exam questions', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go back')),
            ],
          ),
        ),
      );
    }

    final q = questions[_current];
    final type = q['type'] ?? 'mcq';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.dark,
        appBar: AppBar(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: Colors.white,
          title: Text(_exam?['title']?.toString() ?? 'Exam'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _confirmExit),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: _secondsLeft < 120 ? Colors.redAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (_current + 1) / questions.length,
                backgroundColor: Colors.white12,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text('Question ${_current + 1} of ${questions.length}', style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),
              Text(
                q['question']?.toString() ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: type == 'true_false'
                    ? Column(
                        children: [
                          _Option(label: 'True', selected: _answers.length > _current && _answers[_current] == true, onTap: () => _setAnswer(true)),
                          _Option(label: 'False', selected: _answers.length > _current && _answers[_current] == false, onTap: () => _setAnswer(false)),
                        ],
                      )
                    : ListView.builder(
                        itemCount: (q['options'] as List?)?.length ?? 0,
                        itemBuilder: (_, i) {
                          final options = q['options'] as List;
                          return _Option(
                            label: options[i].toString(),
                            selected: _answers.length > _current && _answers[_current] == i,
                            onTap: () => _setAnswer(i),
                          );
                        },
                      ),
              ),
              Row(
                children: [
                  if (_current > 0)
                    Expanded(child: OutlinedButton(onPressed: () => setState(() => _current--), child: const Text('Previous'))),
                  if (_current > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_current < questions.length - 1) {
                          setState(() => _current++);
                        } else {
                          _submit();
                        }
                      },
                      child: Text(_current < questions.length - 1 ? 'Next' : 'Submit Exam'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setAnswer(dynamic value) {
    setState(() {
      while (_answers.length <= _current) {
        _answers.add(null);
      }
      _answers[_current] = value;
    });
  }
}

class _Option extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Option({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : Colors.white24, width: selected ? 2 : 1),
          ),
          child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        ),
      ),
    );
  }
}
