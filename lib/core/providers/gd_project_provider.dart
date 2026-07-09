// lib/core/providers/gd_project_provider.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';
import '../errors/api_response.dart';
import '../network/api_service.dart';
import '../../model/gd_project_model.dart';

class GdProjectProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  // ── Projects list state ─────────────────────────────────────────────────
  ApiResponse<List<GdProject>> _response = ApiResponse.idle();
  ApiResponse<List<GdProject>> get response => _response;

  List<GdProject> get allProjects => _response.data ?? [];
  List<GdProject> get pendingProjects =>
      allProjects.where((p) => p.status.toLowerCase() == 'pending').toList();
  List<GdProject> get inProgressProjects => allProjects
      .where((p) => p.status.toLowerCase() == 'in progress')
      .toList();
  List<GdProject> get completedProjects => allProjects
      .where((p) => p.status.toLowerCase() == 'completed')
      .toList();
  List<GdProject> get reviewProjects =>
      allProjects.where((p) => p.status.toLowerCase() == 'review').toList();

  // ── Upload state ────────────────────────────────────────────────────────
  ApiResponse<void> _uploadResponse = ApiResponse.idle();
  ApiResponse<void> get uploadResponse => _uploadResponse;

  XFile? _pickedFile;
  XFile? get pickedFile => _pickedFile;
  bool get hasFile => _pickedFile != null;

  double _uploadProgress = 0;
  double get uploadProgress => _uploadProgress;

  GdProject? _selectedProject;
  GdProject? get selectedProject => _selectedProject;

  // ── Pick file from gallery / camera ────────────────────────────────────
  Future<void> pickFile() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        _pickedFile = file;
        _uploadResponse = ApiResponse.idle();
        notifyListeners();
      }
    } catch (_) {
      // User cancelled or permission denied — no-op
    }
  }

  Future<void> pickVideo() async {
    try {
      final file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file != null) {
        _pickedFile = file;
        _uploadResponse = ApiResponse.idle();
        notifyListeners();
      }
    } catch (_) {}
  }

  void removeFile() {
    _pickedFile = null;
    _uploadProgress = 0;
    _uploadResponse = ApiResponse.idle();
    notifyListeners();
  }

  void selectProject(GdProject? project) {
    _selectedProject = project;
    notifyListeners();
  }

  void resetUpload() {
    _pickedFile = null;
    _uploadProgress = 0;
    _uploadResponse = ApiResponse.idle();
    _selectedProject = null;
    notifyListeners();
  }

  // ── Derive fileType from extension ─────────────────────────────────────
  String _resolveFileType(String path) {
    return 'Final';
  }

  // ── Upload file to POST /api/gd/projects/:id/files ──────────────────────
  Future<bool> uploadFile({required String projectId}) async {
    if (_pickedFile == null) return false;

    _uploadResponse = ApiResponse.loading();
    _uploadProgress = 0;
    notifyListeners();

    try {
      final file = File(_pickedFile!.path);
      final fileName = _pickedFile!.name;
      final fileType = _resolveFileType(fileName);

      final formData = FormData.fromMap({
        'designFile': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'fileType': fileType,
        'fileName': fileName,
      });

      // Use postMultipart with onSendProgress via Dio directly
      final dio = ApiService.rawDio;
      final response = await dio.post(
        '${AppConstants.gdProjectFiles}/$projectId/files',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            _uploadProgress = sent / total;
            notifyListeners();
          }
        },
      );

      final data = response.data;
      final bool success = data is Map && data['success'] == true;

      if (success) {
        _uploadResponse = ApiResponse.success(null,
            message: data['msg']?.toString() ?? 'File uploaded successfully!');
        _uploadProgress = 1.0;
        notifyListeners();
        return true;
      } else {
        final msg = data is Map
            ? data['msg']?.toString() ?? 'Upload failed.'
            : 'Upload failed.';
        _uploadResponse = ApiResponse.error(msg);
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response!.data['msg']?.toString() ??
          e.response!.data['message']?.toString() ??
          'Upload failed. Please try again.'
          : e.message ?? 'Upload failed. Please try again.';
      _uploadResponse = ApiResponse.error(msg);
      notifyListeners();
      return false;
    } catch (e) {
      _uploadResponse = ApiResponse.error(e.toString());
      notifyListeners();
      return false;
    }
  }

  // ── Fetch projects ──────────────────────────────────────────────────────
  Future<void> fetchProjects({bool silent = false}) async {
    if (!silent) {
      _response = ApiResponse.loading();
      notifyListeners();
    }

    try {
      final raw = await _api.get(AppConstants.gdProjects);
      final bool success = raw['success'] == true;
      if (!success) {
        _response = ApiResponse.error(
            raw['msg']?.toString() ?? 'Failed to fetch projects.');
        notifyListeners();
        return;
      }
      final data = raw['data'] as Map<String, dynamic>? ?? {};
      final list = (data['projects'] as List<dynamic>? ?? [])
          .map((e) => GdProject.fromJson(e as Map<String, dynamic>))
          .toList();
      _response = ApiResponse.success(list, message: raw['msg']?.toString());
      notifyListeners();
    } catch (e) {
      _response = ApiResponse.error(e.toString());
      notifyListeners();
    }
  }

  void reset() {
    _response = ApiResponse.idle();
    notifyListeners();
  }
}