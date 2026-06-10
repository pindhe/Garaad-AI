'use client';

import { useEffect, useState } from 'react';
import Header from '@/components/Header';
import { api } from '@/lib/api';

interface Subscription {
  id: number;
  name: string;
  plan_type: string;
  price_monthly: number;
  features: string;
  is_active: boolean;
}

export default function SubscriptionsPage() {
  const [subs, setSubs] = useState<Subscription[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api<Subscription[]>('/analytics/subscriptions')
      .then(setSubs)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  return (
    <>
      <Header title="Subscriptions" subtitle="Manage subscription plans" />

      <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
        {loading ? (
          <p className="text-slate-400">Loading...</p>
        ) : (
          subs.map((s) => {
            const features = typeof s.features === 'string' ? JSON.parse(s.features) : s.features;
            return (
              <div
                key={s.id}
                className={`rounded-2xl border p-6 shadow-sm ${
                  s.plan_type === 'pro' ? 'border-blue-500 bg-blue-50' : 'border-slate-200 bg-white'
                }`}
              >
                <h3 className="text-xl font-bold text-slate-900">{s.name}</h3>
                <p className="mt-2 text-3xl font-bold text-blue-600">
                  ${Number(s.price_monthly).toFixed(2)}
                  <span className="text-sm font-normal text-slate-500">/mo</span>
                </p>
                <ul className="mt-4 space-y-2">
                  {(features as string[]).map((f, i) => (
                    <li key={i} className="flex items-center gap-2 text-sm text-slate-600">
                      <span className="text-green-500">✓</span> {f}
                    </li>
                  ))}
                </ul>
              </div>
            );
          })
        )}
      </div>
    </>
  );
}
