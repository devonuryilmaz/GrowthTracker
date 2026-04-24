import 'package:flutter/foundation.dart';
import 'package:growth_tracker/models/daily_task.dart';
import 'package:growth_tracker/services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  List<DailyTask> _todayTasks = [];
  DailyTask? _activeTask;
  bool _isLoading = false;
  String? _error;

  List<DailyTask> get todayTasks => _todayTasks;
  DailyTask? get activeTask => _activeTask;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveTask => _activeTask != null;
  bool get isTodayCompleted => _activeTask?.isCompleted ?? false;

  /// Bugün tamamlanan görev sayısı (maksimum 3)
  int get completedTodayCount {
    final today = DateTime.now();
    return _todayTasks.where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      final d = t.completedAt!;
      return d.year == today.year && d.month == today.month && d.day == today.day;
    }).length;
  }

  /// Kullanıcı bugün daha fazla görev seçebilir mi?
  bool get canSelectMore => completedTodayCount < 3;

  final ApiService _api = ApiService();

  Future<void> loadTodayTasks(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todayTasks = await _api.fetchTodayTasks(userId);
      _activeTask = _todayTasks
          .where((t) => t.isSelected && !t.isCompleted)
          .firstOrNull;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<TaskSuggestion>> loadSuggestions(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final suggestions = await _api.fetchSuggestions(userId);
      return suggestions;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> selectTask(int taskId, String userId) async {
    try {
      await _api.selectTask(taskId, userId);
      // Seçilen görevi aktif olarak işaretle, önceki seçimi kaldır
      for (final task in _todayTasks) {
        task.isSelected = task.id == taskId;
      }
      _activeTask = _todayTasks.where((t) => t.id == taskId).firstOrNull;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeTask(int taskId, String userId) async {
    try {
      await _api.completeTask(taskId, userId);
      final idx = _todayTasks.indexWhere((t) => t.id == taskId);
      if (idx != -1) {
        _todayTasks[idx].isCompleted = true;
      }
      final now = DateTime.now();
      final activeIdx = _todayTasks.indexWhere((t) => t.id == taskId);
      if (activeIdx != -1) {
        _todayTasks[activeIdx].isCompleted = true;
        _todayTasks[activeIdx].completedAt = now;
      }
      if (_activeTask?.id == taskId) {
        _activeTask!.isCompleted = true;
        _activeTask!.completedAt = now;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> loadTaskExamples(
      int taskId, String userId) async {
    try {
      return await _api.fetchTaskExamples(taskId, userId);
    } catch (e) {
      return [];
    }
  }

  Future<DailyTask?> selectSuggestion(
      TaskSuggestion suggestion, String userId) async {
    try {
      final task = await _api.createAndSelectSuggestion(suggestion, userId);
      _todayTasks.add(task);
      _activeTask = task;
      notifyListeners();
      return task;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
