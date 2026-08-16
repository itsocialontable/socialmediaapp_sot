import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'privacy_policy_page.dart';
import 'help_support_page.dart';

// ─────────────────────────────────────────
// ABOUT PAGE
// ─────────────────────────────────────────
class AboutPage extends StatefulWidget {
  final Color accentColor;
  final LinearGradient gradient;

  const AboutPage({
    super.key,
    required this.accentColor,
    required this.gradient,
  });

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _version = '1.0.0'; _buildNumber = '1'; });
    }
  }

  Future<void> _launchEmail() async {
    final uri = Uri(scheme: 'mailto', path: 'support@growthcraftsmm.com', query: 'subject=App Feedback');
    try { await launchUrl(uri); } catch (_) {}
  }

  void _copyVersion() {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: 'v$_version (build $_buildNumber)'));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Version copied to clipboard', style: GoogleFonts.sora(fontSize: 13)),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

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
          shaderCallback: (b) => widget.gradient.createShader(b),
          child: Text('About',
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
          children: [
            const SizedBox(height: 8),

            // ── App icon / name ──
            Container(
              width: 84, height: 84,
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: widget.accentColor.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 38),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.85, 0.85)),

            const SizedBox(height: 16),
            Text('GrowthCraft SMM',
                style: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary))
                .animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _copyVersion,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.accentColor.withOpacity(0.3)),
                ),
                child: Text(
                  _version.isEmpty ? 'Loading version...' : 'Version $_version (build $_buildNumber)',
                  style: GoogleFonts.sora(fontSize: 11.5, fontWeight: FontWeight.w600, color: widget.accentColor),
                ),
              ),
            ).animate(delay: 150.ms).fadeIn(),

            const SizedBox(height: 24),

            CommonCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                'GrowthCraft SMM helps agencies manage social media content, design projects, and client collaboration — all in one place. '
                'Plan posts, assign tasks, track approvals, and keep your team in sync across every role.',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(fontSize: 12.5, color: AppColors.textSecondary, height: 1.6),
              ),
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: 24),

            // ── Links ──
            Column(
              children: [
                _AboutTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  accentColor: widget.accentColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PrivacyPolicyPage(accentColor: widget.accentColor, gradient: widget.gradient),
                  )),
                ),
                _AboutTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  accentColor: widget.accentColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => HelpSupportPage(accentColor: widget.accentColor, gradient: widget.gradient),
                  )),
                ),
                _AboutTile(
                  icon: Icons.mail_outline_rounded,
                  label: 'Send Feedback',
                  accentColor: widget.accentColor,
                  onTap: _launchEmail,
                ),
                _AboutTile(
                  icon: Icons.description_outlined,
                  label: 'Terms of Service',
                  accentColor: widget.accentColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PrivacyPolicyPage(accentColor: widget.accentColor, gradient: widget.gradient),
                  )),
                ),
              ],
            ).animate(delay: 260.ms).fadeIn(),

            const SizedBox(height: 24),
            Text('Made with care for social media teams',
                style: GoogleFonts.sora(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text('© ${DateTime.now().year} GrowthCraft SMM. All rights reserved.',
                style: GoogleFonts.sora(fontSize: 10.5, color: AppColors.textMuted)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _AboutTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CommonCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 17),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
