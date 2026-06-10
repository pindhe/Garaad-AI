'use client';

import { useEffect, useState } from 'react';
import Header from '@/components/Header';
import { api, AiLog } from '@/lib/api';

export default function AiPage() {
  const [enabled, setEnabled] = useState(true);
  const [logs, setLogs] = useState<AiLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [generateForm, setGenerateForm] = useState({ subject: '', level: 'beginner', topics: '' });

  useEffect(() => {
    Promise.all([
      api<{ enabled: boolean }>('/ai/status'),
      api<AiLog[]>('/ai/logs?limit=30'),
    ])
      .then(([status, aiLogs]) => {
        setEnabled(status.enabled);
        setLogs(aiLogs);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  async function toggleAi() {
    const newState = !enabled;
    await api('/ai/toggle', { method: 'PUT', body: JSON.stringify({ enabled: newState }) });
    setEnabled(newState);
  }

  async function generateCourse(e: React.FormEvent) {
    e.preventDefault();
    const topics = generateForm.topics.split(',').map((t) => t.trim()).filter(Boolean);
    await api('/ai/generate-course', {
      method: 'POST',
      body: JSON.stringify({
        subject: generateForm.subject,
        level: generateForm.level,
        topics,
      }),
    });
    alert('Course generated! Check Courses page.');
  }

  return (
    <>
      <Header title="AI Teacher" subtitle="Control and monitor the AI teacher system" />

      <div className="mb-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className="mb-4 text-lg font-semibold">AI Teacher Status</h3>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-500">System Status</p>
              <p className={`text-xl font-bold ${enabled ? 'text-green-600' : 'text-red-600'}`}>
                {enabled ? 'Online' : 'Offline'}
              </p>
            </div>
            <button
              onClick={toggleAi}
              className={`rounded-lg px-6 py-2.5 text-sm font-medium text-white ${
                enabled ? 'bg-red-600 hover:bg-red-700' : 'bg-green-600 hover:bg-green-700'
              }`}
            >
              {enabled ? 'Disable AI' : 'Enable AI'}
            </button>
          </div>
        </div>

        <form onSubmit={generateCourse} className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className="mb-4 text-lg font-semibold">Generate Course with AI</h3>
          <div className="space-y-3">
            <input
              placeholder="Subject (e.g. Mathematics)"
              value={generateForm.subject}
              onChange={(e) => setGenerateForm({ ...generateForm, subject: e.target.value })}
              className="w-full rounded-lg border border-slate-300 px-4 py-2"
              required
            />
            <select
              value={generateForm.level}
              onChange={(e) => setGenerateForm({ ...generateForm, level: e.target.value })}
              className="w-full rounded-lg border border-slate-300 px-4 py-2"
            >
              <option value="beginner">Beginner</option>
              <option value="intermediate">Intermediate</option>
              <option value="advanced">Advanced</option>
            </select>
            <input
              placeholder="Topics (comma-separated)"
              value={generateForm.topics}
              onChange={(e) => setGenerateForm({ ...generateForm, topics: e.target.value })}
              className="w-full rounded-lg border border-slate-300 px-4 py-2"
              required
            />
            <button type="submit" className="w-full rounded-lg bg-blue-600 py-2 text-white hover:bg-blue-700">
              Generate Course
            </button>
          </div>
        </form>
      </div>

      <div className="rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div className="border-b border-slate-200 px-6 py-4">
          <h3 className="text-lg font-semibold">AI Activity Logs</h3>
        </div>
        <div className="max-h-96 overflow-y-auto">
          {loading ? (
            <p className="p-6 text-slate-400">Loading...</p>
          ) : logs.length === 0 ? (
            <p className="p-6 text-slate-400">No AI activity yet</p>
          ) : (
            logs.map((log) => (
              <div key={log.id} className="border-b border-slate-100 px-6 py-4 last:border-0">
                <div className="flex items-center justify-between">
                  <span className="rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-700">
                    {log.action}
                  </span>
                  <span className="text-xs text-slate-400">
                    {new Date(log.created_at).toLocaleString()}
                  </span>
                </div>
                <p className="mt-2 line-clamp-2 text-sm text-slate-600">{log.response_summary}</p>
                <p className="mt-1 text-xs text-slate-400">
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
