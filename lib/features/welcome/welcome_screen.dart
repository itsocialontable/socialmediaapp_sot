import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // Logo & Brand
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                    child: Text(
                      'SocialFlow',
                      style: GoogleFonts.sora(
                          fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage. Create. Schedule. Grow.',
                    style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: 56),

              // Account Type Selection
              Text(
                'Choose your account type',
                style: GoogleFonts.sora(
                    fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ).animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 20),

              // Admin Card
              _AccountTypeCard(
                icon: Icons.shield_outlined,
                title: 'Agency',
                subtitle: 'Manage your agency and team',
                gradient: AppColors.adminGradient,
                onTap: () => context.go('/auth/admin/login'),
              ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.3, end: 0),

              const SizedBox(height: 16),

              // User Card
              _AccountTypeCard(
                icon: Icons.people_alt_outlined,
                title: 'User',
                subtitle: 'Login as team member or client',
                gradient: AppColors.designerGradient,
                onTap: () => context.go('/auth/user/role'),
              ).animate(delay: 450.ms).fadeIn().slideX(begin: 0.3, end: 0),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _AccountTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.sora(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}
