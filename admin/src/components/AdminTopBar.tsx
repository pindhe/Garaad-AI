'use client';

import { usePathname } from 'next/navigation';
import { Bell, Menu, Search } from 'lucide-react';
import { useAdmin } from './AdminContext';
import ThemeToggle from './ThemeToggle';

const routeLabels: Record<string, string> = {
  '/': 'Dashboard',
  '/students': 'Students',
  '/courses': 'Courses',
  '/ai': 'AI Teacher',
  '/analytics': 'Analytics',
  '/subscriptions': 'Subscriptions',
  '/announcements': 'Announcements',
  '/settings': 'Settings',
};

function getBreadcrumb(pathname: string) {
  if (pathname === '/') return [{ label: 'Dashboard', href: '/' }];
  if (pathname.startsWith('/courses/')) {
    return [
      { label: 'Courses', href: '/courses' },
      { label: 'Manage', href: pathname },
    ];
  }
  const label = routeLabels[pathname] ?? 'Admin';
  return [{ label, href: pathname }];
}

export default function AdminTopBar() {
  const pathname = usePathname();
  const { user, setSidebarOpen } = useAdmin();
  const crumbs = getBreadcrumb(pathname);

  return (
    <header className="sticky top-0 z-30 border-b border-slate-200/80 bg-white/80 backdrop-blur-xl dark:border-slate-800/80 dark:bg-slate-950/80">
      <div className="flex h-16 items-center gap-3 px-4 sm:px-6 lg:px-8">
        <button
          type="button"
          onClick={() => setSidebarOpen(true)}
          className="rounded-xl border border-slate-200 p-2.5 text-slate-600 hover:bg-slate-50 lg:hidden dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
          aria-label="Open menu"
        >
          <Menu className="h-5 w-5" />
        </button>

        <div className="hidden min-w-0 flex-1 items-center gap-2 text-sm lg:flex">
          <span className="font-semibold text-slate-900 dark:text-white">MacallinAI</span>
          <span className="text-slate-300 dark:text-slate-600">/</span>
          {crumbs.map((crumb, i) => (
            <span key={crumb.href} className="flex items-center gap-2">
              {i > 0 && <span className="text-slate-300 dark:text-slate-600">/</span>}
              <span
                className={
                  i === crumbs.length - 1
                    ? 'truncate font-medium text-slate-600 dark:text-slate-300'
                    : 'truncate text-slate-400 dark:text-slate-500'
                }
              >
                {crumb.label}
              </span>
            </span>
          ))}
        </div>

        <div className="relative mx-auto hidden max-w-md flex-1 lg:block">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <input
            type="search"
            placeholder="Search students, courses..."
            className="h-10 w-full rounded-xl border border-slate-200 bg-slate-50 pl-10 pr-4 text-sm text-slate-700 placeholder:text-slate-400 focus:border-blue-500 focus:bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200 dark:placeholder:text-slate-500 dark:focus:bg-slate-900"
          />
        </div>

        <div className="ml-auto flex items-center gap-2 sm:gap-3">
          <ThemeToggle />
          <button
            type="button"
            className="relative rounded-xl border border-slate-200 p-2.5 text-slate-500 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-400 dark:hover:bg-slate-800"
            aria-label="Notifications"
          >
            <Bell className="h-5 w-5" />
            <span className="absolute right-2 top-2 h-2 w-2 rounded-full bg-blue-500 ring-2 ring-white dark:ring-slate-950" />
          </button>
          {user && (
            <div className="hidden items-center gap-2.5 rounded-xl border border-slate-200 py-1.5 pl-1.5 pr-3 sm:flex dark:border-slate-700 dark:bg-slate-900/50">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-blue-500 to-indigo-600 text-xs font-bold text-white">
                {user.first_name?.charAt(0)}
                {user.last_name?.charAt(0)}
              </div>
              <div className="hidden text-left md:block">
                <p className="text-xs font-semibold leading-tight text-slate-900 dark:text-white">
                  {user.first_name} {user.last_name}
                </p>
                <p className="text-[10px] capitalize text-slate-500 dark:text-slate-400">{user.role}</p>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
