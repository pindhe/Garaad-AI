import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/public_api.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/auth_form_widgets.dart';
import 'widgets/auth_mobile_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _entranceCtrl;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  bool _loading = false;
  bool _obscure = true;
  bool _rememberMe = true;
  bool _apiOnline = false;
  String? _error;
  PlatformStats _stats = const PlatformStats();

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _loadSavedEmail();
    _loadLiveData();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email');
    final remember = prefs.getBool('remember_me') ?? true;
    if (email != null && mounted) {
      setState(() {
        _emailController.text = email;
        _rememberMe = remember;
      });
    }
  }

  Future<void> _loadLiveData() async {
    final online = await PublicApi.checkHealth();
    final stats = await PublicApi.fetchStats();
    if (mounted) setState(() { _apiOnline = online; _stats = stats; });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      _triggerShake();
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthProvider>().login(_emailController.text.trim(), _passwordController.text);
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('saved_email');
        await prefs.setBool('remember_me', false);
      }
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

  void _triggerShake() => _shakeCtrl.forward(from: 0);

  double _shakeOffset() {
    if (!_shakeCtrl.isAnimating) return 0;
    return math.sin(_shakeAnim.value * math.pi * 4) * 8 * (1 - _shakeAnim.value);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entranceCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final compact = height < 720;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthMobileBackground(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                AuthHeroHeader(
                  title: 'Welcome\nback',
                  subtitle: _stats.tagline,
                  apiOnline: _apiOnline,
                  compact: compact,
                ),
                if (!compact) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AuthCompactStats(
                      students: _stats.totalStudents,
                      courses: _stats.totalCourses,
                      aiToday: _stats.aiSessionsToday,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: Transform.translate(
                    offset: Offset(_shakeOffset(), 0),
                    child: AuthFormSheet(
                      isDark: isDark,
                      child: Form(
                        key: _formKey,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Sign in to continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text('${_stats.activeUsers} learners online now', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  const SizedBox(height: 20),
                                  if (_error != null) AuthErrorBanner(message: _error!),
                                  AuthAnimatedField(
                                    delay: 80,
                                    child: AuthPillField(
                                      controller: _emailController,
                                      label: 'Email address',
                                      icon: Icons.mail_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  AuthAnimatedField(
                                    delay: 140,
                                    child: AuthPillField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      obscure: _obscure,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: _login,
                                      suffix: IconButton(
                                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                        onPressed: () => setState(() => _obscure = !_obscure),
                                      ),
                                      validator: (v) => v != null && v.length >= 6 ? null : 'Minimum 6 characters',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 28,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                        ),
                                      ),
                                      Text('Remember me', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                                    ],
                                  ),
                                  SizedBox(height: compact ? 20 : 32),
                                  AuthGradientButton(loading: _loading, onPressed: _login, label: 'Sign In', icon: Icons.arrow_forward_rounded),
                                  const SizedBox(height: 16),
                                  AuthLinkRow(
                                    prompt: "Don't have an account?",
                                    action: 'Create one',
                                    onTap: () => Navigator.pushNamed(context, '/register'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
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
