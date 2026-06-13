'use client';

import { adminTextPrimary, adminTextSecondary } from '@/lib/admin-ui';

interface HeaderProps {
  title: string;
  subtitle?: string;
}

export default function Header({ title, subtitle }: HeaderProps) {
  const today = new Date().toLocaleDateString('en-US', {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
  });

  return (
    <div className="mb-8">
      <p className="mb-1 text-xs font-medium uppercase tracking-wider text-slate-400 dark:text-slate-500">
        {today}
      </p>
      <h1 className={`text-2xl font-bold tracking-tight sm:text-3xl ${adminTextPrimary}`}>{title}</h1>
      {subtitle && <p className={`mt-1 max-w-xl text-sm ${adminTextSecondary}`}>{subtitle}</p>}
    </div>
  );
}
