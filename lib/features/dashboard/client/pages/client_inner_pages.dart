// lib/features/dashboard/client/pages/client_inner_pages.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/errors/api_response.dart';
import '../../../../core/providers/client_design_project_provider.dart';
import '../../../../model/client_design_project_model.dart';
import '../../../../shared/widgets/common_widgets.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CLIENT PROJECTS PAGE
// List view — GET /api/client/design-projects
// ═════════════════════════════════════════════════════════════════════════════

class ClientProjectsPage extends StatefulWidget {
  const ClientProjectsPage({super.key});

  @override
  State<ClientProjectsPage> createState() => _ClientProjectsPageState();
}

class _ClientProjectsPageState extends State<ClientProjectsPage> {
  int _tab = 0;
  final _tabs = ['All', 'In Progress', 'Pending Review', 'Completed'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientDesignProjectProvider>().fetchProjects();
    });
  }

  List<ClientDesignProject> _filtered(
      List<ClientDesignProject> all, int tab) {
    switch (tab) {
      case 1:
        return all.where((p) => p.isInProgress).toList();
      case 2:
        return all.where((p) => p.isPendingReview).toList();
      case 3:
        return all.where((p) => p.isCompleted || p.isApproved).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientDesignProjectProvider>(
      builder: (_, provider, __) {
        final state = provider.listState;

        return Column(
          children: [
            // ── Tab bar ───────────────────────────────────────────────────
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? AppColors.clientGradient
                              : null,
                          color: isSelected
                              ? null
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? null
                              : Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          e.value,
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 12),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(child: _buildBody(state, provider)),
          ],
        );
      },
    );
  }

  Widget _buildBody(
    ApiResponse<List<ClientDesignProject>> state,
    ClientDesignProjectProvider provider,
  ) {
    if (state.isLoading) {
      return const _LoadingView();
    }

    if (state.isError) {
      return _ErrorView(
        message: state.message ?? 'Something went wrong.',
        onRetry: () => provider.fetchProjects(),
      );
    }

    final projects = _filtered(provider.allProjects, _tab);

    if (projects.isEmpty) {
      return _EmptyView(
        message: _tab == 0
            ? 'No design projects yet.'
            : 'No projects in this category.',
      );
    }

    return RefreshIndicator(
      color: AppColors.clientColor,
      onRefresh: () => provider.fetchProjects(silent: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: projects.length,
        itemBuilder: (_, i) => _ProjectCard(
          project: projects[i],
          index: i,
          onTap: () => _openDetail(context, projects[i]),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, ClientDesignProject project) {
    context
        .read<ClientDesignProjectProvider>()
        .fetchProjectById(project.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ClientDesignProjectProvider>(),
        child: _ProjectDetailSheet(projectId: project.id),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Project card
// ─────────────────────────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final ClientDesignProject project;
  final int index;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.index,
    required this.onTap,
  });

  Color get _statusColor {
    if (project.isApproved) return AppColors.success;
    if (project.isPendingReview) return AppColors.warning;
    if (project.isCompleted) return AppColors.info;
    return AppColors.clientColor;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
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
                      gradient: AppColors.clientGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        project.title.isNotEmpty ? project.title[0] : '?',
                        style: GoogleFonts.sora(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                        Text(
                          project.designType,
                          style: GoogleFonts.sora(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      project.displayStatus,
                      style: GoogleFonts.sora(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: GoogleFonts.sora(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${project.progressPercentage}%',
                    style: GoogleFonts.sora(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.clientColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: project.progressFraction,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.clientColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (project.deadline != null) ...[
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Deadline: ${_formatDate(project.deadline!)}',
                      style: GoogleFonts.sora(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    'View Details →',
                    style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.clientColor),
                  ),
                ],
              ),
            ],
          ),
        ).animate(delay: Duration(milliseconds: 60 * index)).fadeIn(),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_month(dt.month)} ${dt.year}';

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ═════════════════════════════════════════════════════════════════════════════
// PROJECT DETAIL BOTTOM SHEET
// Detail + Review — GET /:id  +  PATCH /:id/review
// ═════════════════════════════════════════════════════════════════════════════

class _ProjectDetailSheet extends StatefulWidget {
  final String projectId;
  const _ProjectDetailSheet({required this.projectId});

  @override
  State<_ProjectDetailSheet> createState() => _ProjectDetailSheetState();
}

class _ProjectDetailSheetState extends State<_ProjectDetailSheet> {
  final _feedbackController = TextEditingController();
  bool _showFeedbackField = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientDesignProjectProvider>(
      builder: (_, provider, __) {
        final detail = provider.detailState;
        final review = provider.reviewState;

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Content ───────────────────────────────────────────────
                Expanded(
                  child: _buildContent(
                    context, provider, detail, review, scrollCtrl),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ClientDesignProjectProvider provider,
    ApiResponse<ClientDesignProject> detail,
    ApiResponse<ClientDesignProject> review,
    ScrollController scrollCtrl,
  ) {
    if (detail.isLoading) {
      return const _LoadingView();
    }

    if (detail.isError) {
      return _ErrorView(
        message: detail.message ?? 'Failed to load project.',
        onRetry: () => provider.fetchProjectById(widget.projectId),
      );
    }

    final project = detail.data;
    if (project == null) return const SizedBox.shrink();

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.clientGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  project.title.isNotEmpty ? project.title[0] : '?',
                  style: GoogleFonts.sora(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    project.designType,
                    style: GoogleFonts.sora(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            _StatusBadge(project: project),
          ],
        ),

        const SizedBox(height: 20),

        // ── Progress ────────────────────────────────────────────────────
        CommonCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress',
                      style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(
                    '${project.progressPercentage}%',
                    style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.clientColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: project.progressFraction,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.clientColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Info grid ───────────────────────────────────────────────────
        CommonCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _InfoRow(
                  icon: Icons.design_services_rounded,
                  label: 'Type',
                  value: project.designType),
              _InfoRow(
                  icon: Icons.priority_high_rounded,
                  label: 'Priority',
                  value: project.priority),
              if (project.deadline != null)
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Deadline',
                  value: _formatDate(project.deadline!),
                ),
              if (project.assignedTo != null)
                _InfoRow(
                  icon: Icons.person_rounded,
                  label: 'Designer',
                  value: project.assignedTo!.name,
                ),
            ],
          ),
        ),

        if (project.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          CommonCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description',
                    style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  project.description,
                  style: GoogleFonts.sora(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],

        // ── Files ───────────────────────────────────────────────────────
        if (project.files.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Design Files',
              style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          ...project.files.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CommonCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.clientColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.insert_drive_file_rounded,
                          color: AppColors.clientColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.fileName,
                              style: GoogleFonts.sora(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(f.fileType,
                              style: GoogleFonts.sora(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // ── Review section (shown only when project is in review) ────────
        if (project.isPendingReview) ...[
          const SizedBox(height: 20),
          Text('Review Design',
              style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          // Success message after review
          if (review.isSuccess) ...[
            _ReviewSuccessBanner(
              message: review.message ?? 'Review submitted!',
              isApproved: review.data?.isApproved ?? false,
            ),
          ] else ...[
            // Feedback field (toggled by "Request Changes")
            if (_showFeedbackField) ...[
              CommonCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Feedback',
                        style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _feedbackController,
                      maxLines: 4,
                      style: GoogleFonts.sora(
                          fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText:
                            'Describe what changes you\'d like...',
                        hintStyle: GoogleFonts.sora(
                            fontSize: 12,
                            color: AppColors.textMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Error from review submission
            if (review.isError)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    review.message ?? 'Failed to submit review.',
                    style: GoogleFonts.sora(
                        fontSize: 12, color: AppColors.error),
                  ),
                ),
              ),

            // Action buttons
            review.isLoading
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ))
                : Row(
                    children: [
                      // Approve button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _approve(context, provider, project.id),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: AppColors.clientGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text('Approve',
                                  style: GoogleFonts.sora(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Request changes button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _toggleChanges(
                              context, provider, project.id),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.error.withOpacity(0.4)),
                            ),
                            child: Center(
                              child: Text(
                                _showFeedbackField
                                    ? 'Submit Changes'
                                    : 'Request Changes',
                                style: GoogleFonts.sora(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  /// Approve without feedback
  Future<void> _approve(
    BuildContext context,
    ClientDesignProjectProvider provider,
    String projectId,
  ) async {
    final ok = await provider.submitReview(
      projectId: projectId,
      action: 'approved',
      feedback: '',
    );
    if (ok && mounted) {
      // Silently refresh list in background
      provider.fetchProjects(silent: true);
    }
  }

  /// Toggle feedback field; if already visible, submit changes
  Future<void> _toggleChanges(
    BuildContext context,
    ClientDesignProjectProvider provider,
    String projectId,
  ) async {
    if (!_showFeedbackField) {
      setState(() => _showFeedbackField = true);
      return;
    }

    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback first.')),
      );
      return;
    }

    final ok = await provider.submitReview(
      projectId: projectId,
      action: 'changes_requested',
      feedback: feedback,
    );
    if (ok && mounted) {
      setState(() => _showFeedbackField = false);
      provider.fetchProjects(silent: true);
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_month(dt.month)} ${dt.year}';

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final ClientDesignProject project;
  const _StatusBadge({required this.project});

  Color get _color {
    if (project.isApproved) return AppColors.success;
    if (project.isPendingReview) return AppColors.warning;
    if (project.isCompleted) return AppColors.info;
    return AppColors.clientColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        project.displayStatus,
        style: GoogleFonts.sora(
            fontSize: 10, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.clientColor),
          const SizedBox(width: 10),
          Text('$label:',
              style: GoogleFonts.sora(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSuccessBanner extends StatelessWidget {
  final String message;
  final bool isApproved;
  const _ReviewSuccessBanner(
      {required this.message, required this.isApproved});

  @override
  Widget build(BuildContext context) {
    final color = isApproved ? AppColors.success : AppColors.info;
    final icon =
        isApproved ? Icons.check_circle_rounded : Icons.edit_note_rounded;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.clientColor,
        strokeWidth: 2.5,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.clientGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
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

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_off_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.sora(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CLIENT REPORTS PAGE (unchanged — static UI)
// ═════════════════════════════════════════════════════════════════════════════

class ClientReportsPage extends StatelessWidget {
  const ClientReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final platforms = [
      ('Instagram', '156.2K', '+15.5%', const Color(0xFFE1306C), 0.82),
      ('Facebook', '245.6K', '+11.2%', const Color(0xFF1877F2), 0.68),
      ('LinkedIn', '38.4K', '+8.2%', const Color(0xFF0A66C2), 0.45),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonCard(
            gradient: AppColors.clientGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('This Month',
                        style: GoogleFonts.sora(
                            fontSize: 13, color: Colors.white70)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('May 2024',
                          style: GoogleFonts.sora(
                              fontSize: 11, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ReportStat('156.2K', 'Reach'),
                    const SizedBox(width: 28),
                    _ReportStat('28.4K', 'Engagement'),
                    const SizedBox(width: 28),
                    _ReportStat('8.6K', 'Clicks'),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 20),

          Text('Platform Breakdown',
                  style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary))
              .animate(delay: 100.ms)
              .fadeIn(),

          const SizedBox(height: 12),

          ...platforms.asMap().entries.map((e) {
            final p = e.value;
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
                        color: p.$4.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(p.$1[0],
                            style: GoogleFonts.sora(
                                fontWeight: FontWeight.w700, color: p.$4)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.$1,
                              style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: p.$5,
                              backgroundColor: AppColors.border,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(p.$4),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(p.$2,
                            style: GoogleFonts.sora(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        Text(p.$3,
                            style: GoogleFonts.sora(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success)),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: Duration(milliseconds: 150 + e.key * 80)).fadeIn(),
            );
          }),

          const SizedBox(height: 20),

          CommonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Engagement Overview',
                    style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [0.5, 0.7, 0.4, 0.8, 0.6, 0.9, 0.75]
                        .asMap()
                        .entries
                        .map((e) {
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 80 * e.value,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.clientColor,
                                    AppColors.clientColor.withOpacity(0.3),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ['M', 'T', 'W', 'T', 'F', 'S', 'S'][e.key],
                              style: GoogleFonts.sora(
                                  fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ).animate(delay: 450.ms).fadeIn(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  final String value, label;
  const _ReportStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        Text(label,
            style:
                GoogleFonts.sora(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}
