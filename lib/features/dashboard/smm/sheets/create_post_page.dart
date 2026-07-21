import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../smm_dashboard_screen.dart';
import 'assign_task_page.dart' show UserOption;

// ─────────────────────────────────────────
// PLATFORM OPTION
// ─────────────────────────────────────────
class PlatformOption {
  final String id;          // unique chip id (accountId for facebook, platform key otherwise)
  final String platform;    // canonical platform key, e.g. "facebook"
  final String name;
  final Color color;
  final IconData icon;
  final String? connectedAs;
  final String? accountId;  // page/account id, only set for facebook
  const PlatformOption(this.id, this.platform, this.name, this.color, this.icon, {this.connectedAs, this.accountId});
}

// Known platform → (label, color, icon) lookup used to render whatever
// platforms come back as "connected" for the selected client.
class _PlatformMeta {
  final String label;
  final Color color;
  final IconData icon;
  const _PlatformMeta(this.label, this.color, this.icon);
}

const Map<String, _PlatformMeta> _kPlatformMeta = {
  'instagram': _PlatformMeta('Instagram', Color(0xFFE1306C), Icons.camera_alt_rounded),
  'facebook': _PlatformMeta('Facebook', Color(0xFF1877F2), Icons.facebook_rounded),
  'twitter': _PlatformMeta('Twitter / X', Color(0xFF1DA1F2), Icons.alternate_email_rounded),
  'linkedin': _PlatformMeta('LinkedIn', Color(0xFF0A66C2), Icons.work_rounded),
  'pinterest': _PlatformMeta('Pinterest', Color(0xFFE60023), Icons.push_pin_rounded),
  'youtube': _PlatformMeta('YouTube', Color(0xFFFF0000), Icons.play_circle_fill_rounded),
  'threads': _PlatformMeta('Threads', Color(0xFF000000), Icons.tag_rounded),
};

PlatformOption _platformOptionFromJson(Map<String, dynamic> json) {
  final key = (json['platform'] ?? json['network'] ?? '').toString().toLowerCase();
  final meta = _kPlatformMeta[key] ?? _PlatformMeta(key.isEmpty ? 'Unknown' : key, AppColors.textMuted, Icons.public_rounded);

  // Ab har platform (Threads, Pinterest, YouTube, Facebook) ke neeche account name dikhega.
  final connectedAs = json['accountName']?.toString() ??
      json['username']?.toString() ??
      json['name']?.toString() ??
      json['displayName']?.toString();

  // Facebook ke sabhi accounts ka "platform" field "facebook" hi hota hai, isliye unique
  // chip id ke liye accountId use karo - warna sab chips ek hi selection share kar lete hain.
  final accountId = key == 'facebook' ? (json['accountId']?.toString() ?? json['_id']?.toString()) : null;
  final uniqueId = accountId ?? key;

  return PlatformOption(uniqueId, key, meta.label, meta.color, meta.icon, connectedAs: connectedAs, accountId: accountId);
}

// ─────────────────────────────────────────
// CREATE POST PAGE
// ─────────────────────────────────────────
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _contentCtrl = TextEditingController();
  DateTime? _scheduledAt;
  final Set<String> _selectedPlatforms = {};
  bool _isCreating = false;
  bool _isSavingDraft = false;
  XFile? _pickedFile;
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();

  // Client dropdown
  List<UserOption> _clients = [];
  bool _clientsLoading = true;
  String? _clientsError;
  UserOption? _selectedClient;

  // Connected devices for the selected client (fetched from /api/social/accounts?clientId=)
  List<PlatformOption> _platforms = [];
  bool _accountsLoading = false;
  String? _accountsError;

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    setState(() { _clientsLoading = true; _clientsError = null; });
    try {
      final res = await _apiService.get(AppConstants.smmClients);
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

  Future<void> _fetchConnectedAccounts(String clientId) async {
    setState(() { _accountsLoading = true; _accountsError = null; _platforms = []; });
    try {
      final res = await _apiService.get(AppConstants.socialAccount, queryParams: {'clientId': clientId});
      final data = res['data'];
      final raw = (data is List ? data : null) ?? (data is Map ? data['accounts'] : null) ?? res['accounts'] ?? res['data'] ?? res;
      final list = raw is List ? raw.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
      setState(() { _platforms = list.map(_platformOptionFromJson).toList(); _accountsLoading = false; });
    } on NetworkException catch (_) {
      setState(() { _accountsError = 'No internet connection'; _accountsLoading = false; });
    } on UnauthorizedException catch (_) {
      setState(() { _accountsError = 'Session expired'; _accountsLoading = false; });
    } on AppException catch (e) {
      setState(() { _accountsError = e.message; _accountsLoading = false; });
    } catch (_) {
      setState(() { _accountsError = 'Failed to load connected accounts'; _accountsLoading = false; });
    }
  }

  void _onClientChanged(UserOption? client) {
    setState(() {
      _selectedClient = client;
      _selectedPlatforms.clear();
      _platforms = [];
      _accountsError = null;
    });
    if (client != null) _fetchConnectedAccounts(client.id);
  }

  Widget _buildClientDropdown() {
    if (_clientsLoading) {
      return Container(
        height: 48,
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const SizedBox(width: 14),
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.smmColor)),
          const SizedBox(width: 10),
          Text('Loading clients...', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted)),
        ]),
      );
    }
    if (_clientsError != null) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(_clientsError!, style: GoogleFonts.sora(fontSize: 12, color: AppColors.error), maxLines: 1, overflow: TextOverflow.ellipsis)),
          GestureDetector(
            onTap: _fetchClients,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Text('Retry', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
            ),
          ),
        ]),
      );
    }
    if (_clients.isEmpty) {
      return Container(
        height: 48, padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text('No clients found', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _selectedClient != null ? AppColors.smmColor.withOpacity(0.6) : AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UserOption>(
          value: _selectedClient, isExpanded: true,
          hint: Text('Select client...', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted)),
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          items: _clients.map((u) => DropdownMenuItem<UserOption>(
            value: u,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(u.name, style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary)),
              if (u.email != null) Text(u.email!, style: GoogleFonts.sora(fontSize: 10, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          )).toList(),
          onChanged: _onClientChanged,
        ),
      ),
    );
  }

  Widget _buildConnectedDevices() {
    if (_selectedClient == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text('Select a client to see their connected accounts', style: GoogleFonts.sora(fontSize: 12, color: AppColors.textMuted))),
        ]),
      );
    }
    if (_accountsLoading) {
      return Container(
        height: 48,
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const SizedBox(width: 14),
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.smmColor)),
          const SizedBox(width: 10),
          Text('Loading connected devices...', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted)),
        ]),
      );
    }
    if (_accountsError != null) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(_accountsError!, style: GoogleFonts.sora(fontSize: 12, color: AppColors.error), maxLines: 1, overflow: TextOverflow.ellipsis)),
          GestureDetector(
            onTap: () => _fetchConnectedAccounts(_selectedClient!.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Text('Retry', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
            ),
          ),
        ]),
      );
    }
    if (_platforms.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.link_off_rounded, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(child: Text('No connected device for this client', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning))),
        ]),
      );
    }
    // Facebook ke multiple accounts ko alag group mein daalo, baaki platforms waise hi ek row mein.
    final facebookAccounts = _platforms.where((p) => p.platform == 'facebook').toList();
    final otherPlatforms = _platforms.where((p) => p.platform != 'facebook').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (otherPlatforms.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, children: otherPlatforms.map(_platformChip).toList()),
        if (otherPlatforms.isNotEmpty && facebookAccounts.isNotEmpty) const SizedBox(height: 10),
        if (facebookAccounts.isNotEmpty) _buildFacebookGroup(facebookAccounts),
      ],
    );
  }

  // Ek chip ka UI. Facebook ke liye sirf account name dikhta hai (upar group header mein
  // "Facebook" already likha hota hai), baaki platforms apna name dikhate hain jaise pehle.
  Widget _platformChip(PlatformOption p) {
    final sel = _selectedPlatforms.contains(p.id);
    final isFacebook = p.platform == 'facebook';
    final primaryLabel = isFacebook ? (p.connectedAs ?? p.name) : p.name;

    return GestureDetector(
      onTap: () => setState(() => sel ? _selectedPlatforms.remove(p.id) : _selectedPlatforms.add(p.id)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? p.color.withOpacity(0.18) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? p.color : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(p.icon, color: sel ? p.color : AppColors.textSecondary, size: 16),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(primaryLabel, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? p.color : AppColors.textSecondary)),
                if (!isFacebook && p.connectedAs != null)
                  Text(p.connectedAs!, style: GoogleFonts.sora(fontSize: 9, color: sel ? p.color.withOpacity(0.8) : AppColors.textMuted)),
              ],
            ),
            if (sel) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded, size: 13, color: p.color),
            ],
          ],
        ),
      ),
    );
  }

  // Facebook ke saare connected pages ek card mein, "Show all / Show less" ke saath
  // Facebook ke saare connected pages ek fixed-height card mein, box ka size same rehta
  // hai - agar accounts jyada hain to andar hi scroll ho jata hai (box bada nahi hota).
  Widget _buildFacebookGroup(List<PlatformOption> accounts) {
    const maxBoxHeight = 160.0;
    final selectedCount = accounts.where((a) => _selectedPlatforms.contains(a.id)).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.facebook_rounded, color: Color(0xFF1877F2), size: 18),
              const SizedBox(width: 8),
              Text('Facebook Pages (${accounts.length})',
                  style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              if (selectedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF1877F2).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text('$selectedCount selected',
                      style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF1877F2))),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: maxBoxHeight),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 4),
                child: Wrap(spacing: 8, runSpacing: 8, children: accounts.map(_platformChip).toList()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _pickedFile = picked);
  }

  void _removeMedia() => setState(() => _pickedFile = null);

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(primary: AppColors.smmColor, surface: AppColors.surface)),
        child: child!,
      ),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(primary: AppColors.smmColor, surface: AppColors.surface)),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
    log("Selected: $_scheduledAt");
  }

  // Selected chips (facebook accounts + other platforms) unke PlatformOption ke saath
  List<PlatformOption> get _selectedPlatformOptions =>
      _platforms.where((p) => _selectedPlatforms.contains(p.id)).toList();

  // Backend ke purane "platforms" field ke liye - platform names, deduped (e.g. ["facebook", "threads"])
  List<String> get _selectedPlatformNames =>
      _selectedPlatformOptions.map((p) => p.platform).toSet().toList();

  // Naya "platformAccounts" field - kaunsa specific Facebook page select hua hai
  List<Map<String, String>> get _selectedPlatformAccounts => _selectedPlatformOptions
      .where((p) => p.accountId != null)
      .map((p) => {'platform': p.platform, 'accountId': p.accountId!})
      .toList();

  PostModel _buildPost() => PostModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    content: _contentCtrl.text.trim(),
    platforms: _selectedPlatformNames,
    scheduledAt: _scheduledAt,
    hasMedia: _pickedFile != null,
    createdAt: DateTime.now(),
  );

  String? _validate() {
    if (_selectedClient == null) return 'Please select a client.';
    if (_contentCtrl.text.trim().isEmpty) return 'Please write some content before posting.';
    if (_selectedPlatforms.isEmpty) return 'Select at least one connected platform.';
    return null;
  }

  void _showSnack(BuildContext ctx, {required String message, required Color color, required IconData icon}) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: GoogleFonts.sora(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _createPost(BuildContext ctx) async {
    final error = _validate();
    if (error != null) {
      _showSnack(ctx, message: error, color: AppColors.warning, icon: Icons.warning_amber_rounded);
      return;
    }
    setState(() => _isCreating = true);
    try {
      if (_pickedFile != null) {
        final formData = FormData.fromMap({
          'content': _contentCtrl.text.trim(),
          'clientId': _selectedClient!.id,
          for (int i = 0; i < _selectedPlatformNames.length; i++) 'platforms[$i]': _selectedPlatformNames[i],
          if (_selectedPlatformAccounts.isNotEmpty)
            'platformAccounts': jsonEncode(_selectedPlatformAccounts),
          if (_scheduledAt != null)
            'scheduleDate':
            DateFormat('yyyy-MM-dd').format(_scheduledAt!),

          if (_scheduledAt != null)
            'scheduleTime':
            DateFormat('HH:mm').format(_scheduledAt!),
          'media': await MultipartFile.fromFile(_pickedFile!.path, filename: _pickedFile!.name),
        });
        await _apiService.postMultipart(AppConstants.createPost, formData: formData);
      } else {
        final body = <String, dynamic>{
          'content': _contentCtrl.text.trim(),
          'clientId': _selectedClient!.id,
          'platforms': _selectedPlatformNames,
          if (_selectedPlatformAccounts.isNotEmpty) 'platformAccounts': _selectedPlatformAccounts,
          if (_scheduledAt != null)
            'scheduleDate':
            DateFormat('yyyy-MM-dd').format(_scheduledAt!),

          if (_scheduledAt != null)
            'scheduleTime':
            DateFormat('HH:mm').format(_scheduledAt!),
        };
        await _apiService.post(AppConstants.createPost, body: body);
      }
      final provider = ctx.read<PostsProvider>();
      provider.addToQueue(_buildPost());
      if (ctx.mounted) {
        Navigator.pop(ctx);
        _showSnack(ctx, message: 'Post added to queue!', color: AppColors.success, icon: Icons.check_circle_rounded);
      }
    } on ValidationException catch (e) {
      if (ctx.mounted) _showSnack(ctx, message: e.message, color: AppColors.warning, icon: Icons.warning_amber_rounded);
    } on UnauthorizedException catch (_) {
      if (ctx.mounted) _showSnack(ctx, message: 'Session expired. Please log in again.', color: AppColors.error, icon: Icons.lock_outline_rounded);
    } on NetworkException catch (_) {
      if (ctx.mounted) _showSnack(ctx, message: 'No internet connection. Please try again.', color: AppColors.error, icon: Icons.wifi_off_rounded);
    } on TimeoutException catch (_) {
      if (ctx.mounted) _showSnack(ctx, message: 'Request timed out. Please try again.', color: AppColors.error, icon: Icons.timer_off_outlined);
    } on AppException catch (e) {
      if (ctx.mounted) _showSnack(ctx, message: e.message, color: AppColors.error, icon: Icons.error_outline_rounded);
    } catch (e) {
      if (ctx.mounted) _showSnack(ctx, message: 'Something went wrong. Please try again.', color: AppColors.error, icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _saveDraft(BuildContext ctx) async {
    if (_contentCtrl.text.trim().isEmpty) {
      _showSnack(ctx, message: 'Write some content before saving a draft.', color: AppColors.warning, icon: Icons.warning_amber_rounded);
      return;
    }
    setState(() => _isSavingDraft = true);
    try {
      if (_pickedFile != null) {
        final formData = FormData.fromMap({
          'content': _contentCtrl.text.trim(),
          if (_selectedClient != null) 'clientId': _selectedClient!.id,
          for (int i = 0; i < _selectedPlatformNames.length; i++) 'platforms[$i]': _selectedPlatformNames[i],
          if (_selectedPlatformAccounts.isNotEmpty)
            'platformAccounts': jsonEncode(_selectedPlatformAccounts),
          'media': await MultipartFile.fromFile(_pickedFile!.path, filename: _pickedFile!.name),
        });
        await _apiService.postMultipart(AppConstants.saveDraftPost, formData: formData);
      } else {
        final body = <String, dynamic>{
          'content': _contentCtrl.text.trim(),
          if (_selectedClient != null) 'clientId': _selectedClient!.id,
          'platforms': _selectedPlatformNames,
          if (_selectedPlatformAccounts.isNotEmpty) 'platformAccounts': _selectedPlatformAccounts,
        };
        await _apiService.post(AppConstants.saveDraftPost, body: body);
      }
      final provider = ctx.read<PostsProvider>();
      provider.saveDraft(_buildPost());
      if (ctx.mounted) {
        Navigator.pop(ctx);
        _showSnack(ctx, message: 'Draft saved successfully!', color: const Color(0xFF6C63FF), icon: Icons.bookmark_rounded);
      }
    } on ValidationException catch (e) {
      if (ctx.mounted) _showSnack(ctx, message: e.message, color: AppColors.warning, icon: Icons.warning_amber_rounded);
    } on UnauthorizedException catch (_) {
      if (ctx.mounted) _showSnack(ctx, message: 'Session expired. Please log in again.', color: AppColors.error, icon: Icons.lock_outline_rounded);
    } on NetworkException catch (_) {
      if (ctx.mounted) _showSnack(ctx, message: 'No internet connection. Please try again.', color: AppColors.error, icon: Icons.wifi_off_rounded);
    } on TimeoutException catch (_) {
      if (ctx.mounted) _showSnack(ctx, message: 'Request timed out. Please try again.', color: AppColors.error, icon: Icons.timer_off_outlined);
    } on AppException catch (e) {
      if (ctx.mounted) _showSnack(ctx, message: e.message, color: AppColors.error, icon: Icons.error_outline_rounded);
    } catch (e) {
      if (ctx.mounted) _showSnack(ctx, message: 'Something went wrong. Please try again.', color: AppColors.error, icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (b) => AppColors.smmGradient.createShader(b),
          child: Text('Create Post', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.border, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Client
          _secLabel('Client'),
          const SizedBox(height: 10),
          _buildClientDropdown(),
          const SizedBox(height: 20),

          // Platforms (connected devices for the selected client)
          _secLabel('Connected Devices'),
          const SizedBox(height: 10),
          _buildConnectedDevices(),
          const SizedBox(height: 20),

          // Content
          _secLabel('Content'),
          const SizedBox(height: 10),
          _textArea(_contentCtrl, 'Write your post content here...', 5),
          const SizedBox(height: 20),

          // Schedule
          _secLabel('Schedule'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _scheduledAt != null ? AppColors.smmColor : AppColors.border),
              ),
              child: Row(children: [
                Icon(Icons.calendar_month_rounded, color: _scheduledAt != null ? AppColors.smmColor : AppColors.textMuted, size: 18),
                const SizedBox(width: 10),
                Text(
                  _scheduledAt != null
                      ? '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year}  ${_scheduledAt!.hour.toString().padLeft(2, '0')}:${_scheduledAt!.minute.toString().padLeft(2, '0')}'
                      : 'Select date & time',
                  style: GoogleFonts.sora(fontSize: 13, color: _scheduledAt != null ? AppColors.textPrimary : AppColors.textMuted),
                ),
                const Spacer(),
                if (_scheduledAt != null)
                  GestureDetector(
                    onTap: () => setState(() => _scheduledAt = null),
                    child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Media
          _secLabel('Media'),
          const SizedBox(height: 10),
          if (_pickedFile != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(File(_pickedFile!.path), height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: _removeMedia,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8, right: 8,
                  child: GestureDetector(
                    onTap: _pickMedia,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text('Replace', style: GoogleFonts.sora(fontSize: 11, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: _pickMedia,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted, size: 32),
                  const SizedBox(height: 8),
                  Text('Tap to add image / video', style: GoogleFonts.sora(fontSize: 12, color: AppColors.textMuted)),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 28),

          // Action Buttons
          Row(
            children: [
              // Save Draft
              Expanded(
                child: GestureDetector(
                  onTap: (_isSavingDraft || _isCreating) ? null : () => _saveDraft(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: (_isSavingDraft || _isCreating) ? AppColors.border : const Color(0xFF6C63FF).withOpacity(0.5)),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isSavingDraft)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)))
                        else
                          const Icon(Icons.bookmark_border_rounded, color: Color(0xFF6C63FF), size: 18),
                        const SizedBox(width: 7),
                        Text(
                          _isSavingDraft ? 'Saving…' : 'Save Draft',
                          style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: (_isSavingDraft || _isCreating) ? AppColors.textMuted : const Color(0xFF6C63FF)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Create Post
              Expanded(
                child: GestureDetector(
                  onTap: (_isCreating || _isSavingDraft) ? null : () => _createPost(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: (_isCreating || _isSavingDraft) ? null : AppColors.smmGradient,
                      color: (_isCreating || _isSavingDraft) ? AppColors.surfaceLight : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: (_isCreating || _isSavingDraft) ? [] : [BoxShadow(color: AppColors.smmColor.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 5))],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isCreating)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        else
                          Icon(Icons.send_rounded, color: _isSavingDraft ? AppColors.textMuted : Colors.white, size: 18),
                        const SizedBox(width: 7),
                        Text(
                          _isCreating ? 'Posting…' : 'Create Post',
                          style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: (_isCreating || _isSavingDraft) ? AppColors.textMuted : Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Helpers ───
Widget _secLabel(String t) => Text(t, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary));

Widget _textArea(TextEditingController c, String hint, int lines) => Container(
  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
  child: TextField(
    controller: c, maxLines: lines,
    style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
    decoration: InputDecoration(
      hintText: hint, hintStyle: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted),
      border: InputBorder.none, contentPadding: const EdgeInsets.all(14),
    ),
  ),
);