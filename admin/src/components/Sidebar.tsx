'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  LayoutDashboard,
  Users,
  BookOpen,
  Bot,
  BarChart3,
  CreditCard,
  Megaphone,
  Settings,
  GraduationCap,
  LogOut,
  ChevronLeft,
  ChevronRight,
  X,
  Sparkles,
} from 'lucide-react';
import { useAdmin } from './AdminContext';

const navSections = [
  {
    title: 'Overview',
    items: [
      { href: '/', label: 'Dashboard', icon: LayoutDashboard },
      { href: '/analytics', label: 'Analytics', icon: BarChart3 },
    ],
  },
  {
    title: 'Management',
    items: [
      { href: '/students', label: 'Students', icon: Users },
      { href: '/courses', label: 'Courses', icon: BookOpen },
      { href: '/subscriptions', label: 'Subscriptions', icon: CreditCard },
    ],
  },
  {
    title: 'AI & Comms',
    items: [
      { href: '/ai', label: 'AI Teacher', icon: Bot, badge: 'Live' },
      { href: '/announcements', label: 'Announcements', icon: Megaphone },
    ],
  },
];

function isActive(pathname: string, href: string) {
  if (href === '/') return pathname === '/';
  return pathname === href || pathname.startsWith(`${href}/`);
}

function getInitials(firstName?: string, lastName?: string, email?: string) {
  const first = firstName?.charAt(0) ?? '';
  const last = lastName?.charAt(0) ?? '';
  if (first || last) return `${first}${last}`.toUpperCase();
  return email?.charAt(0).toUpperCase() ?? 'A';
}

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, sidebarOpen, setSidebarOpen, sidebarCollapsed, setSidebarCollapsed } = useAdmin();

  function logout() {
    localStorage.removeItem('token');
    router.push('/login');
  }

  const sidebarWidth = sidebarCollapsed ? 'w-20' : 'w-72';

  return (
    <>
      {sidebarOpen && (
        <button
          type="button"
          aria-label="Close menu"
          className="fixed inset-0 z-40 bg-slate-900/60 backdrop-blur-sm lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      <aside
        className={`fixed left-0 top-0 z-50 flex h-screen flex-col border-r border-slate-800/80 bg-gradient-to-b from-slate-950 via-slate-900 to-slate-950 text-white shadow-2xl transition-all duration-300 ${sidebarWidth} ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
        }`}
      >
        <div className={`flex items-center border-b border-slate-800/80 ${sidebarCollapsed ? 'justify-center px-3 py-5' : 'gap-3 px-5 py-5'}`}>
          <div className="relative flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600 shadow-lg shadow-blue-500/25">
            <GraduationCap className="h-6 w-6 text-white" />
            <span className="absolute -right-0.5 -top-0.5 flex h-3 w-3">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-60" />
              <span className="relative inline-flex h-3 w-3 rounded-full bg-emerald-400 ring-2 ring-slate-900" />
            </span>
          </div>
          {!sidebarCollapsed && (
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-1.5">
                <h1 className="truncate text-lg font-bold tracking-tight">MacallinAI</h1>
                <Sparkles className="h-3.5 w-3.5 shrink-0 text-amber-400" />
              </div>
              <p className="truncate text-xs text-slate-400">Admin Control Center</p>
            </div>
          )}
          <button
            type="button"
            onClick={() => setSidebarOpen(false)}
            className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-800 hover:text-white lg:hidden"
            aria-label="Close sidebar"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <nav className="flex-1 space-y-6 overflow-y-auto px-3 py-5 scrollbar-thin">
          {navSections.map((section) => (
            <div key={section.title}>
              {!sidebarCollapsed && (
                <p className="mb-2 px-3 text-[10px] font-semibold uppercase tracking-widest text-slate-500">
                  {section.title}
                </p>
              )}
              <div className="space-y-1">
                {section.items.map(({ href, label, icon: Icon, badge }) => {
                  const active = isActive(pathname, href);
                  return (
                    <Link
                      key={href}
                      href={href}
                      onClick={() => setSidebarOpen(false)}
                      title={sidebarCollapsed ? label : undefined}
                      className={`group relative flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-all ${
                        active
                          ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/30'
                          : 'text-slate-300 hover:bg-slate-800/80 hover:text-white'
                      } ${sidebarCollapsed ? 'justify-center px-2' : ''}`}
                    >
                      {active && (
                        <span className="absolute left-0 top-1/2 h-6 w-1 -translate-y-1/2 rounded-r-full bg-white/90" />
                      )}
                      <Icon className={`h-5 w-5 shrink-0 ${active ? 'text-white' : 'text-slate-400 group-hover:text-white'}`} />
                      {!sidebarCollapsed && (
                        <>
                          <span className="flex-1 truncate">{label}</span>
                          {badge && (
                            <span className="rounded-full bg-emerald-500/20 px-2 py-0.5 text-[10px] font-semibold text-emerald-300">
                              {badge}
                            </span>
                          )}
                        </>
                      )}
                    </Link>
                  );
                })}
              </div>
            </div>
          ))}
        </nav>

        <div className="border-t border-slate-800/80 p-3">
          <Link
            href="/settings"
            onClick={() => setSidebarOpen(false)}
            title={sidebarCollapsed ? 'Settings' : undefined}
            className={`mb-2 flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors ${
              isActive(pathname, '/settings')
                ? 'bg-blue-600 text-white'
                : 'text-slate-400 hover:bg-slate-800/80 hover:text-white'
            } ${sidebarCollapsed ? 'justify-center' : ''}`}
          >
            <Settings className="h-5 w-5 shrink-0" />
            {!sidebarCollapsed && <span>Settings</span>}
          </Link>

          {!sidebarCollapsed && user && (
            <div className="mb-2 flex items-center gap-3 rounded-xl bg-slate-800/50 px-3 py-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-blue-500 to-violet-600 text-sm font-bold text-white">
                {getInitials(user.first_name, user.last_name, user.email)}
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold text-white">
                  {user.first_name} {user.last_name}
                </p>
                <p className="truncate text-xs text-slate-400">{user.email}</p>
              </div>
            </div>
          )}

          <div className={`flex gap-2 ${sidebarCollapsed ? 'flex-col' : ''}`}>
            <button
              type="button"
              onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
              className="hidden flex-1 items-center justify-center gap-2 rounded-xl border border-slate-700/80 px-3 py-2 text-xs font-medium text-slate-400 transition-colors hover:border-slate-600 hover:bg-slate-800 hover:text-white lg:flex"
              aria-label={sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
            >
              {sidebarCollapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
              {!sidebarCollapsed && <span>Collapse</span>}
            </button>
            <button
              type="button"
              onClick={logout}
              title="Logout"
              className={`flex items-center justify-center gap-2 rounded-xl bg-red-500/10 px-3 py-2 text-xs font-medium text-red-300 transition-colors hover:bg-red-500/20 hover:text-red-200 ${
                sidebarCollapsed ? 'w-full' : 'flex-1'
              }`}
            >
              <LogOut className="h-4 w-4" />
              {!sidebarCollapsed && <span>Logout</span>}
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}
