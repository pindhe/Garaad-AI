'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  Users,
  BookOpen,
  Bot,
  Activity,
  DollarSign,
  ArrowRight,
  Megaphone,
  Sparkles,
  TrendingUp,
} from 'lucide-react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import Header from '@/components/Header';
import StatCard from '@/components/StatCard';
import { useAdmin } from '@/components/AdminContext';
import { api, AiLog, DashboardStats } from '@/lib/api';

const COLORS = ['#2563EB', '#F59E0B', '#10B981', '#8B5CF6', '#EF4444'];

const quickActions = [
  {
    href: '/students',
    label: 'Manage Students',
    description: 'View and suspend accounts',
    icon: Users,
    color: 'from-blue-500 to-blue-600',
  },
  {
    href: '/courses',
    label: 'Create Course',
    description: 'Add or publish new content',
    icon: BookOpen,
    color: 'from-violet-500 to-purple-600',
  },
  {
    href: '/ai',
    label: 'AI Teacher',
    description: 'Generate courses & monitor usage',
    icon: Bot,
    color: 'from-amber-500 to-orange-600',
  },
  {
    href: '/announcements',
    label: 'Send Announcement',
    description: 'Notify all students at once',
    icon: Megaphone,
    color: 'from-emerald-500 to-teal-600',
  },
];

export default function DashboardPage() {
  const { user } = useAdmin();
  const [data, setData] = useState<DashboardStats | null>(null);
  const [recentLogs, setRecentLogs] = useState<AiLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    Promise.all([
      api<DashboardStats>('/analytics/dashboard'),
      api<AiLog[]>('/ai/logs?limit=5'),
    ])
      .then(([dashboard, logs]) => {
        setData(dashboard);
        setRecentLogs(logs);
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load dashboard'))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <>
        <Header title="Dashboard" subtitle="Loading platform overview..." />
        <div className="grid animate-pulse grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-32 rounded-2xl bg-white shadow-sm" />
          ))}
        </div>
      </>
    );
  }

  if (error) {
    return (
      <>
        <Header title="Dashboard" subtitle="Overview of your AI education platform" />
        <div className="rounded-2xl border border-red-200 bg-red-50 px-6 py-8 text-center">
          <p className="font-medium text-red-700">{error}</p>
          <button
            type="button"
            onClick={() => window.location.reload()}
            className="mt-4 rounded-lg bg-red-600 px-4 py-2 text-sm text-white hover:bg-red-700"
          >
            Retry
          </button>
        </div>
      </>
    );
  }

  const stats = data?.stats;
  const enrollments = data?.enrollmentsByMonth ?? [];
  const aiUsage = data?.aiUsageByAction ?? [];
  const topCourses = data?.topCourses ?? [];
  const maxEnrollments = Math.max(...topCourses.map((c) => c.enrollments), 1);

  return (
    <>
      <Header title="Dashboard" subtitle="Overview of your AI education platform" />

      <div className="mb-8 overflow-hidden rounded-2xl bg-gradient-to-r from-blue-600 via-indigo-600 to-violet-600 p-6 text-white shadow-lg shadow-blue-500/20 sm:p-8">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <div className="mb-2 inline-flex items-center gap-2 rounded-full bg-white/15 px-3 py-1 text-xs font-medium backdrop-blur-sm">
              <Sparkles className="h-3.5 w-3.5 text-amber-300" />
              Welcome back
            </div>
            <h2 className="text-2xl font-bold sm:text-3xl">
              {user ? `${user.first_name}, your platform is running` : 'Platform overview'}
            </h2>
            <p className="mt-2 max-w-xl text-sm text-blue-100">
              Track students, courses, AI usage, and revenue from one place. Use quick actions below to manage your school.
            </p>
          </div>
          <div className="flex shrink-0 items-center gap-3 rounded-2xl bg-white/10 px-5 py-4 backdrop-blur-sm">
            <TrendingUp className="h-8 w-8 text-emerald-300" />
            <div>
              <p className="text-xs uppercase tracking-wider text-blue-100">Active users</p>
              <p className="text-2xl font-bold">{stats?.activeUsers ?? 0}</p>
            </div>
          </div>
        </div>
      </div>

      <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <StatCard
          title="Total Students"
          value={stats?.totalStudents ?? 0}
          icon={Users}
          color="bg-blue-600 shadow-blue-600/30"
          subtitle="Registered learners"
        />
        <StatCard
          title="Active Users"
          value={stats?.activeUsers ?? 0}
          icon={Activity}
          color="bg-emerald-600 shadow-emerald-600/30"
          subtitle="Currently enabled"
        />
        <StatCard
          title="Total Courses"
          value={stats?.totalCourses ?? 0}
          icon={BookOpen}
          color="bg-violet-600 shadow-violet-600/30"
          subtitle="Published & drafts"
        />
        <StatCard
          title="AI Requests Today"
          value={stats?.aiRequestsToday ?? 0}
          icon={Bot}
          color="bg-amber-500 shadow-amber-500/30"
          subtitle="Teacher interactions"
        />
        <StatCard
          title="Revenue"
          value={`$${Number(stats?.totalRevenue ?? 0).toFixed(2)}`}
          icon={DollarSign}
          color="bg-purple-600 shadow-purple-600/30"
          subtitle="Completed payments"
        />
      </div>

      <div className="mb-8">
        <h3 className="mb-4 text-sm font-semibold uppercase tracking-wider text-slate-500">Quick Actions</h3>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {quickActions.map(({ href, label, description, icon: Icon, color }) => (
            <Link
              key={href}
              href={href}
              className="group flex items-center gap-4 rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm transition-all hover:-translate-y-0.5 hover:border-slate-300 hover:shadow-md"
            >
              <div className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br ${color} text-white shadow-lg`}>
                <Icon className="h-6 w-6" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="font-semibold text-slate-900">{label}</p>
                <p className="text-xs text-slate-500">{description}</p>
              </div>
              <ArrowRight className="h-4 w-4 shrink-0 text-slate-300 transition-transform group-hover:translate-x-1 group-hover:text-blue-600" />
            </Link>
          ))}
        </div>
      </div>

      <div className="mb-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm">
          <div className="mb-6 flex items-center justify-between">
            <div>
              <h3 className="text-lg font-semibold text-slate-900">Enrollments</h3>
              <p className="text-sm text-slate-500">Last 6 months</p>
            </div>
          </div>
          {enrollments.length > 0 ? (
            <ResponsiveContainer width="100%" height={260}>
              <AreaChart data={enrollments}>
                <defs>
                  <linearGradient id="enrollGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#2563EB" stopOpacity={0.25} />
                    <stop offset="95%" stopColor="#2563EB" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="month" tick={{ fontSize: 12 }} stroke="#94a3b8" />
                <YAxis tick={{ fontSize: 12 }} stroke="#94a3b8" allowDecimals={false} />
                <Tooltip
                  contentStyle={{ borderRadius: 12, border: '1px solid #e2e8f0', boxShadow: '0 4px 12px rgba(0,0,0,0.08)' }}
                />
                <Area type="monotone" dataKey="count" stroke="#2563EB" strokeWidth={2} fill="url(#enrollGradient)" />
              </AreaChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex h-64 flex-col items-center justify-center rounded-xl bg-slate-50 text-slate-400">
              <BookOpen className="mb-2 h-8 w-8" />
              <p className="text-sm">No enrollment data yet</p>
            </div>
          )}
        </div>

        <div className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm">
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-slate-900">AI Usage</h3>
            <p className="text-sm text-slate-500">By action type · last 30 days</p>
          </div>
          {aiUsage.length > 0 ? (
            <ResponsiveContainer width="100%" height={260}>
              <PieChart>
                <Pie
                  data={aiUsage}
                  dataKey="count"
                  nameKey="action"
                  cx="50%"
                  cy="50%"
                  innerRadius={55}
                  outerRadius={90}
                  paddingAngle={3}
                  label={({ name, percent }) =>
                    `${name ?? ''} ${((percent ?? 0) * 100).toFixed(0)}%`
                  }
                >
                  {aiUsage.map((_, i) => (
                    <Cell key={i} fill={COLORS[i % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{ borderRadius: 12, border: '1px solid #e2e8f0', boxShadow: '0 4px 12px rgba(0,0,0,0.08)' }}
                />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex h-64 flex-col items-center justify-center rounded-xl bg-slate-50 text-slate-400">
              <Bot className="mb-2 h-8 w-8" />
              <p className="text-sm">No AI activity yet</p>
            </div>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm lg:col-span-2">
          <div className="mb-6 flex items-center justify-between">
            <div>
              <h3 className="text-lg font-semibold text-slate-900">Top Courses</h3>
              <p className="text-sm text-slate-500">Most enrolled content</p>
            </div>
            <Link href="/courses" className="text-sm font-medium text-blue-600 hover:underline">
              View all
            </Link>
          </div>
          <div className="space-y-4">
            {topCourses.length > 0 ? (
              topCourses.map((course, i) => (
                <div key={i} className="group">
                  <div className="mb-1.5 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-blue-50 text-xs font-bold text-blue-600">
                        {i + 1}
                      </span>
                      <span className="font-medium text-slate-900">{course.title}</span>
                    </div>
                    <span className="text-sm font-medium text-slate-600">{course.enrollments}</span>
                  </div>
                  <div className="h-2 overflow-hidden rounded-full bg-slate-100">
                    <div
                      className="h-full rounded-full bg-gradient-to-r from-blue-500 to-indigo-500 transition-all"
                      style={{ width: `${(course.enrollments / maxEnrollments) * 100}%` }}
                    />
                  </div>
                </div>
              ))
            ) : (
              <p className="py-8 text-center text-sm text-slate-400">No courses yet</p>
            )}
          </div>
        </div>

        <div className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm">
          <div className="mb-6 flex items-center justify-between">
            <div>
              <h3 className="text-lg font-semibold text-slate-900">Recent AI Activity</h3>
              <p className="text-sm text-slate-500">Latest teacher requests</p>
            </div>
            <Link href="/ai" className="text-sm font-medium text-blue-600 hover:underline">
              View logs
            </Link>
          </div>
          <div className="space-y-3">
            {recentLogs.length > 0 ? (
              recentLogs.map((log) => (
                <div key={log.id} className="rounded-xl bg-slate-50 px-4 py-3">
                  <div className="flex items-center justify-between gap-2">
                    <span className="rounded-full bg-blue-100 px-2 py-0.5 text-[10px] font-semibold uppercase text-blue-700">
                      {log.action.replace(/_/g, ' ')}
                    </span>
                    <span className="text-[10px] text-slate-400">
                      {new Date(log.created_at).toLocaleDateString()}
                    </span>
                  </div>
                  <p className="mt-2 line-clamp-2 text-xs text-slate-600">{log.response_summary || 'No summary'}</p>
                </div>
              ))
            ) : (
              <div className="flex flex-col items-center py-8 text-slate-400">
                <Bot className="mb-2 h-8 w-8" />
                <p className="text-sm">No recent activity</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </>
  );
}
