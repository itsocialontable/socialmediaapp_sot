import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/client_design_project_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/pages/messages_page.dart';
import '../../../shared/pages/profile_page.dart';
import '../../../shared/pages/content_calendar_page.dart';
import 'pages/client_inner_pages.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});
  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientDesignProjectProvider>().fetchProjects();
    });
  }

  String get _title {
    switch (_navIndex) {
      case 0: return 'Dashboard';
      case 1: return 'My Projects';
      case 2: return 'Calendar';
      case 3: return 'Messages';
      case 4: return 'Profile';
      default: return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return CommonScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _navIndex == 0
                          ? Text('Hi, ${auth.userName} 👋',
                              style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary))
                          : ShaderMask(
                              shaderCallback: (b) => AppColors.clientGradient.createShader(b),
                              child: Text(_title,
                                  style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                      if (_navIndex == 0)
                        Text("Here's the update on your projects",
                            style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(gradient: AppColors.clientGradient, shape: BoxShape.circle),
                        child: Center(child: Text('A', style: GoogleFonts.sora(fontWeight: FontWeight.w700, color: Colors.white))),
                      ),
                      Positioned(right: 0, top: 0,
                        child: Container(width: 16, height: 16,
                          decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 2)),
                          child: Center(child: Text('7', style: GoogleFonts.sora(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white))))),
                    ],
                  ),
                ],
              ).animate().fadeIn(),
            ),
            Expanded(child: _buildPage()),
          ],
        ),
      ),
      bottomNavigationBar: CommonBottomNav(
        currentIndex: _navIndex,
        activeColor: AppColors.clientColor,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
          BottomNavItem(icon: Icons.folder_outlined, activeIcon: Icons.folder_rounded, label: 'Projects'),
          BottomNavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Calendar'),
          BottomNavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Messages'),
          BottomNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_navIndex) {
      case 0: return _ClientHome(onNav: (i) => setState(() => _navIndex = i));
      case 1: return const ClientProjectsPage();
      case 2: return ContentCalendarPage(accentColor: AppColors.clientColor, accentGradient: AppColors.clientGradient);
      case 3: return MessagesPage(accentColor: AppColors.clientColor, gradient: AppColors.clientGradient);
      case 4: return ProfilePage(accentColor: AppColors.clientColor, gradient: AppColors.clientGradient);
      default: return _ClientHome(onNav: (i) => setState(() => _navIndex = i));
    }
  }
}

class _ClientHome extends StatelessWidget {
  final Function(int) onNav;
  const _ClientHome({required this.onNav});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientDesignProjectProvider>(
      builder: (_, provider, __) {
        final all = provider.allProjects;
        final pendingReview = provider.pendingReviewProjects;
        final inProgress = provider.inProgressProjects;
        final completed = provider.completedProjects;

        // Take up to 3 projects for the home preview
        final previewProjects = all.take(3).toList();
        // Pending review items to show in approvals
        final approvals = pendingReview.take(3).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  StatCard(
                    label: 'Active Projects',
                    value: provider.listState.isLoading
                        ? '—'
                        : inProgress.length.toString(),
                    icon: Icons.folder_rounded,
                    color: AppColors.clientColor,
                  ),
                  StatCard(
                    label: 'Pending Approvals',
                    value: provider.listState.isLoading
                        ? '—'
                        : pendingReview.length.toString(),
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.warning,
                  ),
                  StatCard(
                    label: 'Total Projects',
                    value: provider.listState.isLoading
                        ? '—'
                        : all.length.toString(),
                    icon: Icons.schedule_rounded,
                    color: AppColors.info,
                  ),
                  StatCard(
                    label: 'Completed',
                    value: provider.listState.isLoading
                        ? '—'
                        : completed.length.toString(),
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                ],
              ).animate(delay: 100.ms).fadeIn(),

              const SizedBox(height: 24),

              // Row(
              //   children: [
              //     _ClientQuickNav(Icons.folder_rounded, 'Projects',
              //         AppColors.clientColor, () => onNav(1)),
              //     const SizedBox(width: 10),
              //     _ClientQuickNav(Icons.calendar_month_rounded, 'Calendar',
              //         AppColors.info, () => onNav(2)),
              //     const SizedBox(width: 10),
              //     _ClientQuickNav(Icons.chat_bubble_rounded, 'Messages',
              //         AppColors.secondary, () => onNav(3)),
              //     const SizedBox(width: 10),
              //     _ClientQuickNav(
              //         Icons.bar_chart_rounded, 'Reports', AppColors.success, () {}),
              //   ],
              // ).animate(delay: 200.ms).fadeIn(),
              //
              // const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Projects',
                      style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  GestureDetector(
                    onTap: () => onNav(1),
                    child: Text('View All',
                        style: GoogleFonts.sora(
                            fontSize: 12, color: AppColors.clientColor)),
                  ),
                ],
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 12),

              // Projects list from API
              if (provider.listState.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.listState.isError)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    provider.listState.message ?? 'Failed to load projects.',
                    style: GoogleFonts.sora(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                )
              else if (previewProjects.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No projects yet.',
                    style: GoogleFonts.sora(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                )
              else
                ...previewProjects.asMap().entries.map((e) {
                  final p = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CommonCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(p.title,
                                    style: GoogleFonts.sora(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                              ),
                              Text('${p.progressPercentage}%',
                                  style: GoogleFonts.sora(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.clientColor)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(p.designType,
                              style: GoogleFonts.sora(
                                  fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: p.progressFraction,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.clientColor),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ).animate(
                        delay: Duration(milliseconds: 350 + e.key * 80)).fadeIn(),
                  );
                }),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Approvals',
                      style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  if (pendingReview.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Pending (${pendingReview.length})',
                        style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning),
                      ),
                    ),
                ],
              ).animate(delay: 600.ms).fadeIn(),

              const SizedBox(height: 12),

              if (approvals.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No pending approvals.',
                    style: GoogleFonts.sora(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                )
              else
                ...approvals.asMap().entries.map((e) {
                  final a = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CommonCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: AppColors.clientGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.image_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title,
                                    style: GoogleFonts.sora(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                                Text(
                                  a.assignedTo?.name ?? a.designType,
                                  style: GoogleFonts.sora(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text("hjdbhehc"),
                          Row(children: [
                            GestureDetector(
                              onTap: () => _quickApprove(context, a.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  gradient: AppColors.clientGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Approve',
                                    style: GoogleFonts.sora(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _showDetailSheet(context, a.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.error.withOpacity(0.3)),
                                ),
                                child: Text('Changes',
                                    style: GoogleFonts.sora(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.error)),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ).animate(
                        delay:
                            Duration(milliseconds: 650 + e.key * 80)).fadeIn(),
                  );
                }),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  /// Quick approve from the home page approval card
  Future<void> _quickApprove(BuildContext context, String projectId) async {
    final provider = context.read<ClientDesignProjectProvider>();
    final ok = await provider.submitReview(
      projectId: projectId,
      action: 'approved',
      feedback: '',
    );
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project approved!')),
      );
      provider.fetchProjects(silent: true);
    } else if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.reviewState.message ?? 'Approval failed.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Open project detail sheet (for "Changes" tap)
  void _showDetailSheet(BuildContext context, String projectId) {
    context.read<ClientDesignProjectProvider>().fetchProjectById(projectId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ClientDesignProjectProvider>(),
        child: _ClientApprovalDetailSheet(projectId: projectId),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Minimal detail sheet opened from home approval cards ("Changes" tap)
// ─────────────────────────────────────────────────────────────────────────────

class _ClientApprovalDetailSheet extends StatefulWidget {
  final String projectId;
  const _ClientApprovalDetailSheet({required this.projectId});

  @override
  State<_ClientApprovalDetailSheet> createState() =>
      _ClientApprovalDetailSheetState();
}

class _ClientApprovalDetailSheetState
    extends State<_ClientApprovalDetailSheet> {
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientDesignProjectProvider>(
      builder: (_, provider, __) {
        final review = provider.reviewState;
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Request Changes',
                  style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('Describe the changes you\'d like the designer to make.',
                  style: GoogleFonts.sora(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              if (review.isSuccess)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Text(
                    review.message ?? 'Change request submitted!',
                    style: GoogleFonts.sora(
                        fontSize: 12, color: AppColors.info),
                  ),
                )
              else ...[
                CommonCard(
                  padding: const EdgeInsets.all(12),
                  child: TextFormField(
                    controller: _feedbackController,
                    maxLines: 4,
                    style: GoogleFonts.sora(
                        fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. Please adjust the color palette...',
                      hintStyle: GoogleFonts.sora(
                          fontSize: 12, color: AppColors.textMuted),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (review.isError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      review.message ?? 'Failed to submit.',
                      style: GoogleFonts.sora(
                          fontSize: 12, color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: 16),
                review.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GestureDetector(
                        onTap: () async {
                          final feedback =
                              _feedbackController.text.trim();
                          if (feedback.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please enter your feedback.')),
                            );
                            return;
                          }
                          final ok = await provider.submitReview(
                            projectId: widget.projectId,
                            action: 'changes_requested',
                            feedback: feedback,
                          );
                          if (ok && mounted) {
                            provider.fetchProjects(silent: true);
                            await Future.delayed(
                                const Duration(seconds: 1));
                            if (mounted) Navigator.of(context).pop();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.4)),
                          ),
                          child: Center(
                            child: Text('Submit Change Request',
                                style: GoogleFonts.sora(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error)),
                          ),
                        ),
                      ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// class _ClientQuickNav extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback onTap;
//   const _ClientQuickNav(this.icon, this.label, this.color, this.onTap);
//
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         child: CommonCard(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Column(
//             children: [
//               Container(width: 34, height: 34,
//                 decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(9)),
//                 child: Icon(icon, color: color, size: 16)),
//               const SizedBox(height: 5),
//               Text(label, style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
