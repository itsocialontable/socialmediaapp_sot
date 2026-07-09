import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../widgets/common_widgets.dart';
import 'edit_profile_page.dart';
import 'notifications_page.dart';


// ─────────────────────────────────────────
// PROFILE PAGE
// ─────────────────────────────────────────
class ProfilePage extends StatelessWidget {
  final Color accentColor;
  final LinearGradient gradient;

  const ProfilePage({
    super.key,
    required this.accentColor,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final menuItems = [
      _MenuItem(Icons.person_outline_rounded, 'Edit Profile', 'Update your information'),
      _MenuItem(Icons.notifications_outlined, 'Notifications', 'View alerts & reminders'),
      _MenuItem(Icons.color_lens_outlined, 'Appearance', 'Theme & display settings'),
      _MenuItem(Icons.help_outline_rounded, 'Help & Support', 'FAQs and contact'),
      _MenuItem(Icons.privacy_tip_outlined, 'Privacy Policy', 'Read our privacy policy'),
      _MenuItem(Icons.info_outline_rounded, 'About', 'App version & info'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // ── Avatar & Info ──
          Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: auth.profileImageUrl == null ? gradient : null,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: auth.profileImageUrl != null && auth.profileImageUrl!.isNotEmpty
                          ? (auth.profileImageUrl!.startsWith('/') || auth.profileImageUrl!.startsWith('file://')
                          ? Image.file(File(auth.profileImageUrl!), fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _defaultLetterAvatar(auth, gradient))
                          : Image.network(auth.profileImageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _defaultLetterAvatar(auth, gradient)))
                          : _defaultLetterAvatar(auth, gradient),
                    ),
                  ),
                  Positioned(
                    bottom: 2, right: 2,
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => EditProfilePage(accentColor: accentColor, gradient: gradient),
                      )),
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor, width: 1.5),
                        ),
                        child: Icon(Icons.camera_alt_rounded, size: 13, color: accentColor),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                auth.userName,
                style: GoogleFonts.sora(
                    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                auth.userEmail,
                style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Text(
                  _roleLabel(auth.userRole),
                  style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),

          const SizedBox(height: 28),

          // ── Stats Row ──
          // CommonCard(
          //   padding: const EdgeInsets.symmetric(vertical: 18),
          //   child: Row(
          //     children: [
          //       _StatItem('24', 'Projects', accentColor),
          //       _Divider(),
          //       _StatItem('156', 'Posts', accentColor),
          //       _Divider(),
          //       _StatItem('4.9', 'Rating', accentColor),
          //     ],
          //   ),
          // ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 20),

          // ── Menu Items ──
          ...List.generate(menuItems.length, (i) {
            final item = menuItems[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CommonCard(
                onTap: () {
                  if (item.title == 'Edit Profile') {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => EditProfilePage(accentColor: accentColor, gradient: gradient),
                    ));
                  } else if (item.title == 'Notifications') {
                    _openNotificationsPage(context);
                  }
                },
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: accentColor, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          Text(item.subtitle,
                              style: GoogleFonts.sora(
                                  fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: AppColors.textMuted),
                  ],
                ),
              ).animate(delay: Duration(milliseconds: 150 + i * 60)).fadeIn().slideX(begin: 0.2, end: 0),
            );
          }),

          const SizedBox(height: 16),

          CommonButton(
            label: 'Logout',
            outlined: true,
            gradient: gradient,
            icon: const Icon(Icons.logout_rounded, color: AppColors.primary, size: 18),
            onTap: () {
              context.read<AuthProvider>().logout();
              context.go('/welcome');
            },
          ).animate(delay: 700.ms).fadeIn(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _openNotificationsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsPage(
          accentColor: accentColor,
          gradient: gradient,
        ),
      ),
    );
  }

  String _roleLabel(UserRole? role) {
    switch (role) {
      case UserRole.admin: return 'Admin';
      case UserRole.graphicDesigner: return 'Graphic Designer';
      case UserRole.smm: return 'Social Media Manager';
      case UserRole.client: return 'Client';
      default: return 'User';
    }
  }

  Widget _defaultLetterAvatar(AuthProvider auth, LinearGradient gradient) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Center(
        child: Text(
          auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'U',
          style: GoogleFonts.sora(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const _MenuItem(this.icon, this.title, this.subtitle);
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatItem(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.sora(
                  fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}


