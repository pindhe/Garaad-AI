import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  final int quizId;
  const QuizScreen({super.key, required this.quizId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Map<String, dynamic>? _quiz;
  bool _loading = true;
  int _current = 0;
  final _answers = <dynamic>[];
  Timer? _timer;
  int _secondsLeft = 0;
  int _startTime = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _quiz = await context.read<AuthProvider>().api.getQuiz(widget.quizId);
      _secondsLeft = (_quiz?['time_limit_minutes'] ?? 30) * 60;
      _startTime = DateTime.now().millisecondsSinceEpoch;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          _submit();
        }
      });
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    _timer?.cancel();
    final timeTaken = ((DateTime.now().millisecondsSinceEpoch - _startTime) / 1000).round();
    try {
      final result = await context.read<AuthProvider>().api.submitQuiz(widget.quizId, _answers, timeTaken);
      if (mounted) Navigator.pushReplacementNamed(context, '/results', arguments: result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final questions = (_quiz?['questions'] as List?) ?? [];
    if (questions.isEmpty) return const Scaffold(body: Center(child: Text('No questions')));

    final q = questions[_current];
    final type = q['type'] ?? 'mcq';

    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz?['title'] ?? 'Quiz'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                style: TextStyle(color: _secondsLeft < 60 ? Colors.red : null, fontWeight: FontWeight.bold),
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
            LinearProgressIndicator(value: (_current + 1) / questions.length, color: AppColors.primary),
            const SizedBox(height: 8),
            Text('Question ${_current + 1} of ${questions.length}', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Text(q['question'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Expanded(
              child: type == 'true_false'
                  ? Column(
                      children: [
                        _OptionButton(label: 'True', selected: _answers.length > _current && _answers[_current] == true, onTap: () => setState(() { while (_answers.length <= _current) _answers.add(null); _answers[_current] = true; })),
                        _OptionButton(label: 'False', selected: _answers.length > _current && _answers[_current] == false, onTap: () => setState(() { while (_answers.length <= _current) _answers.add(null); _answers[_current] = false; })),
                      ],
                    )
                  : ListView.builder(
                      itemCount: (q['options'] as List?)?.length ?? 0,
                      itemBuilder: (_, i) {
                        final options = q['options'] as List;
                        return _OptionButton(
                          label: options[i].toString(),
                          selected: _answers.length > _current && _answers[_current] == i,
                          onTap: () => setState(() { while (_answers.length <= _current) _answers.add(null); _answers[_current] = i; }),
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
                    child: Text(_current < questions.length - 1 ? 'Next' : 'Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300, width: selected ? 2 : 1),
          ),
          child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? AppColors.primary : null)),
        ),
      ),
    );
  }
}
