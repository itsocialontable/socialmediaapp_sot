// lib/core/providers/posts_analytics_provider.dart

import 'package:flutter/material.dart';
import '../errors/api_response.dart';
import '../../model/posts_analytics_overview_model.dart';
import '../../features/dashboard/smm/repositories/posts_analytics_repository.dart';

class PostsAnalyticsProvider extends ChangeNotifier {
  final PostsAnalyticsRepository _repo = PostsAnalyticsRepository();

  ApiResponse<PostsOverviewAnalytics> _response = ApiResponse.idle();
  ApiResponse<PostsOverviewAnalytics> get response => _response;

  /// Convenience getter — always non-null, falls back to a zeroed model so
  /// the UI can render immediately without null checks everywhere.
  PostsOverviewAnalytics get overview =>
      _response.data ?? PostsOverviewAnalytics.empty();

  /// Currently applied client scope, if any.
  String? _clientId;
  String? get clientId => _clientId;

  Future<void> fetchOverview({String? clientId, bool silent = false}) async {
    _clientId = clientId;
    if (!silent) {
      _response = ApiResponse.loading();
      notifyListeners();
    }
    try {
      final data = await _repo.fetchOverview(clientId: clientId);
      _response = ApiResponse.success(data);
    } catch (e) {
      _response = ApiResponse.error(e.toString());
    }
    notifyListeners();
  }

  /// Pull-to-refresh — re-fetches with the currently applied clientId
  /// without flashing the loading state.
  Future<void> refresh() => fetchOverview(clientId: _clientId, silent: true);

  void reset() {
    _response = ApiResponse.idle();
    _clientId = null;
    notifyListeners();
  }
}
