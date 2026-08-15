// lib/core/providers/smm_design_project_provider.dart

import 'package:flutter/material.dart';
import '../errors/api_response.dart';
import '../../model/smm_design_project_model.dart';
import '../../features/dashboard/smm/repositories/smm_design_project_repository.dart';

class SmmDesignProjectProvider extends ChangeNotifier {
  final SmmDesignProjectRepository _repo = SmmDesignProjectRepository();

  // ── List state ───────────────────────────────────────────────────────────
  ApiResponse<List<SmmDesignProject>> _response = ApiResponse.idle();
  ApiResponse<List<SmmDesignProject>> get response => _response;
  List<SmmDesignProject> get projects => _response.data ?? [];

  Future<void> fetchProjects({bool silent = false}) async {
    if (!silent) {
      _response = ApiResponse.loading();
      notifyListeners();
    }
    try {
      final list = await _repo.fetchAll();
      _response = ApiResponse.success(list);
    } catch (e) {
      _response = ApiResponse.error(e.toString());
    }
    notifyListeners();
  }

  // ── Detail state ─────────────────────────────────────────────────────────
  ApiResponse<SmmDesignProject> _detail = ApiResponse.idle();
  ApiResponse<SmmDesignProject> get detail => _detail;

  Future<void> fetchDetail(String id) async {
    _detail = ApiResponse.loading();
    notifyListeners();
    try {
      final project = await _repo.fetchById(id);
      _detail = ApiResponse.success(project);
    } catch (e) {
      _detail = ApiResponse.error(e.toString());
    }
    notifyListeners();
  }

  void clearDetail() {
    _detail = ApiResponse.idle();
    notifyListeners();
  }

  // ── Update ───────────────────────────────────────────────────────────────
  ApiResponse<SmmDesignProject> _updateResponse = ApiResponse.idle();
  ApiResponse<SmmDesignProject> get updateResponse => _updateResponse;

  Future<bool> updateProject(String id, SmmDesignProjectUpdateRequest body) async {
    _updateResponse = ApiResponse.loading();
    notifyListeners();
    try {
      final updated = await _repo.update(id, body);
      _updateResponse = ApiResponse.success(updated);
      // Reflect the change in the already-loaded list, if present.
      final idx = projects.indexWhere((p) => p.id == id);
      if (idx != -1) {
        final newList = List<SmmDesignProject>.from(projects);
        newList[idx] = updated;
        _response = ApiResponse.success(newList);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _updateResponse = ApiResponse.error(e.toString());
      notifyListeners();
      return false;
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────
  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  Future<bool> deleteProject(String id) async {
    _isDeleting = true;
    notifyListeners();
    try {
      await _repo.delete(id);
      final newList = projects.where((p) => p.id != id).toList();
      _response = ApiResponse.success(newList);
      _isDeleting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _response = ApiResponse.idle();
    _detail = ApiResponse.idle();
    _updateResponse = ApiResponse.idle();
    notifyListeners();
  }
}
