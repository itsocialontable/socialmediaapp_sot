import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

// ─────────────────────────────────────────
// SMM POST SCHEDULING PAGE
// ─────────────────────────────────────────
class SmmSchedulePage extends StatefulWidget {
  const SmmSchedulePage({super.key});
  @override
  State<SmmSchedulePage> createState() => _SmmSchedulePageState();
}

class _SmmSchedulePageState extends State<SmmSchedulePage> {
  final _platforms = ['Instagram', 'Facebook', 'LinkedIn', 'Twitter', 'YouTube'];
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Post Card
          CommonCard(
            gradient: AppColors.smmGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Schedule New Post',
                    style: GoogleFonts.sora(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Plan and schedule your content',
                    style: GoogleFonts.sora(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text('Create Post',
                            style: GoogleFonts.sora(
                                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 20),

          // Platform Selector
          Text('Select Platforms',
              style: GoogleFonts.sora(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))
              .animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _platforms.map((p) {
              final isSelected = _selected.contains(p);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) _selected.remove(p); else _selected.add(p);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.smmGradient : null,
                    color: isSelected ? null : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected ? null : Border.all(color: AppColors.border),
                  ),
                  child: Text(p,
                      style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textSecondary)),
                ),
              );
            }).toList(),
          ).animate(delay: 150.ms).fadeIn(),

          const SizedBox(height: 20),

          // Caption
          CommonTextField(
            label: 'Post Caption',
            hint: 'Write your post caption here...',
            prefixIcon: Icons.edit_note_rounded,
            accentColor: AppColors.smmColor,
          ).animate(delay: 200.ms).fadeIn(),

          const SizedBox(height: 14),

          // Date & Time
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  label: 'Date',
                  hint: 'May 16, 2024',
                  prefixIcon: Icons.calendar_today_rounded,
                  accentColor: AppColors.smmColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: CommonTextField(
                  label: 'Time',
                  hint: '10:00 AM',
                  prefixIcon: Icons.schedule_rounded,
                  accentColor: AppColors.smmColor,
                ),
              ),
            ],
          ).animate(delay: 250.ms).fadeIn(),

          const SizedBox(height: 14),

          CommonTextField(
            label: 'Client / Project',
            hint: 'Select client...',
            prefixIcon: Icons.people_rounded,
            accentColor: AppColors.smmColor,
          ).animate(delay: 300.ms).fadeIn(),

          const SizedBox(height: 24),

          CommonButton(
            label: 'Schedule Post',
            gradient: AppColors.smmGradient,
            onTap: () {},
          ).animate(delay: 350.ms).fadeIn(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// SMM APPROVALS PAGE
// ─────────────────────────────────────────
class SmmApprovalsPage extends StatefulWidget {
  const SmmApprovalsPage({super.key});
  @override
  State<SmmApprovalsPage> createState() => _SmmApprovalsPageState();
}

class _SmmApprovalsPageState extends State<SmmApprovalsPage> {
  int _tab = 0;
  final _tabs = ['Pending (16)', 'Approved', 'Rejected'];

  final _approvals = [
    _Approval('Instagram Post', 'Summer Collection', 'By Sarah Designer', '2h ago', false),
    _Approval('Facebook Cover', 'New Arrivals', 'By Mike Designer', '3h ago', false),
    _Approval('LinkedIn Post', 'Our New Office', 'By Sarah Designer', '5h ago', false),
    _Approval('Instagram Reel', 'Behind the Scenes', 'By James Designer', '6h ago', false),
    _Approval('Twitter Banner', 'Product Launch', 'By Emily Designer', 'Yesterday', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: _tabs.asMap().entries.map((e) {
              final isSelected = e.key == _tab;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _tab = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.smmGradient : null,
                      color: isSelected ? null : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? null : Border.all(color: AppColors.border),
                    ),
                    child: Text(e.value,
                        style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSecondary)),
                  ),
                ),
              );
            }).toList(),
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 12),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _approvals.length,
            itemBuilder: (_, i) {
              final a = _approvals[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CommonCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppColors.smmGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.image_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title,
                                    style: GoogleFonts.sora(
                                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text(a.subtitle,
                                    style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
                                Text('${a.by} • ${a.time}',
                                    style: GoogleFonts.sora(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  gradient: AppColors.smmGradient,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text('Approve',
                                      style: GoogleFonts.sora(
                                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                                ),
                                child: Center(
                                  child: Text('Reject',
                                      style: GoogleFonts.sora(
                                          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// SMM CLIENT MANAGEMENT PAGE
// ─────────────────────────────────────────
class SmmClientsPage extends StatelessWidget {
  const SmmClientsPage({super.key});

  final _clients = const [
    ('Fashion Brand', 'Instagram, Facebook', 'Active', 10, 5),
    ('Tech Company', 'LinkedIn, Twitter', 'Active', 8, 3),
    ('Travel Agency', 'All Platforms', 'On Hold', 5, 7),
    ('Food Restaurant', 'Instagram', 'Active', 12, 2),
    ('Fitness Brand', 'Instagram, YouTube', 'Active', 6, 4),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _clients.length,
      itemBuilder: (_, i) {
        final c = _clients[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CommonCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.smmGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(c.$1[0],
                            style: GoogleFonts.sora(
                                fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.$1,
                              style: GoogleFonts.sora(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          Text(c.$2,
                              style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (c.$3 == 'Active' ? AppColors.success : AppColors.warning).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(c.$3,
                          style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: c.$3 == 'Active' ? AppColors.success : AppColors.warning)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _MiniStat('${c.$4}', 'Scheduled', AppColors.smmColor),
                    const SizedBox(width: 10),
                    _MiniStat('${c.$5}', 'Pending', AppColors.warning),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {},
                      child: Text('View Details',
                          style: GoogleFonts.sora(
                              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.smmColor)),
                    ),
                  ],
                ),
              ],
            ),
          ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _MiniStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(value,
              style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Approval {
  final String title, subtitle, by, time;
  final bool approved;
  const _Approval(this.title, this.subtitle, this.by, this.time, this.approved);
}
