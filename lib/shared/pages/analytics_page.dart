import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AnalyticsPage extends StatefulWidget {
  final Color accentColor;
  final LinearGradient gradient;

  const AnalyticsPage({
    super.key,
    required this.accentColor,
    required this.gradient,
  });

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int _selectedPeriod = 1;
  final _periods = ['Week', 'Month', 'Year'];

  final _platformStats = [
    _PlatformStat('Instagram', '156.2K', '+15.5%', const Color(0xFFE1306C), 0.82),
    _PlatformStat('Facebook', '245.6K', '+11.2%', const Color(0xFF1877F2), 0.68),
    _PlatformStat('LinkedIn', '38.4K', '+8.2%', const Color(0xFF0A66C2), 0.45),
    _PlatformStat('Twitter', '28.4K', '+6.7%', const Color(0xFF1DA1F2), 0.38),
    _PlatformStat('YouTube', '8.6K', '+4.7%', const Color(0xFFFF0000), 0.28),
  ];

  final _topPosts = [
    _TopPost('Summer Collection Launch', 'Instagram', '5.3K Reach', '8.3% Eng.'),
    _TopPost('New Product Reveal', 'Facebook', '4.1K Reach', '6.2% Eng.'),
    _TopPost('Behind the Scenes', 'Instagram', '3.8K Reach', '5.9% Eng.'),
  ];

  // Bar chart data (normalized 0-1)
  final _weekData = [0.4, 0.65, 0.5, 0.8, 0.6, 0.9, 0.7];
  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          Row(
            children: List.generate(_periods.length, (i) {
              final isSelected = i == _selectedPeriod;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? widget.gradient : null,
                      color: isSelected ? null : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? null : Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _periods[i],
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ).animate().fadeIn(),

          const SizedBox(height: 20),

          // Overview Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatCard(label: 'Total Reach', value: '156.2K',icon: Icons.people_rounded, color: widget.accentColor),
              StatCard(label: 'Engagement', value: '28.4K',  icon: Icons.favorite_rounded, color: AppColors.secondary),
              StatCard(label: 'Impressions', value: '245.6K',  icon: Icons.visibility_rounded, color: AppColors.info),
              StatCard(label: 'Profile Visits', value: '8.6K',icon: Icons.person_search_rounded, color: AppColors.accent),
            ],
          ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 24),

          // Engagement Chart
          CommonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Engagement Overview',
                        style: GoogleFonts.sora(
                            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('This Week',
                        style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _weekData.asMap().entries.map((e) {
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 100 * e.value,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.accentColor,
                                    widget.accentColor.withOpacity(0.4),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(_days[e.key],
                                style: GoogleFonts.sora(
                                    fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(),

          const SizedBox(height: 20),

          // Platform Performance
          Text('Platform Performance',
              style: GoogleFonts.sora(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary))
              .animate(delay: 300.ms).fadeIn(),

          const SizedBox(height: 12),

          ..._platformStats.asMap().entries.map((e) {
            final p = e.value;
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
                            color: p.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(p.platform[0],
                                style: GoogleFonts.sora(
                                    fontWeight: FontWeight.w700, color: p.color)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(p.platform,
                              style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(p.reach,
                                style: GoogleFonts.sora(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            Text(p.growth,
                                style: GoogleFonts.sora(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: p.progress,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(p.color),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: Duration(milliseconds: 350 + e.key * 60)).fadeIn(),
            );
          }),

          const SizedBox(height: 20),

          // Top Performing Posts
          Text('Top Performing Posts',
              style: GoogleFonts.sora(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary))
              .animate(delay: 650.ms).fadeIn(),

          const SizedBox(height: 12),

          ..._topPosts.asMap().entries.map((e) {
            final p = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CommonCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: widget.gradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title,
                              style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          Text(p.platform,
                              style:
                                  GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(p.reach,
                            style: GoogleFonts.sora(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text(p.engagement,
                            style: GoogleFonts.sora(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: widget.accentColor)),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: Duration(milliseconds: 700 + e.key * 60)).fadeIn(),
            );
          }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PlatformStat {
  final String platform, reach, growth;
  final Color color;
  final double progress;
  const _PlatformStat(this.platform, this.reach, this.growth, this.color, this.progress);
}

class _TopPost {
  final String title, platform, reach, engagement;
  const _TopPost(this.title, this.platform, this.reach, this.engagement);
}
