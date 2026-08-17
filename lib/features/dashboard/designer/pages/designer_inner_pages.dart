// lib/features/dashboard/designer/pages/designer_inner_pages.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/errors/api_response.dart';
import '../../../../core/providers/gd_project_provider.dart';
import '../../../../model/gd_project_model.dart';
import '../../../../shared/widgets/common_widgets.dart';

// ─────────────────────────────────────────
// DESIGNER TASKS PAGE
// ─────────────────────────────────────────
class DesignerTasksPage extends StatefulWidget {
  const DesignerTasksPage({super.key});
  @override
  State<DesignerTasksPage> createState() => _DesignerTasksPageState();
}

class _DesignerTasksPageState extends State<DesignerTasksPage> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GdProjectProvider>().fetchProjects();
    });
  }

  List<GdProject> _filtered(GdProjectProvider prov) {
    switch (_tabIndex) {
      case 1: return prov.pendingProjects;
      case 2: return prov.inProgressProjects;
      case 3: return prov.reviewProjects;
      case 4: return prov.completedProjects;
      default: return prov.allProjects;
    }
  }

  List<String> _tabs(GdProjectProvider prov) => [
    'All (${prov.allProjects.length})',
    'Pending (${prov.pendingProjects.length})',
    'In Progress (${prov.inProgressProjects.length})',
    'Review (${prov.reviewProjects.length})',
    'Completed (${prov.completedProjects.length})',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<GdProjectProvider>(
      builder: (context, prov, _) {
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: _tabs(prov).asMap().entries.map((e) {
                  final isSelected = e.key == _tabIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _tabIndex = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.designerGradient : null,
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
            Expanded(child: _buildBody(prov.response, prov)),
          ],
        );
      },
    );
  }

  Widget _buildBody(ApiResponse<List<GdProject>> resp, GdProjectProvider prov) {
    if (resp.isLoading) return const _TasksShimmer();
    if (resp.isError) return _ErrorState(message: resp.message ?? 'Something went wrong.', onRetry: () => prov.fetchProjects());
    final projects = _filtered(prov);
    if (projects.isEmpty) return _EmptyState(tabLabel: _tabIndex == 0 ? 'tasks' : _tabs(prov)[_tabIndex].split(' ').first.toLowerCase());
    return RefreshIndicator(
      color: AppColors.designerColor,
      onRefresh: () => prov.fetchProjects(silent: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: projects.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DesignerTaskDetailPage(project: projects[i]),
              ),
            ),
            child: _ProjectCard(project: projects[i]),
          )
              .animate(delay: Duration(milliseconds: 60 * i))
              .fadeIn()
              .slideX(begin: 0.15, end: 0),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// TASK DETAIL PAGE — shown when a task card is tapped
// Read-only view with all task + client information
// ─────────────────────────────────────────
class DesignerTaskDetailPage extends StatelessWidget {
  final GdProject project;
  const DesignerTaskDetailPage({super.key, required this.project});

  Color get _priorityColor {
    switch (project.priority.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  String _fmt(DateTime? d, String fallback) {
    if (d == null) return fallback;
    return DateFormat('MMM d, yyyy • h:mm a').format(d.toLocal());
  }

  Widget _sectionLabel(String t, {IconData? icon}) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 22),
    child: Row(children: [
      if (icon != null) ...[
        Icon(icon, size: 14, color: AppColors.designerColor),
        const SizedBox(width: 6),
      ],
      Text(t,
          style: GoogleFonts.sora(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.2)),
    ]),
  );

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: AppColors.designerColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: AppColors.designerColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                  GoogleFonts.sora(fontSize: 10.5, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (b) => AppColors.designerGradient.createShader(b),
          child: Text('Task Details',
              style: GoogleFonts.sora(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(color: AppColors.border, height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header summary card ───────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.designerGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.title.isNotEmpty ? project.title : 'Untitled Task',
                      style: GoogleFonts.sora(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(
                      project.designType.isNotEmpty
                          ? project.designType
                          : 'Design Task',
                      style: GoogleFonts.sora(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                          project.status.isNotEmpty ? project.status : 'Pending',
                          style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                          '${project.priority.isNotEmpty ? project.priority : 'Normal'} Priority',
                          style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ]),
                  if (project.progressPercentage > 0) ...[
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: project.progressPercentage / 100,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${project.progressPercentage}%',
                          style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ]),
                  ],
                ],
              ),
            ).animate().fadeIn(),

            // ── Task Information ──────────────────────────────
            _sectionLabel('Task Information', icon: Icons.info_outline_rounded),
            _infoRow(Icons.category_rounded, 'Design Type',
                project.designType.isNotEmpty ? project.designType : 'Not specified'),
            _infoRow(Icons.flag_rounded, 'Priority',
                project.priority.isNotEmpty ? project.priority : 'Not specified'),
            _infoRow(Icons.timelapse_rounded, 'Status',
                project.status.isNotEmpty ? project.status : 'Pending'),
            _infoRow(Icons.event_rounded, 'Deadline',
                _fmt(project.deadline, 'No deadline set')),
            _infoRow(Icons.calendar_today_rounded, 'Created On',
                _fmt(project.createdAt, 'Unknown')),

            // ── Client Information ────────────────────────────
            _sectionLabel('Client Information', icon: Icons.business_rounded),
            _infoRow(
                Icons.apartment_rounded,
                'Company',
                project.client.companyName.isNotEmpty
                    ? project.client.companyName
                    : 'Not specified'),
            _infoRow(
                Icons.person_outline_rounded,
                'Contact Name',
                project.client.name.isNotEmpty
                    ? project.client.name
                    : 'Not specified'),
            _infoRow(
                Icons.email_outlined,
                'Email',
                project.client.email.isNotEmpty
                    ? project.client.email
                    : 'Not specified'),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// PROJECT CARD
// ─────────────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final GdProject project;
  const _ProjectCard({required this.project});

  Color get _priorityColor {
    switch (project.priority.toLowerCase()) {
      case 'high': return AppColors.error;
      case 'medium': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  Color get _statusColor {
    switch (project.status.toLowerCase()) {
      case 'pending': return AppColors.warning;
      case 'in progress': return AppColors.info;
      case 'review': return AppColors.secondary;
      case 'completed': return AppColors.success;
      default: return AppColors.textMuted;
    }
  }

  String get _deadlineText {
    if (project.deadline == null) return 'No deadline';
    return 'Due ${DateFormat('MMM d, h:mm a').format(project.deadline!.toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _priorityColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.image_outlined, color: _priorityColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(project.title, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text('${project.client.companyName} • ${project.designType}', style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.access_time_rounded, size: 10, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text(_deadlineText, style: GoogleFonts.sora(fontSize: 10, color: AppColors.textMuted)),
              ]),
              if (project.progressPercentage > 0) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: project.progressPercentage / 100,
                        backgroundColor: AppColors.designerColor.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.designerColor),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${project.progressPercentage}%', style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.designerColor)),
                ]),
              ],
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _priorityColor.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
              child: Text(project.priority, style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: _priorityColor)),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _statusColor.withOpacity(0.10), borderRadius: BorderRadius.circular(5), border: Border.all(color: _statusColor.withOpacity(0.3))),
              child: Text(project.status, style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w500, color: _statusColor)),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// DESIGNER UPLOAD PAGE  — real API
// ─────────────────────────────────────────
class DesignerUploadPage extends StatefulWidget {
  const DesignerUploadPage({super.key});
  @override
  State<DesignerUploadPage> createState() => _DesignerUploadPageState();
}

class _DesignerUploadPageState extends State<DesignerUploadPage> {
  @override
  void initState() {
    super.initState();
    // Ensure projects are loaded for the dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<GdProjectProvider>();
      if (prov.allProjects.isEmpty) {
        prov.fetchProjects(silent: true);
      }
    });
  }

  Future<void> _handleUpload(GdProjectProvider prov) async {
    if (!prov.hasFile) {
      _showSnack('Please select a file first.', isError: true);
      return;
    }
    if (prov.selectedProject == null) {
      _showSnack('Please select a project.', isError: true);
      return;
    }

    final success = await prov.uploadFile(projectId: prov.selectedProject!.id);

    if (!mounted) return;
    if (success) {
      _showSnack(prov.uploadResponse.message ?? 'Uploaded successfully!', isError: false);
      prov.resetUpload();
    } else {
      _showSnack(prov.uploadResponse.message ?? 'Upload failed.', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: GoogleFonts.sora(fontSize: 13, color: Colors.white))),
        ]),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GdProjectProvider>(
      builder: (context, prov, _) {
        final isUploading = prov.uploadResponse.isLoading;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Pick File Zone ──────────────────────────────────────────
              _PickFileZone(prov: prov, isUploading: isUploading)
                  .animate().fadeIn(),

              const SizedBox(height: 16),

              // ── Upload Progress ─────────────────────────────────────────
              if (isUploading) ...[
                _UploadProgressBar(progress: prov.uploadProgress)
                    .animate().fadeIn(),
                const SizedBox(height: 16),
              ],

              // ── Error Banner ────────────────────────────────────────────
              if (prov.uploadResponse.isError) ...[
                _ErrorBanner(message: prov.uploadResponse.message ?? 'Upload failed.')
                    .animate().fadeIn().slideY(begin: -0.3, end: 0),
                const SizedBox(height: 16),
              ],

              // ── Project Dropdown ────────────────────────────────────────
              _ProjectDropdown(prov: prov, enabled: !isUploading)
                  .animate(delay: 80.ms).fadeIn(),

              const SizedBox(height: 20),

              // ── Upload Button ───────────────────────────────────────────
              CommonButton(
                label: isUploading ? 'Uploading…' : 'Upload & Submit',
                gradient: AppColors.designerGradient,
                isLoading: isUploading,
                onTap: isUploading ? null : () => _handleUpload(prov),
              ).animate(delay: 120.ms).fadeIn(),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────
// PICK FILE ZONE
// ─────────────────────────────────────────
class _PickFileZone extends StatelessWidget {
  final GdProjectProvider prov;
  final bool isUploading;
  const _PickFileZone({required this.prov, required this.isUploading});

  @override
  Widget build(BuildContext context) {
    if (prov.hasFile) {
      return _FilePreviewCard(prov: prov, isUploading: isUploading);
    }

    return Column(
      children: [
        // Image
        GestureDetector(
          onTap: isUploading ? null : prov.pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.designerColor.withOpacity(0.5), width: 1.5),
            ),
            child: Column(children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.designerGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.designerColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: const Icon(Icons.image_outlined, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 14),
              Text('Tap to pick an image', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('JPG  •  PNG  •  WEBP', style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
        ),

        const SizedBox(height: 10),

        // Video row
        GestureDetector(
          onTap: isUploading ? null : prov.pickVideo,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.videocam_outlined, color: AppColors.designerColor, size: 18),
              const SizedBox(width: 8),
              Text('Pick a video instead', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.designerColor)),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// FILE PREVIEW CARD
// ─────────────────────────────────────────
class _FilePreviewCard extends StatelessWidget {
  final GdProjectProvider prov;
  final bool isUploading;
  const _FilePreviewCard({required this.prov, required this.isUploading});

  String get _readableSize {
    try {
      final bytes = File(prov.pickedFile!.path).lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }

  bool get _isImage {
    final ext = prov.pickedFile!.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.designerColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(children: [
        // Preview
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          child: _isImage
              ? Image.file(File(prov.pickedFile!.path), height: 160, width: double.infinity, fit: BoxFit.cover)
              : Container(
            height: 100,
            width: double.infinity,
            color: AppColors.surfaceLight,
            child: const Icon(Icons.videocam_rounded, color: AppColors.designerColor, size: 40),
          ),
        ),

        // Info row
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(gradient: AppColors.designerGradient, borderRadius: BorderRadius.circular(8)),
              child: Icon(_isImage ? Icons.image_rounded : Icons.video_file_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(prov.pickedFile!.name,
                  style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(_readableSize, style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            if (!isUploading)
              GestureDetector(
                onTap: prov.removeFile,
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.close_rounded, color: AppColors.error, size: 16),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// UPLOAD PROGRESS BAR
// ─────────────────────────────────────────
class _UploadProgressBar extends StatelessWidget {
  final double progress;
  const _UploadProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.designerColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.designerColor.withOpacity(0.2)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.designerColor),
              ),
            ),
            const SizedBox(width: 8),
            Text('Uploading file…', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.designerColor)),
          ]),
          Text('$pct%', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.designerColor)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.designerColor.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.designerColor),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// ERROR BANNER
// ─────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: GoogleFonts.sora(fontSize: 12, color: AppColors.error))),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// PROJECT DROPDOWN
// ─────────────────────────────────────────
class _ProjectDropdown extends StatelessWidget {
  final GdProjectProvider prov;
  final bool enabled;

  const _ProjectDropdown({
    required this.prov,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    // Remove duplicate projects
    final Map<String, GdProject> uniqueMap = {};

    for (final project in prov.allProjects) {
      uniqueMap[project.id.toString()] = project;
    }

    final projects = uniqueMap.values.toList();

    // Selected project ID
    final selectedId = prov.selectedProject?.id.toString();

    // Make sure selected ID exists in dropdown items
    final validSelectedId = projects.any(
          (project) => project.id.toString() == selectedId,
    )
        ? selectedId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Project',
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.surfaceLight
                : AppColors.surfaceLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: validSelectedId != null
                  ? AppColors.designerColor.withOpacity(0.5)
                  : AppColors.border,
            ),
          ),

          child: projects.isEmpty
              ? Row(
            children: [
              const Icon(
                Icons.folder_off_outlined,
                color: AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'No projects available',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          )
              : DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: validSelectedId,

              hint: Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Select a project…',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),

              isExpanded: true,

              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
              ),

              dropdownColor: AppColors.surface,

              style: GoogleFonts.sora(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),

              onChanged: enabled
                  ? (String? projectId) {
                if (projectId == null) return;

                final project = projects.firstWhere(
                      (p) => p.id.toString() == projectId,
                );

                prov.selectProject(project);
              }
                  : null,

              items: projects.map((project) {
                return DropdownMenuItem<String>(
                  value: project.id.toString(),

                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: AppColors.designerGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Text(
                              project.title,
                              style: GoogleFonts.sora(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),

                            Text(
                              project.client.companyName,
                              style: GoogleFonts.sora(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// ASSETS PAGE  (unchanged)
// ─────────────────────────────────────────
class DesignerAssetsPage extends StatefulWidget {
  const DesignerAssetsPage({super.key});
  @override
  State<DesignerAssetsPage> createState() => _DesignerAssetsPageState();
}

class _DesignerAssetsPageState extends State<DesignerAssetsPage> {
  int _selectedTab = 0;
  final _tabs = ['All', 'Logos', 'Icons', 'Stock Images'];
  final _folders = [
    ('Brand Kits', '40 items', Icons.folder_rounded, AppColors.designerColor),
    ('Templates', '28 items', Icons.dashboard_rounded, AppColors.smmColor),
    ('Icons', '100 items', Icons.interests_rounded, AppColors.info),
    ('Stock Images', '200 items', Icons.photo_library_rounded, AppColors.primaryLight),
    ('Fonts', '15 items', Icons.text_fields_rounded, AppColors.warning),
    ('Graphics', '65 items', Icons.auto_awesome_rounded, AppColors.secondary),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Container(
          height: 44,
          decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(hintText: 'Search assets...', hintStyle: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted), border: InputBorder.none, contentPadding: EdgeInsets.zero),
            )),
          ]),
        ).animate().fadeIn(),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(children: _tabs.asMap().entries.map((e) {
          final isSelected = e.key == _selectedTab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.designerGradient : null,
                  color: isSelected ? null : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: AppColors.border),
                ),
                child: Text(e.value, style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          );
        }).toList()),
      ).animate(delay: 80.ms).fadeIn(),
      const SizedBox(height: 12),
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3),
        itemCount: _folders.length,
        itemBuilder: (_, i) {
          final f = _folders[i];
          return GestureDetector(
            onTap: () {},
            child: CommonCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: f.$4.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(f.$3, color: f.$4, size: 22)),
                const Spacer(),
                Text(f.$1, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(f.$2, style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(),
          );
        },
      )),
    ]);
  }
}

// ─────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────
class _TasksShimmer extends StatefulWidget {
  const _TasksShimmer();
  @override
  State<_TasksShimmer> createState() => _TasksShimmerState();
}

class _TasksShimmerState extends State<_TasksShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 80,
          decoration: BoxDecoration(color: AppColors.surfaceLight.withOpacity(_a.value + 0.1), borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.border.withOpacity(_a.value), borderRadius: BorderRadius.circular(12))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(height: 12, width: 160, decoration: BoxDecoration(color: AppColors.border.withOpacity(_a.value), borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(height: 10, width: 100, decoration: BoxDecoration(color: AppColors.border.withOpacity(_a.value * 0.7), borderRadius: BorderRadius.circular(6))),
            ])),
          ]),
        ),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 32)),
        const SizedBox(height: 16),
        Text('Oops! Something went wrong', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(message, style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
            decoration: BoxDecoration(gradient: AppColors.designerGradient, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('Try Again', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          ),
        ),
      ]).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String tabLabel;
  const _EmptyState({required this.tabLabel});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.designerColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.inbox_rounded, color: AppColors.designerColor, size: 32)),
        const SizedBox(height: 16),
        Text('No $tabLabel found', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text('Your $tabLabel will appear here.', style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
      ]).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    ),
  );
}