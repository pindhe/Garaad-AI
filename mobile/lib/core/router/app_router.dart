import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/chat/ai_chat_screen.dart';
import '../../features/courses/courses_screen.dart';
import '../../features/courses/course_detail_screen.dart';
import '../../features/lessons/lesson_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/assignments/assignment_screen.dart';
import '../../features/exams/exam_screen.dart';
import '../../features/results/results_screen.dart';
import '../../features/certificates/certificates_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _fade(const SplashScreen());
      case '/onboarding':
        return _fade(const OnboardingScreen());
      case '/login':
        return _slide(const LoginScreen());
      case '/register':
        return _slide(const RegisterScreen());
      case '/home':
        return _fade(const HomeScreen());
      case '/chat':
        return _slide(const AiChatScreen());
      case '/courses':
        return _slide(const CoursesScreen());
      case '/course':
        final id = settings.arguments as int;
        return _slide(CourseDetailScreen(courseId: id));
      case '/lesson':
        final id = settings.arguments as int;
        return _slide(LessonScreen(lessonId: id));
      case '/quiz':
        final id = settings.arguments as int;
        return _slide(QuizScreen(quizId: id));
      case '/assignments':
        return _slide(const AssignmentScreen());
      case '/exam':
        final id = settings.arguments as int;
        return _slide(ExamScreen(examId: id));
      case '/results':
        final result = settings.arguments as Map<String, dynamic>;
        return _slide(ResultsScreen(result: result));
      case '/certificates':
        return _slide(const CertificatesScreen());
      default:
        return _fade(const SplashScreen());
    }
  }

  static PageRouteBuilder _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
