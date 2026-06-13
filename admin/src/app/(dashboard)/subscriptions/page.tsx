'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Check,
  CreditCard,
  Crown,
  Loader2,
  Pencil,
  Plus,
  Sparkles,
  Trash2,
  X,
  Zap,
} from 'lucide-react';
import Header from '@/components/Header';
import { api } from '@/lib/api';
import {
  adminAlertError,
  adminAlertSuccess,
  adminCard,
  adminInput,
  adminTextMuted,
  adminTextPrimary,
  adminTextSecondary,
} from '@/lib/admin-ui';

const PLAN_TYPES = ['free', 'pro', 'school', 'university'] as const;
type PlanType = (typeof PLAN_TYPES)[number];

interface Subscription {
  id: number;
  name: string;
  plan_type: PlanType;
  price_monthly: number;
  features: string[] | string;
  is_active: boolean;
}

interface PlanForm {
  name: string;
  planType: PlanType;
  priceMonthly: number;
  featuresText: string;
  isActive: boolean;
}

const emptyForm = (): PlanForm => ({
  name: '',
  planType: 'free',
  priceMonthly: 0,
  featuresText: '',
  isActive: true,
});

function parseFeatures(features: Subscription['features']): string[] {
  if (Array.isArray(features)) return features;
  if (typeof features === 'string') {
    try {
      const parsed = JSON.parse(features);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  return [];
}

function featuresToText(features: Subscription['features']): string {
  return parseFeatures(features).join('\n');
}

function planTheme(planType: string) {
  switch (planType) {
    case 'pro':
      return {
        icon: Zap,
        card: 'border-blue-500/30 bg-gradient-to-br from-blue-500/[0.08] via-slate-900/40 to-slate-900/90 dark:from-blue-500/15 dark:via-slate-900/60 dark:to-[#0b1220]',
        badge: 'bg-blue-500/15 text-blue-400 ring-blue-500/20',
        price: 'text-blue-400',
      };
    case 'school':
      return {
        icon: Sparkles,
        card: 'border-violet-500/30 bg-gradient-to-br from-violet-500/[0.08] via-slate-900/40 to-slate-900/90 dark:from-violet-500/15 dark:via-slate-900/60 dark:to-[#0b1220]',
        badge: 'bg-violet-500/15 text-violet-400 ring-violet-500/20',
        price: 'text-violet-400',
      };
    case 'university':
      return {
        icon: Crown,
        card: 'border-amber-500/30 bg-gradient-to-br from-amber-500/[0.08] via-slate-900/40 to-slate-900/90 dark:from-amber-500/15 dark:via-slate-900/60 dark:to-[#0b1220]',
        badge: 'bg-amber-500/15 text-amber-400 ring-amber-500/20',
        price: 'text-amber-400',
      };
    default:
      return {
        icon: CreditCard,
        card: 'border-slate-500/25 bg-gradient-to-br from-slate-500/[0.06] via-slate-900/40 to-slate-900/90 dark:from-slate-500/10 dark:via-slate-900/60 dark:to-[#0b1220]',
        badge: 'bg-slate-500/15 text-slate-400 ring-slate-500/20',
        price: 'text-slate-300',
      };
  }
}

const btnSecondary =
  'inline-flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-slate-200/80 bg-white/80 px-3 py-2 text-sm font-medium text-slate-700 transition-colors hover:bg-slate-50 dark:border-slate-600/80 dark:bg-slate-800/80 dark:text-slate-200 dark:hover:bg-slate-700/80';

export default function SubscriptionsPage() {
  const [subs, setSubs] = useState<Subscription[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState('');
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [form, setForm] = useState<PlanForm>(emptyForm());

  const usedPlanTypes = useMemo(
    () => new Set(subs.filter((s) => s.id !== editingId).map((s) => s.plan_type)),
    [subs, editingId]
  );

  const activeCount = subs.filter((s) => s.is_active).length;
  const canAdd = PLAN_TYPES.some((t) => !usedPlanTypes.has(t));

  const loadSubs = useCallback(async () => {
    setError('');
    try {
      const data = await api<Subscription[]>('/analytics/subscriptions');
      setSubs(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load subscriptions');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadSubs();
  }, [loadSubs]);

  function flash(msg: string) {
    setError('');
    setMessage(msg);
    setTimeout(() => setMessage(''), 4000);
  }

  function openCreate() {
    const available = PLAN_TYPES.find((t) => !usedPlanTypes.has(t)) ?? 'free';
    setEditingId(null);
    setForm({ ...emptyForm(), planType: available });
    setShowForm(true);
  }

  function openEdit(sub: Subscription) {
    setEditingId(sub.id);
    setForm({
      name: sub.name,
      planType: sub.plan_type,
      priceMonthly: Number(sub.price_monthly),
      featuresText: featuresToText(sub.features),
      isActive: sub.is_active,
    });
    setShowForm(true);
  }

  function closeForm() {
    setShowForm(false);
    setEditingId(null);
    setForm(emptyForm());
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy('save');
    const features = form.featuresText
      .split('\n')
      .map((f) => f.trim())
      .filter(Boolean);

    try {
      const payload = {
        name: form.name,
        planType: form.planType,
        priceMonthly: form.priceMonthly,
        features,
        isActive: form.isActive,
      };

      if (editingId) {
        await api(`/analytics/subscriptions/${editingId}`, {
          method: 'PUT',
          body: JSON.stringify(payload),
        });
        flash('Plan updated successfully');
      } else {
        await api('/analytics/subscriptions', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
        flash('Plan created successfully');
      }

      closeForm();
      await loadSubs();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save plan');
    } finally {
      setBusy('');
    }
  }

  async function handleDelete(sub: Subscription) {
    if (!confirm(`Delete "${sub.name}" plan? This cannot be undone.`)) return;
    setBusy(`delete-${sub.id}`);
    try {
      await api(`/analytics/subscriptions/${sub.id}`, { method: 'DELETE' });
      flash('Plan deleted');
      await loadSubs();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete plan');
    } finally {
      setBusy('');
    }
  }

  async function toggleActive(sub: Subscription) {
    setBusy(`toggle-${sub.id}`);
    try {
      await api(`/analytics/subscriptions/${sub.id}`, {
        method: 'PUT',
        body: JSON.stringify({ isActive: !sub.is_active }),
      });
      flash(sub.is_active ? 'Plan deactivated' : 'Plan activated');
      await loadSubs();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update plan');
    } finally {
      setBusy('');
    }
  }

  return (
    <>
      <Header title="Subscriptions" subtitle="Create, update, and manage subscription plans" />

      <div className={`mb-6 overflow-hidden ${adminCard}`}>
        <div className="flex flex-col gap-4 border-b border-slate-200/80 p-5 sm:flex-row sm:items-center sm:justify-between dark:border-slate-700/80">
          <div className="flex flex-wrap gap-6">
            <div>
              <p className={`text-xs font-medium uppercase tracking-wider ${adminTextMuted}`}>Total plans</p>
              <p className={`text-2xl font-bold ${adminTextPrimary}`}>{subs.length}</p>
            </div>
            <div>
              <p className={`text-xs font-medium uppercase tracking-wider ${adminTextMuted}`}>Active</p>
              <p className="text-2xl font-bold text-emerald-500 dark:text-emerald-400">{activeCount}</p>
            </div>
            <div>
              <p className={`text-xs font-medium uppercase tracking-wider ${adminTextMuted}`}>Plan types</p>
              <p className={`text-2xl font-bold ${adminTextPrimary}`}>4 max</p>
            </div>
          </div>
          <button
            type="button"
            onClick={openCreate}
            disabled={!canAdd}
            className="inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 px-5 py-2.5 text-sm font-semibold text-white shadow-lg shadow-blue-500/20 hover:from-blue-700 hover:to-indigo-700 disabled:cursor-not-allowed disabled:opacity-40"
          >
            <Plus className="h-4 w-4" />
            Add plan
          </button>
        </div>
        <p className={`px-5 py-3 text-sm ${adminTextSecondary}`}>
          Students choose from active plans in the mobile app. Each plan type (free, pro, school, university) can only be used once.
        </p>
      </div>

      {!canAdd && !showForm && (
        <div className="mb-6 rounded-xl border border-amber-500/25 bg-amber-500/10 px-4 py-3 text-sm text-amber-700 dark:text-amber-300">
          All plan types are in use. Edit or delete a plan to add a different one.
        </div>
      )}

      {message && <div className={`mb-6 ${adminAlertSuccess}`}>{message}</div>}
      {error && <div className={`mb-6 ${adminAlertError}`}>{error}</div>}

      {showForm && (
        <form onSubmit={handleSubmit} className={`mb-8 p-6 ${adminCard}`}>
          <div className="mb-6 flex items-center justify-between">
            <div>
              <h3 className={`text-lg font-semibold ${adminTextPrimary}`}>
                {editingId ? 'Edit subscription plan' : 'New subscription plan'}
              </h3>
              <p className={`mt-0.5 text-sm ${adminTextSecondary}`}>
                {editingId ? 'Update pricing, features, and visibility' : 'Configure a new billing tier'}
              </p>
            </div>
            <button
              type="button"
              onClick={closeForm}
              className="rounded-lg p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-200"
            >
              <X className="h-5 w-5" />
            </button>
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <div>
              <label className={`mb-1 block text-sm font-medium ${adminTextSecondary}`}>Plan name</label>
              <input
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                className={adminInput}
                placeholder="e.g. Pro"
                required
              />
            </div>
            <div>
              <label className={`mb-1 block text-sm font-medium ${adminTextSecondary}`}>Plan type</label>
              <select
                value={form.planType}
                onChange={(e) => setForm({ ...form, planType: e.target.value as PlanType })}
                className={adminInput}
                disabled={!!editingId}
              >
                {PLAN_TYPES.map((type) => (
                  <option key={type} value={type} disabled={!editingId && usedPlanTypes.has(type)}>
                    {type}
                    {!editingId && usedPlanTypes.has(type) ? ' (in use)' : ''}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className={`mb-1 block text-sm font-medium ${adminTextSecondary}`}>Monthly price ($)</label>
              <input
                type="number"
                min={0}
                step={0.01}
                value={form.priceMonthly}
                onChange={(e) => setForm({ ...form, priceMonthly: Number(e.target.value) })}
                className={adminInput}
                required
              />
            </div>
            <div className="flex items-end">
              <label className="flex w-full cursor-pointer items-center gap-3 rounded-xl border border-slate-200/80 px-4 py-3 dark:border-slate-600/80 dark:bg-slate-800/40">
                <input
                  type="checkbox"
                  checked={form.isActive}
                  onChange={(e) => setForm({ ...form, isActive: e.target.checked })}
                  className="h-4 w-4 rounded border-slate-300 text-blue-600 dark:border-slate-500"
                />
                <span className={`text-sm font-medium ${adminTextPrimary}`}>Active (visible to students)</span>
              </label>
            </div>
          </div>

          <div className="mt-4">
            <label className={`mb-1 block text-sm font-medium ${adminTextSecondary}`}>Features (one per line)</label>
            <textarea
              value={form.featuresText}
              onChange={(e) => setForm({ ...form, featuresText: e.target.value })}
              className={adminInput}
              rows={5}
              placeholder={'All courses\nUnlimited AI chat\nCertificates'}
            />
          </div>

          <div className="mt-6 flex gap-3">
            <button
              type="submit"
              disabled={busy === 'save'}
              className="rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 px-5 py-2.5 text-sm font-semibold text-white hover:from-blue-700 hover:to-indigo-700 disabled:opacity-60"
            >
              {busy === 'save' ? 'Saving...' : editingId ? 'Update plan' : 'Create plan'}
            </button>
            <button
              type="button"
              onClick={closeForm}
              className="rounded-xl border border-slate-200/80 px-5 py-2.5 text-sm text-slate-600 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-800"
            >
              Cancel
            </button>
          </div>
        </form>
      )}

      {loading ? (
        <div className="flex h-48 items-center justify-center">
          <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
        </div>
      ) : subs.length === 0 ? (
        <div className={`border-dashed px-6 py-16 text-center ${adminCard}`}>
          <CreditCard className={`mx-auto mb-3 h-10 w-10 ${adminTextMuted}`} />
          <p className={`font-medium ${adminTextPrimary}`}>No subscription plans yet</p>
          <button type="button" onClick={openCreate} className="mt-4 text-sm font-medium text-blue-500 hover:underline">
            Create your first plan
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-4">
          {subs.map((s) => {
            const features = parseFeatures(s.features);
            const theme = planTheme(s.plan_type);
            const Icon = theme.icon;
            const isDeleting = busy === `delete-${s.id}`;
            const isToggling = busy === `toggle-${s.id}`;
            const isPopular = s.plan_type === 'pro';

            return (
              <div
                key={s.id}
                className={`relative flex flex-col overflow-hidden rounded-2xl border p-6 shadow-sm transition-all hover:shadow-md dark:shadow-none dark:hover:shadow-lg dark:hover:shadow-black/30 ${theme.card} ${
                  !s.is_active ? 'opacity-60 saturate-50' : ''
                } ${isPopular ? 'ring-1 ring-blue-500/30' : ''}`}
              >
                {isPopular && s.is_active && (
                  <div className="absolute right-4 top-0 rounded-b-lg bg-gradient-to-r from-blue-600 to-indigo-600 px-3 py-1 text-[10px] font-bold uppercase tracking-wider text-white">
                    Popular
                  </div>
                )}

                <div className="mb-5 flex items-start justify-between gap-2">
                  <div className="flex items-start gap-3">
                    <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ring-1 ${theme.badge}`}>
                      <Icon className="h-5 w-5" />
                    </div>
                    <div>
                      <span className={`mb-1 inline-block rounded-md px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider ring-1 ${theme.badge}`}>
                        {s.plan_type}
                      </span>
                      <h3 className={`text-lg font-bold ${adminTextPrimary}`}>{s.name}</h3>
                    </div>
                  </div>
                  <span
                    className={`shrink-0 rounded-full px-2.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide ${
                      s.is_active
                        ? 'bg-emerald-500/15 text-emerald-400 ring-1 ring-emerald-500/25'
                        : 'bg-slate-500/15 text-slate-400 ring-1 ring-slate-500/25'
                    }`}
                  >
                    {s.is_active ? 'Active' : 'Inactive'}
                  </span>
                </div>

                <div className="mb-5">
                  <p className={`text-3xl font-bold tracking-tight ${theme.price}`}>
                    ${Number(s.price_monthly).toFixed(2)}
                  </p>
                  <p className={`text-sm ${adminTextMuted}`}>/month</p>
                </div>

                <ul className="mb-6 flex-1 space-y-2.5">
                  {features.length > 0 ? (
                    features.map((f, i) => (
                      <li key={i} className={`flex items-start gap-2.5 text-sm ${adminTextSecondary}`}>
                        <span className="mt-0.5 flex h-4 w-4 shrink-0 items-center justify-center rounded-full bg-emerald-500/15 text-emerald-500 dark:text-emerald-400">
                          <Check className="h-2.5 w-2.5" />
                        </span>
                        <span>{f}</span>
                      </li>
                    ))
                  ) : (
                    <li className={`text-sm ${adminTextMuted}`}>No features listed</li>
                  )}
                </ul>

                <div className="flex flex-wrap gap-2 border-t border-slate-200/50 pt-4 dark:border-slate-700/50">
                  <button type="button" onClick={() => openEdit(s)} className={btnSecondary}>
                    <Pencil className="h-3.5 w-3.5" />
                    Edit
                  </button>
                  <button
                    type="button"
                    onClick={() => toggleActive(s)}
                    disabled={isToggling}
                    className={btnSecondary}
                  >
                    {isToggling ? '...' : s.is_active ? 'Deactivate' : 'Activate'}
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDelete(s)}
                    disabled={isDeleting}
                    className="inline-flex items-center justify-center rounded-xl border border-red-500/25 bg-red-500/10 px-3 py-2 text-red-500 transition-colors hover:bg-red-500/20 dark:text-red-400"
                    aria-label={`Delete ${s.name}`}
                  >
                    {isDeleting ? <Loader2 className="h-4 w-4 animate-spin" /> : <Trash2 className="h-4 w-4" />}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </>
  );
}
