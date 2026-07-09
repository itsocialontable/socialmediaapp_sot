// lib/features/dashboard/client/repositories/client_design_project_repository.dart

import '../../../../core/network/api_service.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../model/client_design_project_model.dart';

/// Repository that maps raw API responses for the 3 client design-project
/// endpoints into typed Dart objects.
///
/// Endpoints handled:
///   GET   /api/client/design-projects
///   GET   /api/client/design-projects/:id
///   PATCH /api/client/design-projects/:id/review  { action, feedback }
class ClientDesignProjectRepository {
  final ApiService _api;

  ClientDesignProjectRepository({ApiService? api}) : _api = api ?? ApiService();

  // ─────────────────────────────────────────────────────────────────────────
  // GET /api/client/design-projects
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches all design projects for the authenticated client.
  /// Returns a [List<ClientDesignProject>] on success.
  /// Throws an [AppException] on any network / server error.
  Future<List<ClientDesignProject>> fetchProjects() async {
    final raw = await _api.get('/api/client/design-projects');

    _assertSuccess(raw, 'Failed to fetch design projects.');

    final data = raw['data'];
    List<dynamic> projectsJson;

    // Handle both { data: { projects: [...] } } and { data: [...] }
    if (data is Map<String, dynamic>) {
      final inner = data['projects'] ?? data['data'];
      projectsJson = inner is List ? inner : [];
    } else if (data is List) {
      projectsJson = data;
    } else {
      projectsJson = [];
    }

    return projectsJson
        .whereType<Map<String, dynamic>>()
        .map(ClientDesignProject.fromJson)
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET /api/client/design-projects/:id
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches a single design project by [id].
  /// Throws [NotFoundException] if not found, [AppException] on other errors.
  Future<ClientDesignProject> fetchProjectById(String id) async {
    if (id.trim().isEmpty) {
      throw const ValidationException('Project ID must not be empty.');
    }

    final raw = await _api.get('/api/client/design-projects/$id');

    _assertSuccess(raw, 'Failed to fetch project details.');

    final data = raw['data'];
    Map<String, dynamic> projectJson;

    if (data is Map<String, dynamic>) {
      // Some APIs nest under { data: { project: {...} } }
      final inner = data['project'];
      projectJson = inner is Map<String, dynamic> ? inner : data;
    } else {
      throw ServerException(
        raw['msg']?.toString() ?? 'Unexpected response format.',
      );
    }

    return ClientDesignProject.fromJson(projectJson);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PATCH /api/client/design-projects/:id/review
  // ─────────────────────────────────────────────────────────────────────────

  /// Submits a review action for the project with [projectId].
  ///
  /// [request.action]   — 'approved' | 'changes_requested'
  /// [request.feedback] — required when action is 'changes_requested'
  ///
  /// Returns the updated [ClientDesignProject] on success.
  /// Throws a [ValidationException] on invalid input, [AppException] otherwise.
  Future<ClientDesignProject> submitReview({
    required String projectId,
    required ClientDesignProjectReviewRequest request,
  }) async {
    if (projectId.trim().isEmpty) {
      throw const ValidationException('Project ID must not be empty.');
    }
    _validateReviewRequest(request);

    final raw = await _api.patch(
      '/api/client/design-projects/$projectId/review',
      body: request.toJson(),
    );

    _assertSuccess(raw, 'Failed to submit review.');

    final data = raw['data'];
    Map<String, dynamic>? projectJson;

    if (data is Map<String, dynamic>) {
      final inner = data['project'];
      projectJson = inner is Map<String, dynamic> ? inner : data;
    }

    if (projectJson != null && projectJson.containsKey('_id')) {
      return ClientDesignProject.fromJson(projectJson);
    }

    // Server may return just { success: true, msg: '...' } without updated doc.
    // Return a minimal stub; the provider will refresh the list automatically.
    return _stubProjectFromReview(projectId, request);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Asserts `success == true` in [raw]; otherwise extracts the server message
  /// and throws the appropriate [AppException].
  void _assertSuccess(Map<String, dynamic> raw, String fallback) {
    if (raw['success'] == true) return;

    final msg = raw['msg']?.toString() ??
        raw['message']?.toString() ??
        raw['error']?.toString() ??
        fallback;

    final code = raw['statusCode'] as int?;
    if (code == 422 || code == 400) throw ValidationException(msg);
    if (code == 404) throw NotFoundException(msg);
    throw ServerException(msg, statusCode: code);
  }

  /// Validates the review request before sending to the API.
  void _validateReviewRequest(ClientDesignProjectReviewRequest req) {
    const validActions = {'approved', 'changes_requested'};
    if (!validActions.contains(req.action)) {
      throw ValidationException(
        'Invalid action "${req.action}". '
        'Must be one of: ${validActions.join(", ")}.',
      );
    }
    if (req.action == 'changes_requested' && req.feedback.trim().isEmpty) {
      throw const ValidationException(
        'Feedback is required when requesting changes.',
      );
    }
  }

  /// Returns a minimal stub when the server doesn't echo back the full project.
  ClientDesignProject _stubProjectFromReview(
    String id,
    ClientDesignProjectReviewRequest req,
  ) {
    return ClientDesignProject(
      id: id,
      title: '',
      designType: '',
      priority: '',
      status: req.action == 'approved' ? 'approved' : 'changes requested',
      description: '',
      progressPercentage: 0,
      reviewAction: req.action,
      clientFeedback: req.feedback,
    );
  }
}
