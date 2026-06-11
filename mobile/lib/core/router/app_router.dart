import 'package:flutter/material.dart';
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
import '../../shared/widgets/loading_screen.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final name = settings.name ?? '/';

    switch (name) {
      case '/loading':
        return _fade(const LoadingScreen(), settings);
      case '/':
        return _fade(const SplashScreen(), settings);
      case '/onboarding':
        return _fade(const OnboardingScreen(), settings);
      case '/login':
        return _slide(const LoginScreen(), settings);
      case '/register':
        return _slide(const RegisterScreen(), settings);
      case '/home':
        return _fade(const HomeScreen(), settings);
      case '/chat':
        return _slide(const AiChatScreen(), settings);
      case '/courses':
        return _slide(const CoursesScreen(), settings);
      case '/course':
        final id = settings.arguments as int? ?? 0;
        return _slide(CourseDetailScreen(courseId: id), settings);
      case '/lesson':
        final id = settings.arguments as int? ?? 0;
        return _slide(LessonScreen(lessonId: id), settings);
      case '/quiz':
        final id = settings.arguments as int? ?? 0;
        return _slide(QuizScreen(quizId: id), settings);
      case '/assignments':
        return _slide(const AssignmentScreen(), settings);
      case '/exam':
        final id = settings.arguments as int? ?? 0;
        return _slide(ExamScreen(examId: id), settings);
      case '/results':
        final result = settings.arguments as Map<String, dynamic>? ?? {};
        return _slide(ResultsScreen(result: result), settings);
      case '/certificates':
        return _slide(const CertificatesScreen(), settings);
      default:
        return _fade(const SplashScreen(), settings);
    }
  }

  static PageRouteBuilder<T> _fade<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder<T> _slide<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
