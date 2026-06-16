'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import {
  BookOpen,
  Bot,
  Loader2,
  Plus,
  Sparkles,
  X,
} from 'lucide-react';
import Header from '@/components/Header';
import { api, Course } from '@/lib/api';
import {
  adminAlertError,
  adminAlertSuccess,
  adminCard,
  adminInput,
  adminTextMuted,
  adminTextPrimary,
  adminTextSecondary,
} from '@/lib/admin-ui';

interface Category {
  id: number;
  name: string;
  is_active: boolean;
}

const emptyForm = {
  title: '',
  description: '',
  categoryId: '',
  thumbnailUrl: '',
  isPublished: false,
};

export default function CoursesPage() {
  const router = useRouter();
  const [courses, setCourses] = useState<Course[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState(emptyForm);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    setError('');
    try {
      const [courseList, cats] = await Promise.all([
        api<Course[]>('/courses'),
        api<Category[]>('/subjects?active=true'),
      ]);
      setCourses(courseList);
      setCategories(cats);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load courses');
    } finally {
      setLoading(false);
    }
  }

  function flash(msg: string) {
    setError('');
    setMessage(msg);
    setTimeout(() => setMessage(''), 4000);
  }

  async function createCourse(e: React.FormEvent) {
    e.preventDefault();
    setBusy('create');
    try {
      const course = await api<Course>('/courses', {
        method: 'POST',
        body: JSON.stringify({
          title: form.title,
          description: form.description || null,
          categoryId: form.categoryId ? Number(form.categoryId) : undefined,
          thumbnailUrl: form.thumbnailUrl || null,
          isPublished: form.isPublished,
        }),
      });
      setForm(emptyForm);
      setShowForm(false);
      flash(`Course "${course.title}" created`);
      await loadData();
      router.push(`/courses/${course.id}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create course');
    } finally {
      setBusy('');
    }
  }

  async function togglePublish(id: number, isPublished: boolean) {
    setBusy(`pub-${id}`);
    try {
      await api(`/courses/${id}`, {
        method: 'PUT',
        body: JSON.stringify({ isPublished: !isPublished }),
      });
      flash(isPublished ? 'Course unpublished' : 'Course published');
      await loadData();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update course');
    } finally {
      setBusy('');
    }
  }

  const publishedCount = courses.filter((c) => c.is_published).length;
  const draftCount = courses.length - publishedCount;

  return (
    <>
      <Header title="Courses" subtitle="Create and manage courses for your students" />

      {message && <div className={`mb-6 ${adminAlertSuccess}`}>{message}</div>}
      {error && <div className={`mb-6 ${adminAlertError}`}>{error}</div>}

      {/* Stats + actions */}
      <div className={`mb-6 ${adminCard}`}>
        <div className="flex flex-col gap-4 p-5 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex flex-wrap gap-6">
            <div>
              <p className={`text-xs font-medium uppercase tracking-wider ${adminTextMuted}`}>Total</p>
              <p className={`text-2xl font-bold ${adminTextPrimary}`}>{courses.length}</p>
            </div>
            <div>
              <p className={`text-xs font-medium uppercase tracking-wider ${adminTextMuted}`}>Published</p>
              <p className="text-2xl font-bold text-emerald-500">{publishedCount}</p>
            </div>
            <div>
              <p className={`text-xs font-medium uppercase tracking-wider ${adminTextMuted}`}>Drafts</p>
              <p className={`text-2xl font-bold ${adminTextPrimary}`}>{draftCount}</p>
            </div>
          </div>
          <div className="flex flex-wrap gap-2">
            <Link
              href="/ai"
              className="inline-flex items-center gap-2 rounded-xl border border-purple-500/30 bg-purple-500/10 px-4 py-2.5 text-sm font-medium text-purple-600 hover:bg-purple-500/15 dark:text-purple-400"
            >
              <Bot className="h-4 w-4" />
              AI generate
            </Link>
            <button
              type="button"
              onClick={() => setShowForm(!showForm)}
              className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 px-4 py-2.5 text-sm font-semibold text-white shadow-lg shadow-blue-500/20"
            >
              {showForm ? <X className="h-4 w-4" /> : <Plus className="h-4 w-4" />}
              {showForm ? 'Cancel' : 'Create course'}
            </button>
          </div>
        </div>
      </div>

      {/* Create course form section */}
      {showForm && (
        <section className={`mb-8 ${adminCard}`}>
          <div className="border-b border-slate-200/80 px-6 py-4 dark:border-slate-700/80">
            <div className="flex items-center gap-2">
              <BookOpen className="h-5 w-5 text-blue-500" />
              <h3 className={`text-lg font-semibold ${adminTextPrimary}`}>Create new course</h3>
            </div>
            <p className={`mt-1 text-sm ${adminTextSecondary}`}>
              Fill in the details below. You can add lessons, quizzes, and assignments after creating the course.
            </p>
          </div>

          <form onSubmit={createCourse} className="space-y-5 p-6">
            <div>
              <label className={`mb-1 block text-sm font-medium ${adminTextSecondary}`}>
                Course title <span className="text-red-500">*</span>
              </label>
              <input
                value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })}
                className={adminInput}
                placeholder="e.g. Introduction to Web Development"
                required
              />
            </div>

            <div>
              <label className={`mb-1 block text-sm font-medium ${adminTextSecondary}`}>Category</label>
              <select
                value={form.categoryId}
                onChange={(e) => setForm({ ...form, categoryId: e.target.value })}
                className={adminInput}
              >
                <option value="">Select category (optional)</option>
                {categories.map((cat) => (
                  <option key={cat.id} value={cat.id}>
                    {cat.name}
                  </option>
                ))}
              </select>
              <p className={`mt-1 text-xs ${adminTextMuted}`}>
                Links the course to IT, Language, Sports, Health, etc.{' '}
                <Link href="/ai" className="text-blue-500 hover:underline">
                  Manage categories
                </Link>
              </p>
            </div>

            <div>
              <label className={`mb-1 block text-sm font-medium ${adminTextSecondary}`}>Description</label>
              <textarea
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
                className={adminInput}
                rows={4}
                placeholder="What students will learn in this course..."
              />
            </div>

            <div>
              <label className={`mb-1 block text-sm font-medium ${adminTextSecondary}`}>
                Thumbnail URL <span className={adminTextMuted}>(optional)</span>
              </label>
              <input
                type="url"
                value={form.thumbnailUrl}
                onChange={(e) => setForm({ ...form, thumbnailUrl: e.target.value })}
                className={adminInput}
                placeholder="https://example.com/course-image.jpg"
              />
            </div>

            <label className="flex cursor-pointer items-center gap-3 rounded-xl border border-slate-200/80 px-4 py-3 dark:border-slate-600/80 dark:bg-slate-800/40">
              <input
                type="checkbox"
                checked={form.isPublished}
                onChange={(e) => setForm({ ...form, isPublished: e.target.checked })}
                className="h-4 w-4 rounded border-slate-300 text-blue-600"
              />
              <div>
                <span className={`text-sm font-medium ${adminTextPrimary}`}>Publish immediately</span>
                <p className={`text-xs ${adminTextMuted}`}>Students can see published courses in the app</p>
              </div>
            </label>

            <div className="flex flex-wrap gap-3 border-t border-slate-200/80 pt-5 dark:border-slate-700/80">
              <button
                type="submit"
                disabled={busy === 'create'}
                className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 px-6 py-2.5 text-sm font-semibold text-white hover:from-emerald-700 hover:to-teal-700 disabled:opacity-60"
              >
                {busy === 'create' ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin" />
                    Creating...
                  </>
                ) : (
                  <>
                    <Plus className="h-4 w-4" />
                    Create course
                  </>
                )}
              </button>
              <button
                type="button"
                onClick={() => setShowForm(false)}
                className="rounded-xl border border-slate-200/80 px-6 py-2.5 text-sm text-slate-600 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-800"
              >
                Cancel
              </button>
            </div>
          </form>
        </section>
      )}

      {/* Course list */}
      <section>
        <h3 className={`mb-4 text-sm font-semibold uppercase tracking-wider ${adminTextMuted}`}>
          All courses
        </h3>

        {loading ? (
          <div className="flex h-40 items-center justify-center">
            <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
          </div>
        ) : courses.length === 0 ? (
          <div className={`border-dashed px-6 py-16 text-center ${adminCard}`}>
            <BookOpen className={`mx-auto mb-3 h-10 w-10 ${adminTextMuted}`} />
            <p className={`font-medium ${adminTextPrimary}`}>No courses yet</p>
            <p className={`mt-1 text-sm ${adminTextSecondary}`}>
              Create a course manually or use the AI Teacher to generate one.
            </p>
            <div className="mt-4 flex justify-center gap-3">
              <button
                type="button"
                onClick={() => setShowForm(true)}
                className="text-sm font-medium text-blue-500 hover:underline"
              >
                Create course
              </button>
              <Link href="/ai" className="text-sm font-medium text-purple-500 hover:underline">
                AI generate
              </Link>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
            {courses.map((c) => (
              <div key={c.id} className={`flex flex-col ${adminCard} p-6`}>
                <div className="mb-2 flex items-start justify-between gap-2">
                  <div className="flex flex-wrap items-center gap-2">
                    <h3 className={`text-lg font-semibold ${adminTextPrimary}`}>{c.title}</h3>
                    {c.ai_generated && (
                      <span className="inline-flex items-center gap-1 rounded-full bg-purple-500/15 px-2 py-0.5 text-xs font-medium text-purple-500">
                        <Sparkles className="h-3 w-3" />
                        AI
                      </span>
                    )}
                  </div>
                  <span
                    className={`shrink-0 rounded-full px-2.5 py-0.5 text-[10px] font-semibold uppercase ${
                      c.is_published
                        ? 'bg-emerald-500/15 text-emerald-500'
                        : 'bg-slate-500/15 text-slate-400'
                    }`}
                  >
                    {c.is_published ? 'Live' : 'Draft'}
                  </span>
                </div>
                {c.subject && (
                  <p className="mb-1 text-sm font-medium text-blue-500">{c.subject}</p>
                )}
                <p className={`mb-4 line-clamp-2 flex-1 text-sm ${adminTextSecondary}`}>
                  {c.description || 'No description'}
                </p>
                <div className="flex items-center justify-between gap-2 border-t border-slate-200/50 pt-4 dark:border-slate-700/50">
                  <Link
                    href={`/courses/${c.id}`}
                    className="text-sm font-medium text-blue-500 hover:underline"
                  >
                    Manage content
                  </Link>
                  <button
                    type="button"
                    onClick={() => togglePublish(c.id, c.is_published)}
                    disabled={busy === `pub-${c.id}`}
                    className="text-sm font-medium text-slate-500 hover:text-slate-700 disabled:opacity-50 dark:hover:text-slate-300"
                  >
                    {busy === `pub-${c.id}` ? '...' : c.is_published ? 'Unpublish' : 'Publish'}
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>
    </>
  );
}
