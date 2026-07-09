// lib/core/providers/client_calendar_provider.dart

import 'package:flutter/material.dart';
import '../errors/api_response.dart';
import '../errors/app_exceptions.dart';
import '../../model/client_calendar_model.dart';
import '../../features/dashboard/client/repositories/client_calendar_repository.dart';

class ClientCalendarProvider extends ChangeNotifier {
  final ClientCalendarRepository _repo;

  ClientCalendarProvider({ClientCalendarRepository? repo})
      : _repo = repo ?? ClientCalendarRepository();

  // ── State ─────────────────────────────────────────────────────────────────

  /// Full grouped map: day → posts for the currently loaded month/year
  ApiResponse<Map<int, List<ClientCalendarPost>>> _calendarState =
      ApiResponse.idle();
  ApiResponse<Map<int, List<ClientCalendarPost>>> get calendarState =>
      _calendarState;

  /// Currently viewed month and year
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  int get month => _month;
  int get year => _year;

  /// Currently selected day
  int _selectedDay = DateTime.now().day;
  int get selectedDay => _selectedDay;

  // ── Derived helpers ───────────────────────────────────────────────────────

  Map<int, List<ClientCalendarPost>> get groupedPosts =>
      _calendarState.data ?? {};

  /// Posts for the currently selected day
  List<ClientCalendarPost> get postsForSelectedDay =>
      groupedPosts[_selectedDay] ?? [];

  /// Days that have at least one post (for dot indicators on the grid)
  Set<int> get daysWithPosts => groupedPosts.keys.toSet();

  /// Total post count for a given day
  int postCountForDay(int day) => groupedPosts[day]?.length ?? 0;

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Load calendar for the current [_month] / [_year].
  /// Set [silent] to skip the loading spinner (e.g. background refresh).
  Future<void> fetchCalendar({bool silent = false}) async {
    if (!silent) {
      _calendarState = ApiResponse.loading();
      notifyListeners();
    }

    try {
      final grouped = await _repo.fetchCalendar(month: _month, year: _year);
      _calendarState = ApiResponse.success(grouped);
    } on AppException catch (e) {
      _calendarState = ApiResponse.error(
        e.message,
        statusCode: e is ServerException ? e.statusCode : null,
      );
    } catch (e) {
      _calendarState = ApiResponse.error('An unexpected error occurred.');
    }

    notifyListeners();
  }

  /// Select a different day — triggers UI rebuild instantly (no API call).
  void selectDay(int day) {
    if (_selectedDay == day) return;
    _selectedDay = day;
    notifyListeners();
  }

  /// Navigate to the previous month and reload.
  Future<void> previousMonth() async {
    if (_month == 1) {
      _month = 12;
      _year -= 1;
    } else {
      _month -= 1;
    }
    _selectedDay = 1;
    await fetchCalendar();
  }

  /// Navigate to the next month and reload.
  Future<void> nextMonth() async {
    if (_month == 12) {
      _month = 1;
      _year += 1;
    } else {
      _month += 1;
    }
    _selectedDay = 1;
    await fetchCalendar();
  }

  /// Month name string for display
  String get monthName => const [
        '',
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][_month];

  String get shortMonthName => monthName.substring(0, 3);
}
