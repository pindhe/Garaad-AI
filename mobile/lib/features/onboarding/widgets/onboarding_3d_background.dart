import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class Onboarding3DBackground extends StatefulWidget {
  final int pageIndex;
  final Color accentColor;
  final Widget child;

  const Onboarding3DBackground({
    super.key,
    required this.pageIndex,
    required this.accentColor,
    required this.child,
  });

  @override
  State<Onboarding3DBackground> createState() => _Onboarding3DBackgroundState();
}

class _Onboarding3DBackgroundState extends State<Onboarding3DBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value * 2 * math.pi;
        final pageShift = widget.pageIndex * 0.4;

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0F172A), widget.accentColor.withValues(alpha: 0.35), const Color(0xFF0F172A)]
                      : [const Color(0xFFEFF6FF), widget.accentColor.withValues(alpha: 0.15), const Color(0xFFF8FAFC)],
                ),
              ),
            ),
            Positioned(
              left: 40 + math.sin(t + pageShift) * 30,
              top: 100 + math.cos(t) * 20,
              child: _Orb(size: 100, color: widget.accentColor.withValues(alpha: 0.2), rotate: t),
            ),
            Positioned(
              right: 30 + math.cos(t + pageShift) * 25,
              top: 200 + math.sin(t) * 15,
              child: _Orb(size: 70, color: AppColors.primary.withValues(alpha: 0.15), rotate: -t * 0.7),
            ),
            Positioned(
              left: 80 + math.cos(t * 0.8) * 20,
              bottom: 180 + math.sin(t + pageShift) * 18,
              child: _Orb(size: 120, color: AppColors.accent.withValues(alpha: 0.12), rotate: t * 0.5),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double rotate;

  const _Orb({required this.size, required this.color, required this.rotate});

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateZ(rotate * 0.3),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// 3D icon card with entrance animation
class Onboarding3DIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double pageOffset;
  final Animation<double> animation;

  const Onboarding3DIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.pageOffset,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final tilt = math.sin(animation.value * math.pi) * 0.12 + pageOffset * 0.05;
        final scale = 0.85 + animation.value * 0.15;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(tilt)
            ..rotateX(-tilt * 0.6),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 32, offset: const Offset(0, 16)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 6)),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
              ),
              child: Icon(icon, size: 64, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
