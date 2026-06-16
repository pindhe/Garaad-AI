'use client';

import { useCallback, useEffect, useState } from 'react';
import {
  Bot,
  BookOpen,
  Calculator,
  Code,
  FlaskConical,
  HeartPulse,
  Landmark,
  Languages,
  Loader2,
  Pencil,
  Plus,
  Power,
  Sparkles,
  Trash2,
  Trophy,
  Wand2,
  X,
  type LucideIcon,
} from 'lucide-react';
import Header from '@/components/Header';
import { api, AiLog } from '@/lib/api';
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
  description: string;
  icon: string;
  is_active: boolean;
  course_count: number;
  lesson_count: number;
  courses?: { id: number; title: string; lesson_count: number; is_published: boolean }[];
}

const ICON_OPTIONS = [
  { value: 'code', label: 'IT / Tech', Icon: Code },
  { value: 'languages', label: 'Language', Icon: Languages },
  { value: 'trophy', label: 'Sports', Icon: Trophy },
  { value: 'heart-pulse', label: 'Health', Icon: HeartPulse },
  { value: 'calculator', label: 'Math', Icon: Calculator },
  { value: 'flask', label: 'Science', Icon: FlaskConical },
  { value: 'landmark', label: 'History', Icon: Landmark },
  { value: 'book', label: 'General', Icon: BookOpen },
];

const ICON_MAP: Record<string, LucideIcon> = Object.fromEntries(
  ICON_OPTIONS.map(({ value, Icon }) => [value, Icon])
);

function CategoryIcon({ name, className }: { name: string; className?: string }) {
  const Icon = ICON_MAP[name] || BookOpen;
  return <Icon className={className} />;
}

export default function AiPage() {
  const [enabled, setEnabled] = useState(true);
  const [logs, setLogs] = useState<AiLog[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const [showCatForm, setShowCatForm] = useState(false);
  const [editingCatId, setEditingCatId] = useState<number | null>(null);
  const [catForm, setCatForm] = useState({ name: '', description: '', icon: 'book', isActive: true });

  const [lessonPanel, setLessonPanel] = useState<number | null>(null);
  const [lessonForm, setLessonForm] = useState({
    topics: '',
    level: 'beginner',
    lessonCount: 3,
    courseId: '',
  });

  const [courseForm, setCourseForm] = useState({
    categoryId: '',
    level: 'beginner',
    topics: '',
  });

  const loadAll = useCallback(async () => {
    try {
      const [status, aiLogs, cats] = await Promise.all([
        api<{ enabled: boolean }>('/ai/status'),
        api<AiLog[]>('/ai/logs?limit=20'),
        api<Category[]>('/subjects'),
      ]);
      setEnabled(status.enabled);
      setLogs(aiLogs);
      setCategories(cats);
      setCourseForm((f) =>
        f.categoryId || !cats.length ? f : { ...f, categoryId: String(cats[0].id) }
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load AI panel');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadAll();
  }, [loadAll]);

  function flash(msg: string) {
    setError('');
    setMessage(msg);
    setTimeout(() => setMessage(''), 4000);
  }

  async function toggleAi() {
    setBusy('toggle');
    try {
      const newState = !enabled;
      await api('/ai/toggle', { method: 'PUT', body: JSON.stringify({ enabled: newState }) });
      setEnabled(newState);
      flash(newState ? 'AI Teacher is now active for students' : 'AI Teacher has been turned off');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to toggle AI');
    } finally {
      setBusy('');
    }
  }

  async function saveCategory(e: React.FormEvent) {
    e.preventDefault();
    setBusy('cat');
    try {
      const payload = {
        name: catForm.name,
        description: catForm.description,
        icon: catForm.icon,
        isActive: catForm.isActive,
      };
      if (editingCatId) {
        await api(`/subjects/${editingCatId}`, { method: 'PUT', body: JSON.stringify(payload) });
        flash('Category updated');
      } else {
        await api('/subjects', { method: 'POST', body: JSON.stringify(payload) });
        flash('Category created');
      }
      setShowCatForm(false);
      setEditingCatId(null);
      setCatForm({ name: '', description: '', icon: 'book', isActive: true });
      await loadAll();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save category');
    } finally {
      setBusy('');
    }
  }

  async function toggleCategory(cat: Category) {
    setBusy(`cat-${cat.id}`);
    try {
      await api(`/subjects/${cat.id}`, {
        method: 'PUT',
        body: JSON.stringify({ isActive: !cat.is_active }),
      });
      await loadAll();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update category');
    } finally {
      setBusy('');
    }
  }

  async function deleteCategory(cat: Category) {
    if (!confirm(`Delete category "${cat.name}"?`)) return;
    setBusy(`del-${cat.id}`);
    try {
      await api(`/subjects/${cat.id}`, { method: 'DELETE' });
      flash('Category deleted');
      await loadAll();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete category');
    } finally {
      setBusy('');
    }
  }

  async function generateCourse(e: React.FormEvent) {
    e.preventDefault();
    const topics = courseForm.topics.split(',').map((t) => t.trim()).filter(Boolean);
    if (!courseForm.categoryId || !topics.length) return;
    setBusy('course');
    try {
      const result = await api<{ courseId: number; message?: string }>('/ai/generate-course', {
        method: 'POST',
        body: JSON.stringify({
          categoryId: Number(courseForm.categoryId),
          level: courseForm.level,
          topics,
        }),
      });
      flash(`Course created with lessons (ID: ${result.courseId})`);
      setCourseForm((f) => ({ ...f, topics: '' }));
      await loadAll();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to generate course');
    } finally {
      setBusy('');
    }
  }

  async function generateLessons(e: React.FormEvent, categoryId: number) {
    e.preventDefault();
    const topics = lessonForm.topics.split(',').map((t) => t.trim()).filter(Boolean);
    if (!topics.length) return;
    setBusy(`lessons-${categoryId}`);
    try {
      const result = await api<{ courseId: number; lessonsAdded: number; message: string }>(
        '/ai/generate-lessons',
        {
          method: 'POST',
          body: JSON.stringify({
            categoryId,
            courseId: lessonForm.courseId ? Number(lessonForm.courseId) : undefined,
            topics,
            level: lessonForm.level,
            lessonCount: lessonForm.lessonCount,
          }),
        }
      );
      flash(result.message || `Added ${result.lessonsAdded} lessons`);
      setLessonPanel(null);
      setLessonForm({ topics: '', level: 'beginner', lessonCount: 3, courseId: '' });
      await loadAll();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to generate lessons');
    } finally {
      setBusy('');
    }
  }

  function openEditCategory(cat: Category) {
    setEditingCatId(cat.id);
    setCatForm({
      name: cat.name,
      description: cat.description || '',
      icon: cat.icon || 'book',
      isActive: cat.is_active,
    });
    setShowCatForm(true);
  }

  return (
    <>
      <Header title="AI Teacher" subtitle="Activate the AI teacher, manage categories, and generate lessons" />

      {message && <div className={`mb-6 ${adminAlertSuccess}`}>{message}</div>}
      {error && <div className={`mb-6 ${adminAlertError}`}>{error}</div>}

      {/* AI Teacher ON/OFF */}
      <div className={`mb-8 overflow-hidden ${adminCard}`}>
        <div className="flex flex-col gap-6 p-6 sm:flex-row sm:items-center sm:justify-between lg:p-8">
          <div className="flex items-start gap-4">
            <div
              className={`flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl ${
                enabled
                  ? 'bg-gradient-to-br from-emerald-500 to-teal-600 shadow-lg shadow-emerald-500/30'
                  : 'bg-slate-500/20 dark:bg-slate-700'
              }`}
            >
              <Bot className={`h-7 w-7 ${enabled ? 'text-white' : 'text-slate-400'}`} />
            </div>
            <div>
              <div className="mb-1 flex items-center gap-2">
                <h3 className={`text-xl font-bold ${adminTextPrimary}`}>AI Teacher</h3>
                <span
                  className={`rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wide ${
                    enabled
                      ? 'bg-emerald-500/15 text-emerald-500 ring-1 ring-emerald-500/30'
                      : 'bg-slate-500/15 text-slate-400 ring-1 ring-slate-500/30'
                  }`}
                >
                  {enabled ? 'Active' : 'Inactive'}
                </span>
              </div>
              <p className={`max-w-lg text-sm ${adminTextSecondary}`}>
                When active, students can chat with the AI teacher in the mobile app. When inactive, all AI features are disabled for students.
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={toggleAi}
            disabled={busy === 'toggle'}
            className={`inline-flex items-center justify-center gap-2 rounded-xl px-6 py-3 text-sm font-semibold text-white transition-all disabled:opacity-60 ${
              enabled
                ? 'bg-red-600 hover:bg-red-700 shadow-lg shadow-red-500/20'
                : 'bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 shadow-lg shadow-emerald-500/20'
            }`}
          >
            <Power className="h-4 w-4" />
            {busy === 'toggle' ? 'Updating...' : enabled ? 'Turn OFF teacher' : 'Turn ON teacher'}
          </button>
        </div>
      </div>

      {/* Categories */}
      <div className="mb-8">
        <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h3 className={`text-lg font-semibold ${adminTextPrimary}`}>Teaching categories</h3>
            <p className={`text-sm ${adminTextSecondary}`}>
              IT, Language, Sports, Health — AI generates courses and lessons per category
            </p>
          </div>
          <button
            type="button"
            onClick={() => {
              setEditingCatId(null);
              setCatForm({ name: '', description: '', icon: 'book', isActive: true });
              setShowCatForm(true);
            }}
            className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 px-4 py-2.5 text-sm font-semibold text-white shadow-lg shadow-blue-500/20"
          >
            <Plus className="h-4 w-4" />
            New category
          </button>
        </div>

        {showCatForm && (
          <form onSubmit={saveCategory} className={`mb-6 p-6 ${adminCard}`}>
            <div className="mb-4 flex items-center justify-between">
              <h4 className={`font-semibold ${adminTextPrimary}`}>
                {editingCatId ? 'Edit category' : 'Create category'}
              </h4>
              <button type="button" onClick={() => setShowCatForm(false)} className="text-slate-400 hover:text-slate-600">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="grid gap-4 md:grid-cols-2">
              <div>
                <label className={`mb-1 block text-sm font-medium ${adminTextSecondary}`}>Name</label>
                <input
                  value={catForm.name}
                  onChange={(e) => setCatForm({ ...catForm, name: e.target.value })}
                  className={adminInput}
                  placeholder="e.g. IT, Language, Sports"
                  required
                />
              </div>
              <div>
                <label className={`mb-1 block text-sm font-medium ${adminTextSecondary}`}>Icon</label>
                <select
                  value={catForm.icon}
                  onChange={(e) => setCatForm({ ...catForm, icon: e.target.value })}
                  className={adminInput}
                >
                  {ICON_OPTIONS.map(({ value, label }) => (
                    <option key={value} value={value}>{label}</option>
                  ))}
                </select>
              </div>
            </div>
            <div className="mt-4">
              <label className={`mb-1 block text-sm font-medium ${adminTextSecondary}`}>Description</label>
              <input
                value={catForm.description}
                onChange={(e) => setCatForm({ ...catForm, description: e.target.value })}
                className={adminInput}
                placeholder="What this category covers"
              />
            </div>
            <label className="mt-4 flex cursor-pointer items-center gap-2">
              <input
                type="checkbox"
                checked={catForm.isActive}
                onChange={(e) => setCatForm({ ...catForm, isActive: e.target.checked })}
                className="rounded border-slate-300 text-blue-600"
              />
              <span className={`text-sm ${adminTextPrimary}`}>Active category</span>
            </label>
            <div className="mt-4 flex gap-3">
              <button type="submit" disabled={busy === 'cat'} className="rounded-xl bg-blue-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-60">
                {busy === 'cat' ? 'Saving...' : editingCatId ? 'Update' : 'Create'}
              </button>
            </div>
          </form>
        )}

        {loading ? (
          <div className="flex h-32 items-center justify-center">
            <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            {categories.map((cat) => (
              <div
                key={cat.id}
                className={`flex flex-col ${adminCard} p-5 ${!cat.is_active ? 'opacity-60' : ''}`}
              >
                <div className="mb-4 flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-blue-500/10 text-blue-500 ring-1 ring-blue-500/20">
                      <CategoryIcon name={cat.icon} className="h-5 w-5" />
                    </div>
                    <div>
                      <h4 className={`font-bold ${adminTextPrimary}`}>{cat.name}</h4>
                      <p className={`text-xs ${adminTextMuted}`}>
                        {cat.course_count} courses · {cat.lesson_count} lessons
                      </p>
                    </div>
                  </div>
                  <span
                    className={`rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase ${
                      cat.is_active ? 'bg-emerald-500/15 text-emerald-500' : 'bg-slate-500/15 text-slate-400'
                    }`}
                  >
                    {cat.is_active ? 'On' : 'Off'}
                  </span>
                </div>
                <p className={`mb-4 flex-1 text-sm ${adminTextSecondary}`}>{cat.description || 'No description'}</p>
                <div className="flex flex-wrap gap-2">
                  <button
                    type="button"
                    onClick={() => setLessonPanel(lessonPanel === cat.id ? null : cat.id)}
                    disabled={!enabled || !cat.is_active}
                    className="inline-flex flex-1 items-center justify-center gap-1 rounded-xl bg-purple-600/90 px-3 py-2 text-xs font-semibold text-white hover:bg-purple-700 disabled:opacity-40"
                  >
                    <Wand2 className="h-3.5 w-3.5" />
                    AI lessons
                  </button>
                  <button type="button" onClick={() => openEditCategory(cat)} className="rounded-xl border border-slate-200/80 p-2 dark:border-slate-600">
                    <Pencil className="h-3.5 w-3.5 text-slate-500" />
                  </button>
                  <button
                    type="button"
                    onClick={() => toggleCategory(cat)}
                    disabled={busy === `cat-${cat.id}`}
                    className="rounded-xl border border-slate-200/80 px-2 py-2 text-xs dark:border-slate-600"
                  >
                    {cat.is_active ? 'Off' : 'On'}
                  </button>
                  <button type="button" onClick={() => deleteCategory(cat)} className="rounded-xl border border-red-500/25 bg-red-500/10 p-2 text-red-500">
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                </div>

                {lessonPanel === cat.id && (
                  <form onSubmit={(e) => generateLessons(e, cat.id)} className="mt-4 space-y-3 border-t border-slate-200/50 pt-4 dark:border-slate-700/50">
                    <input
                      placeholder="Topics (comma-separated)"
                      value={lessonForm.topics}
                      onChange={(e) => setLessonForm({ ...lessonForm, topics: e.target.value })}
                      className={adminInput}
                      required
                    />
                    <div className="grid grid-cols-2 gap-2">
                      <select
                        value={lessonForm.level}
                        onChange={(e) => setLessonForm({ ...lessonForm, level: e.target.value })}
                        className={adminInput}
                      >
                        <option value="beginner">Beginner</option>
                        <option value="intermediate">Intermediate</option>
                        <option value="advanced">Advanced</option>
                      </select>
                      <input
                        type="number"
                        min={1}
                        max={10}
                        value={lessonForm.lessonCount}
                        onChange={(e) => setLessonForm({ ...lessonForm, lessonCount: Number(e.target.value) })}
                        className={adminInput}
                        placeholder="Lessons"
                      />
                    </div>
                    <button
                      type="submit"
                      disabled={busy === `lessons-${cat.id}` || !enabled}
                      className="w-full rounded-xl bg-purple-600 py-2 text-sm font-medium text-white hover:bg-purple-700 disabled:opacity-50"
                    >
                      {busy === `lessons-${cat.id}` ? 'Generating...' : 'Generate lessons with AI'}
                    </button>
                  </form>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Full course generator */}
      <form onSubmit={generateCourse} className={`mb-8 p-6 ${adminCard}`}>
        <div className="mb-4 flex items-center gap-2">
          <Sparkles className="h-5 w-5 text-amber-500" />
          <h3 className={`text-lg font-semibold ${adminTextPrimary}`}>Generate full course</h3>
        </div>
        <p className={`mb-4 text-sm ${adminTextSecondary}`}>
          AI creates a complete course with lessons and a quiz for the selected category.
        </p>
        <div className="grid gap-4 md:grid-cols-3">
          <select
            value={courseForm.categoryId}
            onChange={(e) => setCourseForm({ ...courseForm, categoryId: e.target.value })}
            className={adminInput}
            required
          >
            <option value="">Select category</option>
            {categories.filter((c) => c.is_active).map((c) => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </select>
          <select
            value={courseForm.level}
            onChange={(e) => setCourseForm({ ...courseForm, level: e.target.value })}
            className={adminInput}
          >
            <option value="beginner">Beginner</option>
            <option value="intermediate">Intermediate</option>
            <option value="advanced">Advanced</option>
          </select>
          <input
            placeholder="Topics (comma-separated)"
            value={courseForm.topics}
            onChange={(e) => setCourseForm({ ...courseForm, topics: e.target.value })}
            className={adminInput}
            required
          />
        </div>
        <button
          type="submit"
          disabled={busy === 'course' || !enabled}
          className="mt-4 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 px-6 py-2.5 text-sm font-semibold text-white hover:from-blue-700 hover:to-indigo-700 disabled:opacity-50"
        >
          {busy === 'course' ? 'Generating course...' : 'Generate course + quiz'}
        </button>
        {!enabled && (
          <p className="mt-2 text-xs text-amber-600 dark:text-amber-400">Turn ON the AI Teacher to generate content.</p>
        )}
      </form>

      {/* Activity logs */}
      <div className={adminCard}>
        <div className="border-b border-slate-200/80 px-6 py-4 dark:border-slate-700/80">
          <h3 className={`text-lg font-semibold ${adminTextPrimary}`}>AI activity logs</h3>
        </div>
        <div className="max-h-96 overflow-y-auto">
          {loading ? (
            <p className={`p-6 ${adminTextMuted}`}>Loading...</p>
          ) : logs.length === 0 ? (
            <p className={`p-6 ${adminTextMuted}`}>No AI activity yet</p>
          ) : (
            logs.map((log) => (
              <div key={log.id} className="border-b border-slate-100 px-6 py-4 last:border-0 dark:border-slate-800">
                <div className="flex items-center justify-between gap-2">
                  <span className="rounded-full bg-blue-500/15 px-2.5 py-0.5 text-xs font-medium text-blue-500">
                    {log.action.replace(/_/g, ' ')}
                  </span>
                  <span className={`text-xs ${adminTextMuted}`}>
                    {new Date(log.created_at).toLocaleString()}
                  </span>
                </div>
                <p className={`mt-2 line-clamp-2 text-sm ${adminTextSecondary}`}>{log.response_summary}</p>
                <p className={`mt-1 text-xs ${adminTextMuted}`}>
                  {log.prompt_tokens + log.completion_tokens} tokens · {log.model}
                </p>
              </div>
            ))
          )}
        </div>
      </div>
    </>
  );
}
