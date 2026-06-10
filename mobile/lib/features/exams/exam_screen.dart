import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class ExamScreen extends StatefulWidget {
  final int examId;
  const ExamScreen({super.key, required this.examId});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              const Text('Exam Mode', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Exam #${widget.examId}', style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),
              const Text('Full-screen exam with auto-submit\nConnect to backend to load exam questions',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Exit Exam Mode'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
