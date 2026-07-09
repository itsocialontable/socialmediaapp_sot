import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final Color accentColor;
  final LinearGradient gradient;

  const ForgotPasswordScreen({
    super.key,
    required this.accentColor,
    required this.gradient,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: _emailController.text.trim(),
            accentColor: widget.accentColor,
            gradient: widget.gradient,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      appBar: CommonAppBar(
        title: 'Forgot Password',
        gradientStart: widget.gradient.colors.first,
        gradientEnd: widget.gradient.colors.last,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 36),

                // Illustration
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.accentColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: widget.gradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                Text(
                  'Forgot Password?',
                  style: GoogleFonts.sora(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.3, end: 0),

                const SizedBox(height: 10),

                Text(
                  'No worries! Enter your email and we\'ll\nsend you an OTP to reset your password.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ).animate(delay: 200.ms).fadeIn(),

                const SizedBox(height: 40),

                CommonTextField(
                  label: 'Email Address',
                  hint: 'Enter your registered email',
                  prefixIcon: Icons.mail_outline_rounded,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  accentColor: widget.accentColor,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.2, end: 0),

                const SizedBox(height: 32),

                CommonButton(
                  label: 'Send OTP',
                  gradient: widget.gradient,
                  isLoading: _isLoading,
                  onTap: _sendOtp,
                  icon: _isLoading
                      ? null
                      : Icon(Icons.send_rounded, color: Colors.white, size: 17),
                ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3, end: 0),



                const SizedBox(height: 32),

                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_ios_rounded,
                          size: 14, color: widget.accentColor),
                      const SizedBox(width: 4),
                      Text(
                        'Back to Login',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.accentColor,
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 550.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// OTP VERIFICATION SCREEN
// ─────────────────────────────────────────
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final Color accentColor;
  final LinearGradient gradient;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.accentColor,
    required this.gradient,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 30;
  bool _canResend = false;

  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();
    // _startTimer();
  }

  void _startTimer() {
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendTimer--;
        if (_resendTimer <= 0) _canResend = true;
      });
      return _resendTimer > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _onOtpDigitEntered(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    // Auto-verify when all 6 digits entered
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) _verifyOtp();
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter all 6 digits',
              style: GoogleFonts.sora(fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangePasswordScreen(
            email: widget.email,
            accentColor: widget.accentColor,
            gradient: widget.gradient,
          ),
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() => _isResending = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isResending = false);
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
      _timerController.reset();
      _timerController.forward();
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP resent to ${widget.email}',
              style: GoogleFonts.sora(fontSize: 13)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length < 2) return email;
    final name = parts[0];
    final domain = parts[1];
    final masked = name.length > 2
        ? '${name.substring(0, 2)}${'*' * (name.length - 2)}'
        : name;
    return '$masked@$domain';
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      appBar: CommonAppBar(
        title: 'OTP Verification',
        gradientStart: widget.gradient.colors.first,
        gradientEnd: widget.gradient.colors.last,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.mark_email_read_rounded,
                    color: Colors.white, size: 36),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),

              Text(
                'Verify Your Email',
                style: GoogleFonts.sora(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.3, end: 0),

              const SizedBox(height: 10),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'We\'ve sent a 6-digit OTP to\n',
                  style: GoogleFonts.sora(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.6),
                  children: [
                    TextSpan(
                      text: _maskEmail(widget.email),
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.accentColor,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 150.ms).fadeIn(),

              const SizedBox(height: 40),

              // OTP Input Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    accentColor: widget.accentColor,
                    gradient: widget.gradient,
                    onChanged: (val) => _onOtpDigitEntered(i, val),
                  );
                }),
              ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.3, end: 0),

              const SizedBox(height: 32),

              // Timer & Resend
              AnimatedBuilder(
                animation: _timerController,
                builder: (_, __) => Column(
                  children: [
                    if (!_canResend) ...[
                      // Circular timer
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: CircularProgressIndicator(
                              value: _resendTimer / 30,
                              strokeWidth: 3,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.accentColor),
                            ),
                          ),
                          Text(
                            '${_resendTimer}s',
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: widget.accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Resend OTP in $_resendTimer seconds',
                        style: GoogleFonts.sora(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ] else ...[
                      Text(
                        "Didn't receive the OTP?",
                        style: GoogleFonts.sora(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _isResending ? null : _resendOtp,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: widget.accentColor.withOpacity(0.3)),
                          ),
                          child: _isResending
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        widget.accentColor),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh_rounded,
                                        color: widget.accentColor, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Resend OTP',
                                      style: GoogleFonts.sora(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: widget.accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate(delay: 350.ms).fadeIn(),

              const SizedBox(height: 36),

              CommonButton(
                label: 'Verify OTP',
                gradient: widget.gradient,
                isLoading: _isLoading,
                onTap: _verifyOtp,
              ).animate(delay: 450.ms).fadeIn().slideY(begin: 0.3, end: 0),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_ios_rounded,
                        size: 14, color: widget.accentColor),
                    const SizedBox(width: 4),
                    Text(
                      'Change Email',
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.accentColor,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 500.ms).fadeIn(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// OTP BOX WIDGET
// ─────────────────────────────────────────
class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accentColor;
  final LinearGradient gradient;
  final Function(String) onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.accentColor,
    required this.gradient,
    required this.onChanged,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasTxt = widget.controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46,
      height: 56,
      decoration: BoxDecoration(
        gradient: hasTxt ? widget.gradient : null,
        color: hasTxt ? null : (_isFocused ? widget.accentColor.withOpacity(0.08) : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasTxt
              ? Colors.transparent
              : (_isFocused ? widget.accentColor : AppColors.border),
          width: _isFocused ? 1.5 : 1,
        ),
        boxShadow: _isFocused || hasTxt
            ? [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: GoogleFonts.sora(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: hasTxt ? Colors.white : AppColors.textPrimary,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (val) {
          setState(() {});
          widget.onChanged(val);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────
// CHANGE PASSWORD SCREEN
// ─────────────────────────────────────────
class ChangePasswordScreen extends StatefulWidget {
  final String email;
  final Color accentColor;
  final LinearGradient gradient;

  const ChangePasswordScreen({
    super.key,
    required this.email,
    required this.accentColor,
    required this.gradient,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  // Password strength
  int _strength = 0;
  String _strengthLabel = '';
  Color _strengthColor = AppColors.border;

  final List<_PasswordRule> _rules = [
    _PasswordRule('At least 8 characters', (p) => p.length >= 8),
    _PasswordRule('Contains uppercase letter', (p) => p.contains(RegExp(r'[A-Z]'))),
    _PasswordRule('Contains lowercase letter', (p) => p.contains(RegExp(r'[a-z]'))),
    _PasswordRule('Contains a number', (p) => p.contains(RegExp(r'[0-9]'))),
    _PasswordRule('Contains special character', (p) => p.contains(RegExp(r'[!@#\$&*~]'))),
  ];

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_updateStrength);
  }

  void _updateStrength() {
    final p = _newPasswordController.text;
    final passed = _rules.where((r) => r.check(p)).length;
    setState(() {
      _strength = passed;
      if (passed <= 1) { _strengthLabel = 'Weak'; _strengthColor = AppColors.error; }
      else if (passed <= 3) { _strengthLabel = 'Fair'; _strengthColor = AppColors.warning; }
      else if (passed == 4) { _strengthLabel = 'Good'; _strengthColor = AppColors.info; }
      else { _strengthLabel = 'Strong'; _strengthColor = AppColors.success; }
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text(
                'Password Changed!',
                style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ).animate(delay: 100.ms).fadeIn(),
              const SizedBox(height: 8),
              Text(
                'Your password has been successfully\nupdated. You can now login.',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ).animate(delay: 150.ms).fadeIn(),
              const SizedBox(height: 24),
              CommonButton(
                label: 'Back to Login',
                gradient: widget.gradient,
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.pop(context);
                },
              ).animate(delay: 200.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      appBar: CommonAppBar(
        title: 'New Password',
        gradientStart: widget.gradient.colors.first,
        gradientEnd: widget.gradient.colors.last,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),

                // Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: Colors.white, size: 34),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut),
                ),

                const SizedBox(height: 24),

                Center(
                  child: Text(
                    'Create New Password',
                    style: GoogleFonts.sora(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ).animate(delay: 100.ms).fadeIn(),
                ),

                const SizedBox(height: 6),

                Center(
                  child: Text(
                    'Make sure it\'s different from your previous\npassword for security.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                        fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  ).animate(delay: 150.ms).fadeIn(),
                ),

                const SizedBox(height: 36),

                CommonTextField(
                  label: 'New Password',
                  hint: '••••••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  controller: _newPasswordController,
                  accentColor: widget.accentColor,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter new password';
                    if (v.length < 6) return 'Minimum 6 characters required';
                    return null;
                  },
                ).animate(delay: 250.ms).fadeIn().slideX(begin: -0.2, end: 0),

                // Strength Bar
                if (_newPasswordController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: List.generate(5, (i) {
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                                decoration: BoxDecoration(
                                  color: i < _strength
                                      ? _strengthColor
                                      : AppColors.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _strengthLabel,
                        style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _strengthColor),
                      ),
                    ],
                  ).animate().fadeIn(),
                ],

                const SizedBox(height: 20),

                CommonTextField(
                  label: 'Confirm Password',
                  hint: '••••••••••••',
                  prefixIcon: Icons.lock_reset_rounded,
                  isPassword: true,
                  controller: _confirmController,
                  accentColor: widget.accentColor,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm password';
                    if (v != _newPasswordController.text) return 'Passwords do not match';
                    return null;
                  },
                ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.2, end: 0),

                const SizedBox(height: 24),

                // Password Rules Checklist
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password Requirements',
                        style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      ..._rules.map((r) {
                        final passed = r.check(_newPasswordController.text);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: passed
                                      ? AppColors.success
                                      : AppColors.surfaceLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: passed
                                        ? AppColors.success
                                        : AppColors.border,
                                  ),
                                ),
                                child: passed
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 11)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                r.label,
                                style: GoogleFonts.sora(
                                  fontSize: 12,
                                  color: passed
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  fontWeight: passed
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn(),

                const SizedBox(height: 32),

                // CommonButton(
                //   label: 'Change Password',
                //   gradient: widget.gradient,
                //   isLoading: _isLoading,
                //   onTap: _changePassword,
                // ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.3, end: 0),
                //
                // const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordRule {
  final String label;
  final bool Function(String) check;
  const _PasswordRule(this.label, this.check);
}
