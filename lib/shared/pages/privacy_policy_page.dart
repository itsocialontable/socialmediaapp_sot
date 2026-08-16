import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ─────────────────────────────────────────
// PRIVACY POLICY PAGE
// ─────────────────────────────────────────
class PrivacyPolicyPage extends StatelessWidget {
  final Color accentColor;
  final LinearGradient gradient;

  const PrivacyPolicyPage({
    super.key,
    required this.accentColor,
    required this.gradient,
  });

  static const List<_Section> _sections = [
    _Section(
      Icons.info_outline_rounded,
      '1. Information We Collect',
      'We collect information you provide directly to us, such as your name, email address, phone number, and profile details when you create an account. '
          'We also collect data related to social media accounts you choose to connect, content you create or upload, and usage information such as device type, '
          'app interactions, and log data.',
    ),
    _Section(
      Icons.settings_outlined,
      '2. How We Use Your Information',
      'Your information is used to provide, maintain, and improve our services — including managing your social media posts, design projects, and client '
          'communication — to personalize your experience, respond to support requests, and send important updates about your account or the app.',
    ),
    _Section(
      Icons.share_outlined,
      '3. Sharing of Information',
      'We do not sell your personal information. Data may be shared with team members within your agency workspace (admin, SMM, designers, or clients) as '
          'required for collaboration, with connected social media platforms you explicitly authorize, and with service providers who help us operate the app '
          'under strict confidentiality obligations.',
    ),
    _Section(
      Icons.lock_outline_rounded,
      '4. Data Security',
      'We use industry-standard encryption for data in transit and at rest, secure authentication tokens, and access controls to protect your information. '
          'While we work hard to safeguard your data, no method of transmission or storage is 100% secure.',
    ),
    _Section(
      Icons.storage_outlined,
      '5. Data Retention',
      'We retain your information for as long as your account remains active or as needed to provide our services. You may request deletion of your account '
          'and associated data at any time by contacting our support team.',
    ),
    _Section(
      Icons.fact_check_outlined,
      '6. Your Rights',
      'You have the right to access, update, or delete your personal information, withdraw consent for connected social accounts, and opt out of non-essential '
          'communications at any time from within the app or by contacting us directly.',
    ),
    _Section(
      Icons.cookie_outlined,
      '7. Third-Party Services',
      'Our app integrates with third-party platforms (such as social media networks) to provide core functionality. Your use of those platforms is also '
          'governed by their respective privacy policies.',
    ),
    _Section(
      Icons.child_care_outlined,
      '8. Children\'s Privacy',
      'Our services are not directed at individuals under the age of 13, and we do not knowingly collect personal information from children.',
    ),
    _Section(
      Icons.update_rounded,
      '9. Changes to This Policy',
      'We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new policy within the app and updating '
          'the "last updated" date below.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (b) => gradient.createShader(b),
          child: Text('Privacy Policy',
              style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(Icons.privacy_tip_outlined, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your privacy matters',
                            style: GoogleFonts.sora(
                                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('Last updated: August 2026',
                            style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

            const SizedBox(height: 20),

            ...List.generate(_sections.length, (i) {
              final section = _sections[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: CommonCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(section.icon, color: accentColor, size: 17),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(section.title,
                                style: GoogleFonts.sora(
                                    fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(section.body,
                          style: GoogleFonts.sora(fontSize: 12.5, color: AppColors.textSecondary, height: 1.55)),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 80 + i * 50)).fadeIn().slideX(begin: 0.08, end: 0);
            }),

            const SizedBox(height: 12),
            Center(
              child: Text('Questions about this policy? Reach us via Help & Support.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(fontSize: 11.5, color: AppColors.textMuted)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Section {
  final IconData icon;
  final String title;
  final String body;
  const _Section(this.icon, this.title, this.body);
}
