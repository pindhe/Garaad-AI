'use client';

import { useEffect, useState } from 'react';
import { Users, BookOpen, Bot } from 'lucide-react';
import {
  BarChart,
  Bar,
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
import { api, DashboardStats } from '@/lib/api';

const COLORS = ['#2563EB', '#F59E0B', '#10B981', '#8B5CF6', '#EF4444'];

export default function DashboardPage() {
  const [data, setData] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api<DashboardStats>('/analytics/dashboard')
      .then(setData)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-600 border-t-transparent" />
      </div>
    );
  }

  const stats = data?.stats;

  return (
    <>
      <Header title="Dashboard" subtitle="Overview of your AI education platform" />

      <div className="mb-8 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
        <StatCard title="Total Students" value={stats?.totalStudents ?? 0} icon={Users} color="bg-blue-600" />
        <StatCard title="Active Users" value={stats?.activeUsers ?? 0} icon={Activity} color="bg-green-600" />
        <StatCard title="AI Requests Today" value={stats?.aiRequestsToday ?? 0} icon={Bot} color="bg-amber-500" />
        <StatCard
          title="Revenue"
          value={`$${Number(stats?.totalRevenue ?? 0).toFixed(2)}`}
          icon={DollarSign}
          color="bg-purple-600"
        />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className="mb-4 text-lg font-semibold text-slate-900">Enrollments</h3>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={data?.enrollmentsByMonth ?? []}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="count" fill="#2563EB" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className="mb-4 text-lg font-semibold text-slate-900">AI Usage</h3>
          <ResponsiveContainer width="100%" height={250}>
            <PieChart>
              <Pie
                data={data?.aiUsageByAction ?? []}
                dataKey="count"
                nameKey="action"
                cx="50%"
                cy="50%"
                outerRadius={80}
                label
              >
                {(data?.aiUsageByAction ?? []).map((_, i) => (
                  <Cell key={i} fill={COLORS[i % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="mt-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h3 className="mb-4 text-lg font-semibold text-slate-900">Top Courses</h3>
        <div className="space-y-3">
          {(data?.topCourses ?? []).map((course, i) => (
            <div key={i} className="flex items-center justify-between rounded-lg bg-slate-50 px-4 py-3">
              <div className="flex items-center gap-3">
                <BookOpen className="h-5 w-5 text-blue-600" />
                <span className="font-medium text-slate-900">{course.title}</span>
              </div>
              <span className="text-sm text-slate-500">{course.enrollments} enrollments</span>
            </div>
          ))}
          {!data?.topCourses?.length && (
            <p className="text-center text-sm text-slate-400">No courses yet</p>
          )}
        </div>
      </div>
    </>
  );
}

function Activity(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M22 12h-2.48a2 2 0 0 0-1.93 1.46l-2.35 8.36a.25.25 0 0 1-.48 0L9.24 2.18a.25.25 0 0 0-.48 0l-2.35 8.36A2 2 0 0 1 4.49 12H2" />
    </svg>
  );
}

function DollarSign(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <line x1="12" x2="12" y1="2" y2="22" /><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
    </svg>
  );
}
