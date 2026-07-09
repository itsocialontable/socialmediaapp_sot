import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../model/social_platform_model.dart';
import 'common_widgets.dart';

class SocialPlatformCard extends StatelessWidget {
  final SocialPlatformModel platform;
  final bool loading;
  final VoidCallback onActionPressed;

  const SocialPlatformCard({
    super.key,
    required this.platform,
    required this.onActionPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: platform.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(platform.icon, size: 26, color: platform.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      platform.name,
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (platform.connected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Connected',
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  platform.connected
                      ? platform.connectionLabel
                      : 'Tap to connect your account',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: CommonButton(
              label: platform.connected ? 'Disconnect' : 'Connect',
              onTap: loading ? null : onActionPressed,
              isLoading: loading,
              outlined: platform.connected,
              height: 38,
            ),
          ),
        ],
      ),
    );
  }
}