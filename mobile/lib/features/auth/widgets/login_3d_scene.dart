import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Animated 3D background with floating depth layers and a rotating logo cube.
class Login3DScene extends StatefulWidget {
  final Widget child;
  const Login3DScene({super.key, required this.child});

  @override
  State<Login3DScene> createState() => _Login3DSceneState();
}

class _Login3DSceneState extends State<Login3DScene> with TickerProviderStateMixin {
  late AnimationController _orbitCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topGradient = isDark
        ? [const Color(0xFF0F172A), const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
        : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE), const Color(0xFFF8FAFC)];

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: topGradient,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: Listenable.merge([_orbitCtrl, _floatCtrl, _pulseCtrl]),
          builder: (context, _) {
            final t = _orbitCtrl.value * 2 * math.pi;
            final floatY = math.sin(_floatCtrl.value * math.pi) * 12;
            return Stack(
              children: [
                _DepthOrb(left: 30 + math.sin(t) * 20, top: 80 + floatY, size: 120, color: AppColors.primary.withValues(alpha: 0.18), depth: 0.002),
                _DepthOrb(right: 20 + math.cos(t) * 15, top: 160 - floatY, size: 90, color: AppColors.accent.withValues(alpha: 0.15), depth: 0.003),
                _DepthOrb(left: 60 + math.cos(t + 1) * 25, bottom: 120 + floatY, size: 140, color: const Color(0xFF6366F1).withValues(alpha: 0.12), depth: 0.0015),
                Positioned(
                  top: 48,
                  left: 0,
                  right: 0,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(t * 0.4)
                      ..rotateX(0.15 + math.sin(_floatCtrl.value * math.pi) * 0.08),
                    child: _LogoCube(pulse: 0.85 + _pulseCtrl.value * 0.15),
                  ),
                ),
              ],
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _DepthOrb extends StatelessWidget {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double size;
  final Color color;
  final double depth;

  const _DepthOrb({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.size,
    required this.color,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, depth)
          ..rotateZ(0.3),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 40, spreadRadius: 8)],
          ),
        ),
      ),
    );
  }
}

class _LogoCube extends StatelessWidget {
  final double pulse;
  const _LogoCube({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: pulse,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF1D4ED8), Color(0xFF3730A3)],
          ),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 28, offset: const Offset(0, 14)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 6)),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        ),
        child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 42),
      ),
    );
  }
}
