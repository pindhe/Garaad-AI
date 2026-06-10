'use client';

import { useEffect, useState } from 'react';
import Header from '@/components/Header';
import { api, Student } from '@/lib/api';

export default function StudentsPage() {
  const [students, setStudents] = useState<Student[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api<Student[]>('/students')
      .then(setStudents)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  async function toggleActive(id: number, isActive: boolean) {
    await api(`/students/${id}`, {
      method: 'PUT',
      body: JSON.stringify({ isActive: !isActive }),
    });
    setStudents((prev) =>
      prev.map((s) => (s.id === id ? { ...s, is_active: !isActive } : s))
    );
  }

  return (
    <>
      <Header title="Students" subtitle="Manage student accounts" />

      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        <table className="w-full">
          <thead className="border-b border-slate-200 bg-slate-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase text-slate-500">Name</th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase text-slate-500">Email</th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase text-slate-500">Class</th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase text-slate-500">Plan</th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase text-slate-500">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase text-slate-500">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200">
            {loading ? (
              <tr>
                <td colSpan={6} className="px-6 py-8 text-center text-slate-400">Loading...</td>
              </tr>
            ) : students.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-6 py-8 text-center text-slate-400">No students yet</td>
              </tr>
            ) : (
              students.map((s) => (
                <tr key={s.id} className="hover:bg-slate-50">
                  <td className="px-6 py-4 font-medium text-slate-900">
                    {s.first_name} {s.last_name}
                  </td>
                  <td className="px-6 py-4 text-slate-600">{s.email}</td>
                  <td className="px-6 py-4 text-slate-600">{s.class_name || '—'}</td>
                  <td className="px-6 py-4">
                    <span className="rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-700">
                      {s.subscription_plan || 'free'}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span
                      className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
                        s.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                      }`}
                    >
                      {s.is_active ? 'Active' : 'Suspended'}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <button
                      onClick={() => toggleActive(s.id, s.is_active)}
                      className="text-sm text-blue-600 hover:underline"
                    >
                      {s.is_active ? 'Suspend' : 'Activate'}
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </>
  );
}
