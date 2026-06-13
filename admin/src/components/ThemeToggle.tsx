'use client';

import { Moon, Sun } from 'lucide-react';
import { useTheme } from './ThemeProvider';

interface ThemeToggleProps {
  compact?: boolean;
  className?: string;
}

export default function ThemeToggle({ compact = false, className = '' }: ThemeToggleProps) {
  const { theme, toggleTheme, mounted } = useTheme();
  const isDark = theme === 'dark';

  return (
    <button
      type="button"
      onClick={toggleTheme}
      aria-label={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
      className={`relative inline-flex items-center justify-center rounded-xl border transition-all ${
        compact
          ? 'h-10 w-10 border-white/10 bg-white/5 text-slate-300 hover:bg-white/10 hover:text-white'
          : 'h-10 w-10 border-slate-200 bg-white text-slate-600 shadow-sm hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700'
      } ${className}`}
    >
      {!mounted ? (
        <span className="h-4 w-4 rounded-full bg-current opacity-20" />
      ) : isDark ? (
        <Sun className="h-4 w-4 text-amber-400" />
      ) : (
        <Moon className="h-4 w-4 text-indigo-600" />
      )}
    </button>
  );
}
