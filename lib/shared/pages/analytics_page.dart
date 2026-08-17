// lib/shared/pages/analytics_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/posts_analytics_provider.dart';
import '../../model/posts_analytics_overview_model.dart';
import '../../model/social_platform_model.dart';
import '../widgets/common_widgets.dart';

class AnalyticsPage extends StatefulWidget {
  final Color accentColor;
  final LinearGradient gradient;

  /// Optional client scope. Leave null for "my own" overview (SMM), pass a
  /// client id when this page is reused to drill into a single client
  /// (e.g. from Admin).
  final String? clientId;

  const AnalyticsPage({
    super.key,
    required this.accentColor,
    required this.gradient,
    this.clientId,
  });

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (!mounted) return;
    context.read<PostsAnalyticsProvider>().fetchOverview(clientId: widget.clientId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PostsAnalyticsProvider>(
      builder: (context, provider, _) {
        final res = provider.response;

        if (res.isLoading || res.isIdle) {
          return Center(child: CircularProgressIndicator(color: widget.accentColor));
        }

        if (res.isError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 32),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    res.message ?? 'Failed to load analytics.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _load,
                  child: Text(
                    'Retry',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final overview = provider.overview;
        final analytics = overview.analytics;
        final posts = overview.posts;

        return RefreshIndicator(
          color: widget.accentColor,
          backgroundColor: AppColors.surfaceLight,
          onRefresh: () => provider.fetchOverview(clientId: widget.clientId, silent: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overview.client?.name != null) ...[
                  Text(
                    overview.client!.name!,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Overview Cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                  children: [
                    StatCard(
                      label: 'Total Reach',
                      value: _formatCount(analytics.totalReach),
                      icon: Icons.people_rounded,
                      color: widget.accentColor,
                    ),
                    StatCard(
                      label: 'Engagement',
                      value: _formatCount(analytics.totalEngagement),
                      icon: Icons.favorite_rounded,
                      color: AppColors.secondary,
                    ),
                    StatCard(
                      label: 'Impressions',
                      value: _formatCount(analytics.totalImpressions),
                      icon: Icons.visibility_rounded,
                      color: AppColors.info,
                    ),
                    StatCard(
                      label: 'Profile Visits',
                      value: _formatCount(analytics.totalProfileViews),
                      icon: Icons.person_search_rounded,
                      color: AppColors.primaryLight,
                    ),
                  ],
                ).animate().fadeIn(),

                const SizedBox(height: 24),

                // Posts Overview
                Text(
                  'Posts Overview',
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ).animate(delay: 100.ms).fadeIn(),

                const SizedBox(height: 12),

                CommonCard(
                  child: Row(
                    children: [
                      _PostCountItem(label: 'Total', value: posts.totalPosts, color: widget.accentColor),
                      _PostCountItem(label: 'Published', value: posts.publishedPosts, color: AppColors.success),
                      _PostCountItem(label: 'Scheduled', value: posts.scheduledPosts, color: AppColors.info),
                      _PostCountItem(label: 'Queued', value: posts.queuedPosts, color: AppColors.warning),
                      _PostCountItem(label: 'Drafts', value: posts.draftPosts, color: AppColors.textMuted),
                    ],
                  ),
                ).animate(delay: 150.ms).fadeIn(),

                const SizedBox(height: 24),

                // Platform Performance
                Text(
                  'Platform Performance',
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ).animate(delay: 200.ms).fadeIn(),

                const SizedBox(height: 12),

                if (analytics.byPlatform.isEmpty)
                  _EmptySection(
                    icon: Icons.bar_chart_rounded,
                    message: 'No platform analytics yet',
                    accentColor: widget.accentColor,
                  )
                else ...[
                      () {
                    final maxReach = analytics.byPlatform
                        .map((p) => p.reach)
                        .fold<int>(0, (a, b) => a > b ? a : b);
                    return Column(
                      children: analytics.byPlatform.asMap().entries.map((e) {
                        final p = e.value;
                        final meta = SocialPlatformModel.fromPlatformName(p.platform);
                        final progress = maxReach == 0 ? 0.0 : (p.reach / maxReach).clamp(0.0, 1.0);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CommonCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: meta.color.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(meta.icon, size: 18, color: meta.color),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meta.name,
                                            style: GoogleFonts.sora(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '${p.posts} post${p.posts == 1 ? '' : 's'}',
                                            style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatCount(p.reach),
                                          style: GoogleFonts.sora(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${_formatCount(p.likes + p.comments + p.shares)} eng.',
                                          style: GoogleFonts.sora(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: AppColors.border,
                                    valueColor: AlwaysStoppedAnimation<Color>(meta.color),
                                    minHeight: 5,
                                  ),
                                ),
                              ],
                            ),
                          ).animate(delay: Duration(milliseconds: 250 + e.key * 60)).fadeIn(),
                        );
                      }).toList(),
                    );
                  }(),
                ],

                const SizedBox(height: 24),

                // Profile Views by Platform
                if (analytics.profileViewsByPlatform.isNotEmpty) ...[
                  Text(
                    'Profile Views by Platform',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ).animate(delay: 550.ms).fadeIn(),

                  const SizedBox(height: 12),

                  ...analytics.profileViewsByPlatform.asMap().entries.map((e) {
                    final p = e.value;
                    final meta = SocialPlatformModel.fromPlatformName(p.platform);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CommonCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: widget.gradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(meta.icon, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                meta.name,
                                style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatCount(p.profileViews),
                                  style: GoogleFonts.sora(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${_formatCount(p.reach)} reach',
                                  style: GoogleFonts.sora(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: widget.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate(delay: Duration(milliseconds: 600 + e.key * 60)).fadeIn(),
                    );
                  }),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PostCountItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _PostCountItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color accentColor;

  const _EmptySection({required this.icon, required this.message, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: accentColor.withOpacity(0.5), size: 28),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact count formatting: 1234 -> "1.2K", 1560000 -> "1.6M".
String _formatCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}