'use client';

import { useEffect, useState } from 'react';
import Header from '@/components/Header';
import { api } from '@/lib/api';

interface Progress {
  first_name: string;
  last_name: string;
  course_title: string;
  progress_percent: number;
  enrolled_at: string;
}

export default function AnalyticsPage() {
  const [progress, setProgress] = useState<Progress[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api<Progress[]>('/analytics/progress')
      .then(setProgress)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  return (
    <>
      <Header title="Analytics" subtitle="Student progress and performance metrics" />

      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        <table className="w-full">
          <thead className="border-b border-slate-200 bg-slate-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase text-slate-500">Student</th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase text-slate-500">Course</th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase text-slate-500">Progress</th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase text-slate-500">Enrolled</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200">
            {loading ? (
              <tr><td colSpan={4} className="px-6 py-8 text-center text-slate-400">Loading...</td></tr>
            ) : progress.length === 0 ? (
              <tr><td colSpan={4} className="px-6 py-8 text-center text-slate-400">No enrollment data</td></tr>
            ) : (
              progress.map((p, i) => (
                <tr key={i} className="hover:bg-slate-50">
                  <td className="px-6 py-4 font-medium">{p.first_name} {p.last_name}</td>
                  <td className="px-6 py-4 text-slate-600">{p.course_title}</td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="h-2 w-32 overflow-hidden rounded-full bg-slate-200">
                        <div
                          className="h-full rounded-full bg-blue-600"
                          style={{ width: `${p.progress_percent}%` }}
                        />
                      </div>
                      <span className="text-sm text-slate-600">{p.progress_percent}%</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-500">
                    {new Date(p.enrolled_at).toLocaleDateString()}
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
