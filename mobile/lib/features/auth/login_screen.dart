import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/public_api.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/auth_form_widgets.dart';
import 'widgets/login_3d_scene.dart';
import 'widgets/login_stats_strip.dart';

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
  late AnimationController _cardTiltCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
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
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _cardTiltCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _entranceCtrl.forward();
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
    if (mounted) {
      setState(() {
        _apiOnline = online;
        _stats = stats;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      _triggerShake();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
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

  void _triggerShake() {
    _shakeCtrl.forward(from: 0);
  }

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
              padding: const EdgeInsets.fromLTRB(20, 120, 20, 24),
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
                      child: GlassAuthCard(
                        isDark: isDark,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome back',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _stats.tagline,
                                style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary),
                              ),
                              const SizedBox(height: 20),
                              LoginStatsStrip(stats: _stats, apiOnline: _apiOnline),
                              const SizedBox(height: 24),
                              if (_error != null) AuthErrorBanner(message: _error!),
                              AuthAnimatedField(
                                delay: 100,
                                child: TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                                    filled: true,
                                    fillColor: isDark ? AppColors.darkSurface : Colors.white,
                                  ),
                                  validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                                ),
                              ),
                              const SizedBox(height: 14),
                              AuthAnimatedField(
                                delay: 200,
                                child: TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _login(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_rounded),
                                    filled: true,
                                    fillColor: isDark ? AppColors.darkSurface : Colors.white,
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: (v) => v != null && v.length >= 6 ? null : 'Minimum 6 characters',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  SizedBox(
                                    height: 28,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.primary,
                                      onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                    ),
                                  ),
                                  Text('Remember me', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                                  const Spacer(),
                                  Text(
                                    '${_stats.activeUsers} learners online',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              AuthGradientButton(
                                loading: _loading,
                                onPressed: _login,
                                label: 'Sign In',
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.pushNamed(context, '/register'),
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary),
                                      children: const [
                                        TextSpan(text: "Don't have an account? "),
                                        TextSpan(text: 'Register', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
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
        ),
      ),
    );
  }
}
