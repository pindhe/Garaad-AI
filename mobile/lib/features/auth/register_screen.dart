import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/public_api.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/auth_form_widgets.dart';
import 'widgets/auth_mobile_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageCtrl = PageController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _gradeLevel = TextEditingController();

  late AnimationController _entranceCtrl;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  int _step = 0;
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
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _loadLiveData();
  }

  Future<void> _loadLiveData() async {
    final online = await PublicApi.checkHealth();
    final stats = await PublicApi.fetchStats();
    if (mounted) setState(() { _apiOnline = online; _stats = stats; });
  }

  bool _validateStep1() {
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your first and last name');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (!_formKey.currentState!.validate()) return false;
    if (!_acceptedTerms) {
      setState(() => _error = 'Please accept the terms to continue');
      return false;
    }
    return true;
  }

  void _nextStep() {
    setState(() => _error = null);
    if (_step == 0) {
      if (!_validateStep1()) {
        _triggerShake();
        return;
      }
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      setState(() => _step = 1);
    } else {
      _register();
    }
  }

  void _prevStep() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      setState(() { _step = 0; _error = null; });
    }
  }

  Future<void> _register() async {
    if (!_validateStep2()) {
      _triggerShake();
      return;
    }
    setState(() { _loading = true; _error = null; });
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

  void _triggerShake() => _shakeCtrl.forward(from: 0);

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
    _pageCtrl.dispose();
    _entranceCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AuthMobileBackground(
        gradientColors: const [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF2563EB)],
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: AuthHeroHeader(
                  title: 'Start\nlearning',
                  subtitle: 'Join ${_stats.totalStudents > 0 ? '${_stats.totalStudents}+' : ''} students on MacallinAI',
                  apiOnline: _apiOnline,
                  onBack: _prevStep,
                ),
              ),
              const Spacer(),
              Transform.translate(
                offset: Offset(_shakeOffset(), 0),
                child: SizedBox(
                  height: size.height * 0.58,
                  child: AuthFormSheet(
                    isDark: isDark,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthStepIndicator(total: 2, current: _step),
                          const SizedBox(height: 16),
                          Text(
                            _step == 0 ? 'About you' : 'Your account',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _step == 0 ? 'Tell us who you are' : 'Set up email and password',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          if (_error != null) ...[AuthErrorBanner(message: _error!), const SizedBox(height: 8)],
                          Expanded(
                            child: PageView(
                              controller: _pageCtrl,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _StepOne(
                                  firstName: _firstName,
                                  lastName: _lastName,
                                  gradeLevel: _gradeLevel,
                                ),
                                _StepTwo(
                                  email: _email,
                                  password: _password,
                                  confirmPassword: _confirmPassword,
                                  obscurePassword: _obscurePassword,
                                  obscureConfirm: _obscureConfirm,
                                  acceptedTerms: _acceptedTerms,
                                  onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                                  onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  onTermsChanged: (v) => setState(() {
                                    _acceptedTerms = v ?? false;
                                    if (_acceptedTerms) _error = null;
                                  }),
                                  onPasswordChanged: () => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          AuthGradientButton(
                            loading: _loading,
                            onPressed: _nextStep,
                            label: _step == 0 ? 'Next' : 'Create Account',
                            icon: _step == 0 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                          ),
                          if (_step == 1) ...[
                            const SizedBox(height: 12),
                            AuthLinkRow(
                              prompt: 'Already have an account?',
                              action: 'Sign In',
                              onTap: () => Navigator.pop(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepOne extends StatelessWidget {
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController gradeLevel;

  const _StepOne({required this.firstName, required this.lastName, required this.gradeLevel});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        AuthPillField(
          controller: firstName,
          label: 'First name',
          icon: Icons.person_outline_rounded,
          capitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        AuthPillField(
          controller: lastName,
          label: 'Last name',
          icon: Icons.badge_outlined,
          capitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        AuthPillField(
          controller: gradeLevel,
          label: 'Grade / class',
          hint: 'Optional — e.g. Grade 10',
          icon: Icons.school_outlined,
          capitalization: TextCapitalization.words,
        ),
      ],
    );
  }
}

class _StepTwo extends StatelessWidget {
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool acceptedTerms;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onPasswordChanged;

  const _StepTwo({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.acceptedTerms,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onTermsChanged,
    required this.onPasswordChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      children: [
        AuthPillField(
          controller: email,
          label: 'Email address',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
        ),
        const SizedBox(height: 16),
        AuthPillField(
          controller: password,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: obscurePassword,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onPasswordChanged(),
          suffix: IconButton(
            icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: onTogglePassword,
          ),
          validator: (v) => v != null && v.length >= 6 ? null : 'Minimum 6 characters',
        ),
        PasswordStrengthBar(password: password.text),
        const SizedBox(height: 16),
        AuthPillField(
          controller: confirmPassword,
          label: 'Confirm password',
          icon: Icons.lock_reset_rounded,
          obscure: obscureConfirm,
          textInputAction: TextInputAction.done,
          suffix: IconButton(
            icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: onToggleConfirm,
          ),
          validator: (v) => v == password.text ? null : 'Passwords do not match',
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 28,
              child: Checkbox(
                value: acceptedTerms,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: onTermsChanged,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'I agree to MacallinAI terms of use and responsible learning.',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
