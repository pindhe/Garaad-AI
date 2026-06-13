'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { GraduationCap } from 'lucide-react';
import { auth } from '@/lib/api';
import ThemeToggle from '@/components/ThemeToggle';
import { adminInput } from '@/lib/admin-ui';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const { token, user } = await auth.login(email, password);
      if (user.role !== 'admin') {
        setError('Admin access only');
        return;
      }
      localStorage.setItem('token', token);
      router.push('/');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-[#f4f6fb] px-4 dark:bg-[#070b14]">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_top,rgba(59,130,246,0.15),transparent_55%)] dark:bg-[radial-gradient(ellipse_at_top,rgba(59,130,246,0.08),transparent_55%)]" />
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_bottom_right,rgba(139,92,246,0.1),transparent_50%)]" />

      <div className="absolute right-4 top-4 sm:right-6 sm:top-6">
        <ThemeToggle />
      </div>

      <div className="relative w-full max-w-md rounded-2xl border border-slate-200/80 bg-white p-8 shadow-2xl shadow-slate-200/50 dark:border-slate-700/80 dark:bg-slate-900/90 dark:shadow-black/40">
        <div className="mb-8 flex flex-col items-center">
          <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600 shadow-lg shadow-blue-500/30">
            <GraduationCap className="h-8 w-8 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">MacallinAI</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">Admin Dashboard</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-600 dark:border-red-800 dark:bg-red-950/50 dark:text-red-300">
              {error}
            </div>
          )}
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className={adminInput}
              placeholder="admin@macallinai.com"
              required
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className={adminInput}
              placeholder="••••••••"
              required
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 py-2.5 font-medium text-white shadow-lg shadow-blue-500/25 hover:from-blue-700 hover:to-indigo-700 disabled:opacity-50"
          >
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>
      </div>
    </div>
  );
}
