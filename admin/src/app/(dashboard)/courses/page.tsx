'use client';

import { useEffect, useState } from 'react';
import Header from '@/components/Header';
import { api, Course } from '@/lib/api';

export default function CoursesPage() {
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ title: '', description: '', subject: '' });

  useEffect(() => {
    loadCourses();
  }, []);

  function loadCourses() {
    api<Course[]>('/courses')
      .then(setCourses)
      .catch(console.error)
      .finally(() => setLoading(false));
  }

  async function createCourse(e: React.FormEvent) {
    e.preventDefault();
    await api('/courses', { method: 'POST', body: JSON.stringify(form) });
    setForm({ title: '', description: '', subject: '' });
    setShowForm(false);
    loadCourses();
  }

  async function togglePublish(id: number, isPublished: boolean) {
    await api(`/courses/${id}`, {
      method: 'PUT',
      body: JSON.stringify({ isPublished: !isPublished }),
    });
    loadCourses();
  }

  return (
    <>
      <Header title="Courses" subtitle="Manage courses and subjects" />

      <div className="mb-6">
        <button
          onClick={() => setShowForm(!showForm)}
          className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
        >
          {showForm ? 'Cancel' : '+ New Course'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={createCourse} className="mb-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            <input
              placeholder="Course title"
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
              className="rounded-lg border border-slate-300 px-4 py-2"
              required
            />
            <input
              placeholder="Subject"
              value={form.subject}
              onChange={(e) => setForm({ ...form, subject: e.target.value })}
              className="rounded-lg border border-slate-300 px-4 py-2"
            />
            <input
              placeholder="Description"
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              className="rounded-lg border border-slate-300 px-4 py-2"
            />
          </div>
          <button type="submit" className="mt-4 rounded-lg bg-green-600 px-4 py-2 text-sm text-white hover:bg-green-700">
            Create Course
          </button>
        </form>
      )}

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
        {loading ? (
          <p className="text-slate-400">Loading...</p>
        ) : courses.length === 0 ? (
          <p className="text-slate-400">No courses yet</p>
        ) : (
          courses.map((c) => (
            <div key={c.id} className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
              <div className="mb-2 flex items-center gap-2">
                <h3 className="text-lg font-semibold text-slate-900">{c.title}</h3>
                {c.ai_generated && (
                  <span className="rounded-full bg-purple-100 px-2 py-0.5 text-xs text-purple-700">AI</span>
                )}
              </div>
              <p className="mb-1 text-sm text-blue-600">{c.subject}</p>
              <p className="mb-4 line-clamp-2 text-sm text-slate-500">{c.description}</p>
              <div className="flex items-center justify-between">
                <span
                  className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
                    c.is_published ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-600'
                  }`}
                >
                  {c.is_published ? 'Published' : 'Draft'}
                </span>
                <button
                  onClick={() => togglePublish(c.id, c.is_published)}
                  className="text-sm text-blue-600 hover:underline"
                >
                  {c.is_published ? 'Unpublish' : 'Publish'}
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </>
  );
}
