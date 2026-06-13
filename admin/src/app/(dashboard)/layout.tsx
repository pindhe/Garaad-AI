'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import { AdminProvider, useAdmin } from '@/components/AdminContext';

function DashboardShell({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const { sidebarCollapsed } = useAdmin();

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) router.push('/login');
  }, [router]);

  return (
    <div className="min-h-screen bg-[#f4f6fb]">
      <Sidebar />
      <main
        className={`min-h-screen transition-all duration-300 ${
          sidebarCollapsed ? 'lg:pl-20' : 'lg:pl-72'
        }`}
      >
        <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">{children}</div>
      </main>
    </div>
  );
}

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <AdminProvider>
      <DashboardShell>{children}</DashboardShell>
    </AdminProvider>
  );
}
