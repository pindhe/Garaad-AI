enum CourseStepType { lesson, quiz, assignment, exam }

class CourseStep {
  final int stepNumber;
  final CourseStepType type;
  final int? id;
  final String title;
  final String subtitle;
  final bool completed;
  final bool locked;
  final bool isCurrent;

  const CourseStep({
    required this.stepNumber,
    required this.type,
    this.id,
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.locked,
    required this.isCurrent,
  });
}

List<CourseStep> buildCourseSteps({
  required List<dynamic> lessons,
  required List<dynamic> quizzes,
  required List<dynamic> assignments,
  required List<dynamic> exams,
  required bool enrolled,
}) {
  if (!enrolled) return [];

  final steps = <CourseStep>[];
  var stepNum = 1;
  var foundCurrent = false;

  bool lessonDone(dynamic l) => l['completed'] == true || l['completed'] == 1;

  for (var i = 0; i < lessons.length; i++) {
    final l = lessons[i] as Map<String, dynamic>;
    final completed = lessonDone(l);
    final prevDone = i == 0 || lessonDone(lessons[i - 1]);
    final locked = !prevDone;
    final isCurrent = !foundCurrent && !completed && !locked;
    if (isCurrent) foundCurrent = true;

    steps.add(CourseStep(
      stepNumber: stepNum++,
      type: CourseStepType.lesson,
      id: l['id'] as int?,
      title: l['title']?.toString() ?? 'Lesson',
      subtitle: '${l['duration_minutes'] ?? 15} min lesson',
      completed: completed,
      locked: locked,
      isCurrent: isCurrent,
    ));
  }

  final allLessonsDone = lessons.isEmpty || lessons.every(lessonDone);

  if (allLessonsDone) {
    var extraCurrent = !foundCurrent;

    if (quizzes.isNotEmpty) {
      final q = quizzes.first as Map<String, dynamic>;
      steps.add(CourseStep(
        stepNumber: stepNum++,
        type: CourseStepType.quiz,
        id: q['id'] as int?,
        title: q['title']?.toString() ?? 'Quiz',
        subtitle: '${q['time_limit_minutes'] ?? 15} min quiz',
        completed: false,
        locked: false,
        isCurrent: extraCurrent,
      ));
      if (extraCurrent) {
        foundCurrent = true;
        extraCurrent = false;
      }
    }

    if (assignments.isNotEmpty) {
      final a = assignments.first as Map<String, dynamic>;
      steps.add(CourseStep(
        stepNumber: stepNum++,
        type: CourseStepType.assignment,
        id: a['id'] as int?,
        title: a['title']?.toString() ?? 'Assignment',
        subtitle: 'Submit your work',
        completed: false,
        locked: false,
        isCurrent: extraCurrent,
      ));
      if (extraCurrent) {
        foundCurrent = true;
        extraCurrent = false;
      }
    }

    if (exams.isNotEmpty) {
      final e = exams.first as Map<String, dynamic>;
      steps.add(CourseStep(
        stepNumber: stepNum++,
        type: CourseStepType.exam,
        id: e['id'] as int?,
        title: e['title']?.toString() ?? 'Exam',
        subtitle: '${e['time_limit_minutes'] ?? 60} min exam',
        completed: false,
        locked: false,
        isCurrent: extraCurrent,
      ));
    }
  }

  return steps;
}

CourseStep? currentCourseStep(List<CourseStep> steps) {
  for (final s in steps) {
    if (s.isCurrent) return s;
  }
  if (steps.isNotEmpty && steps.every((s) => s.completed || s.type != CourseStepType.lesson)) {
    return null;
  }
  return steps.isNotEmpty ? steps.firstWhere((s) => !s.completed && !s.locked, orElse: () => steps.last) : null;
}
