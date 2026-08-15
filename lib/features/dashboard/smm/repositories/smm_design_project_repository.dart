// lib/features/dashboard/smm/repositories/smm_design_project_repository.dart

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_service.dart';
import '../../../../model/smm_design_project_model.dart';

class SmmDesignProjectRepository {
  final ApiService _api = ApiService();

  // GET /api/smm/design-projects
  Future<List<SmmDesignProject>> fetchAll() async {
    final res = await _api.get(AppConstants.createDesignProject);
    final data = res['data'];
    final raw = (data is Map ? data['projects'] : null) ??
        (data is Map ? data['designProjects'] : null) ??
        res['projects'] ??
        res['data'] ??
        res;
    final list = raw is List ? raw.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
    return list.map(SmmDesignProject.fromJson).toList();
  }

  // GET /api/smm/design-projects/:id
  Future<SmmDesignProject> fetchById(String id) async {
    final res = await _api.get('${AppConstants.createDesignProject}/$id');
    final data = res['data'];
    final raw = (data is Map ? data['project'] : null) ??
        (data is Map ? data : null) ??
        res['project'] ??
        res;
    return SmmDesignProject.fromJson(raw as Map<String, dynamic>);
  }

  // PUT /api/smm/design-projects/:id
  Future<SmmDesignProject> update(String id, SmmDesignProjectUpdateRequest body) async {
    final res = await _api.put(
      '${AppConstants.createDesignProject}/$id',
      body: body.toJson(),
    );
    final data = res['data'];
    final raw = (data is Map ? data['project'] : null) ??
        (data is Map ? data : null) ??
        res['project'] ??
        res;
    return SmmDesignProject.fromJson(raw as Map<String, dynamic>);
  }

  // DELETE /api/smm/design-projects/:id
  Future<void> delete(String id) async {
    await _api.delete('${AppConstants.createDesignProject}/$id');
  }
}
