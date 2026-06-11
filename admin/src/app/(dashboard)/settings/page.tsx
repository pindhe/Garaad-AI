'use client';

import { useEffect, useState } from 'react';
import Header from '@/components/Header';
import { api } from '@/lib/api';

export default function SettingsPage() {
  const [settings, setSettings] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    api<Record<string, string>>('/analytics/settings')
      .then(setSettings)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    await api('/analytics/settings', {
      method: 'PUT',
      body: JSON.stringify({ settings }),
    });
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  }

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-600 border-t-transparent" />
      </div>
    );
  }

  return (
    <>
      <Header title="Settings" subtitle="System configuration and AI behavior" />

      {saved && (
        <div className="mb-6 rounded-lg bg-green-50 px-4 py-3 text-sm text-green-700">
          Settings saved successfully
        </div>
      )}

      <form onSubmit={handleSave} className="max-w-2xl space-y-6">
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className="mb-4 text-lg font-semibold">AI Teacher</h3>
          <div className="space-y-4">
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">AI Enabled</label>
              <select
                value={settings.ai_teacher_enabled ?? 'true'}
                onChange={(e) => setSettings({ ...settings, ai_teacher_enabled: e.target.value })}
                className="w-full rounded-lg border border-slate-300 px-4 py-2"
              >
                <option value="true">Enabled</option>
                <option value="false">Disabled</option>
              </select>
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">AI Model</label>
              <input
                value={settings.ai_model ?? 'gpt-4o-mini'}
                onChange={(e) => setSettings({ ...settings, ai_model: e.target.value })}
                className="w-full rounded-lg border border-slate-300 px-4 py-2"
              />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">System Prompt</label>
              <textarea
                rows={5}
                value={settings.ai_system_prompt ?? ''}
                onChange={(e) => setSettings({ ...settings, ai_system_prompt: e.target.value })}
                className="w-full rounded-lg border border-slate-300 px-4 py-2"
              />
            </div>
          </div>
        </div>

        <button type="submit" className="rounded-lg bg-blue-600 px-6 py-2.5 text-white hover:bg-blue-700">
          Save Settings
        </button>
      </form>
    </>
  );
}
