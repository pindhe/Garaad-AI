'use client';

import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { auth, type User } from '@/lib/api';

interface AdminContextValue {
  user: User | null;
  sidebarOpen: boolean;
  setSidebarOpen: (open: boolean) => void;
  sidebarCollapsed: boolean;
  setSidebarCollapsed: (collapsed: boolean) => void;
}

const AdminContext = createContext<AdminContextValue | null>(null);
const SIDEBAR_KEY = 'macallin-admin-sidebar-collapsed';

export function AdminProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsedState] = useState(false);

  useEffect(() => {
    auth.me().then(setUser).catch(() => setUser(null));
    const stored = localStorage.getItem(SIDEBAR_KEY);
    if (stored === 'true') setSidebarCollapsedState(true);
  }, []);

  function setSidebarCollapsed(collapsed: boolean) {
    setSidebarCollapsedState(collapsed);
    localStorage.setItem(SIDEBAR_KEY, String(collapsed));
  }

  return (
    <AdminContext.Provider
      value={{
        user,
        sidebarOpen,
        setSidebarOpen,
        sidebarCollapsed,
        setSidebarCollapsed,
      }}
    >
      {children}
    </AdminContext.Provider>
  );
}

export function useAdmin() {
  const ctx = useContext(AdminContext);
  if (!ctx) throw new Error('useAdmin must be used within AdminProvider');
  return ctx;
}
