'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { CreditCard, Loader2, Pencil, Plus, Trash2, X } from 'lucide-react';
import Header from '@/components/Header';
import { api } from '@/lib/api';

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

const inputClass =
  'w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20';

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

function planAccent(planType: string) {
  switch (planType) {
    case 'pro':
      return 'border-blue-500 ring-1 ring-blue-100 bg-gradient-to-b from-blue-50 to-white';
    case 'school':
      return 'border-violet-400 ring-1 ring-violet-100 bg-gradient-to-b from-violet-50 to-white';
    case 'university':
      return 'border-amber-400 ring-1 ring-amber-100 bg-gradient-to-b from-amber-50 to-white';
    default:
      return 'border-slate-200 bg-white';
  }
}

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

  const canAdd = PLAN_TYPES.some((t) => !usedPlanTypes.has(t));

  return (
    <>
      <Header title="Subscriptions" subtitle="Create, update, and manage subscription plans" />

      <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-sm text-slate-500">
          {subs.length} plan{subs.length !== 1 ? 's' : ''} · Students choose from active plans in the mobile app
        </p>
        <button
          type="button"
          onClick={openCreate}
          disabled={!canAdd}
          className="inline-flex items-center justify-center gap-2 rounded-xl bg-blue-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
        >
          <Plus className="h-4 w-4" />
          Add plan
        </button>
      </div>

      {!canAdd && !showForm && (
        <p className="mb-4 text-sm text-amber-700">
          All plan types (free, pro, school, university) are in use. Edit or delete a plan to add a different one.
        </p>
      )}

      {(message || error) && (
        <div
          className={`mb-6 rounded-xl px-4 py-3 text-sm ${
            error ? 'border border-red-200 bg-red-50 text-red-700' : 'border border-emerald-200 bg-emerald-50 text-emerald-700'
          }`}
        >
          {error || message}
        </div>
      )}

      {showForm && (
        <form
          onSubmit={handleSubmit}
          className="mb-8 rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm"
        >
          <div className="mb-6 flex items-center justify-between">
            <h3 className="text-lg font-semibold text-slate-900">
              {editingId ? 'Edit subscription plan' : 'New subscription plan'}
            </h3>
            <button
              type="button"
              onClick={closeForm}
              className="rounded-lg p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600"
            >
              <X className="h-5 w-5" />
            </button>
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">Plan name</label>
              <input
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                className={inputClass}
                placeholder="e.g. Pro"
                required
              />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">Plan type</label>
              <select
                value={form.planType}
                onChange={(e) => setForm({ ...form, planType: e.target.value as PlanType })}
                className={inputClass}
                disabled={!!editingId}
              >
                {PLAN_TYPES.map((type) => (
                  <option key={type} value={type} disabled={!editingId && usedPlanTypes.has(type)}>
                    {type}
                    {!editingId && usedPlanTypes.has(type) ? ' (in use)' : ''}
                  </option>
                ))}
              </select>
              {editingId && (
                <p className="mt-1 text-xs text-slate-400">Plan type cannot be changed after creation.</p>
              )}
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">Monthly price ($)</label>
              <input
                type="number"
                min={0}
                step={0.01}
                value={form.priceMonthly}
                onChange={(e) => setForm({ ...form, priceMonthly: Number(e.target.value) })}
                className={inputClass}
                required
              />
            </div>
            <div className="flex items-end">
              <label className="flex cursor-pointer items-center gap-3 rounded-xl border border-slate-200 px-4 py-3">
                <input
                  type="checkbox"
                  checked={form.isActive}
                  onChange={(e) => setForm({ ...form, isActive: e.target.checked })}
                  className="h-4 w-4 rounded border-slate-300 text-blue-600"
                />
                <span className="text-sm font-medium text-slate-700">Active (visible to students)</span>
              </label>
            </div>
          </div>

          <div className="mt-4">
            <label className="mb-1 block text-sm font-medium text-slate-700">Features (one per line)</label>
            <textarea
              value={form.featuresText}
              onChange={(e) => setForm({ ...form, featuresText: e.target.value })}
              className={inputClass}
              rows={5}
              placeholder={'All courses\nUnlimited AI chat\nCertificates'}
            />
          </div>

          <div className="mt-6 flex gap-3">
            <button
              type="submit"
              disabled={busy === 'save'}
              className="rounded-xl bg-blue-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-60"
            >
              {busy === 'save' ? 'Saving...' : editingId ? 'Update plan' : 'Create plan'}
            </button>
            <button
              type="button"
              onClick={closeForm}
              className="rounded-xl border border-slate-200 px-5 py-2.5 text-sm text-slate-600 hover:bg-slate-50"
            >
              Cancel
            </button>
          </div>
        </form>
      )}

      {loading ? (
        <div className="flex h-48 items-center justify-center">
          <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
        </div>
      ) : subs.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-slate-200 bg-white px-6 py-16 text-center">
          <CreditCard className="mx-auto mb-3 h-10 w-10 text-slate-300" />
          <p className="font-medium text-slate-600">No subscription plans yet</p>
          <button type="button" onClick={openCreate} className="mt-4 text-sm font-medium text-blue-600 hover:underline">
            Create your first plan
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-4">
          {subs.map((s) => {
            const features = parseFeatures(s.features);
            const isDeleting = busy === `delete-${s.id}`;
            const isToggling = busy === `toggle-${s.id}`;

            return (
              <div
                key={s.id}
                className={`relative flex flex-col rounded-2xl border p-6 shadow-sm ${planAccent(s.plan_type)} ${
                  !s.is_active ? 'opacity-70' : ''
                }`}
              >
                <div className="mb-4 flex items-start justify-between gap-2">
                  <div>
                    <span className="mb-2 inline-block rounded-full bg-slate-100 px-2.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-slate-600">
                      {s.plan_type}
                    </span>
                    <h3 className="text-xl font-bold text-slate-900">{s.name}</h3>
                  </div>
                  <span
                    className={`shrink-0 rounded-full px-2.5 py-0.5 text-xs font-medium ${
                      s.is_active ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-200 text-slate-600'
                    }`}
                  >
                    {s.is_active ? 'Active' : 'Inactive'}
                  </span>
                </div>

                <p className="text-3xl font-bold text-blue-600">
                  ${Number(s.price_monthly).toFixed(2)}
                  <span className="text-sm font-normal text-slate-500">/mo</span>
                </p>

                <ul className="mt-4 flex-1 space-y-2">
                  {features.length > 0 ? (
                    features.map((f, i) => (
                      <li key={i} className="flex items-start gap-2 text-sm text-slate-600">
                        <span className="mt-0.5 text-emerald-500">✓</span>
                        <span>{f}</span>
                      </li>
                    ))
                  ) : (
                    <li className="text-sm text-slate-400">No features listed</li>
                  )}
                </ul>

                <div className="mt-6 flex flex-wrap gap-2 border-t border-slate-100 pt-4">
                  <button
                    type="button"
                    onClick={() => openEdit(s)}
                    className="inline-flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                  >
                    <Pencil className="h-3.5 w-3.5" />
                    Edit
                  </button>
                  <button
                    type="button"
                    onClick={() => toggleActive(s)}
                    disabled={isToggling}
                    className="inline-flex flex-1 items-center justify-center rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-60"
                  >
                    {isToggling ? '...' : s.is_active ? 'Deactivate' : 'Activate'}
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDelete(s)}
                    disabled={isDeleting}
                    className="inline-flex items-center justify-center rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm font-medium text-red-600 hover:bg-red-100 disabled:opacity-60"
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
