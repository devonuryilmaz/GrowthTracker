import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:growth_tracker/models/user_model.dart';
import 'package:growth_tracker/services/api_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  final ApiService _api = ApiService();

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId');
    if (id == null) return;

    _user = UserModel(
      id: id,
      name: prefs.getString('userName') ?? '',
      job: prefs.getString('userJob') ?? '',
      age: prefs.getInt('userAge') ?? 0,
      focusArea: prefs.getString('userFocusArea') ?? '',
    );
    notifyListeners();
  }

  Future<void> syncUser({
    String? id,
    required String name,
    required String job,
    required int age,
    required String focusArea,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _api.syncUser(
        id: id,
        name: name,
        job: job,
        age: age,
        focusArea: focusArea,
      );
      _user = user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.id);
      await prefs.setString('userName', user.name);
      await prefs.setString('userJob', user.job);
      await prefs.setInt('userAge', user.age);
      await prefs.setString('userFocusArea', user.focusArea);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _user = null;
    notifyListeners();
  }
}
