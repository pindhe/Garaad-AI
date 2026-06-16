import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Mobile-first auth background with soft animated blobs.
class AuthMobileBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? gradientColors;

  const AuthMobileBackground({super.key, required this.child, this.gradientColors});

  @override
  State<AuthMobileBackground> createState() => _AuthMobileBackgroundState();
}

class _AuthMobileBackgroundState extends State<AuthMobileBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = widget.gradientColors ??
        (isDark
            ? [const Color(0xFF0F172A), const Color(0xFF1E3A8A), const Color(0xFF312E81)]
            : [const Color(0xFF2563EB), const Color(0xFF4F46E5), const Color(0xFF7C3AED)]);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value * 2 * math.pi;
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
            ),
            Positioned(
              top: -40 + math.sin(t) * 20,
              right: -30,
              child: _Blob(size: 180, color: Colors.white.withValues(alpha: 0.12)),
            ),
            Positioned(
              top: 120 + math.cos(t) * 15,
              left: -50,
              child: _Blob(size: 140, color: Colors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              bottom: 200,
              right: 20,
              child: _Blob(size: 100, color: AppColors.accent.withValues(alpha: 0.15)),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class AuthHeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool apiOnline;
  final VoidCallback? onBack;
  final bool compact;

  const AuthHeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.apiOnline,
    this.onBack,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 26.0 : 32.0;
    final topGap = compact ? 16.0 : 28.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, compact ? 8 : 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15)),
                )
              else
                Container(
                  padding: EdgeInsets.all(compact ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.auto_stories_rounded, color: Colors.white, size: compact ? 22 : 26),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: apiOnline ? const Color(0xFF4ADE80) : Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      apiOnline ? 'Online' : 'Offline',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: topGap),
          Text(
            'MacallinAI',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: compact ? 12 : 14, fontWeight: FontWeight.w600, letterSpacing: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: titleSize, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: compact ? 13 : 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class AuthFormSheet extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const AuthFormSheet({super.key, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, -8)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 28 + bottomInset),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCompactStats extends StatelessWidget {
  final int students;
  final int courses;
  final int aiToday;

  const AuthCompactStats({super.key, required this.students, required this.courses, required this.aiToday});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(icon: Icons.people_rounded, value: '$students', label: 'Students'),
        const SizedBox(width: 8),
        _Chip(icon: Icons.menu_book_rounded, value: '$courses', label: 'Courses'),
        const SizedBox(width: 8),
        _Chip(icon: Icons.smart_toy_rounded, value: '$aiToday', label: 'AI today'),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Chip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class AuthStepIndicator extends StatelessWidget {
  final int total;
  final int current;

  const AuthStepIndicator({super.key, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i <= current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: i == current ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class AuthSocialDivider extends StatelessWidget {
  const AuthSocialDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }
}

class AuthLinkRow extends StatelessWidget {
  final String prompt;
  final String action;
  final VoidCallback onTap;

  const AuthLinkRow({super.key, required this.prompt, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: RichText(
          text: TextSpan(
            style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary, fontSize: 14),
            children: [
              TextSpan(text: '$prompt '),
              TextSpan(text: action, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
