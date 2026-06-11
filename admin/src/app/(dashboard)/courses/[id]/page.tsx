'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import Header from '@/components/Header';
import { api } from '@/lib/api';

interface CourseDetail {
  id: number;
  title: string;
  description: string;
  subject: string;
  is_published: boolean;
  lessons: { id: number; title: string; duration_minutes: number }[];
  quizzes: { id: number; title: string }[];
  exams: { id: number; title: string }[];
  assignments: { id: number; title: string }[];
}

export default function CourseManagePage() {
  const params = useParams();
  const courseId = params.id as string;
  const [course, setCourse] = useState<CourseDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [lessonForm, setLessonForm] = useState({ title: '', content: '', orderIndex: 0 });
  const [assignmentForm, setAssignmentForm] = useState({ title: '', description: '' });
  const [quizTopic, setQuizTopic] = useState('');

  useEffect(() => {
    loadCourse();
  }, [courseId]);

  function loadCourse() {
    api<CourseDetail>(`/courses/${courseId}`)
      .then(setCourse)
      .catch(console.error)
      .finally(() => setLoading(false));
  }

  async function addLesson(e: React.FormEvent) {
    e.preventDefault();
    await api('/lessons', {
      method: 'POST',
      body: JSON.stringify({ courseId: Number(courseId), ...lessonForm, orderIndex: course?.lessons.length ?? 0 }),
    });
    setLessonForm({ title: '', content: '', orderIndex: 0 });
    loadCourse();
  }

  async function addAssignment(e: React.FormEvent) {
    e.preventDefault();
    await api('/assignments', {
      method: 'POST',
      body: JSON.stringify({ courseId: Number(courseId), ...assignmentForm }),
    });
    setAssignmentForm({ title: '', description: '' });
    loadCourse();
  }

  async function generateQuiz(e: React.FormEvent) {
    e.preventDefault();
    await api('/ai/generate-quiz', {
      method: 'POST',
      body: JSON.stringify({ topic: quizTopic, count: 5, courseId: Number(courseId) }),
    });
    setQuizTopic('');
    loadCourse();
  }

  if (loading || !course) {
    return <div className="flex h-64 items-center justify-center text-slate-400">Loading...</div>;
  }

  return (
    <>
      <Header
        title={course.title}
        subtitle={`Manage content for ${course.subject || 'course'}`}
      />

      <Link href="/courses" className="mb-6 inline-block text-sm text-blue-600 hover:underline">
        ← Back to courses
      </Link>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className="mb-4 font-semibold">Lessons ({course.lessons.length})</h3>
          <ul className="mb-4 space-y-2">
            {course.lessons.map((l, i) => (
              <li key={l.id} className="rounded-lg bg-slate-50 px-3 py-2 text-sm">
                {i + 1}. {l.title}
              </li>
            ))}
          </ul>
          <form onSubmit={addLesson} className="space-y-3">
            <input
              placeholder="Lesson title"
              value={lessonForm.title}
              onChange={(e) => setLessonForm({ ...lessonForm, title: e.target.value })}
              className="w-full rounded-lg border px-3 py-2 text-sm"
              required
            />
            <textarea
              placeholder="Lesson content"
              value={lessonForm.content}
              onChange={(e) => setLessonForm({ ...lessonForm, content: e.target.value })}
              className="w-full rounded-lg border px-3 py-2 text-sm"
              rows={3}
              required
            />
            <button type="submit" className="rounded-lg bg-blue-600 px-4 py-2 text-sm text-white">
              Add Lesson
            </button>
          </form>
        </div>

        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className="mb-4 font-semibold">Assignments ({course.assignments.length})</h3>
          <ul className="mb-4 space-y-2">
            {course.assignments.map((a) => (
              <li key={a.id} className="rounded-lg bg-slate-50 px-3 py-2 text-sm">{a.title}</li>
            ))}
          </ul>
          <form onSubmit={addAssignment} className="space-y-3">
            <input
              placeholder="Assignment title"
              value={assignmentForm.title}
              onChange={(e) => setAssignmentForm({ ...assignmentForm, title: e.target.value })}
              className="w-full rounded-lg border px-3 py-2 text-sm"
              required
            />
            <textarea
              placeholder="Description / rubric"
              value={assignmentForm.description}
              onChange={(e) => setAssignmentForm({ ...assignmentForm, description: e.target.value })}
              className="w-full rounded-lg border px-3 py-2 text-sm"
              rows={2}
            />
            <button type="submit" className="rounded-lg bg-green-600 px-4 py-2 text-sm text-white">
              Add Assignment
            </button>
          </form>
        </div>

        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm lg:col-span-2">
          <h3 className="mb-4 font-semibold">AI Generate Quiz ({course.quizzes.length} quizzes)</h3>
          <form onSubmit={generateQuiz} className="flex gap-3">
            <input
              placeholder="Quiz topic (e.g. Algebra basics)"
              value={quizTopic}
              onChange={(e) => setQuizTopic(e.target.value)}
              className="flex-1 rounded-lg border px-3 py-2 text-sm"
              required
            />
            <button type="submit" className="rounded-lg bg-purple-600 px-4 py-2 text-sm text-white">
              Generate Quiz
            </button>
          </form>
          <ul className="mt-4 flex flex-wrap gap-2">
            {course.quizzes.map((q) => (
              <li key={q.id} className="rounded-full bg-purple-100 px-3 py-1 text-xs text-purple-700">{q.title}</li>
            ))}
          </ul>
        </div>
      </div>
    </>
  );
}
