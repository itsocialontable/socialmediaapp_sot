import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exceptions.dart';

// ─────────────────────────────────────────
// EDIT DRAFT SHEET
// PUT /api/posts/draft/:id          → Update
// PUT /api/posts/draft/:id/publish  → Publish (requires scheduleDate + scheduleTime)
// ─────────────────────────────────────────
class EditDraftSheet extends StatefulWidget {
  final Map<String, dynamic> draft;
  final VoidCallback onUpdated;

  const EditDraftSheet({
    super.key,
    required this.draft,
    required this.onUpdated,
  });

  @override
  State<EditDraftSheet> createState() => _EditDraftSheetState();
}

class _EditDraftSheetState extends State<EditDraftSheet> {
  final _contentCtrl = TextEditingController();
  final _api         = ApiService();
  final _imagePicker = ImagePicker();

  final Set<String> _selectedPlatforms = {};
  XFile?       _newPickedFile;
  List<String> _existingMediaUrls = [];

  // Schedule
  DateTime? _scheduledDateTime;

  // Loading states
  bool _isUpdating   = false;
  bool _isPublishing = false;

  bool get _isBusy => _isUpdating || _isPublishing;

  // ── Connected devices for this draft's client (fetched from
  //    /api/social/accounts?clientId=), same as Create Post page ──
  List<_PlatformOption> _platforms = [];
  bool _accountsLoading = false;
  String? _accountsError;
  String? _clientId;

  // ────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _contentCtrl.text = widget.draft['content'] as String? ?? '';

    final rawPlatforms = widget.draft['platforms'];
    if (rawPlatforms is List) {
      _selectedPlatforms.addAll(rawPlatforms.map((e) => e.toString()));
    }

    final rawMedia = widget.draft['media'];
    if (rawMedia is List) {
      for (final m in rawMedia) {
        if (m is Map && m['url'] != null) {
          _existingMediaUrls.add(m['url'].toString());
        }
      }
    }

    // Pre-fill schedule if draft already has one
    try {
      final d = widget.draft['scheduleDate']?.toString() ?? '';
      final t = widget.draft['scheduleTime']?.toString() ?? '';
      if (d.isNotEmpty && t.isNotEmpty) {
        _scheduledDateTime = DateFormat('yyyy-MM-dd HH:mm').parse('$d $t');
      }
    } catch (_) {}

    _clientId = _extractClientId(widget.draft);
    if (_clientId != null && _clientId!.isNotEmpty) {
      _fetchConnectedAccounts(_clientId!);
    }
  }

  // Draft objects have shown up with the client id under a few different
  // keys/shapes depending on the endpoint, so check them all.
  String? _extractClientId(Map<String, dynamic> draft) {
    final direct = draft['clientId'] ?? draft['client_id'];
    if (direct != null) return direct.toString();
    final client = draft['client'];
    if (client is Map) {
      final id = client['id'] ?? client['_id'];
      if (id != null) return id.toString();
    } else if (client is String && client.isNotEmpty) {
      return client;
    }
    return null;
  }

  Future<void> _fetchConnectedAccounts(String clientId) async {
    setState(() { _accountsLoading = true; _accountsError = null; });
    try {
      final res = await _api.get(AppConstants.socialAccount, queryParams: {'clientId': clientId});
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

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  // ── Pick media ───────────────────────────
  Future<void> _pickMedia() async {
    final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _newPickedFile = picked);
  }

  // ── Pick schedule date + time ────────────
  Future<void> _pickSchedule() async {
    final now  = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDateTime ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF), surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledDateTime != null
          ? TimeOfDay.fromDateTime(_scheduledDateTime!)
          : TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF), surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _scheduledDateTime = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _clearSchedule() => setState(() => _scheduledDateTime = null);

  // ── Build body map ───────────────────────
  Map<String, dynamic> _buildBody({bool forPublish = false}) {
    final body = <String, dynamic>{
      'content':   _contentCtrl.text.trim(),
      'platforms': _selectedPlatforms.toList(),
    };
    if (forPublish && _scheduledDateTime != null) {
      body['scheduleDate'] = DateFormat('yyyy-MM-dd').format(_scheduledDateTime!);
      body['scheduleTime'] = DateFormat('HH:mm').format(_scheduledDateTime!);
    }
    return body;
  }

  // ── Update (save draft) ──────────────────
  Future<void> _update() async {
    if (_contentCtrl.text.trim().isEmpty) {
      _showSnack('Content likho pehle', isError: true);
      return;
    }
    setState(() => _isUpdating = true);
    try {
      final id = (widget.draft['id'] ?? widget.draft['_id']).toString();
      if (_newPickedFile != null) {
        final fd = FormData.fromMap({
          ..._buildBody(),
          'media': await MultipartFile.fromFile(
              _newPickedFile!.path, filename: _newPickedFile!.name),
        });
        await ApiService.rawDio.put('/api/posts/draft/$id', data: fd);
      } else {
        await _api.put('/api/posts/draft/$id', body: _buildBody());
      }
      widget.onUpdated();
      if (mounted) {
        _showSnack('Draft update ho gaya!');
        Navigator.pop(context);
      }
    } on NetworkException catch (_) {
      _showSnack('No internet connection', isError: true);
    } on UnauthorizedException catch (_) {
      _showSnack('Session expired', isError: true);
    } on AppException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (_) {
      _showSnack('Kuch galat hua, dobara try karo', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // ── Publish ──────────────────────────────
  Future<void> _publish() async {
    if (_contentCtrl.text.trim().isEmpty) {
      _showSnack('Content likho pehle', isError: true);
      return;
    }
    // Validate schedule
    if (_scheduledDateTime == null) {
      _showSnack('Please select schedule time', isError: true);
      return;
    }
    if (_scheduledDateTime!.isBefore(DateTime.now())) {
      _showSnack('Schedule time future mein honi chahiye', isError: true);
      return;
    }

    setState(() => _isPublishing = true);
    try {
      final id = (widget.draft['id'] ?? widget.draft['_id']).toString();
      if (_newPickedFile != null) {
        final fd = FormData.fromMap({
          ..._buildBody(forPublish: true),
          'media': await MultipartFile.fromFile(
              _newPickedFile!.path, filename: _newPickedFile!.name),
        });
        await ApiService.rawDio.put(
            '/api/posts/draft/$id/publish', data: fd);
      } else {
        await _api.put(
            '/api/posts/draft/$id/publish', body: _buildBody(forPublish: true));
      }
      widget.onUpdated();
      if (mounted) {
        _showSnack('Post schedule ho gaya! 🚀');
        Navigator.pop(context);
      }
    } on NetworkException catch (_) {
      _showSnack('No internet connection', isError: true);
    } on UnauthorizedException catch (_) {
      _showSnack('Session expired', isError: true);
    } on AppException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (_) {
      _showSnack('Publish failed, dobara try karo', isError: true);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.sora(fontSize: 13)),
      backgroundColor: isError ? AppColors.error : AppColors.smmColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Handle bar ───────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.edit_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)])
                  .createShader(b),
              child: Text('Edit Draft',
                  style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _isBusy ? null : () => Navigator.pop(context),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textSecondary, size: 18),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Content ──────────────────────────────────────────────────
          _label('Content'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _contentCtrl,
              maxLines: 5,
              style: GoogleFonts.sora(
                  fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Post ka content likho...',
                hintStyle: GoogleFonts.sora(
                    fontSize: 13, color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Platforms ────────────────────────────────────────────────
          _label('Platforms'),
          const SizedBox(height: 10),
          _buildConnectedDevices(),
          const SizedBox(height: 20),

          // ── Media ────────────────────────────────────────────────────
          _label('Media'),
          const SizedBox(height: 10),

          if (_existingMediaUrls.isNotEmpty && _newPickedFile == null) ...[
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _existingMediaUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(_existingMediaUrls[i],
                        width: 80, height: 80, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            width: 80, height: 80,
                            color: AppColors.surfaceLight,
                            child: const Icon(Icons.broken_image_rounded,
                                color: AppColors.textMuted))),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => setState(
                              () => _existingMediaUrls.removeAt(i)),
                      child: Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (_newPickedFile != null) ...[
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_newPickedFile!.path),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover),
              ),
              Positioned(
                top: 8, right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _newPickedFile = null),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
          ],

          GestureDetector(
            onTap: _pickMedia,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded,
                        color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                        _newPickedFile != null
                            ? 'Change Image'
                            : 'Add / Replace Image',
                        style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ]),
            ),
          ),
          const SizedBox(height: 20),

          // ── Schedule Time ─────────────────────────────────────────────
          Row(children: [
            _label('Schedule Time'),
            const Spacer(),
            if (_scheduledDateTime != null)
              GestureDetector(
                onTap: _clearSchedule,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.close_rounded,
                      size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text('Clear',
                      style: GoogleFonts.sora(
                          fontSize: 11, color: AppColors.textMuted)),
                ]),
              ),
          ]),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickSchedule,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: _scheduledDateTime != null
                    ? const Color(0xFF6C63FF).withOpacity(0.08)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _scheduledDateTime != null
                        ? const Color(0xFF6C63FF).withOpacity(0.5)
                        : AppColors.border),
              ),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: _scheduledDateTime != null
                          ? const Color(0xFF6C63FF).withOpacity(0.15)
                          : AppColors.border.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.schedule_rounded,
                      size: 16,
                      color: _scheduledDateTime != null
                          ? const Color(0xFF6C63FF)
                          : AppColors.textMuted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _scheduledDateTime != null
                      ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEE, dd MMM yyyy')
                              .format(_scheduledDateTime!),
                          style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6C63FF)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('hh:mm a')
                              .format(_scheduledDateTime!),
                          style: GoogleFonts.sora(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                      ])
                      : Text('Select date & time',
                      style: GoogleFonts.sora(
                          fontSize: 13,
                          color: AppColors.textMuted)),
                ),
                Icon(
                  _scheduledDateTime != null
                      ? Icons.edit_calendar_rounded
                      : Icons.calendar_month_rounded,
                  color: _scheduledDateTime != null
                      ? const Color(0xFF6C63FF)
                      : AppColors.textMuted,
                  size: 18,
                ),
              ]),
            ),
          ),

          // Schedule required hint for publish
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.info_outline_rounded,
                size: 12, color: AppColors.textMuted),
            const SizedBox(width: 5),
            Text('Please select schedule time',
                style: GoogleFonts.sora(
                    fontSize: 10, color: AppColors.error)),
          ]),
          const SizedBox(height: 28),

          // ── Action Buttons ────────────────────────────────────────────
          Row(children: [
            // UPDATE button
            Expanded(
              child: GestureDetector(
                onTap: _isBusy ? null : _update,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 52,
                  decoration: BoxDecoration(
                    color: _isUpdating
                        ? AppColors.border
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _isUpdating
                            ? AppColors.border
                            : const Color(0xFF6C63FF),
                        width: 1.5),
                  ),
                  child: Center(
                    child: _isUpdating
                        ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF6C63FF)))
                        : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_rounded,
                              color: Color(0xFF6C63FF), size: 16),
                          const SizedBox(width: 7),
                          Text('Update',
                              style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6C63FF))),
                        ]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // PUBLISH button
            Expanded(
              child: GestureDetector(
                onTap: _isBusy ? null : _publish,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: _isPublishing
                        ? null
                        : const LinearGradient(colors: [
                      Color(0xFF00D4AA),
                      Color(0xFF6C63FF),
                    ]),
                    color: _isPublishing ? AppColors.border : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _isPublishing
                        ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.rocket_launch_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 7),
                          Text('Publish',
                              style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ]),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.sora(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary));

  Widget _buildConnectedDevices() {
    if (_clientId == null || _clientId!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text('No client linked to this draft', style: GoogleFonts.sora(fontSize: 12, color: AppColors.textMuted))),
        ]),
      );
    }
    if (_accountsLoading) {
      return Container(
        height: 48,
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const SizedBox(width: 14),
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF))),
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
            onTap: () => _fetchConnectedAccounts(_clientId!),
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _platforms.map((p) {
        final sel = _selectedPlatforms.contains(p.id);
        return GestureDetector(
          onTap: () => setState(() =>
          sel ? _selectedPlatforms.remove(p.id)
              : _selectedPlatforms.add(p.id)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: sel
                  ? p.color.withOpacity(0.15)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: sel ? p.color : AppColors.border,
                  width: sel ? 1.5 : 1),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(p.icon,
                  color: sel ? p.color : AppColors.textMuted,
                  size: 14),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.name,
                      style: GoogleFonts.sora(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sel ? p.color : AppColors.textSecondary)),
                  if (p.connectedAs != null)
                    Text(p.connectedAs!,
                        style: GoogleFonts.sora(
                            fontSize: 9,
                            color: sel ? p.color.withOpacity(0.8) : AppColors.textMuted)),
                ],
              ),
              if (sel) ...[
                const SizedBox(width: 5),
                Icon(Icons.check_circle_rounded,
                    color: p.color, size: 12),
              ],
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────
// PLATFORM OPTION  (private)
// ─────────────────────────────────────────
class _PlatformOption {
  final String id, name;
  final Color color;
  final IconData icon;
  final String? connectedAs;
  const _PlatformOption(this.id, this.name, this.color, this.icon, {this.connectedAs});
}

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

_PlatformOption _platformOptionFromJson(Map<String, dynamic> json) {
  final key = (json['platform'] ?? json['network'] ?? '').toString().toLowerCase();
  final meta = _kPlatformMeta[key] ?? _PlatformMeta(key.isEmpty ? 'Unknown' : key, AppColors.textMuted, Icons.public_rounded);
  final connectedAs = json['username']?.toString() ?? json['name']?.toString() ?? json['displayName']?.toString();
  return _PlatformOption(key, meta.label, meta.color, meta.icon, connectedAs: connectedAs);
}