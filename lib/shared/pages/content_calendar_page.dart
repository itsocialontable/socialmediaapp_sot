// lib/shared/pages/content_calendar_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/client_calendar_provider.dart';
import '../../model/client_calendar_model.dart';

class ContentCalendarPage extends StatefulWidget {
  final Color? accentColor;
  final LinearGradient? accentGradient;

  const ContentCalendarPage({
    super.key,
    this.accentColor,
    this.accentGradient,
  });

  @override
  State<ContentCalendarPage> createState() => _ContentCalendarPageState();
}

class _ContentCalendarPageState extends State<ContentCalendarPage> {
  Color get _accent => widget.accentColor ?? AppColors.clientColor;
  LinearGradient get _gradient =>
      widget.accentGradient ?? AppColors.clientGradient;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientCalendarProvider>().fetchCalendar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientCalendarProvider>(
      builder: (_, provider, __) {
        return Column(
          children: [
            // Month navigator
            _MonthNavigator(provider: provider, accent: _accent, gradient: _gradient),
            const SizedBox(height: 12),

            // Weekday headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((d) => Expanded(
                  child: Center(
                    child: Text(d,
                        style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted)),
                  ),
                ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Calendar grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CalendarGrid(provider: provider, accent: _accent, gradient: _gradient),
            ),

            const SizedBox(height: 16),

            // Selected date label + post count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: _gradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _selectedDateLabel(provider),
                    style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  _PostCountBadge(
                      count: provider.postsForSelectedDay.length,
                      accent: _accent),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 12),

            // Posts list
            Expanded(
              child: _PostsList(provider: provider, accent: _accent, gradient: _gradient),
            ),
          ],
        );
      },
    );
  }

  String _selectedDateLabel(ClientCalendarProvider p) {
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[p.month]} ${p.selectedDay}, ${p.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month navigator
// ─────────────────────────────────────────────────────────────────────────────

class _MonthNavigator extends StatelessWidget {
  final ClientCalendarProvider provider;
  final Color accent;
  final LinearGradient gradient;

  const _MonthNavigator({
    required this.provider,
    required this.accent,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ← Previous
          GestureDetector(
            onTap: provider.calendarState.isLoading
                ? null
                : provider.previousMonth,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(Icons.chevron_left_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),

          // Month + Year
          Column(
            children: [
              Text(provider.monthName,
                  style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text('${provider.year}',
                  style: GoogleFonts.sora(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),

          // → Next
          GestureDetector(
            onTap: provider.calendarState.isLoading
                ? null
                : provider.nextMonth,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Calendar grid
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final ClientCalendarProvider provider;
  final Color accent;
  final LinearGradient gradient;

  const _CalendarGrid({
    required this.provider,
    required this.accent,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final firstWeekday =
        DateTime(provider.year, provider.month, 1).weekday % 7; // Sun=0
    final daysInMonth =
    DateUtils.getDaysInMonth(provider.year, provider.month);
    final today = DateTime.now();
    final isCurrentMonth =
        today.month == provider.month && today.year == provider.year;

    final rows = ((firstWeekday + daysInMonth) / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final index = row * 7 + col;
            final day = index - firstWeekday + 1;
            final valid = day >= 1 && day <= daysInMonth;

            if (!valid) {
              return const Expanded(child: SizedBox(height: 44));
            }

            final isSelected = provider.selectedDay == day;
            final isToday = isCurrentMonth && today.day == day;
            final hasPosts = provider.daysWithPosts.contains(day);
            final postCount = provider.postCountForDay(day);

            return Expanded(
              child: GestureDetector(
                onTap: () => provider.selectDay(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 44,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: isSelected ? gradient : null,
                    color: isSelected
                        ? null
                        : isToday
                        ? accent.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(color: accent.withOpacity(0.4))
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isToday
                              ? accent
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (hasPosts) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            postCount.clamp(1, 3),
                                (_) => Container(
                              width: 4,
                              height: 4,
                              margin:
                              const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.8)
                                    : accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    ).animate().fadeIn(duration: 250.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Posts list for selected day
// ─────────────────────────────────────────────────────────────────────────────

class _PostsList extends StatelessWidget {
  final ClientCalendarProvider provider;
  final Color accent;
  final LinearGradient gradient;

  const _PostsList({
    required this.provider,
    required this.accent,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final state = provider.calendarState;

    if (state.isLoading) {
      return Center(
          child: CircularProgressIndicator(color: accent, strokeWidth: 2.5));
    }

    if (state.isError) {
      return _ErrorView(
        message: state.message ?? 'Failed to load calendar.',
        accent: accent,
        gradient: gradient,
        onRetry: () => provider.fetchCalendar(),
      );
    }

    final posts = provider.postsForSelectedDay;

    if (posts.isEmpty) return _EmptyView(accent: accent);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: posts.length,
      itemBuilder: (_, i) =>
          _PostCard(post: posts[i], index: i, accent: accent),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post card
// ─────────────────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final ClientCalendarPost post;
  final int index;
  final Color accent;

  const _PostCard({
    required this.post,
    required this.index,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Platform colour strip on the left
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: post.platformColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row + status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              post.title,
                              style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: post.statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              post.displayStatus,
                              style: GoogleFonts.sora(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: post.statusColor),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Platform chip + time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: post.platformColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(post.platformIcon,
                                    size: 12, color: post.platformColor),
                                const SizedBox(width: 4),
                                Text(
                                  post.platform.isEmpty
                                      ? 'Platform'
                                      : post.platform[0].toUpperCase() +
                                      post.platform.substring(1),
                                  style: GoogleFonts.sora(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: post.platformColor),
                                ),
                              ],
                            ),
                          ),
                          if (post.scheduledTime != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.access_time_rounded,
                                size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              post.scheduledTime!,
                              style: GoogleFonts.sora(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),

                      // Caption (optional)
                      if (post.caption != null &&
                          post.caption!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          post.caption!,
                          style: GoogleFonts.sora(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 60 * index))
          .fadeIn()
          .slideY(begin: 0.1, end: 0, duration: 250.ms, curve: Curves.easeOut),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _PostCountBadge extends StatelessWidget {
  final int count;
  final Color accent;
  const _PostCountBadge({required this.count, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count post${count > 1 ? 's' : ''}',
        style: GoogleFonts.sora(
            fontSize: 11, fontWeight: FontWeight.w600, color: accent),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final Color accent;
  const _EmptyView({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('No posts scheduled for this day.',
              style: GoogleFonts.sora(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Color accent;
  final LinearGradient gradient;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.accent,
    required this.gradient,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('Retry',
                    style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
