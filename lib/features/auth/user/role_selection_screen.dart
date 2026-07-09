import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;

  final _roles = [
    _RoleOption(
      role: UserRole.graphicDesigner,
      icon: Icons.palette_outlined,
      title: 'Graphic Designer',
      subtitle: 'Create stunning designs and visuals',
      gradient: AppColors.designerGradient,
    ),
    _RoleOption(
      role: UserRole.smm,
      icon: Icons.bar_chart_rounded,
      title: 'Social Media Manager',
      subtitle: 'Plan, schedule and manage social media',
      gradient: AppColors.smmGradient,
    ),
    _RoleOption(
      role: UserRole.client,
      icon: Icons.person_outline_rounded,
      title: 'Client',
      subtitle: 'Review, approve and track your projects',
      gradient: AppColors.clientGradient,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      appBar: CommonAppBar(title: 'Choose Your Role'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Text(
                'Select your role to continue',
                style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary),
              ).animate().fadeIn(),

              const SizedBox(height: 28),

              ...List.generate(_roles.length, (i) {
                final role = _roles[i];
                final isSelected = _selectedRole == role.role;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedRole = role.role);
                      context.read<AuthProvider>().setUserRole(role.role);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? role.gradient.colors.first.withOpacity(0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? role.gradient.colors.first : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: role.gradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: role.gradient.colors.first.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(role.icon, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(role.title,
                                    style: GoogleFonts.sora(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 3),
                                Text(role.subtitle,
                                    style: GoogleFonts.sora(
                                        fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              gradient: isSelected ? role.gradient : null,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? null
                                  : Border.all(color: AppColors.border),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: 100 + i * 100)).fadeIn().slideX(begin: 0.3, end: 0),
                );
              }),

              const Spacer(),

              CommonButton(
                label: 'Continue',
                onTap: _selectedRole != null
                    ? () => context.go('/auth/user/login')
                    : null,
                gradient: _selectedRole != null
                    ? _roles.firstWhere((r) => r.role == _selectedRole).gradient
                    : null,
                solidColor: _selectedRole == null ? AppColors.surfaceLight : null,
              ).animate(delay: 500.ms).fadeIn(),

              const SizedBox(height: 12),

              Center(
                child: GestureDetector(
                  onTap: () => context.go('/welcome'),
                  child: Text(
                    'Back to Login',
                    style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary),
                  ),
                ),
              ).animate(delay: 600.ms).fadeIn(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption {
  final UserRole role;
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;

  const _RoleOption({
    required this.role,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
