// lib/features/dashboard/smm/pages/smm_add_client_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/common_widgets.dart';

// ─────────────────────────────────────────
// SMM ADD CLIENT PAGE
// POST /api/smm/clients
// Same fields/process as Admin's "Add Client", minus the Budget field
// (SMM-created clients don't carry a budget).
// ─────────────────────────────────────────
class SmmAddClientPage extends StatefulWidget {
  final VoidCallback? onCreated;
  const SmmAddClientPage({super.key, this.onCreated});

  @override
  State<SmmAddClientPage> createState() => _SmmAddClientPageState();
}

class _SmmAddClientPageState extends State<SmmAddClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _projectTitleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _gstNumberCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  final _apiService = ApiService();

  // Connected devices / platforms multi-select
  final Set<String> _selectedPlatforms = {};
  String? _platformError;

  static const List<_PlatformOption> _platformOptions = [
    _PlatformOption('youtube', 'YouTube', Icons.play_circle_fill_rounded, Color(0xFFFF0000)),
    _PlatformOption('pinterest', 'Pinterest', Icons.push_pin_rounded, Color(0xFFE60023)),
    _PlatformOption('twitter', 'Twitter', Icons.alternate_email_rounded, Color(0xFF1DA1F2)),
    _PlatformOption('facebook', 'Facebook', Icons.facebook_rounded, Color(0xFF1877F2)),
    _PlatformOption('instagram', 'Instagram', Icons.camera_alt_rounded, Color(0xFFE1306C)),
    _PlatformOption('threads', 'Threads', Icons.tag_rounded, Color(0xFF000000)),
  ];

  void _togglePlatform(String key) {
    setState(() {
      if (_selectedPlatforms.contains(key)) {
        _selectedPlatforms.remove(key);
      } else {
        _selectedPlatforms.add(key);
      }
      if (_selectedPlatforms.isNotEmpty) _platformError = null;
    });
  }

  void _showSuccessSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: GoogleFonts.sora(fontSize: 13))),
      ]),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _cleanErr(String raw) {
    return raw.replaceFirst('Exception: ', '').trim();
  }

  void _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _platformError = _selectedPlatforms.isEmpty ? 'Select at least one platform' : null);
    if (!formValid || _selectedPlatforms.isEmpty) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final res = await _apiService.post(AppConstants.smmClients, body: {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text.trim(),
        'role': 'Client',
        // NOTE: no 'budget' field — SMM-created clients don't carry a budget.
        'address': _addressCtrl.text.trim(),
        'projectTitle': _projectTitleCtrl.text.trim(),
        'duration': _durationCtrl.text.trim(),
        'gstNumber': _gstNumberCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'companyName': _companyCtrl.text.trim(),
        'industry': _industryCtrl.text.trim(),
        'platforms': _selectedPlatforms.toList(),
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated?.call();
        final msg = (res['msg'] ?? res['message'] ?? 'Client created successfully').toString();
        _showSuccessSnack(msg);
      }
    } catch (e) {
      setState(() { _errorMessage = _cleanErr(e.toString()); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _companyCtrl.dispose(); _industryCtrl.dispose();
    _addressCtrl.dispose(); _projectTitleCtrl.dispose(); _durationCtrl.dispose();
    _gstNumberCtrl.dispose(); _passwordCtrl.dispose();
    super.dispose();
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
        title: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(gradient: AppColors.smmGradient, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Add New Client', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text('Fill in client details below', style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ]),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(color: AppColors.border, height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_errorMessage != null) _SmmErrorBanner(_errorMessage!),
            if (_errorMessage != null) const SizedBox(height: 14),
            _SmmSheetField(label: 'Full Name *', hint: 'e.g. Alex Johnson', icon: Icons.person_rounded, controller: _nameCtrl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
            const SizedBox(height: 14),
            _SmmSheetField(label: 'Email Address *', hint: 'e.g. alex@email.com', icon: Icons.email_rounded, controller: _emailCtrl, keyboardType: TextInputType.emailAddress, validator: (v) { if (v == null || v.trim().isEmpty) return 'Email is required'; if (!v.contains('@')) return 'Enter a valid email'; return null; }),
            const SizedBox(height: 14),
            _SmmSheetPasswordField(controller: _passwordCtrl, obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword), validator: (v) { if (v == null || v.trim().isEmpty) return 'Password is required'; if (v.length < 6) return 'Minimum 6 characters'; return null; }),
            const SizedBox(height: 14),
            _SmmSheetField(label: 'Phone Number', hint: 'e.g. +1 234 567 890', icon: Icons.phone_rounded, controller: _phoneCtrl, keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            _SmmSheetField(label: 'Company Name *', hint: 'e.g. Fashion Brand Co.', icon: Icons.business_rounded, controller: _companyCtrl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Company name is required' : null),
            const SizedBox(height: 14),
            _SmmSheetField(label: 'Industry', hint: 'e.g. Fashion & Lifestyle', icon: Icons.category_rounded, controller: _industryCtrl),
            const SizedBox(height: 14),
            // NOTE: Budget field intentionally omitted for SMM-created clients.
            _SmmSheetField(label: 'Address / Location', hint: 'e.g. New York, USA', icon: Icons.location_on_rounded, controller: _addressCtrl),
            const SizedBox(height: 14),
            _SmmSheetField(label: 'Project Title', hint: 'e.g. Instagram Growth Campaign', icon: Icons.assignment_rounded, controller: _projectTitleCtrl),
            const SizedBox(height: 14),
            _SmmSheetField(label: 'Duration', hint: 'e.g. 3 months', icon: Icons.calendar_month_rounded, controller: _durationCtrl),
            const SizedBox(height: 14),
            _SmmSheetField(label: 'GST Number', hint: 'e.g. 22AAAAA0000A1Z5', icon: Icons.receipt_long_rounded, controller: _gstNumberCtrl),
            const SizedBox(height: 14),
            _SmmSheetMultiSelect(
              label: 'Connected Devices *',
              options: _platformOptions,
              selected: _selectedPlatforms,
              onToggle: _togglePlatform,
              errorText: _platformError,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? _SmmLoadingButton(gradient: AppColors.smmGradient)
                : CommonButton(label: 'Create Client', gradient: AppColors.smmGradient, onTap: _submit),
            const SizedBox(height: 8),
            GestureDetector(onTap: () => Navigator.pop(context), child: Center(child: Text('Cancel', style: GoogleFonts.sora(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)))),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Local helper widgets (kept private to this file, mirroring the styling
// used on Admin's Add Client sheet)
// ─────────────────────────────────────────

class _SmmSheetField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const _SmmSheetField({required this.label, required this.hint, required this.icon, required this.controller, this.keyboardType, this.validator, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted),
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 17),
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.smmColor, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _SmmSheetPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _SmmSheetPasswordField({required this.controller, required this.obscure, required this.onToggle, this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password *', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Min. 6 characters',
            hintStyle: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 17),
            suffixIcon: GestureDetector(onTap: onToggle, child: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textMuted, size: 17)),
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.smmColor, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _PlatformOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _PlatformOption(this.key, this.label, this.icon, this.color);
}

class _SmmSheetMultiSelect extends StatelessWidget {
  final String label;
  final List<_PlatformOption> options;
  final Set<String> selected;
  final void Function(String key) onToggle;
  final String? errorText;

  const _SmmSheetMultiSelect({
    required this.label,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: hasError ? AppColors.error : AppColors.border, width: hasError ? 1.2 : 1),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = selected.contains(opt.key);
              return GestureDetector(
                onTap: () => onToggle(opt.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? opt.color.withOpacity(0.14) : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? opt.color : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(opt.icon, size: 15, color: isSelected ? opt.color : AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        opt.label,
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? opt.color : AppColors.textSecondary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle_rounded, size: 14, color: opt.color),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(errorText!, style: GoogleFonts.sora(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}

class _SmmLoadingButton extends StatelessWidget {
  final LinearGradient gradient;
  const _SmmLoadingButton({required this.gradient});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(14)),
      child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))),
    );
  }
}

class _SmmErrorBanner extends StatelessWidget {
  final String message;
  const _SmmErrorBanner(this.message);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: GoogleFonts.sora(fontSize: 12, color: AppColors.error))),
      ]),
    );
  }
}
