import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ─────────────────────────────────────────
// HELP & SUPPORT PAGE
// ─────────────────────────────────────────
class HelpSupportPage extends StatefulWidget {
  final Color accentColor;
  final LinearGradient gradient;

  const HelpSupportPage({
    super.key,
    required this.accentColor,
    required this.gradient,
  });

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  int? _expandedIndex = 0;

  static const String _supportEmail = 'support@growthcraftsmm.com';
  static const String _supportPhone = '+911234567890';

  final List<_Faq> _faqs = const [
    _Faq(
      'How do I reset my password?',
      'Go to the login screen and tap on "Forgot Password". Enter your registered email address and follow the link sent to your inbox to set a new password.',
    ),
    _Faq(
      'How do I connect my social media accounts?',
      'Open your dashboard, go to "Connected Accounts" and tap "Connect" next to the platform you want to link. You will be redirected to log in and authorize access.',
    ),
    _Faq(
      'How can I track the status of my design projects?',
      'Design project status (pending, in review, approved, revision) is shown on your dashboard under the Projects section, with real-time updates as the team works on it.',
    ),
    _Faq(
      'Who can I contact for billing or invoice queries?',
      'Reach out to our support team using the contact options below and mention your account email — our team typically responds within 24 hours.',
    ),
    _Faq(
      'Is my data secure on this app?',
      'Yes. All data is transmitted over encrypted connections and stored securely. You can read the full details in our Privacy Policy.',
    ),
  ];

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=Support Request',
    );
    try {
      await launchUrl(uri);
    } catch (_) {
      _showSnack('Could not open email app.');
    }
  }

  Future<void> _launchCall() async {
    final uri = Uri(scheme: 'tel', path: _supportPhone);
    try {
      await launchUrl(uri);
    } catch (_) {
      _showSnack('Could not open dialer.');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.sora(fontSize: 13)),
      backgroundColor: AppColors.error,
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
          child: Text('Help & Support',
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
            // ── Contact options ──
            Row(
              children: [
                Expanded(
                  child: _ContactTile(
                    icon: Icons.email_outlined,
                    label: 'Email Us',
                    subtitle: _supportEmail,
                    accentColor: widget.accentColor,
                    onTap: _launchEmail,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ContactTile(
                    icon: Icons.call_outlined,
                    label: 'Call Us',
                    subtitle: 'Mon-Sat, 10AM-7PM',
                    accentColor: widget.accentColor,
                    onTap: _launchCall,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

            const SizedBox(height: 28),

            Text('Frequently Asked Questions',
                style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Tap a question to expand the answer',
                style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),

            // ── FAQ Accordion ──
            ...List.generate(_faqs.length, (i) {
              final faq = _faqs[i];
              final isExpanded = _expandedIndex == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CommonCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _expandedIndex = isExpanded ? null : i);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: widget.accentColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(Icons.help_outline_rounded, color: widget.accentColor, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(faq.question,
                                    style: GoogleFonts.sora(
                                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              ),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textMuted, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox(width: double.infinity, height: 0),
                        secondChild: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(width: 44),
                              Expanded(
                                child: Text(faq.answer,
                                    style: GoogleFonts.sora(
                                        fontSize: 12.5, color: AppColors.textSecondary, height: 1.5)),
                              ),
                            ],
                          ),
                        ),
                        crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 220),
                        sizeCurve: Curves.easeInOut,
                      ),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 100 + i * 60)).fadeIn().slideX(begin: 0.1, end: 0);
            }),

            const SizedBox(height: 8),

            // ── Still need help card ──
            CommonCard(
              gradient: widget.gradient,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Still need help?',
                      style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Our support team is just a message away.',
                      style: GoogleFonts.sora(fontSize: 12, color: Colors.white.withOpacity(0.85))),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _launchEmail,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.support_agent_rounded, size: 16, color: widget.accentColor),
                          const SizedBox(width: 8),
                          Text('Contact Support',
                              style: GoogleFonts.sora(
                                  fontSize: 12.5, fontWeight: FontWeight.w700, color: widget.accentColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate(delay: Duration(milliseconds: 100 + _faqs.length * 60)).fadeIn(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.sora(fontSize: 10.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
