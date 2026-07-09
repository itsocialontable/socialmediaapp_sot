import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exceptions.dart';

// ─────────────────────────────────────────
// USER OPTION MODEL
// ─────────────────────────────────────────
class UserOption {
  final String id;
  final String name;
  final String? email;
  const UserOption({required this.id, required this.name, this.email});

  factory UserOption.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'] ?? '').toString();
    final name = (json['name'] ?? json['fullName'] ?? json['full_name'] ?? json['username'] ?? 'Unknown').toString();
    final email = json['email']?.toString();
    return UserOption(id: id, name: name, email: email);
  }
}

// ─────────────────────────────────────────
// ASSIGN TASK PAGE
// ─────────────────────────────────────────
class AssignTaskPage extends StatefulWidget {
  const AssignTaskPage({super.key});

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final _api = ApiService();
  final _picker = ImagePicker();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _audienceCtrl = TextEditingController();
  final _colorsCtrl = TextEditingController();
  final _fontCtrl = TextEditingController();

  UserOption? _selectedClient;
  UserOption? _selectedDesigner;
  String? _designType;
  String? _priority;
  DateTime? _deadline;
  int _revisions = 2;

  List<UserOption> _clients = [];
  List<UserOption> _designers = [];
  bool _clientsLoading = true;
  bool _designersLoading = true;
  String? _clientsError;
  String? _designersError;

  final List<XFile> _assets = [];
  bool _isSubmitting = false;

  static const _designTypes = ['Social Post', 'Logo', 'Banner', 'Video Thumbnail', 'Story', 'Reel Cover'];
  static const _priorities = ['Low', 'Medium', 'High', 'Urgent'];
  static const _pColors = {
    'Low': AppColors.info,
    'Medium': AppColors.warning,
    'High': AppColors.error,
    'Urgent': Color(0xFFFF3B30),
  };

  @override
  void initState() {
    super.initState();
    _fetchClients();
    _fetchDesigners();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _audienceCtrl.dispose();
    _colorsCtrl.dispose();
    _fontCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchClients() async {
    setState(() { _clientsLoading = true; _clientsError = null; });
    try {
      final res = await _api.get(AppConstants.adminClients);
      final data = res['data'];
      final raw = (data is Map ? data['clients'] : null) ?? res['clients'] ?? res['users'] ?? res['data'] ?? res;
      final list = raw is List ? raw.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
      setState(() { _clients = list.map(UserOption.fromJson).toList(); _clientsLoading = false; });
    } on NetworkException catch (_) {
      setState(() { _clientsError = 'No internet connection'; _clientsLoading = false; });
    } on UnauthorizedException catch (_) {
      setState(() { _clientsError = 'Session expired'; _clientsLoading = false; });
    } on AppException catch (e) {
      setState(() { _clientsError = e.message; _clientsLoading = false; });
    } catch (_) {
      setState(() { _clientsError = 'Failed to load clients'; _clientsLoading = false; });
    }
  }

  Future<void> _fetchDesigners() async {
    setState(() { _designersLoading = true; _designersError = null; });
    try {
      final res = await _api.get(AppConstants.adminGraphicDesigners);
      final data = res['data'];
      final raw = (data is Map ? data['designers'] : null) ?? res['designers'] ?? res['users'] ?? res['data'] ?? res;
      final list = raw is List ? raw.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
      setState(() { _designers = list.map(UserOption.fromJson).toList(); _designersLoading = false; });
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

  Future<void> _pickAssets() async {
    try {
      final picked = await _picker.pickMultipleMedia();
      if (picked.isNotEmpty) {
        setState(() {
          for (final f in picked) {
            final alreadyExists = _assets.any((a) => a.path == f.path);
            if (!alreadyExists) _assets.add(f);
          }
        });
      }
    } catch (_) {
      _showSnack('Could not open media picker. Please try again.', AppColors.error, Icons.error_outline_rounded);
    }
  }

  void _removeAsset(int idx) => setState(() => _assets.removeAt(idx));

  bool _isVideo(XFile f) {
    final ext = f.name.toLowerCase().split('.').last;
    return ['mp4', 'mov', 'avi', 'mkv', 'webm', 'hevc'].contains(ext);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.smmColor, surface: AppColors.surface)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _deadline = d);
  }

  String? _validate() {
    if (_selectedClient == null) return 'Please select a client.';
    if (_selectedDesigner == null) return 'Please select a designer.';
    if (_titleCtrl.text.trim().isEmpty) return 'Please enter a project title.';
    if (_designType == null) return 'Please select a design type.';
    if (_priority == null) return 'Please select a priority.';
    if (_deadline == null) return 'Please pick a deadline.';
    return null;
  }

  void _showSnack(String msg, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: GoogleFonts.sora(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _submit(BuildContext ctx) async {
    final err = _validate();
    if (err != null) { _showSnack(err, AppColors.warning, Icons.warning_amber_rounded); return; }
    setState(() => _isSubmitting = true);
    try {
      final formData = FormData.fromMap({
        'clientId': _selectedClient!.id,
        'designerId': _selectedDesigner!.id,
        'title': _titleCtrl.text.trim(),
        'designType': _designType!,
        'deadline': _deadline!.toUtc().toIso8601String(),
        'priority': _priority!,
        'description': _descCtrl.text.trim(),
        'targetAudience': _audienceCtrl.text.trim(),
        'brandColors': _colorsCtrl.text.trim(),
        'fontPreferences': _fontCtrl.text.trim(),
        'revisionLimit': _revisions,
        if (_assets.isNotEmpty)
          'assets': await Future.wait(_assets.map((f) async => MultipartFile.fromFile(f.path, filename: f.name))),
      });
      await _api.postMultipart(AppConstants.createDesignProject, formData: formData);
      if (ctx.mounted) {
        Navigator.pop(ctx);
        _showSnack('Design project created successfully! 🎨', AppColors.success, Icons.check_circle_rounded);
      }
    } on ValidationException catch (e) {
      _showSnack(e.message, AppColors.warning, Icons.warning_amber_rounded);
    } on UnauthorizedException catch (_) {
      _showSnack('Session expired. Please log in again.', AppColors.error, Icons.lock_outline_rounded);
    } on NetworkException catch (_) {
      _showSnack('No internet connection. Please try again.', AppColors.error, Icons.wifi_off_rounded);
    } on TimeoutException catch (_) {
      _showSnack('Request timed out. Please try again.', AppColors.error, Icons.timer_off_outlined);
    } on AppException catch (e) {
      _showSnack(e.message, AppColors.error, Icons.error_outline_rounded);
    } catch (e) {
      _showSnack('Something went wrong. Please try again.', AppColors.error, Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Helpers ──
  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
  );

  Widget _inp(TextEditingController c, String h, {int lines = 1}) => Container(
    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: TextField(
      controller: c, maxLines: lines,
      style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: h, hintStyle: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted),
        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    ),
  );

  Widget _apiDrop({
    required String label, required bool loading, required String? error,
    required List<UserOption> items, required UserOption? value,
    required ValueChanged<UserOption?> onChange, required VoidCallback onRetry, required String emptyHint,
  }) {
    if (loading) {
      return Container(
        height: 48,
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const SizedBox(width: 14),
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.smmColor)),
          const SizedBox(width: 10),
          Text('Loading $label...', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted)),
        ]),
      );
    }
    if (error != null) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(error, style: GoogleFonts.sora(fontSize: 12, color: AppColors.error), maxLines: 1, overflow: TextOverflow.ellipsis)),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Text('Retry', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
            ),
          ),
        ]),
      );
    }
    if (items.isEmpty) {
      return Container(
        height: 48, padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(emptyHint, style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value != null ? AppColors.smmColor.withOpacity(0.6) : AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UserOption>(
          value: value, isExpanded: true,
          hint: Text('Select $label', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted)),
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          items: items.map((u) => DropdownMenuItem<UserOption>(
            value: u,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(u.name, style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary)),
              if (u.email != null) Text(u.email!, style: GoogleFonts.sora(fontSize: 10, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          )).toList(),
          onChanged: onChange,
        ),
      ),
    );
  }

  Widget _drop<T>(String hint, T? val, List<T> items, ValueChanged<T?> onChange, {Color Function(T)? col}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: val != null ? AppColors.smmColor.withOpacity(0.6) : AppColors.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: val, isExpanded: true,
        hint: Text(hint, style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted)),
        dropdownColor: AppColors.surface,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
        items: items.map((e) => DropdownMenuItem<T>(
          value: e,
          child: Text(e.toString(), style: GoogleFonts.sora(fontSize: 13, color: col != null ? col(e) : AppColors.textPrimary)),
        )).toList(),
        onChanged: onChange,
      ),
    ),
  );

  Widget _buildAssetsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl('Assets  (Images & Videos)'),
      if (_assets.isNotEmpty) ...[
        Wrap(
          spacing: 8, runSpacing: 8,
          children: List.generate(_assets.length, (i) {
            final f = _assets[i];
            final isVid = _isVideo(f);
            return Stack(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border), color: AppColors.surfaceLight),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: isVid
                      ? Container(
                    color: AppColors.surface,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.videocam_rounded, color: AppColors.smmColor, size: 26),
                      const SizedBox(height: 4),
                      Text(f.name.length > 10 ? '${f.name.substring(0, 10)}…' : f.name, style: GoogleFonts.sora(fontSize: 9, color: AppColors.textMuted), textAlign: TextAlign.center),
                    ]),
                  )
                      : Image.file(File(f.path), fit: BoxFit.cover, width: 80, height: 80, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: AppColors.textMuted)),
                ),
              ),
              Positioned(
                left: 4, bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isVid ? const Color(0xFF6C63FF).withOpacity(0.85) : AppColors.smmColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(isVid ? 'VID' : 'IMG', style: GoogleFonts.sora(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              Positioned(
                top: -4, right: -4,
                child: GestureDetector(
                  onTap: () => _removeAsset(i),
                  child: Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 1.5)),
                    child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                  ),
                ),
              ),
            ]);
          }),
        ),
        const SizedBox(height: 10),
      ],
      GestureDetector(
        onTap: _assets.length >= 20 ? null : _pickAssets,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _assets.length >= 20 ? AppColors.surfaceLight.withOpacity(0.5) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _assets.isNotEmpty ? AppColors.smmColor.withOpacity(0.5) : AppColors.border),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.smmGradient.createShader(b),
              child: Icon(_assets.isEmpty ? Icons.perm_media_rounded : Icons.add_photo_alternate_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              _assets.isEmpty ? 'Select Images & Videos' : 'Add More  (${_assets.length}/20)',
              style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: _assets.isNotEmpty ? AppColors.smmColor : AppColors.textSecondary),
            ),
          ]),
        ),
      ),
      if (_assets.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text('${_assets.length} file${_assets.length == 1 ? '' : 's'} selected  •  tap × to remove', style: GoogleFonts.sora(fontSize: 10, color: AppColors.textMuted)),
          ]),
        ),
    ]);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.smmGradient.createShader(b),
              child: Text('Assign to Designer', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            Text('Fill in details to assign to a designer', style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.border, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _lbl('Client'),
          _apiDrop(label: 'Client', loading: _clientsLoading, error: _clientsError, items: _clients, value: _selectedClient, onChange: (v) => setState(() => _selectedClient = v), onRetry: _fetchClients, emptyHint: 'No clients found'),
          const SizedBox(height: 16),

          _lbl('Assign to Designer'),
          _apiDrop(label: 'Graphic Designer', loading: _designersLoading, error: _designersError, items: _designers, value: _selectedDesigner, onChange: (v) => setState(() => _selectedDesigner = v), onRetry: _fetchDesigners, emptyHint: 'No designers found'),
          const SizedBox(height: 16),

          _lbl('Project Title'),
          _inp(_titleCtrl, 'e.g. Summer Campaign Banner'),
          const SizedBox(height: 16),

          _lbl('Design Type'),
          _drop('Select design type', _designType, _designTypes, (v) => setState(() => _designType = v)),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _lbl('Priority'),
              _drop('Priority', _priority, _priorities, (v) => setState(() => _priority = v), col: (p) => _pColors[p] ?? AppColors.textPrimary),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _lbl('Deadline'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _deadline != null ? AppColors.smmColor : AppColors.border),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: _deadline != null ? AppColors.smmColor : AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      _deadline != null ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}' : 'Pick date',
                      style: GoogleFonts.sora(fontSize: 12, color: _deadline != null ? AppColors.textPrimary : AppColors.textMuted),
                    ),
                  ]),
                ),
              ),
            ])),
          ]),
          const SizedBox(height: 16),

          _lbl('Description'),
          _inp(_descCtrl, 'Describe the project requirements...', lines: 4),
          const SizedBox(height: 16),

          _lbl('Target Audience'),
          _inp(_audienceCtrl, 'e.g. Women 18–35, fashion enthusiasts'),
          const SizedBox(height: 16),

          _lbl('Brand Colors'),
          _inp(_colorsCtrl, 'e.g. #FF6B9D, #6C63FF'),
          const SizedBox(height: 16),

          _lbl('Font Preferences'),
          _inp(_fontCtrl, 'e.g. Montserrat bold for headings'),
          const SizedBox(height: 16),

          _lbl('Revision Limit'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Text('Revisions allowed:', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _revisions = (_revisions - 1).clamp(0, 10)),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                  child: const Icon(Icons.remove_rounded, size: 16, color: AppColors.textSecondary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('$_revisions', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.smmColor)),
              ),
              GestureDetector(
                onTap: () => setState(() => _revisions = (_revisions + 1).clamp(0, 10)),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(gradient: AppColors.smmGradient, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          _buildAssetsSection(),
          const SizedBox(height: 28),

          // Submit Button
          GestureDetector(
            onTap: _isSubmitting ? null : () => _submit(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _isSubmitting ? null : AppColors.smmGradient,
                color: _isSubmitting ? AppColors.surfaceLight : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isSubmitting ? [] : [BoxShadow(color: AppColors.smmColor.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              alignment: Alignment.center,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_isSubmitting)
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                else
                  const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  _isSubmitting ? 'Creating Project…' : 'Create Design Project',
                  style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: _isSubmitting ? AppColors.textMuted : Colors.white),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
