import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_service.dart';
import '../../core/errors/api_response.dart';
import '../../core/errors/app_exceptions.dart';
import '../widgets/common_widgets.dart';

class EditProfilePage extends StatefulWidget {
  final Color accentColor;
  final LinearGradient gradient;

  const EditProfilePage({
    super.key,
    required this.accentColor,
    required this.gradient,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  final _apiService = ApiService();
  ApiResponse<void> _updateState = ApiResponse.idle();
  ApiResponse<void> _imageUploadState = ApiResponse.idle();
  ApiResponse<void> _imageDeleteState = ApiResponse.idle();

  // Local picked file — sirf preview ke liye jab tak upload pending hai
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl.text = auth.userName;
    _emailCtrl.text = auth.userEmail;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ─── Update Profile ───────────────────────────────────
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _updateState = ApiResponse.loading());

    try {
      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      };
      if (_phoneCtrl.text.trim().isNotEmpty) body['phone'] = _phoneCtrl.text.trim();
      if (_bioCtrl.text.trim().isNotEmpty) body['bio'] = _bioCtrl.text.trim();

      await _apiService.put('/api/admin/profile', body: body);

      if (mounted) {
        await context.read<AuthProvider>().updateUserInfo(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );
        setState(() => _updateState = ApiResponse.success(null));
        _showSnackBar('Profile updated successfully ✓', isError: false);
      }
    } on AppException catch (e) {
      setState(() => _updateState = ApiResponse.error(e.message));
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      setState(() => _updateState = ApiResponse.error('Something went wrong. Please try again.'));
      _showSnackBar('Something went wrong. Please try again.', isError: true);
    }
  }

  // ─── Upload Profile Image ─────────────────────────────
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return;

    // Show local preview immediately
    setState(() {
      _pickedImage = File(picked.path);
      _imageUploadState = ApiResponse.loading();
    });

    try {
      final formData = FormData.fromMap({
        'profileImage': await MultipartFile.fromFile(
          picked.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final res = await _apiService.postMultipart(
        '/api/admin/profile/image',
        formData: formData,
      );

      // Server se image URL ata hai to save kar lo, warna local path rakho
      final imageUrl = res['data']?['profileImage']?.toString() ??
          res['profileImage']?.toString() ??
          res['imageUrl']?.toString();

      if (mounted) {
        // AuthProvider mein save karo taaki profile_page bhi update ho
        await context.read<AuthProvider>().setProfileImageUrl(imageUrl ?? picked.path);
        setState(() {
          _pickedImage = null; // ab provider se milega
          _imageUploadState = ApiResponse.success(null);
        });
        _showSnackBar('Profile photo updated ✓', isError: false);
      }
    } on AppException catch (e) {
      setState(() {
        _pickedImage = null;
        _imageUploadState = ApiResponse.error(e.message);
      });
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      setState(() {
        _pickedImage = null;
        _imageUploadState = ApiResponse.error('Failed to upload image.');
      });
      _showSnackBar('Failed to upload image. Please try again.', isError: true);
    }
  }

  // ─── Delete Profile Image ─────────────────────────────
  Future<void> _deleteProfileImage() async {
    final confirm = await _showConfirmDialog(
      title: 'Remove Photo',
      message: 'Are you sure you want to remove your profile photo?',
    );
    if (!confirm) return;

    setState(() => _imageDeleteState = ApiResponse.loading());

    try {
      await _apiService.delete('/api/admin/profile/image');

      if (mounted) {
        // Provider clear karo — dono pages update ho jayenge
        await context.read<AuthProvider>().setProfileImageUrl(null);
        setState(() {
          _pickedImage = null;
          _imageDeleteState = ApiResponse.success(null);
        });
        _showSnackBar('Profile photo removed', isError: false);
      }
    } on AppException catch (e) {
      setState(() => _imageDeleteState = ApiResponse.error(e.message));
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      setState(() => _imageDeleteState = ApiResponse.error('Failed to delete image.'));
      _showSnackBar('Failed to remove photo. Please try again.', isError: true);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg, style: GoogleFonts.sora(fontSize: 13, color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _showConfirmDialog({required String title, required String message}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: GoogleFonts.sora(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        content: Text(message,
            style: GoogleFonts.sora(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.sora(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove',
                style: GoogleFonts.sora(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Priority: local picked file > provider URL > default avatar
    final providerUrl = auth.profileImageUrl;
    final hasImage = _pickedImage != null || (providerUrl != null && providerUrl.isNotEmpty);
    final isImageLoading = _imageUploadState.isLoading || _imageDeleteState.isLoading;

    return CommonScaffold(
      appBar: CommonAppBar(
        title: 'Edit Profile',
        showBack: true,
        gradientStart: widget.accentColor,
        gradientEnd: widget.accentColor.withOpacity(0.6),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ─── Avatar Section ────────────────────────────
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: hasImage ? null : widget.gradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.accentColor.withOpacity(0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _buildAvatarChild(auth, providerUrl),
                          ),
                        ),

                        // Loading overlay
                        if (isImageLoading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                ),
                              ),
                            ),
                          ),

                        // Camera button
                        if (!isImageLoading)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  gradient: widget.gradient,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.background, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),

                        // Delete button — sirf jab image ho
                        if (!isImageLoading && hasImage)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _deleteProfileImage,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.background, width: 1.5),
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hasImage
                          ? 'Tap camera to change • X to remove'
                          : 'Tap camera to add photo',
                      style: GoogleFonts.sora(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

              const SizedBox(height: 32),

              // _SectionLabel('Personal Information'),
              const SizedBox(height: 14),

              _ProfileTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                accentColor: widget.accentColor,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 2) return 'Name must be at least 2 characters';
                  return null;
                },
              ).animate(delay: 100.ms).fadeIn().slideX(begin: 0.1, end: 0),

              const SizedBox(height: 14),

              _ProfileTextField(
                controller: _emailCtrl,
                label: 'Email Address',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                accentColor: widget.accentColor,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
                  if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
                  return null;
                },
              ).animate(delay: 150.ms).fadeIn().slideX(begin: 0.1, end: 0),

              const SizedBox(height: 14),

              _ProfileTextField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                hint: 'Enter phone number (optional)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                accentColor: widget.accentColor,
              ).animate(delay: 200.ms).fadeIn().slideX(begin: 0.1, end: 0),

              const SizedBox(height: 14),

              _ProfileTextField(
                controller: _bioCtrl,
                label: 'Bio',
                hint: 'Tell us about yourself (optional)',
                icon: Icons.notes_rounded,
                maxLines: 3,
                accentColor: widget.accentColor,
              ).animate(delay: 250.ms).fadeIn().slideX(begin: 0.1, end: 0),

              const SizedBox(height: 32),

              if (_updateState.isError)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _updateState.message ?? 'Something went wrong.',
                          style: GoogleFonts.sora(fontSize: 12, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

              CommonButton(
                label: _updateState.isLoading ? 'Saving...' : 'Save Changes',
                gradient: widget.gradient,
                isLoading: _updateState.isLoading,
                onTap: _updateState.isLoading ? null : _updateProfile,
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarChild(AuthProvider auth, String? providerUrl) {
    // 1. Local picked file (upload pending preview)
    if (_pickedImage != null) {
      return Image.file(_pickedImage!, fit: BoxFit.cover);
    }
    // 2. URL from provider (server se aaya ya local path)
    if (providerUrl != null && providerUrl.isNotEmpty) {
      if (providerUrl.startsWith('/') || providerUrl.startsWith('file://')) {
        return Image.file(File(providerUrl), fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultAvatarWidget(auth));
      }
      return Image.network(
        providerUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultAvatarWidget(auth),
      );
    }
    // 3. Default letter avatar
    return _defaultAvatarWidget(auth);
  }

  Widget _defaultAvatarWidget(AuthProvider auth) {
    return Container(
      decoration: BoxDecoration(gradient: widget.gradient),
      child: Center(
        child: Text(
          auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'U',
          style: GoogleFonts.sora(
              fontSize: 38, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.sora(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Profile Text Field ──────────────────────────────────
class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color accentColor;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accentColor,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),


        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            // labelText: label,
            hintText: hint,
            hintStyle: GoogleFonts.sora(fontSize: 12, color: AppColors.textMuted),
            // labelStyle: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary),
            prefixIcon: Icon(icon, color: accentColor, size: 18),
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorStyle: GoogleFonts.sora(fontSize: 11, color: AppColors.error),
          ),
        ),
      ],
    );
  }
}