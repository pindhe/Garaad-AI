const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000';

export async function api<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;

  const res = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  const data = await res.json();
  if (!res.ok) throw new Error(data.error || 'Request failed');
  return data;
}

export const auth = {
  login: (email: string, password: string) =>
    api<{ token: string; user: User }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),
  me: () => api<User>('/auth/me'),
};

export interface User {
  id: number;
  email: string;
  role: string;
  first_name: string;
  last_name: string;
}

export interface DashboardStats {
  stats: {
    totalStudents: number;
    activeUsers: number;
    totalCourses: number;
    aiRequestsToday: number;
    totalRevenue: number;
  };
  enrollmentsByMonth: { month: string; count: number }[];
  aiUsageByAction: { action: string; count: number }[];
  topCourses: { title: string; enrollments: number }[];
}

export interface Student {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  is_active: boolean;
  grade_level?: string;
  class_name?: string;
  subscription_plan?: string;
  total_xp?: number;
}

export interface Course {
  id: number;
  title: string;
  description: string;
  subject: string;
  is_published: boolean;
  ai_generated: boolean;
}

export interface AiLog {
  id: number;
  action: string;
  prompt_tokens: number;
  completion_tokens: number;
  model: string;
  response_summary: string;
  created_at: string;
  email?: string;
}
