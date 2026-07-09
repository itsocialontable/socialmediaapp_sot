import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/errors/api_response.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../forgot_password/forgot_password_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Reset state when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().resetAdminLoginState();
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.loginAdmin(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      _showSnackBar('Welcome back, Admin! 🎉', isError: false);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) context.go('/dashboard/admin');
    } else {
      final error = auth.adminLoginState.message ?? 'Login failed. Please try again.';
      _showSnackBar(error, isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.sora(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((a) => a.isAdminLoading);

    return CommonScaffold(
      appBar: CommonAppBar(
        title: 'Admin Login',
        gradientStart: AppColors.adminColor,
        gradientEnd: AppColors.primaryLight,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Header Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.adminGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.adminColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 32),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                const SizedBox(height: 16),

                Text(
                  'Admin Login',
                  style: GoogleFonts.sora(
                      fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.3, end: 0),

                const SizedBox(height: 4),

                Text(
                  'Welcome back, Admin!',
                  style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary),
                ).animate(delay: 150.ms).fadeIn(),

                const SizedBox(height: 36),

                CommonTextField(
                  label: 'Email Address',
                  hint: 'admin@example.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  accentColor: AppColors.adminColor,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email';
                    if (!v.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                CommonTextField(
                  label: 'Password',
                  hint: '••••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  controller: _passwordController,
                  accentColor: AppColors.adminColor,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your password';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.2, end: 0),

                const SizedBox(height: 12),

                // Align(
                //   alignment: Alignment.centerRight,
                //   child: GestureDetector(
                //     onTap: () => Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (_) => ForgotPasswordScreen(
                //           accentColor: AppColors.adminColor,
                //           gradient: AppColors.adminGradient,
                //         ),
                //       ),
                //     ),
                //     child: Text(
                //       'Forgot Password?',
                //       style: GoogleFonts.sora(
                //           fontSize: 12,
                //           fontWeight: FontWeight.w600,
                //           color: AppColors.adminColor),
                //     ),
                //   ),
                // ).animate(delay: 350.ms).fadeIn(),

                const SizedBox(height: 32),

                CommonButton(
                  label: 'Login',
                  gradient: AppColors.adminGradient,
                  isLoading: isLoading,
                  onTap: isLoading ? null : _login,
                ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3, end: 0),

                const SizedBox(height: 20),

                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Text(
                //       "Don't have an account? ",
                //       style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary),
                //     ),
                //     GestureDetector(
                //       onTap: () => context.go('/auth/admin/register'),
                //       child: Text(
                //         'Register Now',
                //         style: GoogleFonts.sora(
                //             fontSize: 13,
                //             fontWeight: FontWeight.w600,
                //             color: AppColors.adminColor),
                //       ),
                //     ),
                //   ],
                // ).animate(delay: 500.ms).fadeIn(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
