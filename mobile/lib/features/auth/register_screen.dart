import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/public_api.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/auth_form_widgets.dart';
import 'widgets/login_3d_scene.dart';
import 'widgets/login_stats_strip.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _gradeLevel = TextEditingController();

  late AnimationController _entranceCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _cardTiltCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _shakeAnim;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _apiOnline = false;
  String? _error;
  PlatformStats _stats = const PlatformStats();

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _cardTiltCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _entranceCtrl.forward();
    _loadLiveData();
  }

  Future<void> _loadLiveData() async {
    final online = await PublicApi.checkHealth();
    final stats = await PublicApi.fetchStats();
    if (mounted) {
      setState(() {
        _apiOnline = online;
        _stats = stats;
      });
    }
  }

  InputDecoration _fieldDecoration({required String label, required IconData icon, required bool isDark, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: isDark ? AppColors.darkSurface : Colors.white,
      suffixIcon: suffix,
    );
  }

  Future<void> _register() async {
    if (!_acceptedTerms) {
      setState(() => _error = 'Please accept the terms to continue');
      _triggerShake();
      return;
    }
    if (!_formKey.currentState!.validate()) {
      _triggerShake();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().register(
            email: _email.text.trim(),
            password: _password.text,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            gradeLevel: _gradeLevel.text.trim().isEmpty ? null : _gradeLevel.text.trim(),
          );
      if (mounted) {
        await _entranceCtrl.reverse();
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _triggerShake();
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _triggerShake() {
    _shakeCtrl.forward(from: 0);
  }

  double _shakeOffset() {
    if (!_shakeCtrl.isAnimating) return 0;
    return math.sin(_shakeAnim.value * math.pi * 4) * 8 * (1 - _shakeAnim.value);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _gradeLevel.dispose();
    _entranceCtrl.dispose();
    _shakeCtrl.dispose();
    _cardTiltCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tilt = math.sin(_cardTiltCtrl.value * math.pi) * 0.015;

    return Scaffold(
      body: Login3DScene(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadLiveData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Transform.translate(
                    offset: Offset(_shakeOffset(), 0),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(tilt)
                        ..rotateY(-tilt * 0.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white70 : AppColors.textPrimary),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GlassAuthCard(
                            isDark: isDark,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Create your account',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Join ${_stats.totalStudents > 0 ? '${_stats.totalStudents}+' : ''} learners on ${_stats.platform}',
                                    style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 20),
                                  LoginStatsStrip(stats: _stats, apiOnline: _apiOnline),
                                  const SizedBox(height: 24),
                                  if (_error != null) AuthErrorBanner(message: _error!),
                                  AuthAnimatedField(
                                    delay: 80,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _firstName,
                                            textInputAction: TextInputAction.next,
                                            textCapitalization: TextCapitalization.words,
                                            decoration: _fieldDecoration(label: 'First name', icon: Icons.person_outline_rounded, isDark: isDark),
                                            validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required',
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _lastName,
                                            textInputAction: TextInputAction.next,
                                            textCapitalization: TextCapitalization.words,
                                            decoration: _fieldDecoration(label: 'Last name', icon: Icons.badge_outlined, isDark: isDark),
                                            validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  AuthAnimatedField(
                                    delay: 140,
                                    child: TextFormField(
                                      controller: _email,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      decoration: _fieldDecoration(label: 'Email', icon: Icons.alternate_email_rounded, isDark: isDark),
                                      validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  AuthAnimatedField(
                                    delay: 200,
                                    child: TextFormField(
                                      controller: _gradeLevel,
                                      textInputAction: TextInputAction.next,
                                      textCapitalization: TextCapitalization.words,
                                      decoration: _fieldDecoration(
                                        label: 'Grade / class (optional)',
                                        icon: Icons.school_outlined,
                                        isDark: isDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  AuthAnimatedField(
                                    delay: 260,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        TextFormField(
                                          controller: _password,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.next,
                                          onChanged: (_) => setState(() {}),
                                          decoration: _fieldDecoration(
                                            label: 'Password',
                                            icon: Icons.lock_rounded,
                                            isDark: isDark,
                                            suffix: IconButton(
                                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                            ),
                                          ),
                                          validator: (v) => v != null && v.length >= 6 ? null : 'Minimum 6 characters',
                                        ),
                                        PasswordStrengthBar(password: _password.text),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  AuthAnimatedField(
                                    delay: 320,
                                    child: TextFormField(
                                      controller: _confirmPassword,
                                      obscureText: _obscureConfirm,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _register(),
                                      decoration: _fieldDecoration(
                                        label: 'Confirm password',
                                        icon: Icons.lock_reset_rounded,
                                        isDark: isDark,
                                        suffix: IconButton(
                                          icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                        ),
                                      ),
                                      validator: (v) => v == _password.text ? null : 'Passwords do not match',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  AuthAnimatedField(
                                    delay: 380,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 28,
                                          child: Checkbox(
                                            value: _acceptedTerms,
                                            activeColor: AppColors.primary,
                                            onChanged: (v) => setState(() {
                                              _acceptedTerms = v ?? false;
                                              if (_acceptedTerms) _error = null;
                                            }),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              'I agree to learn responsibly and accept MacallinAI terms of use.',
                                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textSecondary),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  AuthGradientButton(
                                    loading: _loading,
                                    onPressed: _register,
                                    label: 'Create Account',
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary),
                                          children: const [
                                            TextSpan(text: 'Already have an account? '),
                                            TextSpan(text: 'Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
