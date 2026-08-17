// lib/core/providers/client_design_project_provider.dart

import 'package:flutter/material.dart';
import '../errors/api_response.dart';
import '../errors/app_exceptions.dart';
import '../../model/client_design_project_model.dart';
import '../../features/dashboard/client/repositories/client_design_project_repository.dart';

/// Provider that manages state for the client's design-project section.
///
/// Covers:
///   • Fetching the list of all projects
///   • Fetching a single project's detail
///   • Submitting a review action (approve / request changes)
class ClientDesignProjectProvider extends ChangeNotifier {
  final ClientDesignProjectRepository _repo;

  ClientDesignProjectProvider({ClientDesignProjectRepository? repo})
      : _repo = repo ?? ClientDesignProjectRepository();

  // ── List state ───────────────────────────────────────────────────────────

  ApiResponse<List<ClientDesignProject>> _listState = ApiResponse.idle();
  ApiResponse<List<ClientDesignProject>> get listState => _listState;

  List<ClientDesignProject> get allProjects => _listState.data ?? [];

  List<ClientDesignProject> get pendingReviewProjects => allProjects
      .where((p) => p.isPendingReview)
      .toList();

  List<ClientDesignProject> get inProgressProjects => allProjects
      .where((p) => p.isInProgress)
      .toList();

  List<ClientDesignProject> get completedProjects => allProjects
      .where((p) => p.isCompleted)
      .toList();

  List<ClientDesignProject> get approvedProjects => allProjects
      .where((p) => p.isApproved)
      .toList();

  // ── Detail state ─────────────────────────────────────────────────────────

  ApiResponse<ClientDesignProject> _detailState = ApiResponse.idle();
  ApiResponse<ClientDesignProject> get detailState => _detailState;

  ClientDesignProject? get selectedProject => _detailState.data;

  // ── Review state ─────────────────────────────────────────────────────────

  ApiResponse<ClientDesignProject> _reviewState = ApiResponse.idle();
  ApiResponse<ClientDesignProject> get reviewState => _reviewState;

  // ─────────────────────────────────────────────────────────────────────────
  // Fetch all projects — GET /api/client/design-projects
  // ─────────────────────────────────────────────────────────────────────────

  /// Loads all design projects from the API.
  ///
  /// [status] — optional filter, e.g. 'Pending', 'In Progress', 'SMM Review',
  /// 'Client Review', 'Revision', 'Completed', 'Cancelled'. Pass `null` (or
  /// omit) to load all projects.
  ///
  /// Set [silent] to true to skip the loading indicator (e.g. pull-to-refresh).
  Future<void> fetchProjects({String? status, bool silent = false}) async {
    if (!silent) {
      _listState = ApiResponse.loading();
      notifyListeners();
    }

    try {
      final projects = await _repo.fetchProjects(status: status);
      _listState = ApiResponse.success(projects);
    } on AppException catch (e) {
      _listState = ApiResponse.error(
        e.message,
        statusCode: e is ServerException ? e.statusCode : null,
      );
    } catch (e) {
      _listState = ApiResponse.error('An unexpected error occurred.');
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fetch single project — GET /api/client/design-projects/:id
  // ─────────────────────────────────────────────────────────────────────────

  /// Loads the detail for a single project by [id].
  ///
  /// On success the project is stored in [detailState].
  Future<void> fetchProjectById(String id) async {
    _detailState = ApiResponse.loading();
    // Also reset review state so the detail sheet starts fresh
    _reviewState = ApiResponse.idle();
    notifyListeners();

    try {
      final project = await _repo.fetchProjectById(id);
      _detailState = ApiResponse.success(project);
    } on AppException catch (e) {
      _detailState = ApiResponse.error(
        e.message,
        statusCode: e is ServerException ? e.statusCode : null,
      );
    } catch (e) {
      _detailState = ApiResponse.error('An unexpected error occurred.');
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Submit review — PATCH /api/client/design-projects/:id/review
  // ─────────────────────────────────────────────────────────────────────────

  /// Submits a review action for project [projectId].
  ///
  /// [action]   — 'approved' | 'changes_requested'
  /// [feedback] — required when action is 'changes_requested'
  ///
  /// Returns `true` on success. On failure, [reviewState] holds the error.
  Future<bool> submitReview({
    required String projectId,
    required String action,
    String feedback = '',
  }) async {
    _reviewState = ApiResponse.loading();
    notifyListeners();

    try {
      final request = ClientDesignProjectReviewRequest(
        action: action,
        feedback: feedback,
      );

      final updated = await _repo.submitReview(
        projectId: projectId,
        request: request,
      );

      _reviewState = ApiResponse.success(
        updated,
        message: action == 'approved'
            ? 'Project approved successfully!'
            : 'Change request submitted successfully!',
      );

      // Optimistically patch the local list so the UI reflects the new status
      // without requiring a full refresh.
      _patchProjectInList(updated);

      // Also update detail state if it's for the same project
      if (_detailState.data?.id == projectId) {
        _detailState = ApiResponse.success(updated);
      }

      notifyListeners();
      return true;
    } on ValidationException catch (e) {
      _reviewState = ApiResponse.error(e.message);
      notifyListeners();
      return false;
    } on AppException catch (e) {
      _reviewState = ApiResponse.error(
        e.message,
        statusCode: e is ServerException ? e.statusCode : null,
      );
      notifyListeners();
      return false;
    } catch (e) {
      _reviewState = ApiResponse.error('An unexpected error occurred.');
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // State reset helpers
  // ─────────────────────────────────────────────────────────────────────────

  void resetDetail() {
    _detailState = ApiResponse.idle();
    _reviewState = ApiResponse.idle();
    notifyListeners();
  }

  void resetReview() {
    _reviewState = ApiResponse.idle();
    notifyListeners();
  }

  void resetAll() {
    _listState = ApiResponse.idle();
    _detailState = ApiResponse.idle();
    _reviewState = ApiResponse.idle();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Replaces the matching entry in the projects list with [updated] so the
  /// UI reflects the server change without requiring a full re-fetch.
  void _patchProjectInList(ClientDesignProject updated) {
    final current = _listState.data;
    if (current == null) return;

    final idx = current.indexWhere((p) => p.id == updated.id);
    if (idx == -1) return;

    // Only update if the stub has meaningful data; otherwise keep the original
    // and just update its status field.
    final replacement = updated.title.isEmpty ? current[idx] : updated;
    final patched = List<ClientDesignProject>.from(current);
    patched[idx] = replacement;
    _listState = ApiResponse.success(patched, message: _listState.message);
  }
}