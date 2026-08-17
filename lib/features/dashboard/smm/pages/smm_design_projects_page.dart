// lib/features/dashboard/smm/pages/smm_design_projects_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/providers/smm_design_project_provider.dart';
import '../../../../model/smm_design_project_model.dart';

// ─────────────────────────────────────────
// GRAPHIC DESIGNER OPTION (for the assign/change-designer dropdown)
// ─────────────────────────────────────────
class _DesignerOption {
  final String id;
  final String name;
  final String? email;
  const _DesignerOption({required this.id, required this.name, this.email});

  factory _DesignerOption.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'] ?? '').toString();
    final name = (json['name'] ?? json['fullName'] ?? json['full_name'] ?? json['username'] ?? 'Unknown').toString();
    final email = json['email']?.toString();
    return _DesignerOption(id: id, name: name, email: email);
  }

  @override
  bool operator ==(Object other) => other is _DesignerOption && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────
// LIST PAGE — GET /api/smm/design-projects
// ─────────────────────────────────────────
class SmmDesignProjectsListPage extends StatefulWidget {
  const SmmDesignProjectsListPage({super.key});

  @override
  State<SmmDesignProjectsListPage> createState() => _SmmDesignProjectsListPageState();
}

class _SmmDesignProjectsListPageState extends State<SmmDesignProjectsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SmmDesignProjectProvider>().fetchProjects();
    });
  }

  static const _statusColors = {
    'pending': AppColors.warning,
    'in progress': AppColors.info,
    'inprogress': AppColors.info,
    'review': AppColors.secondary,
    'approved': AppColors.success,
    'completed': AppColors.success,
    'changes requested': AppColors.error,
  };

  static const _statusIcons = {
    'pending': Icons.hourglass_top_rounded,
    'in progress': Icons.autorenew_rounded,
    'inprogress': Icons.autorenew_rounded,
    'review': Icons.rate_review_rounded,
    'approved': Icons.check_circle_rounded,
    'completed': Icons.check_circle_rounded,
    'changes requested': Icons.flag_rounded,
  };

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
          shaderCallback: (b) => AppColors.smmGradient.createShader(b),
          child: Text('Design Projects', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(color: AppColors.border, height: 1)),
      ),
      body: Consumer<SmmDesignProjectProvider>(
        builder: (context, provider, _) {
          final res = provider.response;

          if (res.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.smmColor));
          }
          if (res.isError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 32),
                const SizedBox(height: 10),
                Text(res.message ?? 'Failed to load projects', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                TextButton(onPressed: () => provider.fetchProjects(), child: const Text('Retry')),
              ]),
            );
          }
          final projects = provider.projects;
          if (projects.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: AppColors.smmColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.design_services_rounded, color: AppColors.smmColor, size: 28),
                ),
                const SizedBox(height: 14),
                Text('No design projects yet', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('New projects will show up here', style: GoogleFonts.sora(fontSize: 12, color: AppColors.textMuted)),
              ]),
            );
          }

          final activeCount = projects.where((p) {
            final s = p.status.toLowerCase();
            return s != 'completed' && s != 'approved';
          }).length;

          return RefreshIndicator(
            color: AppColors.smmColor,
            backgroundColor: AppColors.surfaceLight,
            onRefresh: () => provider.fetchProjects(silent: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(children: [
                  Expanded(
                    child: _statPill(
                      icon: Icons.folder_copy_rounded,
                      label: 'Total Projects',
                      value: '${projects.length}',
                      color: AppColors.smmColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statPill(
                      icon: Icons.pending_actions_rounded,
                      label: 'Active',
                      value: '$activeCount',
                      color: AppColors.info,
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                for (final p in projects) ...[
                  _projectCard(p),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statPill({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(label, style: GoogleFonts.sora(fontSize: 10, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }

  Widget _projectCard(SmmDesignProject p) {
    final statusKey = p.status.toLowerCase();
    final statusColor = _statusColors[statusKey] ?? AppColors.textMuted;
    final statusIcon = _statusIcons[statusKey] ?? Icons.circle;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SmmDesignProjectDetailPage(projectId: p.id)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(gradient: AppColors.smmGradient, borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.design_services_rounded, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.title.isEmpty ? 'Untitled' : p.title,
                    style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(p.designType.isEmpty ? '—' : p.designType,
                    style: GoogleFonts.sora(fontSize: 11.5, color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 5),
                Text(p.displayStatus, style: GoogleFonts.sora(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor)),
              ]),
            ),
            if (p.priority.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.textMuted.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
                child: Text(p.priority, style: GoogleFonts.sora(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ),
            ],
            const Spacer(),
            if (p.deadline != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.event_rounded, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('${p.deadline!.day}/${p.deadline!.month}/${p.deadline!.year}',
                    style: GoogleFonts.sora(fontSize: 11, color: AppColors.textMuted)),
              ]),
          ]),
          if (p.progressPercentage > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: (p.progressPercentage.clamp(0, 100)) / 100,
                minHeight: 5,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 4),
            Text('${p.progressPercentage}% complete', style: GoogleFonts.sora(fontSize: 10, color: AppColors.textMuted)),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────
// DETAIL / EDIT / DELETE PAGE
// GET /api/smm/design-projects/:id
// PUT /api/smm/design-projects/:id
// DELETE /api/smm/design-projects/:id
// ─────────────────────────────────────────
class SmmDesignProjectDetailPage extends StatefulWidget {
  final String projectId;
  const SmmDesignProjectDetailPage({super.key, required this.projectId});

  @override
  State<SmmDesignProjectDetailPage> createState() => _SmmDesignProjectDetailPageState();
}

class _SmmDesignProjectDetailPageState extends State<SmmDesignProjectDetailPage> {
  static const _designTypes = ['Social Post', 'Logo', 'Banner', 'Video Thumbnail', 'Story', 'Reel Cover'];
  static const _priorities = ['Low', 'Medium', 'High', 'Urgent'];
  static const _priorityColors = {
    'Low': AppColors.info,
    'Medium': AppColors.warning,
    'High': AppColors.error,
    'Urgent': Color(0xFFFF3B30),
  };

  final _api = ApiService();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final Set<String> _selectedTypes = {};
  String? _priority;
  DateTime? _deadline;
  bool _editMode = false;
  bool _isSaving = false;

  // ── Graphic Designer (GD) list — lets SMM change the assigned designer ──
  List<_DesignerOption> _designers = [];
  bool _designersLoading = true;
  String? _designersError;
  _DesignerOption? _selectedDesigner;
  bool _designerHydrated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SmmDesignProjectProvider>().fetchDetail(widget.projectId);
    });
    _fetchDesigners();
  }

  @override
  void dispose() {
    context.read<SmmDesignProjectProvider>().clearDetail();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDesigners() async {
    setState(() { _designersLoading = true; _designersError = null; });
    try {
      final res = await _api.get(AppConstants.smmGraphicDesigners);
      final data = res['data'];
      final raw = (data is Map ? data['designers'] : null) ?? res['designers'] ?? res['users'] ?? res['data'] ?? res;
      final list = raw is List ? raw.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
      setState(() {
        _designers = list.map(_DesignerOption.fromJson).toList();
        _designersLoading = false;
      });
    } on NetworkException catch (_) {
      setState(() { _designersError = 'No internet connection'; _designersLoading = false; });
    } on UnauthorizedException catch (_) {
      setState(() { _designersError = 'Session expired'; _designersLoading = false; });
    } on AppException catch (e) {
      setState(() { _designersError = e.message; _designersLoading = false; });
    } catch (_) {
      setState(() { _designersError = 'Failed to load designers'; _designersLoading = false; });
    }
  }

  void _hydrateForm(SmmDesignProject p) {
    if (_titleCtrl.text.isEmpty) _titleCtrl.text = p.title;
    if (_descCtrl.text.isEmpty) _descCtrl.text = p.description;
    if (_selectedTypes.isEmpty && p.designType.isNotEmpty) {
      _selectedTypes.addAll(p.designType.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    _priority ??= p.priority.isNotEmpty ? p.priority : null;
    _deadline ??= p.deadline;

    // Pre-select the currently assigned designer once, matching against the
    // fetched GD list where possible (falls back to the name we already have).
    if (!_designerHydrated && p.designer != null) {
      _DesignerOption? match;
      for (final d in _designers) {
        if (d.id == p.designer!.id) { match = d; break; }
      }
      _selectedDesigner = match ?? _DesignerOption(id: p.designer!.id, name: p.designer!.name, email: p.designer!.email);
      _designerHydrated = true;
    }
  }

  void _showSnack(String msg, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: GoogleFonts.sora(fontSize: 13))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.smmColor, surface: AppColors.surface)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _deadline = d);
  }

  Future<void> _save() async {
    if (_selectedTypes.isEmpty) {
      _showSnack('Please select at least one design type.', AppColors.warning, Icons.warning_amber_rounded);
      return;
    }
    setState(() => _isSaving = true);
    final provider = context.read<SmmDesignProjectProvider>();
    final ok = await provider.updateProject(
      widget.projectId,
      SmmDesignProjectUpdateRequest(
        title: _titleCtrl.text.trim(),
        designType: _selectedTypes.toList(),
        priority: _priority,
        description: _descCtrl.text.trim(),
        deadline: _deadline,
        designerId: _selectedDesigner?.id,
      ),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      setState(() => _editMode = false);
      _showSnack('Project updated successfully.', AppColors.success, Icons.check_circle_rounded);
    } else {
      _showSnack(provider.updateResponse.message ?? 'Failed to update project.', AppColors.error, Icons.error_outline_rounded);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Project?', style: GoogleFonts.sora(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text('This action cannot be undone.', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.sora(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final provider = context.read<SmmDesignProjectProvider>();
    final ok = await provider.deleteProject(widget.projectId);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      _showSnack('Project deleted.', AppColors.success, Icons.check_circle_rounded);
    } else {
      _showSnack('Failed to delete project.', AppColors.error, Icons.error_outline_rounded);
    }
  }

  Widget _sectionLabel(String t, {IconData? icon}) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 22),
    child: Row(children: [
      if (icon != null) ...[
        Icon(icon, size: 14, color: AppColors.smmColor),
        const SizedBox(width: 6),
      ],
      Text(t, style: GoogleFonts.sora(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.2)),
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
          width: 34, height: 34,
          decoration: BoxDecoration(color: AppColors.smmColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: AppColors.smmColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.sora(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.sora(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  Widget _designerDropdown() {
    if (_designersLoading) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.smmColor)),
          const SizedBox(width: 10),
          Text('Loading graphic designers…', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted)),
        ]),
      );
    }
    if (_designersError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.error.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(_designersError!, style: GoogleFonts.sora(fontSize: 12, color: AppColors.error), maxLines: 1, overflow: TextOverflow.ellipsis)),
          GestureDetector(
            onTap: _fetchDesigners,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Text('Retry', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
            ),
          ),
        ]),
      );
    }
    if (_designers.isEmpty) {
      return Container(
        height: 52, padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        alignment: Alignment.centerLeft,
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text('No graphic designers found', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _selectedDesigner != null ? AppColors.smmColor.withOpacity(0.6) : AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_DesignerOption>(
          value: _designers.contains(_selectedDesigner) ? _selectedDesigner : null,
          isExpanded: true,
          hint: Text(
            _selectedDesigner != null ? _selectedDesigner!.name : 'Select graphic designer',
            style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted),
          ),
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          items: _designers.map((d) => DropdownMenuItem<_DesignerOption>(
            value: d,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(d.name, style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary)),
              if (d.email != null) Text(d.email!, style: GoogleFonts.sora(fontSize: 10, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          )).toList(),
          onChanged: (v) => setState(() => _selectedDesigner = v),
        ),
      ),
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
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Project Details', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(color: AppColors.border, height: 1)),
        actions: [
          IconButton(
            tooltip: _editMode ? 'Cancel editing' : 'Edit project',
            icon: Icon(_editMode ? Icons.close_rounded : Icons.edit_rounded, color: AppColors.smmColor),
            onPressed: () => setState(() => _editMode = !_editMode),
          ),
          IconButton(
            tooltip: 'Delete project',
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Consumer<SmmDesignProjectProvider>(
        builder: (context, provider, _) {
          final res = provider.detail;
          if (res.isLoading || res.isIdle) {
            return const Center(child: CircularProgressIndicator(color: AppColors.smmColor));
          }
          if (res.isError || res.data == null) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 28),
                const SizedBox(height: 10),
                Text(res.message ?? 'Failed to load project', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                TextButton(onPressed: () => provider.fetchDetail(widget.projectId), child: const Text('Retry')),
              ]),
            );
          }

          final p = res.data!;
          _hydrateForm(p);

          if (!_editMode) {
            final statusColor = _priorityColors[p.priority] ?? AppColors.smmColor;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                // ── Hero card ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.smmGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.smmColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.title.isEmpty ? 'Untitled' : p.title,
                        style: GoogleFonts.sora(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final t in p.designType.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                          child: Text(t, style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Text(p.displayStatus, style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.smmColor)),
                      ),
                      const SizedBox(width: 8),
                      if (p.priority.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.6)), borderRadius: BorderRadius.circular(20)),
                          child: Text(p.priority, style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                    ]),
                    if (p.progressPercentage > 0) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: (p.progressPercentage.clamp(0, 100)) / 100,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${p.progressPercentage}% complete', style: GoogleFonts.sora(fontSize: 11, color: Colors.white.withOpacity(0.9))),
                    ],
                  ]),
                ),

                _sectionLabel('Overview', icon: Icons.info_outline_rounded),
                _infoRow(Icons.flag_rounded, 'Priority', p.priority.isEmpty ? '—' : p.priority),
                _infoRow(Icons.event_rounded, 'Deadline', p.deadline != null ? '${p.deadline!.day}/${p.deadline!.month}/${p.deadline!.year}' : '—'),
                if (p.createdAt != null)
                  _infoRow(Icons.calendar_today_rounded, 'Created', '${p.createdAt!.day}/${p.createdAt!.month}/${p.createdAt!.year}'),

                _sectionLabel('People', icon: Icons.people_alt_rounded),
                _infoRow(Icons.person_outline_rounded, 'Client', p.client?.name ?? 'Not assigned'),
                _infoRow(Icons.brush_rounded, 'Graphic Designer', p.designer?.name ?? 'Not assigned'),

                _sectionLabel('Description', icon: Icons.notes_rounded),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Text(p.description.isEmpty ? 'No description provided.' : p.description,
                      style: GoogleFonts.sora(fontSize: 13, height: 1.5, color: p.description.isEmpty ? AppColors.textMuted : AppColors.textPrimary)),
                ),

                if (p.files.isNotEmpty) ...[
                  _sectionLabel('Attached Files', icon: Icons.attach_file_rounded),
                  for (final f in p.files)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Row(children: [
                        const Icon(Icons.insert_drive_file_outlined, size: 18, color: AppColors.smmColor),
                        const SizedBox(width: 10),
                        Expanded(child: Text(f.fileName.isEmpty ? 'File' : f.fileName, style: GoogleFonts.sora(fontSize: 12.5, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                ],
              ],
            );
          }

          // ── Edit mode ──
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _sectionLabel('Basic Info', icon: Icons.badge_outlined),
              TextField(
                controller: _titleCtrl,
                style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Brand name',
                  hintStyle: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted),
                  filled: true, fillColor: AppColors.surfaceLight,
                  prefixIcon: const Icon(Icons.storefront_rounded, size: 18, color: AppColors.smmColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.smmColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),

              _sectionLabel('Design Type', icon: Icons.category_rounded),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _designTypes.map((t) {
                  final selected = _selectedTypes.contains(t);
                  return FilterChip(
                    label: Text(t, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
                    selected: selected,
                    onSelected: (v) => setState(() => v ? _selectedTypes.add(t) : _selectedTypes.remove(t)),
                    backgroundColor: AppColors.surfaceLight,
                    selectedColor: AppColors.smmColor,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: selected ? AppColors.smmColor : AppColors.border),
                  );
                }).toList(),
              ),

              _sectionLabel('Priority', icon: Icons.flag_rounded),
              Wrap(
                spacing: 8,
                children: _priorities.map((p2) {
                  final selected = _priority == p2;
                  final c = _priorityColors[p2] ?? AppColors.smmColor;
                  return ChoiceChip(
                    label: Text(p2, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
                    selected: selected,
                    onSelected: (_) => setState(() => _priority = p2),
                    backgroundColor: AppColors.surfaceLight,
                    selectedColor: c,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: selected ? c : AppColors.border),
                  );
                }).toList(),
              ),

              _sectionLabel('Deadline', icon: Icons.event_rounded),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.smmColor),
                    const SizedBox(width: 8),
                    Text(_deadline != null ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}' : 'Pick a date',
                        style: GoogleFonts.sora(fontSize: 13, color: _deadline != null ? AppColors.textPrimary : AppColors.textMuted)),
                  ]),
                ),
              ),

              // ── Assigned graphic designer — SMM can view/change from the GD list ──
              _sectionLabel('Assigned Designer', icon: Icons.brush_rounded),
              _designerDropdown(),

              _sectionLabel('Description', icon: Icons.notes_rounded),
              TextField(
                controller: _descCtrl, maxLines: 4,
                style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Describe the project…',
                  hintStyle: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted),
                  filled: true, fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.smmColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 26),
              GestureDetector(
                onTap: _isSaving ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _isSaving ? null : AppColors.smmGradient,
                    color: _isSaving ? AppColors.surfaceLight : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isSaving ? null : [BoxShadow(color: AppColors.smmColor.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  alignment: Alignment.center,
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Save Changes', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}