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
