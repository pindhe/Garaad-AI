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
  PanelLeftClose,
  PanelLeftOpen,
  X,
  Sparkles,
} from 'lucide-react';
import { useAdmin } from './AdminContext';
import ThemeToggle from './ThemeToggle';

const navSections = [
  {
    title: 'Overview',
    items: [
      { href: '/', label: 'Dashboard', icon: LayoutDashboard, description: 'Platform overview' },
      { href: '/analytics', label: 'Analytics', icon: BarChart3, description: 'Student progress' },
    ],
  },
  {
    title: 'Management',
    items: [
      { href: '/students', label: 'Students', icon: Users, description: 'User accounts' },
      { href: '/courses', label: 'Courses', icon: BookOpen, description: 'Content library' },
      { href: '/subscriptions', label: 'Subscriptions', icon: CreditCard, description: 'Billing plans' },
    ],
  },
  {
    title: 'AI & Comms',
    items: [
      { href: '/ai', label: 'AI Teacher', icon: Bot, description: 'AI controls', badge: 'Live' },
      { href: '/announcements', label: 'Announcements', icon: Megaphone, description: 'Broadcast messages' },
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

  const width = sidebarCollapsed ? 'w-[4.5rem]' : 'w-[17.5rem]';

  return (
    <>
      {sidebarOpen && (
        <button
          type="button"
          aria-label="Close menu"
          className="fixed inset-0 z-40 bg-slate-950/70 backdrop-blur-sm lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      <aside
        className={`fixed left-0 top-0 z-50 flex h-screen flex-col border-r border-slate-800/60 bg-[#0b0f19] text-white shadow-2xl transition-[width,transform] duration-300 ease-out ${width} ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
        }`}
      >
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_top_left,rgba(59,130,246,0.12),transparent_50%)]" />
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_bottom_right,rgba(139,92,246,0.08),transparent_50%)]" />

        <div
          className={`relative flex shrink-0 items-center border-b border-white/[0.06] ${
            sidebarCollapsed ? 'justify-center px-3 py-4' : 'gap-3 px-4 py-4'
          }`}
        >
          <div className="relative flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-blue-500 via-blue-600 to-indigo-600 shadow-lg shadow-blue-500/30 ring-1 ring-white/10">
            <GraduationCap className="h-5 w-5 text-white" />
            <span className="absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full border-2 border-[#0b0f19] bg-emerald-400" />
          </div>
          {!sidebarCollapsed && (
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-1.5">
                <h1 className="truncate text-base font-bold tracking-tight">MacallinAI</h1>
                <Sparkles className="h-3.5 w-3.5 shrink-0 text-amber-400/90" />
              </div>
              <p className="truncate text-[11px] font-medium uppercase tracking-[0.14em] text-slate-500">
                Admin Console
              </p>
            </div>
          )}
          <button
            type="button"
            onClick={() => setSidebarOpen(false)}
            className="rounded-lg p-1.5 text-slate-500 hover:bg-white/5 hover:text-white lg:hidden"
            aria-label="Close sidebar"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <nav className="relative flex-1 space-y-5 overflow-y-auto px-2.5 py-4 scrollbar-thin">
          {navSections.map((section) => (
            <div key={section.title}>
              {!sidebarCollapsed && (
                <p className="mb-2 px-2.5 text-[10px] font-bold uppercase tracking-[0.16em] text-slate-600">
                  {section.title}
                </p>
              )}
              <div className="space-y-0.5">
                {section.items.map(({ href, label, icon: Icon, description, badge }) => {
                  const active = isActive(pathname, href);
                  return (
                    <Link
                      key={href}
                      href={href}
                      onClick={() => setSidebarOpen(false)}
                      title={sidebarCollapsed ? label : undefined}
                      className={`group relative flex items-center gap-3 rounded-xl px-2.5 py-2.5 transition-all duration-200 ${
                        active
                          ? 'bg-gradient-to-r from-blue-600/90 to-indigo-600/80 text-white shadow-lg shadow-blue-900/40 ring-1 ring-blue-400/20'
                          : 'text-slate-400 hover:bg-white/[0.04] hover:text-slate-100'
                      } ${sidebarCollapsed ? 'justify-center px-2' : ''}`}
                    >
                      <span
                        className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-lg transition-colors ${
                          active
                            ? 'bg-white/15'
                            : 'bg-white/[0.03] group-hover:bg-white/[0.06]'
                        }`}
                      >
                        <Icon className="h-[18px] w-[18px]" />
                      </span>
                      {!sidebarCollapsed && (
                        <div className="min-w-0 flex-1">
                          <div className="flex items-center gap-2">
                            <span className="truncate text-sm font-medium">{label}</span>
                            {badge && (
                              <span className="rounded-md bg-emerald-500/15 px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-wide text-emerald-400">
                                {badge}
                              </span>
                            )}
                          </div>
                          <p className={`truncate text-[11px] ${active ? 'text-blue-100/70' : 'text-slate-600'}`}>
                            {description}
                          </p>
                        </div>
                      )}
                      {active && !sidebarCollapsed && (
                        <span className="h-1.5 w-1.5 shrink-0 rounded-full bg-white/90 shadow-[0_0_8px_rgba(255,255,255,0.8)]" />
                      )}
                    </Link>
                  );
                })}
              </div>
            </div>
          ))}
        </nav>

        <div className="relative shrink-0 border-t border-white/[0.06] p-2.5">
          <Link
            href="/settings"
            onClick={() => setSidebarOpen(false)}
            title={sidebarCollapsed ? 'Settings' : undefined}
            className={`mb-2 flex items-center gap-3 rounded-xl px-2.5 py-2.5 transition-colors ${
              isActive(pathname, '/settings')
                ? 'bg-white/10 text-white'
                : 'text-slate-500 hover:bg-white/[0.04] hover:text-slate-200'
            } ${sidebarCollapsed ? 'justify-center' : ''}`}
          >
            <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-white/[0.03]">
              <Settings className="h-[18px] w-[18px]" />
            </span>
            {!sidebarCollapsed && <span className="text-sm font-medium">Settings</span>}
          </Link>

          {!sidebarCollapsed && user && (
            <div className="mb-2 flex items-center gap-3 rounded-xl border border-white/[0.06] bg-white/[0.03] px-3 py-3">
              <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-blue-500 to-violet-600 text-xs font-bold text-white">
                {getInitials(user.first_name, user.last_name, user.email)}
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold text-white">
                  {user.first_name} {user.last_name}
                </p>
                <p className="truncate text-[11px] text-slate-500">{user.email}</p>
              </div>
            </div>
          )}

          <div className={`flex gap-1.5 ${sidebarCollapsed ? 'flex-col items-center' : ''}`}>
            <ThemeToggle compact className={sidebarCollapsed ? 'w-full' : ''} />
            <button
              type="button"
              onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
              className="hidden flex-1 items-center justify-center gap-2 rounded-xl border border-white/[0.08] bg-white/[0.02] px-2 py-2 text-[11px] font-medium text-slate-500 transition-colors hover:border-white/15 hover:bg-white/[0.05] hover:text-slate-200 lg:flex"
              aria-label={sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
            >
              {sidebarCollapsed ? (
                <PanelLeftOpen className="h-4 w-4" />
              ) : (
                <>
                  <PanelLeftClose className="h-4 w-4" />
                  <span>Collapse</span>
                </>
              )}
            </button>
            <button
              type="button"
              onClick={logout}
              title="Logout"
              className={`flex items-center justify-center gap-2 rounded-xl border border-red-500/20 bg-red-500/10 px-2 py-2 text-[11px] font-medium text-red-300 transition-colors hover:bg-red-500/20 ${
                sidebarCollapsed ? 'h-10 w-10' : 'flex-1'
              }`}
            >
              <LogOut className="h-4 w-4" />
              {!sidebarCollapsed && <span>Logout</span>}
            </button>
          </div>

          {!sidebarCollapsed && (
            <p className="mt-3 text-center text-[10px] text-slate-600">MacallinAI Admin v1.0</p>
          )}
        </div>
      </aside>
    </>
  );
}
