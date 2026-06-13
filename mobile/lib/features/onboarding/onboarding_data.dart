import 'package:flutter/material.dart';
import '../../../core/services/public_api.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingPageModel {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String statLabel;
  final int Function(PlatformStats stats) statValue;

  const OnboardingPageModel({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.statLabel,
    required this.statValue,
  });
}

const onboardingPages = [
  OnboardingPageModel(
    icon: Icons.psychology_alt_rounded,
    color: AppColors.primary,
    title: 'Learn with AI',
    subtitle: 'Your personal AI teacher explains any subject step-by-step with real examples and instant feedback.',
    statLabel: 'AI sessions today',
    statValue: _aiSessions,
  ),
  OnboardingPageModel(
    icon: Icons.auto_awesome_rounded,
    color: AppColors.accent,
    title: 'Personalized Education',
    subtitle: 'Adaptive learning paths tailored to your pace, level, and goals — powered by real course data.',
    statLabel: 'Courses available',
    statValue: _courses,
  ),
  OnboardingPageModel(
    icon: Icons.groups_rounded,
    color: Color(0xFF10B981),
    title: '24/7 AI Teacher',
    subtitle: 'Join learners worldwide. Ask questions anytime and get quizzes, exams, and certificates.',
    statLabel: 'Active learners',
    statValue: _activeUsers,
  ),
];

int _aiSessions(PlatformStats s) => s.aiSessionsToday;
int _courses(PlatformStats s) => s.totalCourses;
int _activeUsers(PlatformStats s) => s.activeUsers;
