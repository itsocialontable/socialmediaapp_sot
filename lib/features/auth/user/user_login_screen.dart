import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().resetUserLoginState();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  LinearGradient _getRoleGradient(UserRole? role) {
    switch (role) {
      case UserRole.graphicDesigner: return AppColors.designerGradient;
      case UserRole.smm:            return AppColors.smmGradient;
      case UserRole.client:         return AppColors.clientGradient;
      default:                      return AppColors.primaryGradient;
    }
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.graphicDesigner: return AppColors.designerColor;
      case UserRole.smm:             return AppColors.smmColor;
      case UserRole.client:          return AppColors.clientColor;
      default:                       return AppColors.primary;
    }
  }

  IconData _getRoleIcon(UserRole? role) {
    switch (role) {
      case UserRole.graphicDesigner: return Icons.palette_outlined;
      case UserRole.smm:             return Icons.bar_chart_rounded;
      case UserRole.client:          return Icons.person_outline_rounded;
      default:                       return Icons.people_alt_outlined;
    }
  }

  String _getRoleTitle(UserRole? role) {
    switch (role) {
      case UserRole.graphicDesigner: return 'Graphic Designer Login';
      case UserRole.smm:             return 'SMM Login';
      case UserRole.client:          return 'Client Login';
      default:                       return 'User Login';
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    if (auth.userRole == null) {
      _showSnackBar('Please select a role first.', isError: true);
      return;
    }

    final success = await auth.loginUser(
      _emailController.text,
      _passwordController.text,
      auth.userRole!,
    );

    if (!mounted) return;

    if (success) {
      _showSnackBar('Login successful! Welcome back 🎉', isError: false);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) context.go(auth.dashboardRoute);
    } else {
      final error = auth.userLoginState.message ?? 'Login failed. Please try again.';
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
    final auth     = context.watch<AuthProvider>();
    final role     = auth.userRole;
    final gradient = _getRoleGradient(role);
    final color    = _getRoleColor(role);
    final icon     = _getRoleIcon(role);
    final title    = _getRoleTitle(role);
    final isLoading = auth.isUserLoading;

    return CommonScaffold(
      appBar: CommonAppBar(
        title: title,
        gradientStart: gradient.colors.first,
        gradientEnd: gradient.colors.last,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Role Icon
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                const SizedBox(height: 16),

                Text(title,
                    style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary))
                    .animate(delay: 100.ms).fadeIn(),

                Text('Welcome back!',
                    style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary))
                    .animate(delay: 150.ms).fadeIn(),

                const SizedBox(height: 36),

                CommonTextField(
                  label: 'Email Address',
                  hint: 'you@example.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  accentColor: color,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email';
                    if (!v.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ).animate(delay: 200.ms).fadeIn(),

                const SizedBox(height: 20),

                CommonTextField(
                  label: 'Password',
                  hint: '••••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  controller: _passwordController,
                  accentColor: color,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your password';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ).animate(delay: 300.ms).fadeIn(),

                const SizedBox(height: 36),

                CommonButton(
                  label: 'Login',
                  gradient: gradient,
                  isLoading: isLoading,
                  onTap: isLoading ? null : _login,
                ).animate(delay: 380.ms).fadeIn(),

                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () => context.go('/auth/user/role'),
                  child: Text(
                    'Back to Role Selection',
                    style: GoogleFonts.sora(
                        fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ).animate(delay: 460.ms).fadeIn(),

                const SizedBox(height: 20),

                // Contact Admin Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(Icons.admin_panel_settings_outlined, color: color, size: 17),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Credentials provided by Admin',
                              style: GoogleFonts.sora(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your login credentials are set by your Admin. If you don\'t have access, please contact your Administrator.',
                              style: GoogleFonts.sora(
                                  fontSize: 11, color: AppColors.textSecondary, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 520.ms).fadeIn(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
