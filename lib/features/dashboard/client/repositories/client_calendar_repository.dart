// lib/features/dashboard/client/repositories/client_calendar_repository.dart

import '../../../../core/network/api_service.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../model/client_calendar_model.dart';

/// Handles: GET /api/client/content-calendar
///
/// The API returns all posts for the month. We group them by day locally
/// so the calendar grid can show dots and the list can filter by selected date.
class ClientCalendarRepository {
  final ApiService _api;

  ClientCalendarRepository({ApiService? api}) : _api = api ?? ApiService();

  // ─────────────────────────────────────────────────────────────────────────
  // GET /api/client/content-calendar
  // Query param: month  (single combined value, e.g. ?month=2026-07)
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches the content calendar for [month]/[year].
  ///
  /// Sends a single combined `month` query param in `YYYY-MM` format
  /// (e.g. `2026-07`) instead of separate `month` and `year` params,
  /// since sending them separately caused the backend to calculate the
  /// wrong date range.
  ///
  /// Returns a map of  day-of-month → List<ClientCalendarPost>
  /// so the UI can instantly look up posts for any selected date.
  Future<Map<int, List<ClientCalendarPost>>> fetchCalendar({
    required int month,
    required int year,
  }) async {
    final monthParam =
        '$year-${month.toString().padLeft(2, '0')}'; // e.g. 2026-07

    final raw = await _api.get(
      '/api/client/content-calendar',
      queryParams: {'month': monthParam},
    );

    _assertSuccess(raw, 'Failed to fetch calendar.');

    // Unwrap posts list — handle common response shapes:
    //   { success: true, data: { posts: [...] } }
    //   { success: true, data: [...] }
    //   { success: true, posts: [...] }
    List<dynamic> postsList;
    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      final inner = data['posts'] ?? data['data'] ?? data['items'];
      postsList = inner is List ? inner : [];
    } else if (data is List) {
      postsList = data;
    } else {
      final fallback = raw['posts'] ?? raw['items'];
      postsList = fallback is List ? fallback : [];
    }

    // Parse and group by day
    final grouped = <int, List<ClientCalendarPost>>{};
    for (final item in postsList) {
      if (item is! Map<String, dynamic>) continue;
      final post = ClientCalendarPost.fromJson(item);
      final day = post.scheduledAt?.day;
      if (day == null) continue;
      grouped.putIfAbsent(day, () => []).add(post);
    }

    return grouped;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _assertSuccess(Map<String, dynamic> raw, String fallback) {
    if (raw['success'] == true) return;

    final msg = raw['msg']?.toString() ??
        raw['message']?.toString() ??
        raw['error']?.toString() ??
        fallback;

    final code = raw['statusCode'] as int?;
    if (code == 401) throw UnauthorizedException(msg);
    if (code == 404) throw NotFoundException(msg);
    throw ServerException(msg, statusCode: code);
  }
}