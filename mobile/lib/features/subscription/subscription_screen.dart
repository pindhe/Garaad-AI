import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/glass_card.dart';
import '../auth/widgets/auth_form_widgets.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<dynamic> _plans = [];
  bool _loading = true;
  bool _upgrading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _plans = await context.read<AuthProvider>().api.getSubscriptions();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  String _currentPlan() {
    final student = context.read<AuthProvider>().user?['student'] as Map<String, dynamic>?;
    return student?['subscription_plan']?.toString() ?? 'free';
  }

  List<String> _features(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    try {
      final parsed = jsonDecode(raw.toString());
      if (parsed is List) return parsed.map((e) => e.toString()).toList();
    } catch (_) {}
    return [];
  }

  Future<void> _selectPlan(String planType) async {
    if (planType == _currentPlan()) return;
    setState(() => _upgrading = true);
    try {
      await context.read<AuthProvider>().api.updateSubscription(planType);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plan updated to ${planType.toUpperCase()}')),
        );
        setState(() => _upgrading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _upgrading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentPlan();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppPageScaffold(
      title: 'Subscription',
      subtitle: 'Choose the plan that fits your learning',
      headerColor: const Color(0xFF7C3AED),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(icon: Icons.cloud_off_outlined, title: 'Could not load plans', subtitle: _error!, action: FilledButton(onPressed: _load, child: const Text('Retry')))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      GlassCard(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withValues(alpha: 0.9), const Color(0xFF1D4ED8)],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.white, size: 32),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Current plan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text(current.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._plans.map((p) {
                        final plan = p as Map<String, dynamic>;
                        final type = plan['plan_type']?.toString() ?? '';
                        final isCurrent = type == current;
                        final price = double.tryParse(plan['price_monthly']?.toString() ?? '0') ?? 0;
                        final features = _features(plan['features']);
                        final isPro = type == 'pro';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: GlassCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(plan['name']?.toString() ?? type, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                              if (isPro) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                                  child: const Text('Popular', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            price == 0 ? 'Free forever' : '\$${price.toStringAsFixed(2)}/month',
                                            style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('Active', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 12)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                ...features.map((f) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded, size: 18, color: isCurrent ? AppColors.primary : AppColors.textSecondary),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                                        ],
                                      ),
                                    )),
                                const SizedBox(height: 14),
                                if (isCurrent)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: OutlinedButton(onPressed: null, child: const Text('Current Plan')),
                                  )
                                else
                                  AuthGradientButton(
                                    loading: _upgrading,
                                    onPressed: () => _selectPlan(type),
                                    label: price == 0 ? 'Switch to Free' : 'Upgrade',
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Text(
                        'Demo mode: upgrades are recorded instantly without payment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
    );
  }
}
