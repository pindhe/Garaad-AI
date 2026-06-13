'use client';

import { useCallback, useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  BookOpen,
  Bot,
  Calendar,
  ChevronDown,
  ChevronRight,
  ClipboardList,
  Clock,
  FileText,
  GraduationCap,
  Loader2,
  Pencil,
  Plus,
  Sparkles,
  Trash2,
  Users,
} from 'lucide-react';
import Header from '@/components/Header';
import { api } from '@/lib/api';

type TabId = 'lessons' | 'assignments' | 'assessments' | 'settings';

interface LessonSummary {
  id: number;
  title: string;
  order_index: number;
  duration_minutes: number;
}

interface LessonDetail extends LessonSummary {
  content: string;
  notes?: string;
}

interface QuizSummary {
  id: number;
  title: string;
  time_limit_minutes?: number;
  passing_score?: number;
}

interface ExamSummary {
  id: number;
  title: string;
  time_limit_minutes?: number;
  passing_score?: number;
  is_published?: boolean;
}

interface AssignmentSummary {
  id: number;
  title: string;
  description?: string;
  due_date?: string;
  max_score?: number;
}

interface CourseDetail {
  id: number;
  title: string;
  description: string;
  subject: string;
  is_published: boolean;
  ai_generated: boolean;
  created_at?: string;
  updated_at?: string;
  enrollmentCount?: number;
  lessons: LessonSummary[];
  quizzes: QuizSummary[];
  exams: ExamSummary[];
  assignments: AssignmentSummary[];
}

const tabs: { id: TabId; label: string; icon: typeof BookOpen }[] = [
  { id: 'lessons', label: 'Lessons', icon: BookOpen },
  { id: 'assignments', label: 'Assignments', icon: ClipboardList },
  { id: 'assessments', label: 'Quizzes & Exams', icon: GraduationCap },
  { id: 'settings', label: 'Settings', icon: Pencil },
];

const inputClass =
  'w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20';

export default function CourseManagePage() {
  const params = useParams();
  const router = useRouter();
  const courseId = params.id as string;

  const [course, setCourse] = useState<CourseDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [activeTab, setActiveTab] = useState<TabId>('lessons');
  const [busy, setBusy] = useState('');

  const [expandedLessonId, setExpandedLessonId] = useState<number | null>(null);
  const [lessonDetails, setLessonDetails] = useState<Record<number, LessonDetail>>({});

  const [showLessonForm, setShowLessonForm] = useState(false);
  const [lessonForm, setLessonForm] = useState({
    title: '',
    content: '',
    notes: '',
    durationMinutes: 15,
  });

  const [showAssignmentForm, setShowAssignmentForm] = useState(false);
  const [assignmentForm, setAssignmentForm] = useState({
    title: '',
    description: '',
    dueDate: '',
    maxScore: 100,
  });

  const [quizTopic, setQuizTopic] = useState('');
  const [quizDifficulty, setQuizDifficulty] = useState('medium');

  const [editForm, setEditForm] = useState({
    title: '',
    description: '',
    subject: '',
  });

  const loadCourse = useCallback(async () => {
    setError('');
    try {
      const data = await api<CourseDetail>(`/courses/${courseId}`);
      setCourse(data);
      setEditForm({
        title: data.title,
        description: data.description || '',
        subject: data.subject || '',
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load course');
    } finally {
      setLoading(false);
    }
  }, [courseId]);

  useEffect(() => {
    setLoading(true);
    loadCourse();
  }, [loadCourse]);

  function flash(msg: string) {
    setError('');
    setMessage(msg);
    setTimeout(() => setMessage(''), 4000);
  }

  async function toggleLesson(lessonId: number) {
    if (expandedLessonId === lessonId) {
      setExpandedLessonId(null);
      return;
    }
    setExpandedLessonId(lessonId);
    if (!lessonDetails[lessonId]) {
      const detail = await api<LessonDetail>(`/lessons/${lessonId}`);
      setLessonDetails((prev) => ({ ...prev, [lessonId]: detail }));
    }
  }

  async function addLesson(e: React.FormEvent) {
    e.preventDefault();
    setBusy('lesson');
    try {
      await api('/lessons', {
        method: 'POST',
        body: JSON.stringify({
          courseId: Number(courseId),
          title: lessonForm.title,
          content: lessonForm.content,
          notes: lessonForm.notes || null,
          orderIndex: course?.lessons.length ?? 0,
          durationMinutes: lessonForm.durationMinutes,
        }),
      });
      setLessonForm({ title: '', content: '', notes: '', durationMinutes: 15 });
      setShowLessonForm(false);
      flash('Lesson added successfully');
      await loadCourse();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to add lesson');
    } finally {
      setBusy('');
    }
  }

  async function addAssignment(e: React.FormEvent) {
    e.preventDefault();
    setBusy('assignment');
    try {
      await api('/assignments', {
        method: 'POST',
        body: JSON.stringify({
          courseId: Number(courseId),
          title: assignmentForm.title,
          description: assignmentForm.description || null,
          dueDate: assignmentForm.dueDate || null,
          maxScore: assignmentForm.maxScore,
        }),
      });
      setAssignmentForm({ title: '', description: '', dueDate: '', maxScore: 100 });
      setShowAssignmentForm(false);
      flash('Assignment created');
      await loadCourse();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to add assignment');
    } finally {
      setBusy('');
    }
  }

  async function generateQuiz(e: React.FormEvent) {
    e.preventDefault();
    setBusy('quiz');
    try {
      await api('/ai/generate-quiz', {
        method: 'POST',
        body: JSON.stringify({
          topic: quizTopic,
          count: 5,
          difficulty: quizDifficulty,
          courseId: Number(courseId),
        }),
      });
      setQuizTopic('');
      flash('Quiz generated with AI');
      await loadCourse();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to generate quiz');
    } finally {
      setBusy('');
    }
  }

  async function togglePublish() {
    if (!course) return;
    setBusy('publish');
    try {
      await api(`/courses/${courseId}`, {
        method: 'PUT',
        body: JSON.stringify({ isPublished: !course.is_published }),
      });
      flash(course.is_published ? 'Course unpublished' : 'Course published');
      await loadCourse();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update course');
    } finally {
      setBusy('');
    }
  }

  async function saveCourseSettings(e: React.FormEvent) {
    e.preventDefault();
    setBusy('settings');
    try {
      await api(`/courses/${courseId}`, {
        method: 'PUT',
        body: JSON.stringify({
          title: editForm.title,
          description: editForm.description,
          subject: editForm.subject,
        }),
      });
      flash('Course settings saved');
      await loadCourse();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save settings');
    } finally {
      setBusy('');
    }
  }

  async function deleteCourse() {
    if (!course || !confirm(`Delete "${course.title}"? This cannot be undone.`)) return;
    setBusy('delete');
    try {
      await api(`/courses/${courseId}`, { method: 'DELETE' });
      router.push('/courses');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete course');
      setBusy('');
    }
  }

  if (loading) {
    return (
      <>
        <Header title="Course" subtitle="Loading course content..." />
        <div className="animate-pulse space-y-6">
          <div className="h-40 rounded-2xl bg-white" />
          <div className="grid grid-cols-2 gap-4 lg:grid-cols-5">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="h-24 rounded-2xl bg-white" />
            ))}
          </div>
          <div className="h-96 rounded-2xl bg-white" />
        </div>
      </>
    );
  }

  if (error && !course) {
    return (
      <>
        <Header title="Course not found" subtitle="This course may have been removed" />
        <div className="rounded-2xl border border-red-200 bg-red-50 px-6 py-8 text-center">
          <p className="text-red-700">{error}</p>
          <Link href="/courses" className="mt-4 inline-block text-sm font-medium text-blue-600 hover:underline">
            ← Back to courses
          </Link>
        </div>
      </>
    );
  }

  if (!course) return null;

  const stats = [
    { label: 'Lessons', value: course.lessons.length, icon: BookOpen, color: 'text-blue-600 bg-blue-50' },
    { label: 'Quizzes', value: course.quizzes.length, icon: Bot, color: 'text-purple-600 bg-purple-50' },
    { label: 'Exams', value: course.exams.length, icon: GraduationCap, color: 'text-amber-600 bg-amber-50' },
    { label: 'Assignments', value: course.assignments.length, icon: ClipboardList, color: 'text-emerald-600 bg-emerald-50' },
    { label: 'Enrolled', value: course.enrollmentCount ?? 0, icon: Users, color: 'text-indigo-600 bg-indigo-50' },
  ];

  return (
    <>
      <Header title={course.title} subtitle={course.subject || 'Course management'} />

      <nav className="mb-6 flex items-center gap-2 text-sm text-slate-500">
        <Link href="/courses" className="inline-flex items-center gap-1 hover:text-blue-600">
          <ArrowLeft className="h-4 w-4" />
          Courses
        </Link>
        <ChevronRight className="h-4 w-4" />
        <span className="truncate font-medium text-slate-900">{course.title}</span>
      </nav>

      {(message || error) && (
        <div
          className={`mb-6 rounded-xl px-4 py-3 text-sm ${
            error ? 'border border-red-200 bg-red-50 text-red-700' : 'border border-emerald-200 bg-emerald-50 text-emerald-700'
          }`}
        >
          {error || message}
        </div>
      )}

      <div className="mb-8 overflow-hidden rounded-2xl border border-slate-200/80 bg-white shadow-sm">
        <div className="bg-gradient-to-r from-blue-600 via-indigo-600 to-violet-600 px-6 py-8 text-white sm:px-8">
          <div className="flex flex-col gap-6 lg:flex-row lg:items-start lg:justify-between">
            <div className="min-w-0 flex-1">
              <div className="mb-3 flex flex-wrap items-center gap-2">
                <span
                  className={`rounded-full px-3 py-1 text-xs font-semibold ${
                    course.is_published ? 'bg-emerald-400/20 text-emerald-100' : 'bg-white/15 text-white'
                  }`}
                >
                  {course.is_published ? 'Published' : 'Draft'}
                </span>
                {course.ai_generated && (
                  <span className="inline-flex items-center gap-1 rounded-full bg-purple-400/20 px-3 py-1 text-xs font-semibold text-purple-100">
                    <Sparkles className="h-3 w-3" />
                    AI Generated
                  </span>
                )}
                {course.subject && (
                  <span className="rounded-full bg-white/15 px-3 py-1 text-xs font-medium">{course.subject}</span>
                )}
              </div>
              <h2 className="text-2xl font-bold sm:text-3xl">{course.title}</h2>
              <p className="mt-3 max-w-2xl text-sm leading-relaxed text-blue-100">
                {course.description || 'No description yet. Add one in Settings.'}
              </p>
            </div>
            <div className="flex shrink-0 flex-wrap gap-2">
              <button
                type="button"
                onClick={togglePublish}
                disabled={busy === 'publish'}
                className="rounded-xl bg-white px-4 py-2.5 text-sm font-semibold text-blue-700 shadow-sm hover:bg-blue-50 disabled:opacity-60"
              >
                {busy === 'publish' ? 'Saving...' : course.is_published ? 'Unpublish' : 'Publish'}
              </button>
              <button
                type="button"
                onClick={() => setActiveTab('settings')}
                className="rounded-xl border border-white/30 px-4 py-2.5 text-sm font-medium text-white hover:bg-white/10"
              >
                Edit details
              </button>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-2 divide-x divide-y divide-slate-100 border-t border-slate-100 sm:grid-cols-3 lg:grid-cols-5 lg:divide-y-0">
          {stats.map(({ label, value, icon: Icon, color }) => (
            <div key={label} className="flex items-center gap-3 px-5 py-4">
              <div className={`flex h-10 w-10 items-center justify-center rounded-xl ${color}`}>
                <Icon className="h-5 w-5" />
              </div>
              <div>
                <p className="text-2xl font-bold text-slate-900">{value}</p>
                <p className="text-xs text-slate-500">{label}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="mb-6 flex flex-wrap gap-2 border-b border-slate-200">
        {tabs.map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            type="button"
            onClick={() => setActiveTab(id)}
            className={`inline-flex items-center gap-2 border-b-2 px-4 py-3 text-sm font-medium transition-colors ${
              activeTab === id
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-slate-500 hover:text-slate-900'
            }`}
          >
            <Icon className="h-4 w-4" />
            {label}
          </button>
        ))}
      </div>

      {activeTab === 'lessons' && (
        <section className="space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-semibold text-slate-900">Course lessons</h3>
              <p className="text-sm text-slate-500">Ordered content students will follow</p>
            </div>
            <button
              type="button"
              onClick={() => setShowLessonForm(!showLessonForm)}
              className="inline-flex items-center gap-2 rounded-xl bg-blue-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-blue-700"
            >
              <Plus className="h-4 w-4" />
              Add lesson
            </button>
          </div>

          {showLessonForm && (
            <form onSubmit={addLesson} className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm">
              <h4 className="mb-4 font-semibold text-slate-900">New lesson</h4>
              <div className="grid gap-4 lg:grid-cols-2">
                <input
                  placeholder="Lesson title"
                  value={lessonForm.title}
                  onChange={(e) => setLessonForm({ ...lessonForm, title: e.target.value })}
                  className={inputClass}
                  required
                />
                <input
                  type="number"
                  min={1}
                  placeholder="Duration (minutes)"
                  value={lessonForm.durationMinutes}
                  onChange={(e) => setLessonForm({ ...lessonForm, durationMinutes: Number(e.target.value) })}
                  className={inputClass}
                />
              </div>
              <textarea
                placeholder="Lesson content"
                value={lessonForm.content}
                onChange={(e) => setLessonForm({ ...lessonForm, content: e.target.value })}
                className={`${inputClass} mt-4`}
                rows={5}
                required
              />
              <textarea
                placeholder="Teacher notes (optional)"
                value={lessonForm.notes}
                onChange={(e) => setLessonForm({ ...lessonForm, notes: e.target.value })}
                className={`${inputClass} mt-4`}
                rows={2}
              />
              <div className="mt-4 flex gap-3">
                <button
                  type="submit"
                  disabled={busy === 'lesson'}
                  className="rounded-xl bg-blue-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-60"
                >
                  {busy === 'lesson' ? 'Saving...' : 'Save lesson'}
                </button>
                <button
                  type="button"
                  onClick={() => setShowLessonForm(false)}
                  className="rounded-xl border border-slate-200 px-5 py-2.5 text-sm text-slate-600 hover:bg-slate-50"
                >
                  Cancel
                </button>
              </div>
            </form>
          )}

          <div className="space-y-3">
            {course.lessons.length === 0 ? (
              <div className="rounded-2xl border border-dashed border-slate-200 bg-white px-6 py-12 text-center">
                <BookOpen className="mx-auto mb-3 h-10 w-10 text-slate-300" />
                <p className="font-medium text-slate-600">No lessons yet</p>
                <p className="mt-1 text-sm text-slate-400">Add your first lesson to start building this course.</p>
              </div>
            ) : (
              course.lessons.map((lesson, index) => {
                const expanded = expandedLessonId === lesson.id;
                const detail = lessonDetails[lesson.id];
                return (
                  <div key={lesson.id} className="overflow-hidden rounded-2xl border border-slate-200/80 bg-white shadow-sm">
                    <button
                      type="button"
                      onClick={() => toggleLesson(lesson.id)}
                      className="flex w-full items-center gap-4 px-5 py-4 text-left hover:bg-slate-50"
                    >
                      <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-blue-100 text-sm font-bold text-blue-700">
                        {index + 1}
                      </span>
                      <div className="min-w-0 flex-1">
                        <p className="font-semibold text-slate-900">{lesson.title}</p>
                        <p className="mt-0.5 flex items-center gap-1 text-xs text-slate-500">
                          <Clock className="h-3.5 w-3.5" />
                          {lesson.duration_minutes} min
                        </p>
                      </div>
                      {expanded ? (
                        <ChevronDown className="h-5 w-5 shrink-0 text-slate-400" />
                      ) : (
                        <ChevronRight className="h-5 w-5 shrink-0 text-slate-400" />
                      )}
                    </button>
                    {expanded && (
                      <div className="border-t border-slate-100 bg-slate-50 px-5 py-4">
                        {!detail ? (
                          <div className="flex items-center gap-2 text-sm text-slate-500">
                            <Loader2 className="h-4 w-4 animate-spin" />
                            Loading lesson...
                          </div>
                        ) : (
                          <div className="space-y-3 text-sm">
                            <div className="whitespace-pre-wrap rounded-xl bg-white p-4 text-slate-700">
                              {detail.content}
                            </div>
                            {detail.notes && (
                              <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-amber-900">
                                <p className="mb-1 text-xs font-semibold uppercase tracking-wide">Notes</p>
                                {detail.notes}
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                );
              })
            )}
          </div>
        </section>
      )}

      {activeTab === 'assignments' && (
        <section className="space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-semibold text-slate-900">Assignments</h3>
              <p className="text-sm text-slate-500">Tasks for students with optional due dates</p>
            </div>
            <button
              type="button"
              onClick={() => setShowAssignmentForm(!showAssignmentForm)}
              className="inline-flex items-center gap-2 rounded-xl bg-emerald-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-emerald-700"
            >
              <Plus className="h-4 w-4" />
              Add assignment
            </button>
          </div>

          {showAssignmentForm && (
            <form onSubmit={addAssignment} className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm">
              <h4 className="mb-4 font-semibold text-slate-900">New assignment</h4>
              <div className="grid gap-4 lg:grid-cols-2">
                <input
                  placeholder="Assignment title"
                  value={assignmentForm.title}
                  onChange={(e) => setAssignmentForm({ ...assignmentForm, title: e.target.value })}
                  className={inputClass}
                  required
                />
                <input
                  type="date"
                  value={assignmentForm.dueDate}
                  onChange={(e) => setAssignmentForm({ ...assignmentForm, dueDate: e.target.value })}
                  className={inputClass}
                />
              </div>
              <textarea
                placeholder="Description / grading rubric"
                value={assignmentForm.description}
                onChange={(e) => setAssignmentForm({ ...assignmentForm, description: e.target.value })}
                className={`${inputClass} mt-4`}
                rows={3}
              />
              <div className="mt-4 flex items-center gap-4">
                <label className="text-sm text-slate-600">
                  Max score
                  <input
                    type="number"
                    min={1}
                    value={assignmentForm.maxScore}
                    onChange={(e) => setAssignmentForm({ ...assignmentForm, maxScore: Number(e.target.value) })}
                    className={`${inputClass} mt-1 w-32`}
                  />
                </label>
              </div>
              <div className="mt-4 flex gap-3">
                <button
                  type="submit"
                  disabled={busy === 'assignment'}
                  className="rounded-xl bg-emerald-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-60"
                >
                  {busy === 'assignment' ? 'Saving...' : 'Create assignment'}
                </button>
                <button
                  type="button"
                  onClick={() => setShowAssignmentForm(false)}
                  className="rounded-xl border border-slate-200 px-5 py-2.5 text-sm text-slate-600 hover:bg-slate-50"
                >
                  Cancel
                </button>
              </div>
            </form>
          )}

          <div className="grid gap-4 md:grid-cols-2">
            {course.assignments.length === 0 ? (
              <div className="col-span-full rounded-2xl border border-dashed border-slate-200 bg-white px-6 py-12 text-center">
                <ClipboardList className="mx-auto mb-3 h-10 w-10 text-slate-300" />
                <p className="font-medium text-slate-600">No assignments yet</p>
              </div>
            ) : (
              course.assignments.map((assignment) => (
                <div key={assignment.id} className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm">
                  <div className="mb-2 flex items-start justify-between gap-3">
                    <h4 className="font-semibold text-slate-900">{assignment.title}</h4>
                    <span className="shrink-0 rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-600">
                      /{assignment.max_score ?? 100} pts
                    </span>
                  </div>
                  {assignment.description && (
                    <p className="mb-3 line-clamp-3 text-sm text-slate-600">{assignment.description}</p>
                  )}
                  {assignment.due_date && (
                    <p className="flex items-center gap-1.5 text-xs text-slate-500">
                      <Calendar className="h-3.5 w-3.5" />
                      Due {new Date(assignment.due_date).toLocaleDateString()}
                    </p>
                  )}
                </div>
              ))
            )}
          </div>
        </section>
      )}

      {activeTab === 'assessments' && (
        <section className="space-y-8">
          <div className="rounded-2xl border border-purple-200/80 bg-gradient-to-br from-purple-50 to-indigo-50 p-6">
            <div className="mb-4 flex items-center gap-2">
              <Bot className="h-5 w-5 text-purple-600" />
              <h3 className="text-lg font-semibold text-slate-900">AI Quiz Generator</h3>
            </div>
            <p className="mb-4 text-sm text-slate-600">
              Generate multiple-choice and true/false questions instantly for this course.
            </p>
            <form onSubmit={generateQuiz} className="flex flex-col gap-3 sm:flex-row">
              <input
                placeholder="Topic (e.g. Algebra basics)"
                value={quizTopic}
                onChange={(e) => setQuizTopic(e.target.value)}
                className={`${inputClass} flex-1`}
                required
              />
              <select
                value={quizDifficulty}
                onChange={(e) => setQuizDifficulty(e.target.value)}
                className={`${inputClass} sm:w-40`}
              >
                <option value="easy">Easy</option>
                <option value="medium">Medium</option>
                <option value="hard">Hard</option>
              </select>
              <button
                type="submit"
                disabled={busy === 'quiz'}
                className="inline-flex items-center justify-center gap-2 rounded-xl bg-purple-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-purple-700 disabled:opacity-60"
              >
                {busy === 'quiz' ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin" />
                    Generating...
                  </>
                ) : (
                  <>
                    <Sparkles className="h-4 w-4" />
                    Generate quiz
                  </>
                )}
              </button>
            </form>
          </div>

          <div>
            <h3 className="mb-4 text-lg font-semibold text-slate-900">Quizzes ({course.quizzes.length})</h3>
            {course.quizzes.length === 0 ? (
              <p className="rounded-xl bg-slate-50 px-4 py-6 text-center text-sm text-slate-500">No quizzes yet</p>
            ) : (
              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                {course.quizzes.map((quiz) => (
                  <div key={quiz.id} className="rounded-2xl border border-purple-100 bg-white p-4 shadow-sm">
                    <span className="mb-2 inline-block rounded-full bg-purple-100 px-2 py-0.5 text-[10px] font-semibold uppercase text-purple-700">
                      Quiz
                    </span>
                    <p className="font-medium text-slate-900">{quiz.title}</p>
                    <p className="mt-2 text-xs text-slate-500">
                      {quiz.time_limit_minutes ?? 30} min · Pass {quiz.passing_score ?? 60}%
                    </p>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div>
            <h3 className="mb-4 text-lg font-semibold text-slate-900">Exams ({course.exams.length})</h3>
            {course.exams.length === 0 ? (
              <p className="rounded-xl bg-slate-50 px-4 py-6 text-center text-sm text-slate-500">No exams yet</p>
            ) : (
              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                {course.exams.map((exam) => (
                  <div key={exam.id} className="rounded-2xl border border-amber-100 bg-white p-4 shadow-sm">
                    <div className="mb-2 flex items-center justify-between gap-2">
                      <span className="rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-semibold uppercase text-amber-700">
                        Exam
                      </span>
                      {exam.is_published !== undefined && (
                        <span
                          className={`text-[10px] font-medium ${
                            exam.is_published ? 'text-emerald-600' : 'text-slate-400'
                          }`}
                        >
                          {exam.is_published ? 'Published' : 'Draft'}
                        </span>
                      )}
                    </div>
                    <p className="font-medium text-slate-900">{exam.title}</p>
                    <p className="mt-2 text-xs text-slate-500">
                      {exam.time_limit_minutes ?? 60} min · Pass {exam.passing_score ?? 60}%
                    </p>
                  </div>
                ))}
              </div>
            )}
          </div>
        </section>
      )}

      {activeTab === 'settings' && (
        <section className="grid gap-6 lg:grid-cols-3">
          <form onSubmit={saveCourseSettings} className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm lg:col-span-2">
            <h3 className="mb-1 text-lg font-semibold text-slate-900">Course details</h3>
            <p className="mb-6 text-sm text-slate-500">Update title, subject, and description</p>
            <div className="space-y-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Title</label>
                <input
                  value={editForm.title}
                  onChange={(e) => setEditForm({ ...editForm, title: e.target.value })}
                  className={inputClass}
                  required
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Subject</label>
                <input
                  value={editForm.subject}
                  onChange={(e) => setEditForm({ ...editForm, subject: e.target.value })}
                  className={inputClass}
                  placeholder="e.g. Mathematics"
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Description</label>
                <textarea
                  value={editForm.description}
                  onChange={(e) => setEditForm({ ...editForm, description: e.target.value })}
                  className={inputClass}
                  rows={5}
                />
              </div>
            </div>
            <button
              type="submit"
              disabled={busy === 'settings'}
              className="mt-6 rounded-xl bg-blue-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-60"
            >
              {busy === 'settings' ? 'Saving...' : 'Save changes'}
            </button>
          </form>

          <div className="space-y-6">
            <div className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm">
              <h3 className="mb-4 flex items-center gap-2 text-sm font-semibold text-slate-900">
                <FileText className="h-4 w-4" />
                Course info
              </h3>
              <dl className="space-y-3 text-sm">
                <div>
                  <dt className="text-slate-500">Course ID</dt>
                  <dd className="font-medium text-slate-900">#{course.id}</dd>
                </div>
                <div>
                  <dt className="text-slate-500">Status</dt>
                  <dd className="font-medium text-slate-900">{course.is_published ? 'Published' : 'Draft'}</dd>
                </div>
                {course.created_at && (
                  <div>
                    <dt className="text-slate-500">Created</dt>
                    <dd className="font-medium text-slate-900">
                      {new Date(course.created_at).toLocaleDateString()}
                    </dd>
                  </div>
                )}
              </dl>
            </div>

            <div className="rounded-2xl border border-red-200 bg-red-50 p-6">
              <h3 className="mb-2 font-semibold text-red-900">Danger zone</h3>
              <p className="mb-4 text-sm text-red-700">
                Deleting this course removes all lessons, quizzes, exams, and enrollments.
              </p>
              <button
                type="button"
                onClick={deleteCourse}
                disabled={busy === 'delete'}
                className="inline-flex items-center gap-2 rounded-xl bg-red-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60"
              >
                <Trash2 className="h-4 w-4" />
                {busy === 'delete' ? 'Deleting...' : 'Delete course'}
              </button>
            </div>
          </div>
        </section>
      )}
    </>
  );
}
