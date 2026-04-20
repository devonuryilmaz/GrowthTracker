import 'package:flutter/foundation.dart';
import 'package:growth_tracker/models/daily_task.dart';
import 'package:growth_tracker/services/api_service.dart';

class StatsProvider extends ChangeNotifier {
  List<DailyTask> _history = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;

  List<DailyTask> get history => _history;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCompleted => _stats?['totalCompleted'] as int? ?? 0;
  List<dynamic> get byCategory => _stats?['byCategory'] as List<dynamic>? ?? [];

  int get currentStreak {
    if (_history.isEmpty) return 0;
    final completedDates = _history
        .where((t) => t.completedAt != null)
        .map((t) {
          final d = t.completedAt!.toLocal();
          return DateTime(d.year, d.month, d.day);
        })
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (completedDates.isEmpty) return 0;
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    int streak = 0;
    DateTime expected = todayNorm;
    for (final date in completedDates) {
      if (date == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else if (date.isBefore(expected)) {
        break;
      }
    }
    return streak;
  }

  int get weeklyCompleted {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _history
        .where((t) => t.completedAt != null && t.completedAt!.isAfter(cutoff))
        .length;
  }

  final ApiService _api = ApiService();

  Future<void> loadHistory(String userId, {int days = 30}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _history = await _api.fetchHistory(userId, days: days);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _api.fetchStats(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
