import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  const ResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final score = result['score'] ?? 0;
    final feedback = result['feedback'] ?? 'Great effort!';
    final passed = score >= 60;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                passed ? Icons.emoji_events : Icons.refresh,
                size: 80,
                color: passed ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                passed ? 'Well Done!' : 'Keep Learning!',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                '${score.toString()}%',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: passed ? AppColors.primary : Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('AI Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(feedback, textAlign: TextAlign.center, style: const TextStyle(height: 1.5)),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
