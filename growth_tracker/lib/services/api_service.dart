import 'package:flutter/material.dart';
import 'package:growth_tracker/models/reminder.dart';
import 'package:growth_tracker/models/user_model.dart';
import 'package:growth_tracker/models/daily_task.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:growth_tracker/helper/helper.dart';

class ApiService {
  // API service methods will be implemented here

  final String baseUrl = "http://localhost:5058/api";

  Future<List<Reminder>> fetchReminders() async {
    final response = await http.get(Uri.parse('$baseUrl/reminders/upcoming'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Reminder.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load reminders');
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reminders'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'title': reminder.title,
        'description': reminder.description,
        'reminderDate': reminder.reminderDate.toIso8601String(),
        'isCompleted': reminder.isCompleted,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add reminder');
    }
  }

  Future<void> sendTokenToServer(String token, String platform) async {
    final url = Uri.parse('$baseUrl/deviceToken');
    
    // Cihaz ID'sini helper'dan al
    String deviceId = await getDeviceId();
    
    final body = jsonEncode({
      'userId': null,
      'deviceId': deviceId,
      'token': token,
      'platform': platform,
    });

    try {
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"}, body: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Token sent successfully to server.');
      } else {
        print(
            'Failed to send token to server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }

  // --- User ---

  Future<UserModel> syncUser({
    String? id,
    required String name,
    required String job,
    required int age,
    required String focusArea,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/sync'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'id': id,
        'name': name,
        'job': job,
        'age': age,
        'focusArea': focusArea,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return UserModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to sync user: ${response.statusCode}');
  }

  Future<UserModel> getUser(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get user: ${response.statusCode}');
  }

  // --- Daily Tasks ---

  Future<List<DailyTask>> fetchTodayTasks(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dailytasks/today?userId=$userId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((e) => DailyTask.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch today tasks: ${response.statusCode}');
  }

  Future<List<TaskSuggestion>> fetchSuggestions(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ai/suggestions?userId=$userId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((e) => TaskSuggestion.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch suggestions: ${response.statusCode}');
  }

  Future<DailyTask> createAndSelectSuggestion(
      TaskSuggestion suggestion, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/dailytasks/from-suggestion?userId=$userId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'title': suggestion.title,
        'description': suggestion.description,
        'category': suggestion.category,
        'estimatedMinutes': suggestion.estimatedMinutes,
      }),
    );
    if (response.statusCode == 200) {
      return DailyTask.fromJson(jsonDecode(response.body));
    }
    throw Exception(
        'Failed to create task from suggestion: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> selectTask(int taskId, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/dailytasks/$taskId/select?userId=$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to select task: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> completeTask(int taskId, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/dailytasks/$taskId/complete?userId=$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to complete task: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> fetchTaskExamples(
      int taskId, String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ai/task-examples?taskId=$taskId&userId=$userId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch task examples: ${response.statusCode}');
  }

  Future<List<DailyTask>> fetchHistory(String userId, {int days = 30}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dailytasks/history?userId=$userId&days=$days'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((e) => DailyTask.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch history: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> fetchStats(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dailytasks/stats?userId=$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch stats: ${response.statusCode}');
  }
}
