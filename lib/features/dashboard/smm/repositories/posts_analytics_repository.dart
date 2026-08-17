// lib/features/dashboard/smm/repositories/posts_analytics_repository.dart

import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/network/api_service.dart';
import '../../../../../../core/errors/app_exceptions.dart';
import '../../../../../../model/posts_analytics_overview_model.dart';

class PostsAnalyticsRepository {
  final ApiService _api = ApiService();

  /// GET /api/posts/overviewAnalytics
  ///
  /// Returns posts + analytics overview for the logged-in SMM, or for one
  /// client when [clientId] is passed (used by Admin, or by SMM to drill
  /// into a specific client).
  Future<PostsOverviewAnalytics> fetchOverview({String? clientId}) async {
    try {
      final res = await _api.get(
        AppConstants.postsOverviewAnalytics,
        queryParams: (clientId != null && clientId.trim().isNotEmpty)
            ? {'clientId': clientId.trim()}
            : null,
      );

      if (res['success'] == false) {
        throw ServerException(
          (res['message'] ?? 'Failed to load analytics overview.').toString(),
        );
      }

      final data = res['data'];
      if (data is! Map<String, dynamic>) {
        throw const ServerException(
          'Unexpected response format from analytics overview API.',
        );
      }

      return PostsOverviewAnalytics.fromJson(data);
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }
}
