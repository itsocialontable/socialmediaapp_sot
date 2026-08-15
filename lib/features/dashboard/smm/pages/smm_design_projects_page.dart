// lib/features/dashboard/smm/pages/smm_design_projects_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/smm_design_project_provider.dart';
import '../../../../model/smm_design_project_model.dart';

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
              child: Text('No design projects yet', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted)),
            );
          }

          return RefreshIndicator(
            color: AppColors.smmColor,
            onRefresh: () => provider.fetchProjects(silent: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = projects[i];
                final statusColor = _statusColors[p.status.toLowerCase()] ?? AppColors.textMuted;
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SmmDesignProjectDetailPage(projectId: p.id)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(gradient: AppColors.smmGradient, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.design_services_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.title.isEmpty ? 'Untitled' : p.title, style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text(p.designType.isEmpty ? '—' : p.designType, style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(p.displayStatus, style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                      ),
                    ]),
                  ),
                );
              },
            ),
          );
        },
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

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final Set<String> _selectedTypes = {};
  String? _priority;
  DateTime? _deadline;
  bool _editMode = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SmmDesignProjectProvider>().fetchDetail(widget.projectId);
    });
  }

  @override
  void dispose() {
    context.read<SmmDesignProjectProvider>().clearDetail();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _hydrateForm(SmmDesignProject p) {
    if (_titleCtrl.text.isEmpty) _titleCtrl.text = p.title;
    if (_descCtrl.text.isEmpty) _descCtrl.text = p.description;
    if (_selectedTypes.isEmpty && p.designType.isNotEmpty) {
      _selectedTypes.addAll(p.designType.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    _priority ??= p.priority.isNotEmpty ? p.priority : null;
    _deadline ??= p.deadline;
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

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 16),
    child: Text(t, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
  );

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
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.close_rounded : Icons.edit_rounded, color: AppColors.smmColor),
            onPressed: () => setState(() => _editMode = !_editMode),
          ),
          IconButton(
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
            return Center(child: Text(res.message ?? 'Failed to load project', style: GoogleFonts.sora(color: AppColors.textSecondary)));
          }

          final p = res.data!;
          _hydrateForm(p);

          if (!_editMode) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(p.title.isEmpty ? 'Untitled' : p.title, style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final t in p.designType.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.smmColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(t, style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.smmColor)),
                    ),
                ]),
                _lbl('Status'),
                Text(p.displayStatus, style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary)),
                _lbl('Priority'),
                Text(p.priority, style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary)),
                _lbl('Deadline'),
                Text(p.deadline != null ? '${p.deadline!.day}/${p.deadline!.month}/${p.deadline!.year}' : '—', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary)),
                _lbl('Description'),
                Text(p.description.isEmpty ? '—' : p.description, style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary)),
                if (p.client != null) ...[
                  _lbl('Client'),
                  Text(p.client!.name, style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary)),
                ],
                if (p.designer != null) ...[
                  _lbl('Designer'),
                  Text(p.designer!.name, style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary)),
                ],
              ],
            );
          }

          // ── Edit mode ──
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _lbl('Brand Name'),
              TextField(
                controller: _titleCtrl,
                style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true, fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              _lbl('Design Type (select multiple)'),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _designTypes.map((t) {
                  final selected = _selectedTypes.contains(t);
                  return FilterChip(
                    label: Text(t, style: GoogleFonts.sora(fontSize: 12, color: selected ? Colors.white : AppColors.textSecondary)),
                    selected: selected,
                    onSelected: (v) => setState(() => v ? _selectedTypes.add(t) : _selectedTypes.remove(t)),
                    backgroundColor: AppColors.surfaceLight,
                    selectedColor: AppColors.smmColor,
                    checkmarkColor: Colors.white,
                    side: BorderSide(color: selected ? AppColors.smmColor : AppColors.border),
                  );
                }).toList(),
              ),
              _lbl('Priority'),
              Wrap(
                spacing: 8,
                children: _priorities.map((p2) {
                  final selected = _priority == p2;
                  return ChoiceChip(
                    label: Text(p2, style: GoogleFonts.sora(fontSize: 12, color: selected ? Colors.white : AppColors.textSecondary)),
                    selected: selected,
                    onSelected: (_) => setState(() => _priority = p2),
                    backgroundColor: AppColors.surfaceLight,
                    selectedColor: AppColors.smmColor,
                    side: BorderSide(color: selected ? AppColors.smmColor : AppColors.border),
                  );
                }).toList(),
              ),
              _lbl('Deadline'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.smmColor),
                    const SizedBox(width: 6),
                    Text(_deadline != null ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}' : 'Pick date', style: GoogleFonts.sora(fontSize: 12, color: AppColors.textPrimary)),
                  ]),
                ),
              ),
              _lbl('Description'),
              TextField(
                controller: _descCtrl, maxLines: 4,
                style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true, fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _isSaving ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: _isSaving ? null : AppColors.smmGradient,
                    color: _isSaving ? AppColors.surfaceLight : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Save Changes', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
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
