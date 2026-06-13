'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import AdminTopBar from '@/components/AdminTopBar';
import { AdminProvider, useAdmin } from '@/components/AdminContext';

function DashboardShell({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const { sidebarCollapsed } = useAdmin();

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) router.push('/login');
  }, [router]);

  return (
    <div className="min-h-screen bg-[#f4f6fb] transition-colors duration-300 dark:bg-[#070b14]">
      <Sidebar />
      <div
        className={`flex min-h-screen flex-col transition-[padding] duration-300 ${
          sidebarCollapsed ? 'lg:pl-[4.5rem]' : 'lg:pl-[17.5rem]'
        }`}
      >
        <AdminTopBar />
        <main className="flex-1">
          <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">{children}</div>
        </main>
      </div>
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
