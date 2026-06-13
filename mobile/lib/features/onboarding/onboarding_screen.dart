import 'package:flutter/material.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/services/public_api.dart';
import '../../../core/theme/app_theme.dart';
import 'onboarding_data.dart';
import 'widgets/onboarding_3d_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final _pageController = PageController();
  late AnimationController _entranceCtrl;
  late AnimationController _iconCtrl;

  int _page = 0;
  PlatformStats _stats = const PlatformStats();
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _iconCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await PublicApi.fetchStats();
    if (mounted) setState(() { _stats = stats; _statsLoading = false; });
  }

  Future<void> _finish() async {
    await OnboardingService.markCompleted();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _next() {
    if (_page < onboardingPages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = onboardingPages[_page];

    return Scaffold(
      body: Onboarding3DBackground(
        pageIndex: _page,
        accentColor: current.color,
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut),
            child: Column(
              children: [
                _TopBar(
                  stats: _stats,
                  loading: _statsLoading,
                  onSkip: _finish,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: onboardingPages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double offset = 0;
                          if (_pageController.position.haveDimensions) {
                            offset = (_pageController.page ?? index.toDouble()) - index;
                          }
                          final rotateY = offset.clamp(-1.0, 1.0) * -0.35;
                          final scale = 1 - (offset.abs() * 0.08);

                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(rotateY),
                            child: Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: (1 - offset.abs()).clamp(0.4, 1.0),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: _OnboardSlide(
                          model: onboardingPages[index],
                          stats: _stats,
                          iconAnimation: _iconCtrl,
                          pageOffset: index - _page.toDouble(),
                        ),
                      );
                    },
                  ),
                ),
                _PageIndicator(count: onboardingPages.length, index: _page),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: Column(
                    children: [
                      _PrimaryButton(
                        label: _page < onboardingPages.length - 1 ? 'Continue' : 'Get Started',
                        color: current.color,
                        onPressed: _next,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text(
                          'Already have an account? Sign in',
                          style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final PlatformStats stats;
  final bool loading;
  final VoidCallback onSkip;

  const _TopBar({required this.stats, required this.loading, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  stats.platform,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (!loading && !stats.offline)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Live', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          TextButton(onPressed: onSkip, child: const Text('Skip')),
        ],
      ),
    );
  }
}

class _OnboardSlide extends StatelessWidget {
  final OnboardingPageModel model;
  final PlatformStats stats;
  final Animation<double> iconAnimation;
  final double pageOffset;

  const _OnboardSlide({
    required this.model,
    required this.stats,
    required this.iconAnimation,
    required this.pageOffset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statVal = model.statValue(stats);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Onboarding3DIcon(
            icon: model.icon,
            color: model.color,
            pageOffset: pageOffset,
            animation: iconAnimation,
          ),
          const SizedBox(height: 36),
          _LiveStatBadge(
            label: model.statLabel,
            value: stats.offline ? '—' : _formatStat(statVal),
            color: model.color,
            offline: stats.offline,
          ),
          const SizedBox(height: 28),
          Text(
            model.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            model.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStat(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k+';
    if (n > 0) return '$n+';
    return 'New';
  }
}

class _LiveStatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool offline;

  const _LiveStatBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.offline,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textPrimary)),
              Text(
                offline ? 'Connect backend for live data' : 'Real-time from platform',
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int index;

  const _PageIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: active ? 32 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: active
                ? const LinearGradient(colors: [AppColors.primary, Color(0xFF1D4ED8)])
                : null,
            color: active ? null : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, 0.15)!]),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Center(
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
